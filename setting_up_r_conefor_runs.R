#####################
### Command lines ###
#####################

setwd("C:/Users/Konstantina/Desktop/Distance/merged_tables")

Compl<- read.table("CSnE_info.txt", h=T)
Compl<- Compl[,c(1,3,4,6,10)]

Dist<- read.csv("Dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "Disp_mean"

Com<- merge(Compl, Dist, by="id_no")


out_path= "C:/Users/Konstantina/Desktop/Distance/Conefor_analysis/command"


for (i in unique(Com$id_no)){
  
  dt<- subset(Com, id_no==i)
  print(dt)
  a<- unique(dt$Disp_mean)
  print(a)
  write.table(dt, paste0(out_path,"/", i, "_",a))
}



setwd(out_path)

file_list <- list.files()
file_list


dt<- strsplit(file_list, "_")
a<- lapply(dt, function(x) {paste0("shell('C:/Users/Konstantina/Desktop/conefor_analysis/coneforWin64.exe -nodeFile Nodes",x[1],".txt -conFile Distances", x[1],".txt -t dist all -confProb ",x[2]," 0.36788 -PC -prefix", x[1],"')")} )
a<- (unlist(lapply(a, paste, collapse=" ")))

write.csv(a, "command_line.csv")
