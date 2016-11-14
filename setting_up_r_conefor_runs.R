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

file_list <- list.files()
stringPattern="nodes_*"
file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
file_list
suffix=c()
id_list=c()
#getting id_no from filename if embedded in a string
for (file in file_list){
  dt<- strsplit(file,"_")[[1]]#splits string
  dt<-dt[c(FALSE,FALSE,TRUE,FALSE)]#chooses certain part to keep
  print (dt)
  id_list<-append(id_list, dt)
  suffix<-append(suffix,gsub("nodes_", "", file))
  print (suffix)
}

suffix
id_list
id_list<-data.frame(cbind(id_list,suffix))
names(id_list)<-c("id_no","suffix")
str(id_list)

Com<- merge(id_list, Dist, by="id_no")

str(Com)

for (i in unique(Com$id_no)){
  
  dt<- subset(Com, id_no==i)
  print(dt)
  a<- unique(dt$Disp_mean)
  print(a)
  write.table(dt, paste0(out_path,"/", i, "_",a))
}

Com
setwd(in_path2)
x<-Com

dataFrame<-Com
test<-paste0("shell('C:/Users/Konstantina/Desktop/conefor_analysis/coneforWin64.exe -nodeFile nodes_",x[2],".txt -conFile distances_", x[1],".txt -t dist all -confProb ",x[2]," 0.36788 -PC -prefix", x[1],"')")  
for (i in Com){:
by(dataFrame, 1:nrow(dataFrame), function(row) print(test))
                    
#Com$command<-paste0("shell('C:/Users/Konstantina/Desktop/conefor_analysis/coneforWin64.exe -nodeFile nodes_",x[1],".txt -conFile distances_", x[1],".txt -t dist all -confProb ",x[2]," 0.36788 -PC -prefix", x[1],"')")
  print (test
         
         )
a<- lapply(Com, function(x) {paste0("shell('C:/Users/Konstantina/Desktop/conefor_analysis/coneforWin64.exe -nodeFile nodes_",x[1],".txt -conFile distances_", x[1],".txt -t dist all -confProb ",x[2]," 0.36788 -PC -prefix", x[1],"')")} )
a<- (unlist(lapply(a, paste, collapse=" ")))
a

setwd(out_path)
write.csv(a, "command_line.csv")

shell("conefor_1_0_86_bcc_x86.exe -nodeFile nodes_sp_22682638_1.txt  -conFile distances_sp_22682638_1.txt -confAdj 9665.3451 -IIC -nodetypes")
