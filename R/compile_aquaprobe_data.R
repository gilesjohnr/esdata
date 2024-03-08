#' Compile aquaprobe data
#'
#' This function consumes .csv files produced by the `parse_aquaprobe_xlsx` and compiles them into a single data set.
#'
#' @param path_in A full file path to the directory containing parsed .csv files.
#' @param path_out A full file path to the location where output files are to be written.
#' @param verbose Logical indicating whether to print messages.
#'
#' @returns data.frame
#'
#' @examples
#' \dontrun{
#' compile_aquaprobe_data(path_in = "/User/test/aquaprobe/raw/csv/input.csv",
#'                        path_out = "/User/test/aquaprobe")
#' }



compile_aquaprobe_data <- function(path_in,
                                   path_out,
                                   verbose=TRUE
) {

     # Check directories
     for (i in seq_along(path_in)) if (!file.exists(path_in[i])) stop("path_in not valid")
     if (!dir.exists(path_out)) dir.create(path_out, recursive=TRUE)
     if (!dir.exists(path_out)) stop("path_out not valid")

     all_aquaprobe_data_sets <- list()

     for (i in seq_along(path_in)) {

          if (verbose) message(path_in[i])
          tmp <- as.data.frame(data.table::fread(path_in[i]))

          for (j in colnames(tmp)) {

               if (j %in% c('Date & Time', 'SAMPLE ID', 'Lat', 'Lon', 'Collection site')) {

                    tmp[,j] <- suppressWarnings(as.character(tmp[,j]))

               } else {

                    tmp[,j] <- suppressWarnings(as.numeric(tmp[,j]))

               }

          }

          tmp <- tmp[!(colnames(tmp) %in% c('ID', 'Tag', 'Collection time (AM)', 'DOC', 'SL', 'SL NO'))]

          tmp_file_name <- stringr::str_split(path_in[i], "[./]", simplify=TRUE)
          tmp_file_name <- tmp_file_name[length(tmp_file_name)-1]
          tmp$aquaprobe_file_name <- tmp_file_name

          all_aquaprobe_data_sets <- c(all_aquaprobe_data_sets, list(tmp))

     }


     ap <- as.data.frame(data.table::rbindlist(all_aquaprobe_data_sets, fill=TRUE))

     if (verbose) message('Consolidating duplicated measurements')
     ap_consolidated_numeric <- lapply(
          split(ap, as.factor(ap$`SAMPLE ID`)),
          function(x) {

               for (i in 1:ncol(x)) {

                    if (is.numeric(x[,i])) x[1,i] <- mean(x[,i], na.rm=TRUE)

               }

               return(x[1,])

          }
     )

     out <- do.call(rbind, ap_consolidated_numeric)
     rm(ap_consolidated_numeric)

     if (verbose) message('Converting dates')
     out$aquaprobe_date <- convert_date_time(out$`Date & Time`)
     out <- out[!(colnames(out) == 'Date & Time')]


     if (verbose) message('Converting spatial coordinates')
     tmp <- convert_dms_to_dd(out$Lat)
     out$lat_dms <- tmp$dms
     out$lat_dd <- tmp$dd

     tmp <- convert_dms_to_dd(out$Lon)
     out$lon_dms <- tmp$dms
     out$lon_dd <- tmp$dd

     out <- out[!(colnames(out) %in% c('Lat', 'Lon'))]

     if (verbose) message('Cleaning up')
     colnames(out)[colnames(out) == 'SAMPLE ID'] <- 'aquaprobe_id'
     colnames(out)[colnames(out) == 'Temperature'] <- 'temperature'
     colnames(out)[colnames(out) == 'Barometric_pressure'] <- 'barometric_pressure'
     colnames(out)[colnames(out) == 'Depth'] <- 'depth'
     colnames(out)[colnames(out) == 'pH'] <- 'ph'
     colnames(out)[colnames(out) == 'pHmV'] <- 'ph_millivolt'
     colnames(out)[colnames(out) == 'ORP'] <- 'oxidation_reduction_potential'
     colnames(out)[colnames(out) == 'DO_sat'] <- 'dissolved_oxygen_percent_saturation'
     colnames(out)[colnames(out) == 'DO_mgL'] <- 'dissolved_oxygen_mg_l'
     colnames(out)[colnames(out) == 'EC'] <- 'electrical_conductivity'
     colnames(out)[colnames(out) == 'RES'] <- 'resistivity'
     colnames(out)[colnames(out) == 'TDS'] <- 'total_dissolved_solids'
     colnames(out)[colnames(out) == 'SAL'] <- 'salinity'
     colnames(out)[colnames(out) == 'Turbidity'] <- 'turbidity'
     colnames(out)[colnames(out) == 'Alt'] <- 'altitude'
     colnames(out)[colnames(out) == 'SSG'] <- 'specific_gravity'
     colnames(out)[colnames(out) == 'Alt'] <- 'altitude'
     colnames(out)[colnames(out) == 'Lat'] <- 'lat'
     colnames(out)[colnames(out) == 'Lon'] <- 'lon'
     colnames(out)[colnames(out) == 'Collection site'] <- 'location_name'
     colnames(out)[colnames(out) == 'Ward No.'] <- 'ward_id'
     colnames(out)[colnames(out) == 'Location No.'] <- 'location_id'
     colnames(out)[colnames(out) == 'Water collected (litre)'] <- 'liters_water_collected'
     colnames(out)[colnames(out) == 'Water through filter (litre)'] <- 'liters_water_through_filter'
     colnames(out)[colnames(out) == 'Water left in bag (litre)'] <- 'liters_water_left_in_bag'

     tmp_path <- file.path(path_out, 'compiled_aquaprobe.csv')
     data.table::fwrite(out, file=tmp_path)
     if (verbose) message(paste('Compiled aquaprobe data is here:', tmp_path))

}
