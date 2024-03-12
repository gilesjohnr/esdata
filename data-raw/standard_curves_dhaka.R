# Prep standard curve data for viral load modeling

df <- as.data.frame(readxl::read_xls(file.path(getwd(), "data-raw/standard_curves_dhaka_3_std_card_BG.xls")))

df <- df[,!(colnames(df) == 'Sample Name')]
df <- df[,!(colnames(df) == 'Ct Mean')]

colnames(df)[colnames(df) == 'Target Name'] <- 'target_name_unique'
colnames(df)[colnames(df) == 'CT1'] <- 'ct_value_1'
colnames(df)[colnames(df) == 'CT2'] <- 'ct_value_2'
colnames(df)[colnames(df) == 'Quantity'] <- 'quantity'


df$target_name_concise <- NA

key <- read.csv(file.path(getwd(), "data-raw/key.csv"))

# Get concise names for all exact matches

for (i in 1:nrow(df)) {

     sel <- which(key$target_name_unique == df$target_name_unique[i])

     if (length(sel) > 0) {

          df$target_name_concise[i] <- key$target_name_concise[sel]

     } else {

          sel <- which(key$target_name_concise == df$target_name_unique[i])
          if (length(sel) > 0) df$target_name_concise[i] <- key$target_name_concise[sel]

     }

}


# Get concise names for remaining targets using fuzzy matching

for (i in 1:nrow(df)) {

     if (is.na(df$target_name_concise[i])) {

          sel <- agrep(df$target_name_unique[i], key$target_name_unique, value=FALSE, ignore.case=TRUE, max=list(all=0.1))

          if (length(sel) > 0) {

               df$target_name_concise[i] <- key$target_name_concise[sel]

          } else {

               sel <- agrep(df$target_name_unique[i], key$target_name_concise, value=FALSE, ignore.case=TRUE, max=list(all=0.1))
               if (length(sel) > 0) df$target_name_concise[i] <- key$target_name_concise[sel]

          }

     }

}


standard_curves_dhaka <- df[,c(1,5,2:4)]

write.csv(standard_curves_dhaka, file=file.path(getwd(), "data-raw/standard_curves_dhaka.csv"), row.names=FALSE)

usethis::use_data(standard_curves_dhaka, overwrite=TRUE)
