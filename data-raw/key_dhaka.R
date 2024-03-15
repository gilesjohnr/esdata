# Make metadata keys
key_dhaka <- as.data.frame(readxl::read_xlsx(file.path(getwd(), "data-raw/key_dhaka.xlsx")))

for (i in 1:nrow(key_dhaka)) {

     if (key_dhaka$target_name_concise[i] == "NA") {

          key_dhaka$target_name_concise[i] <- key_dhaka$target_name_unique[i]

     }
}

key_dhaka <- key_dhaka[order(key_dhaka$target_name_concise),]
key_dhaka$include[is.na(key_dhaka$include)] <- 1
key_dhaka <- key_dhaka[,colnames(key_dhaka) != 'description']

write.csv(key_dhaka, file.path(getwd(), "data-raw/key_dhaka.csv"), row.names=FALSE)
usethis::use_data(key_dhaka, overwrite=TRUE)
