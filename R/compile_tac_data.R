#' Compile TAC data
#'
#' This function consumes .csv files produced by the `parse_taq_eds` and `parse_taq_xls` and compiles them into a single data set. When compiling, duplicated names are corrected as defined by the data in the
#' `key` data set included in this package. Adjustments to the Ct values are made using blank samples to control for contamination and relevant RNA/DNA targets as qPCR amplification controls.
#'
#' @param path_in A full file path to the directory containing parsed .csv files.
#' @param path_out A full file path to the location where output files are to be written.
#' @param tau The threshold Ct value for the amplification control. For each TAC, when relevant amplification controls (e.g. MS2, PhHV) are BELOW this threshold, "Undetermined" responses can be set to this threshold value.
#' @param key A data.frame containing the mapping of unique and concise target names and amplification controls. See \code{esdata::key_dhaka} for template.
#' @param verbose Logical indicating whether to print messages. Default set to TRUE.
#'
#' @returns data.frame
#'
#' @examples
#' \dontrun{
#' compile_tac_data(path_in = "/User/test/rtac/raw/csv",
#'                  path_out = "/User/test/rtac",
#'                  key = esdata::key_dhaka)
#' }

compile_tac_data <- function(path_in,
                             path_out,
                             tau,
                             key,
                             verbose=TRUE
) {

     csv_file_paths <- list.files(path_in, pattern='.csv', full.names=TRUE)

     if (verbose) message('Precheck .csv files')
     ncols <- unlist(lapply(csv_file_paths, function(x) ncol(utils::read.csv(x))))
     ncols_expected <- as.numeric(names(sort(table(ncols), decreasing=TRUE))[1])
     sel <- which(ncols > ncols_expected)

     if (length(sel) > 0) {

          if (verbose) {

               message('Ignoring the following .csv files (too many columns):')
               message(paste0(utils::capture.output(csv_file_paths[sel]), collapse = "\n"))

          }

          csv_file_paths <- csv_file_paths[-sel]

     }

     if (verbose) message('Loading .csv files')
     d <- do.call(rbind, lapply(csv_file_paths, function(x) as.data.frame(data.table::fread(x)) ))

     tmp <- strsplit(d$experiment_name, " ")
     d$experiment_name <- unlist(lapply(tmp, function(x) paste(x[-1], collapse=" ")))

     d <- d[order(d$experiment_date, d$experiment_name),]

     # Mask any sensitive targets
     if (verbose) message('Removing excluded targets')
     target_exclude <- key[key$include == 0, 'target_name_concise']
     d <- d[!(d$target_name %in% target_exclude),]


     # Fix duplicated target names
     if (verbose) message('Fixing duplicated target names')

     pb <- .init_pb(nrow(d))

     for (i in 1:nrow(d)) {

          pb$tick()
          d$target_name[i] <- key[key$target_name_unique == d$target_name[i], 'target_name_concise']

     }

     pb$terminate()

     # Contamination control: use Blank samples to determine which 'Undetermined' samples are NA
     if (verbose) message('Editing ct_value responses based on contamination controls')

     # Get blank samples for taq card i
     d_blanks <- d[stringr::str_sub(d$sample_id, end=5) %in% c('BLANK', 'Blank', 'blank'),]

     # If blank not 'Undetermined' for a pathogen, then that pathogens ct value must be set to NA on that card
     d_blanks_contam <- d_blanks[d_blanks$ct_value != 'Undetermined',]

     # Get quick info on how many samples affected
     samples_contam <- unique(d_blanks$sample_id)
     if (verbose) message(glue::glue("Samples blanks with contaminated observations: {length(samples_contam)}"))
     message(paste0(utils::capture.output(samples_contam), collapse = "\n"))

     # Get quick info about how many observations affected
     observations_contam <- table(d_blanks_contam$target_name)
     if (verbose) message(glue::glue("Number observations removed due to contaminated blanks: {sum(observations_contam)}"))
     if (verbose) message(paste0(utils::capture.output(observations_contam), collapse = "\n"))

     # Get list of unique blank samples
     unique_samples <- unique(d[order(d$experiment_barcode, d$sample_id, d$well), 'sample_id'])
     sel_blanks <- stringr::str_sub(unique_samples, end=5) %in% c('BLANK', 'Blank', 'blank')
     unique_blanks <- unique_samples[sel_blanks]


     # List unique taq cards and whether they have a blank sample
     unique_cards <- unique(d[,c("experiment_date", "experiment_name", "experiment_barcode")])
     unique_cards <- unique_cards[order(unique_cards$experiment_date, unique_cards$experiment_barcode),]
     unique_cards$blank_samp_name <- unique_cards$blank <- NA

     for (i in 1:nrow(unique_cards)) {

          samps <- d$sample_id[d$experiment_name == unique_cards$experiment_name[i]]
          unique_cards$blank[i] <- as.integer(any(samps %in% unique_blanks))
          if (unique_cards$blank[i]) unique_cards$blank_samp_name[i] <- unique_blanks[unique_blanks %in% samps]

     }


     # Blank sample contamination affects card in point and following two cards
     # (likely need to revise this since spacing of blanks does not appear to be regular)
     for (i in 1:nrow(d_blanks_contam)) {

          sel <- which(unique_cards$experiment_name == d_blanks_contam$experiment_name[i])
          cards_contam <- unique_cards[(sel-1):(sel+2), 'experiment_name']
          d$ct_value[d$experiment_name %in% cards_contam & d$target_name == d_blanks_contam$target_name[i]] <- NA

     }

     # Remove all blank samples
     d <- d[!(d$sample_id %in% unique_blanks),]
     d <- d[!(d$sample_id == 'NFW'),]


     # Amplification control: use MS2 and PhHV controls to edit 'Undetermined' status to the Ct value cutoff (35)
     if (verbose) message('Editing ct_value responses based on amplification controls')

     unique_samples <- unique(d$sample_id)
     unique_targets <- unique(d$target_name)

     key_controls <- list(
          MS2 = c("MS2", "MS2_1", "MS2_2"),
          PhHV = c("PhHV", "PhHV_1", "PhHV_2")
     )

     pb <- .init_pb(length(unique_samples))

     for (i in 1:length(unique_samples)) {

          pb$tick()

          for(j in 1:length(unique_targets)) {

               if (!(unique_targets[j] %in% c('MS2_1', 'MS2_2', 'PhHV_1', 'PhHV_2', '18S', 'Hs99999901_s1'))) {

                    sel <- d$sample_id == unique_samples[i] & d$target_name == unique_targets[j]

                    if (nrow(d[sel,]) == 1) {

                         if (!is.na(d[sel, 'ct_value'])) {

                              if (d[sel, 'ct_value'] == 'Undetermined') {

                                   # Get the relevant amplification control(s) and their ct values
                                   control <- key_controls[[key[key$target_name_concise == unique_targets[j], 'control'][1]]]
                                   control_ct_value <- as.numeric(d[d$sample_id == unique_samples[i] & d$target_name %in% control, 'ct_value'])

                                   # Change 'Undetermined' responses as needed
                                   d[sel, 'ct_value'] <- ifelse(test=any(control_ct_value < tau), yes=tau, no=NA)

                              }

                         }

                    }

               }

          }

     }

     pb$terminate()


     if (verbose) message("Cleaning up remaining 'Undetermined' observations")
     d$ct_value[d$ct_value == 'Undetermined'] <- NA
     d$ct_value <- as.numeric(d$ct_value)

     if (verbose) message("Parsing sample id")
     tmp <- stringr::str_split(d$sample_id, "-", simplify=TRUE)
     d$aquaprobe_id <- tmp[,3]
     d$sample_date <- as.Date(tmp[,2], format="%d%b%y")

     d <- d[,c(1:6,10,9,7,8)]

     if (verbose) {

          message("Final data:")
          message(paste0(utils::capture.output(str(d)), collapse = "\n"))

     }

     tmp_path <- file.path(path_out, 'compiled_tac.csv')
     data.table::fwrite(d, file=tmp_path)
     if (verbose) message(paste('Compiled TAC data is here:', tmp_path))


}
