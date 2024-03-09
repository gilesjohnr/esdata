#' Parse Taqman .xls files
#'
#' This function takes a directory with .xls files produced by QuantStudio software and extracts its contents into individual csv files containing raw data.
#'
#' @param path_in A full file path to the directory containing the .xls files.
#' @param path_out A full file path to the location where output files are to be written.
#' @param verbose Logical indicating whether to print messages.
#'
#' @returns data.frame
#'
#' @examples
#' \dontrun{
#' parse_tac_xls(path_in = c("/User/test/dir1", "/Users/test/dir2"),
#'               path_out = "/User/test")
#' }

parse_tac_xls <- function(path_in,
                          path_out,
                          verbose=TRUE
) {

     # Check directories
     for (i in seq_along(path_in)) if (!dir.exists(path_in[i])) stop("path_in not valid")
     if (!dir.exists(path_out)) dir.create(path_out, recursive=TRUE)
     if (!dir.exists(path_out)) stop("path_out not valid")

     # Set output directories
     suppressWarnings(dir.create(file.path(path_out, 'raw/xls'), recursive=TRUE))
     suppressWarnings(dir.create(file.path(path_out, 'raw/csv'), recursive=TRUE))

     # Set file paths
     xls_file_paths <- unlist(sapply(path_in, function(x) list.files(x, pattern='.xls', full.names=TRUE)))

     # Get individual card names
     xls_file_names <- unlist(lapply(strsplit(xls_file_paths, "/"), function(x) x[length(x)]))
     xls_file_names <- stringr::str_sub(xls_file_names, end=-5)


     pb <- .init_pb(length(xls_file_paths))

     for (i in seq_along(xls_file_paths)) {

          pb$tick() # Update progress bar

          n_sheets <- length(readxl::excel_sheets(xls_file_paths[i]))

          if (n_sheets > 1) {

               warning(glue::glue("File exclude due to >1 sheet: \n {xls_file_paths[i]}"))

          } else {

               tmp <- xlsx::read.xlsx2(xls_file_paths[i], sheetIndex=1, header=FALSE, colIndex = 1:10)
               tmp <- tmp[!sapply(tmp, function (x) all(is.na(x) | x == ""))]


               # Header and data are separated by empty row
               row_blank <- which(apply(tmp, 1, function(x) all(x == "")))

               # Get row start of data
               row_data_column_names <- which(apply(tmp, 1, function(x) {

                    all(!is.na(x)) & any(c('Well', 'Sample Name') %in% x)

               }))

               # Parse header
               header <- tmp[2:(row_blank - 1),]
               colnames(header) <- tmp[1,]

               # Parse data
               data <- tmp[(row_data_column_names + 1):nrow(tmp),]
               colnames(data) <- tmp[row_data_column_names,]
               colnames(data)[colnames(data) == "Well"] <- 'well'
               colnames(data)[colnames(data) == "Well Position"] <- 'well_position'
               colnames(data)[colnames(data) == "Sample Name"] <- 'sample_id'
               colnames(data)[colnames(data) == "Target Name"] <- 'target_name'
               colnames(data)[colnames(data) == "CT"] <- 'ct_value'

               # Get experiment date
               experiment_date <- header[header$`Block Type` == "Experiment Run End Time", 2]
               experiment_date <- unlist(strsplit(experiment_date, " "))[1]
               experiment_date <- as.Date(experiment_date, format="%Y-%m-%d")

               out <- data.frame(
                    experiment_name = xls_file_names[i],
                    experiment_barcode = header[header$`Block Type` == "Experiment Barcode", 2],
                    experiment_date = experiment_date,
                    data
               )

               xlsx::write.xlsx(tmp, file.path(path_out, 'raw/xls', paste0(xls_file_names[i], '.xls')))
               write.csv(out, file.path(path_out, 'raw/csv', paste0(xls_file_names[i], '.csv')), row.names=FALSE)

          }
     }

     pb$terminate()

     out_path <- file.path(path_out, 'raw/csv')
     n_csv <- length(list.files(out_path))

     message(glue::glue("Input .xls files: {length(xls_file_paths)}"))
     message(glue::glue("Parsed .csv files: {n_csv}"))
     message(glue::glue("Output here: {out_path}"))


}
