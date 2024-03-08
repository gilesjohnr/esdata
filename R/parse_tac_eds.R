#' Parse Taqman .eds files
#'
#' This function takes a directory with .eds files produced by QuantStudio software and extracts its contents into xml and txt files containing raw data and experiment metadata.
#'
#' @param path_in A full file path to the directory containing the .eds files.
#' @param path_out A full file path to the location where output files are to be written.
#'
#' @returns NULL
#'
#' @examples
#' \dontrun{
#' parse_tac_eds(path_in = "/User/test/dir1",
#'               path_out = "/User/test")
#' }

parse_tac_eds <- function(path_in,
                          path_out=NULL
) {

     if (is.null(path_out)) path_out <- file.path(path_in, 'rtac')
     if (!dir.exists(path_out)) dir.create(path_out)
     if (!dir.exists(path_in)) stop("path_in not valid")
     if (!dir.exists(path_out)) stop("path_out not valid")

     path_py <- file.path(find.package('rtac'), 'parse_eds.py')
     command <- paste(c('python3', path_py, path_in, path_out), collapse=" ")
     system(command, wait=TRUE, intern=TRUE)

}
