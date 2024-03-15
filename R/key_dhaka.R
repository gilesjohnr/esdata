#' Master key for target names
#'
#' These data serve as a key to cross reference the unique (and sometimes duplicated) target names
#' across all Taqman cards to appropriate concise target names, relevant control samples, and
#' whether to include the target in the compiled data set. The key applies to data collected in Dhaka, Bangladesh,
#' however, this key may be used as a template for apllications in other studies as well.
#'
#' @format ## `key_dhaka`
#' A data frame with 4 columns:
#' \describe{
#'   \item{target_name_unique}{The original target name found on each of the taqman array cards. May contain typos and duplicates.}
#'   \item{target_name_concise}{The associated concise target name with typos and duplicates removed.}
#'   \item{control}{The amplification control for each target. MS2 for RNA based targets and PhHV for DNA based targets.}
#'   \item{include}{Binary operator giving a 1 for targets that should be included.}
#' }
"key_dhaka"
