#' Parse Aquaprobe .xlsx files
#'
#' This function takes a .xlsx file path (or vector of file paths) and extracts its contents into individual csv files containing raw data.
#'
#' @param path_in A full file path to the directory containing the .xlsx files.
#' @param path_out A full file path to the location where output files are to be written.
#' @param verbose Logical indicating whether to print messages.
#'
#' @returns data.frame
#'
#' @examples
#' \dontrun{
#' parse_aquaprobe_xlsx(path_in = c("/User/test/dir1", "/Users/test/dir2"),
#'                      path_out = "/User/test")
#' }


parse_aquaprobe_xlsx <- function(path_in,
                                 path_out,
                                 verbose=TRUE
) {

     # Check directories
     for (i in seq_along(path_in)) if (!file.exists(path_in[i])) stop("path_in not valid")
     if (!dir.exists(path_out)) dir.create(path_out, recursive=TRUE)
     if (!dir.exists(path_out)) stop("path_out not valid")


     for (i in 1:length(path_in)) {

          if (verbose) message(path_in[i])
          sheet_names <- readxl::excel_sheets(path_in[i])
          if (length(sheet_names) > 2) stop('Expecting 2 sheets per file')

          d1 <- as.data.frame(readxl::read_excel(path_in[i], sheet=1))
          d2 <- as.data.frame(readxl::read_excel(path_in[i], sheet=2))
          d <- merge(d1, d2, by.x='SAMPLE ID', by.y='ES ID', all.x=T)

          tmp_file_name <- unlist(strsplit(path_in[i], "[/.]"))
          tmp_file_name <- tmp_file_name[length(tmp_file_name)-1]

          tmp_path <- file.path(path_out, 'raw/csv')
          if (!dir.exists(tmp_path)) dir.create(tmp_path, recursive=TRUE)
          write.csv(d, file=file.path(tmp_path, paste0(tmp_file_name, '.csv')), row.names=FALSE)

          tmp_path <- file.path(path_out, 'raw/xlsx')
          if (!dir.exists(tmp_path)) dir.create(tmp_path, recursive=TRUE)
          system(glue::glue("cp '{path_in[i]}' '{file.path(tmp_path, paste0(tmp_file_name, '.xlsx'))}'"))

     }

     if (verbose) {

          out_path <- file.path(path_out, 'raw/csv')
          n_csv <- length(list.files(out_path))

          message(glue::glue("Input .xlsx files: {length(path_in)}"))
          message(glue::glue("Parsed .csv files: {n_csv}"))
          message(glue::glue("Output here: {out_path}"))

     }
}
