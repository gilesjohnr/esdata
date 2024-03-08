# Make metadata keys
key <- as.data.frame(readxl::read_xlsx(file.path(getwd(), "local/data/key_master_with_notes.xlsx")))

for (i in 1:nrow(key)) {

     if (key$target_name_concise[i] == "NA") {

          key$target_name_concise[i] <- key$target_name_unique[i]

     }
}

key <- key[order(key$target_name_concise),]
key$include[is.na(key$include)] <- 1
key <- key[,colnames(key) != 'description']

write.csv(key, file.path(getwd(), "local/data/key.csv"), row.names=FALSE)

usethis::use_data(key, overwrite=TRUE)
