#' Convert Aquaprobe coordinates from DMS to DD
#'
#' This function takes the character strings giving Latitude and Longitude from the Aquaprobe .xlsx files, and returns spatial coordinates in
#' Degree Minute Second (DMS) and Decimal Degree (DD) formats.
#'
#' @param x A vector containing character strings of Latitude or Longitude in the informal DMS format from the Dhaka aquaprobe .xlsx files.
#'
#' @returns List with both DMS and DD formats
#'
#' @examples
#' \dontrun{
#' convert_dms_to_dd(df$Lat)
#' }

convert_dms_to_dd <- function(x) {

     # Split strings

     tmp <- stringr::str_split(x, "[\u00b0 | ']", simplify=TRUE)
     tmp[,4] <- 0
     tmp <- as.character(glue::glue("{tmp[,2]}d{tmp[,3]}'{tmp[,4]}\"{tmp[,1]}"))

     # Make degree minute second with consistent format

     x_dms <- as.character(rep(NA, length(tmp)))

     for (i in 1:length(tmp)) {

          x_dms[i] <- tryCatch({

               as.character(sp::char2dms(tmp[i]))

          }, error = function(e) {

               'NA'

          })

     }

     # Make decimal degree conversion

     x_dd <- as.numeric(rep(NA, length(tmp)))

     for (i in 1:length(tmp)) {

          x_dd[i] <- tryCatch({

               as.numeric(sp::char2dms(x_dms[i]))

          }, error = function(e) {

               NA

          })

     }

     # Return both

     return(list(dms = x_dms, dd = x_dd))

}
