#####################
### Command lines ###
#####################

in_path1="C:/Data/cci_connectivity/scratch/dispersal"
in_path2="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t0"
out_path="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t0"

conefor_version<-"conefor_1_0_86_bcc_x86.exe"

#for varPC/dPC leave as "" 
#but if just need summary values like PC/ECA then use"onlyoverall"
#onlyoverall<-"onlyoverall"
onlyoverall<-""
  
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
  dt<-dt[c(FALSE,TRUE,FALSE)]#chooses certain part to keep
  #print (dt)
  id_list<-append(id_list, dt)
  suffix<-append(suffix,gsub("nodes_", "", file))
  #print (suffix)
  suffix<-gsub(".txt", "", suffix)
}


#view ouptuts
suffix# should contain species ID and Season including ".txt" at the end
id_list# shoudl jsut be species ID

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
#as in metres and dispersal estimates in km
conversion<-1000

x<-Com
###test on first row
i=1

#shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_22681782_1.txt -conFile distances_22681782.txt -t dist notall -confProb 787.011729 0.36788 -PC -nodetypes -prefix 22681782_1')

command_list=c()
nodeCount=c()
#loop through and make commands basded on dataframe

for (i in 1:length(Com[,1])){
  count<-length(read.table(paste0("nodes_",x[i,2],".txt"))[,1])
  #if (length(nodeList[,1])<1000){
  line<-paste0("shell('",in_path2,"/",conefor_version," -nodeFile nodes_",x[i,2],".txt -conFile distances_", x[i,2],".txt -t dist notall -confProb ",x[i,3]*conversion," 0.36788 -PC ",onlyoverall," -nodetypes -prefix ", x[i,2],"')")  
  print (line)
  print (count)    
  nodeCount<-append(nodeCount,count)
  command_list<-append(command_list,line)
  #} else { 
   # print("too many nodes, skipping")
  #}
}

command_dframe<-data.frame(cbind(command_list,nodeCount))
command_dframe

setwd(out_path)#where to put the output csv of command lines
write.csv(command_dframe, "command_line.csv")


shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t0/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_22680659_1.txt -conFile distances_22680659_1.txt -t dist notall -confProb 1214.121576 0.36788 -PC   -prefix 22680659_1')
shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t0/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_22683862_1.txt -conFile distances_22683862_1.txt -t dist notall -confProb 7265.694423 0.36788 -PC   -prefix 22683862_1')
shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/t0/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_22706690_1.txt -conFile distances_22706690_1.txt -t dist notall -confProb 1476.214736 0.36788 -PC   -prefix 22706690_1')
