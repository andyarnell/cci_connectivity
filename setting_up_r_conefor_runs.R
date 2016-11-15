#####################
### Command lines ###
#####################

in_path1="C:/Data/cci_connectivity/scratch/dispersal"
in_path2="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test"
out_path="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test"

#get dispersal distances from csv
setwd(in_path1)
Dist<- read.csv("dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "Disp_mean"


#get species ids from node files
setwd(in_path2)

#make list of node and distance files for conefor in the in_path2 folder
file_list <- list.files()

#selecting files for nodes only, based on string recognition
stringPattern="nodes_*"
file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
file_list

#opening vector lists up
suffix=c()
id_list=c()

#getting id_no (speceis id) from filename - this should be embedded in the filename string somehow sperated by underscores - tweak the TRUE/ FALSE parameters accordingly
for (file in file_list){
  dt<- strsplit(file,"_")[[1]]#splits string
  dt<-dt[c(FALSE,FALSE,TRUE,FALSE)]#chooses certain part to keep
  print (dt)
  id_list<-append(id_list, dt)
  suffix<-append(suffix,gsub("nodes_", "", file))
  print (suffix)
}

#view ouptuts
suffix
id_list
#make a dataframe from the vectors bt column binding 
id_list<-data.frame(cbind(id_list,suffix))
#name columns
names(id_list)<-c("id_no","suffix")

#view datframe structure
str(id_list)

#inner join of dataframe with distnace CSV, based on the species id (id_no) 
Com<- merge(id_list, Dist, by="id_no")
str(Com)

# comparing row numbers before and after - a simple check to find how many files have been dropped due to missing diseprsal links (no matching IDs)
missed_joins=length(id_list[,1])-length(Com[,1])
missed_joins
###N.B. if more missing_joins is >0 then invsetigate using outerjoins to see which ones and find their dispersal distances

#not sure what this does
# for (i in unique(Com$id_no)){
#   
#   dt<- subset(Com, id_no==i)
#   print(dt)
#   a<- unique(dt$Disp_mean)
#   print(a)
#   write.table(dt, paste0(out_path,"/", i, "_",a))
# }

setwd(in_path2)#where to put the output csv of command lines

#bit that isn't working completely (cos i'm dense))
a<- lapply(Com, function(x) {paste0("shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test/coneforWin64.exe -nodeFile nodes_",x[1],".txt -conFile distances_", x[1],".txt -t dist all -confProb ",x[2]," 0.36788 -PC -prefix", x[1],"')")} )
a<- (unlist(lapply(a, paste, collapse=" ")))
a
#
setwd(out_path)
write.csv(a, "command_line.csv")
