#' Calculate delta delta Ct
#'
#' This function calculates relative gene expression using the delta delta Ct method described in Livak & Schmittgen (2001).
#'
#' @param ct_target_t A scalar providing the Ct value of the target gene for an observation at time t
#' @param ct_reference_t A scalar providing the Ct value of the reference gene for an observation at time t
#' @param ct_target_t0 A scalar providing the Ct value of the target gene for the reference observation at time t=0
#' @param ct_reference_t0 A scalar providing the Ct value of the reference gene for the reference observation at time t=0
#'
#' @returns Scalar
#'
#' @examples
#' \dontrun{
#'
#' calc_delta_delta_ct(ct_target_t = 32.5,
#'                     ct_reference_t = 25,
#'                     ct_target_t0 = 34,
#'                     ct_reference_t0 = 30)
#'
#' }

calc_delta_delta_ct <- function(ct_target_t,
                                ct_reference_t,
                                ct_target_t0,
                                ct_reference_t0
){
     cond <- length(ct_target_t) == 1 & length(ct_reference_t) == 1 & length(ct_target_t0) == 1 & length(ct_reference_t0) == 1
     if (!cond) stop('all args must be scalar')

     cond <- is.numeric(ct_target_t) & is.numeric(ct_reference_t) & is.numeric(ct_target_t0) & is.numeric(ct_reference_t0)
     if (!cond) stop('all args must be numeric')

     delta_ct_target_sample <- ct_target_t - ct_reference_t
     delta_ct_reference_sample <- ct_target_t0 - ct_reference_t0
     delta_delta_ct <- delta_ct_target_sample - delta_ct_reference_sample
     return(2^-delta_delta_ct)

}
