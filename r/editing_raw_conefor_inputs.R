
##change t0 to t1 and vice versa in row 5 and 29

in_folder<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species"
out_folder<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t1"

setwd(in_folder)


file_list<- list.files()
file_list

string_pattern<- "distances_*"
#choose only the distance files
file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
file_list

#read data frames
file_list2<- lapply(file_list, read.table)

#set dataframe names
file_list<- strsplit(file_list, ".txt")
#file_list<- lapply(file_list, function(x) gsub("nodes", "nodes",x))

names(file_list2)<- file_list

#create the format for conefor
file_list2<- lapply(file_list2, function(x) x[c(1,2,3)]) 

#write new files in the conefor folder
sapply(names(file_list2), function(x) write.table(file_list2[[x]], 
                                                  file=paste0(out_folder, "/",x,".txt"), 
                                                  col.names=F, row.names=F ))
