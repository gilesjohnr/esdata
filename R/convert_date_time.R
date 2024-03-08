#' Convert Aquaprobe data and time to consistent date format
#'
#' This function takes a vector of the 'Date & Time' column in the Aquaprobe data, and transforms it into a
#' consistent Date-class object. Note that many of the dates in this column are corrupted and give NAs.
#'
#' @param x A vector containing character strings of the 'Date & Time' column from an Aquaprobe data set
#'
#' @returns vector
#'
#' @examples
#' \dontrun{
#' convert_date_time(df$`Date & Time`)
#' }

convert_date_time <- function(x) {

     for (i in 1:length(x)) x[i] <- stringr::str_split(x[i], " ", simplify=TRUE)[1]

     out <- as.character(rep('NA', length(x)))

     for (i in 1:length(x)) {

          out[i] <- tryCatch({

               as.character(datefixR::fix_date(x[i]))

          }, error = function(e) {

               'NA'

          })

     }

     out <- as.Date(out, format="%Y-%m-%d")
     return(out)

}
