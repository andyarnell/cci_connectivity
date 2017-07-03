 ####################
  ##Aim: split the distances and nodes files that are inputs to conefor
  ###into smaller chunks based on grid cells
  ###these are split into two sets of files:
  ###1) for modelling the node dpc/varpc values within a grid cell 
  ###where nodes within max distance (currently 8 * median dist) outside grid cell are include and area/quality of all nodes included
  
  ###2) for preparing runs for conefor to get the ECA for the grid cell
  ###where nodes within max distance outside grid cell are included but area/quality only included for nodes within grid cell (and outside coded as zero)
  ###these ECAs are used for creating area-weighted distances between grid cells (as per supplementary material in Santini et al., 2016)
  ###this involves distance and nodes files from step 1.
  
  rm(list=ls())
  ls()
  
  #import library
  library(foreign)

  ###########################
  # input folders  
  in_folder_1<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/ecoregions"
  workingFolder_2<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_node_varpc/ecoregions"
  workingFolder_3<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_eca/ecoregions"
  workingFolder_4<-"C:/Data/cci_connectivity/scratch/dispersal" ###contains dispersal distances if running probabilities 
  
  #get list of ecoregions to loop through
  a<-read.csv("C:/Data/cci_connectivity/scratch/nodes/corridors/eco_nodecount.csv",header=TRUE)
  #select subset those that have input folders already

  setwd(in_folder_1)
  
  file_list1<- list.files()
  str(file_list1)
  file_list1<-data.frame(file_list1)
  file_list1$file_list1<-as.character(file_list1$file_list1)
  a$eco_name<-as.character(a$eco_name)
  
  str(file_list1)
  
  a<-merge(a,file_list1,by.x="eco_name",by.y="file_list1")
  
  a
  
#a<-a[2:3,]  
#get dispersal constants by species
setwd(workingFolder_4)
Dist<- read.csv("dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "disp_mean"

#Import Look up table (LUT) for getting gridcell codes

#LUT from flatfile (shapefile attribute table used for dsitance calculations ) dbf 
lut_gridcell<- read.dbf("C:/Data/cci_connectivity/scratch/nodes/corridors/hansenNew_eco_20km_passNew_kba_corr_floss1_wgs84.dbf")
lut_gridcell<- lut_gridcell[,c("nodiddiss4","FID_fnet_2")]
colnames(lut_gridcell)<- c("node","gridcell_id") 
str(unique(lut_gridcell$gridcell_id))

#####
#Optional parameters

#Extended version where larger number of nodes may be included
#i.e. the inclusion distance for nodes surrounding grid cell for pc/dpc calculations, 
#is made from any nodes touching (i.e, zero distance) nodes in target grid cell and not just the grid cell nodes
#this is iterative so nodes touching these extras will be included too until no zero distances are found
#(the inclusion distance used is then based on max dispersal estimate for species - 8 x dispersal max distance)

#Optional parameter to Use extended version? should be more accurate, but slower - as will often include more nodes
extended_inclusion_dist<-FALSE
write.table(paste0("extended version==",extended_inclusion_dist, " i.e., if true (and file creation times match this log file) then using extended version where larger number of nodes may be included - slower, but should be more accurate"),paste0(out_folder2,"/1_log.txt"),row.names = FALSE,col.names = FALSE)
write.table(paste0("extended version==",extended_inclusion_dist, " i.e., if true (and file creation times match this log file) then using extended version where larger number of nodes may be included - slower, but should be more accurate"),paste0(out_folder3,"/1_log.txt"),row.names = FALSE,col.names = FALSE)

print ("extended inclusion distance:")
print (extended_inclusion_dist)

#number of times zero distance loop runs - limits analysis so it doesn't get too many cells and grow too large
k_number=20
#Optional parameter to convert distances to probabilities - (TRUE or FALSE) easier for creating conefor batches as only one command needed for all files in folder

convert_to_probabilities=TRUE
print ("converting distances to probabilities:")
print (convert_to_probabilities)
#####################


for (y in 1:length(a$eco_id)){
  #list time periods
  time_periods<-c("t0","t1")
  for (k in 1:length(time_periods)){
    dir.create(file.path(workingFolder_2,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k]), recursive = TRUE)
    dir.create(file.path(workingFolder_3,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k]), recursive = TRUE)

    out_folder2<-file.path(workingFolder_2,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k])
    out_folder3<-file.path(workingFolder_3,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k])
 
    #######################
    setwd(file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k]))
    file_list <- list.files()
    
    distancesprefix<-"distances"
    nodesprefix<-"nodes"
    
    #selecting files, based on string recognition to select outputs
    stringPattern<-"distances_" #distancesprefix
    stringPattern<-paste0(substr(stringPattern,1,nchar(stringPattern)-1),"*")
    #stringPattern<-"distances_22692177_1"
    #get list of species files    
    file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
    file_list<-unique(file_list)
    x<-file_list
    #which columns gridcell ids will be in - typcially 4 and 5 
    fromgridcellid.col=4
    togridcellid.col=5
    i=1
    j=1
    
    getwd()
    #split analysis by distance file (one per species id and season combination)
    for (i in 1:length(x)){
      gc()
      print (x[i])
      
      
      ###add in splitting bit for getting species ids
      file<-x[i]
      id_no1<- strsplit(file,"_")[[1]]#splits string
      id_no1<-id_no1[c(FALSE,TRUE,FALSE)]#chooses certain part to keep
      id_no1<-as.integer(id_no1)
      
      print( paste0("Ecoregion ",a$eco_name[y],": ",y ," of ",length(a$eco_id), " ecoregions"))
      print( paste0("Species input file ", i, " of ",length(x)))
      
      #import distances file for this species
      in.data<-read.table(x[i],header=FALSE)
      
      #getting species dispersal distances from file
      if (convert_to_probabilities==TRUE){
        Dist.sub<-subset(Dist,Dist$id_no==id_no1)
        dispConst<-Dist.sub$disp_mean*1000
        dispConst
        inP<-0.36788
        in.data$V3<- exp(-(-1*(log(inP)/dispConst)) * in.data$V3)
      }
      #getting grid cell ids attached to distances file
      in.data<-merge(in.data,lut_gridcell,by.x="V1",by.y="node", all.x = TRUE)   
      #droplevels(in.data)
      str(in.data)
      in.data<-merge(in.data,lut_gridcell,by.x="V2",by.y="node",all.x = TRUE)
      names(in.data)<-c("V1","V2","V3","fromgridcellid.col","togridcellid.col")
      cells.from<-(unique(in.data[fromgridcellid.col]))
      cells.to<-(unique(in.data[togridcellid.col]))
      names(cells.to)<-names(cells.from)
      cells<-(unique(rbind(cells.from,cells.to)))
      cells<-droplevels(cells)
      in.nodes<-read.table(sub(distancesprefix,nodesprefix,x[i]))
      in.nodes$V3<-1 
      str(cells)
      
      ##split by grid cell id 
      for (j in 1:nrow(cells)){ 
        print (paste0(j," of ",nrow(cells)," grid cells"))
        ##then for each grid cell select all distances with that grid cell id
        rows.subset<-unique(in.data[which(in.data[fromgridcellid.col]==cells[j,]|in.data[togridcellid.col]==cells[j,]),])[1:3]
        ##then write all distances with selected grid id to a table 
        ##table name will have prefix of species id (and season code) from input file (and removing ".txt" ending)
        prefix<-substr(x[i],1,nchar(x[i])-4)
        ##and suffix from the grid cell id 
        suffix<-cells[j,]
        #select only the first 3 columns
        rows.subset<-cbind(rows.subset[1:3])
        ##write to table in out_folder2
        out.distances.name<-paste0(out_folder2,"/",prefix,"_",suffix,".txt")
        write.table(rows.subset,out.distances.name,row.names=F, col.names=F)
        #get list of nodes
        from.nodes<-unique(rows.subset[1])
        to.nodes<-unique(rows.subset[2])
        names(to.nodes)<-names(from.nodes)
        nodes.subset<-unique(rbind(to.nodes,from.nodes))
        nodes.out<-merge(nodes.subset,in.nodes,by="V1")  
        nodes.out<-cbind(nodes.out[1:3])
        out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
        #edit dataframe for the third column 
        #so that only nodes in the target grid cell get dpc/varpc calculated
        gridcell.nodes<-data.frame(unique(lut_gridcell[1][which(lut_gridcell[2]==cells[j,]),]))
        gridcell.nodes$V2<-as.integer(1)
        colnames(gridcell.nodes)<-c("V1","V2")
        #str(gridcell.nodes)
        #str(nodes.out)
        nodes.out<-merge(nodes.out,gridcell.nodes,by.x="V1",by.y="V1",all.x=TRUE)
        names(nodes.out)<-c("V1","V2","V3","V4")
        nodes.out$V3[which(is.na(nodes.out$V4))] <--1
        nodes.out$V3[which(nodes.out$V4==1)] <-1
        nodes.out<-cbind(nodes.out[1:3])
        write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
        #write second table to text file for ECA calculations - these have no areas for nodes outside
        nodes.out$V2[which(nodes.out$V3==-1)]<-0
        out.distances.name<-paste0(out_folder3,"/",prefix,"_",suffix,".txt")
        write.table(rows.subset,out.distances.name,row.names=F, col.names=F)
        out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
        write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
        #################
        #adding extras
        rows.subset1<-rows.subset
        k=0
        zero.rows<-rows.subset1
        while (nrow(zero.rows)>=1 & extended_inclusion_dist==TRUE & k <k_number){
          #print("K")
          #print (k)
          k=k+1
          #select subset with zero distances
          zero.dist1<-subset(rows.subset1[1],rows.subset1[3]==0)
          zero.dist2<-subset(rows.subset1[2],rows.subset1[3]==0)
          names(zero.dist2)<-names(zero.dist1)
          zero.dist<-rbind(zero.dist1,zero.dist2)
          zero.dist<-unique(subset(zero.dist, !is.na(zero.dist)))
          #str(nodes.subset)
          #str(zero.dist)
          #nodes.subset<-c(nodes.subset)
          #select only those nodes that aren't in the cell of interest
          #zero.dist<-subset(zero.dist,zero.dist$V1 %in% nodes.subset$V1 ==FALSE)
          
          from.rows<-subset(in.data,in.data$V1==zero.dist$V1[k])
          to.rows<-subset(in.data,in.data$V2==zero.dist$V1[k])
          zero.rows<-rbind(from.rows,to.rows)
          zero.rows<-cbind(zero.rows[1:3])
          zero.rows<-unique(zero.rows)
          #zero.rows<-cbind(zero.rows[1:3])
          if (k==1){
            print ("first run")
            zero.rows1<-zero.rows
          } else {
            zero.rows<-subset(zero.rows,zero.rows$V1 %in% nodes.subset$V1 ==FALSE)
            zero.rows<-subset(zero.rows,zero.rows$V2 %in% nodes.subset$V1 ==FALSE)
            zero.rows1<-unique(rbind(zero.rows,zero.rows1))
            print ("not first run")
          }
          
          #print(rows.subset)
          rows.subset2<-unique(rbind(zero.rows1,rows.subset))
          rows.subset2<-cbind(rows.subset2[1:3])
          ##write extended outputs to table in out_folder2 
          ##i.e. now with all distances to nodes in max dist of nodes touching / zero distance from grid cell
          out.distances.name<-paste0(out_folder2,"/",prefix,"_",suffix,".txt")
          #out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
          write.table(rows.subset2,out.distances.name,row.names=F, col.names=F)
          #get list of nodes for extended outputs
          from.nodes2<-unique(rows.subset2[1])
          to.nodes2<-unique(rows.subset2[2])
          names(to.nodes2)<-names(from.nodes2)
          nodes.subset2<-unique(rbind(to.nodes2,from.nodes2))
          nodes.out2<-merge(nodes.subset2,in.nodes,by="V1")  
          #edit nodes dataframe third column 
          #so that only nodes in the target grid cell get dpc/varpc calculated
          #this requires joining/merging dataframes 
          gridcell.nodes$V2<-1
          #str(gridcell.nodes)
          #str(nodes.out2)
          nodes.out2<-merge(nodes.out2,gridcell.nodes,by.x="V1",by.y="V1",all.x=TRUE)
          names(nodes.out2)<-c("V1","V2","V3","V4")
          nodes.out2$V3[which(is.na(nodes.out2$V4))] <--1
          nodes.out2$V3[which(nodes.out2$V4==1)] <-1
          nodes.out2<-cbind(nodes.out2[1:3])
          out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
          write.table(nodes.out2,out.nodes.name,row.names=F, col.names=F)
          #write second table to text file for ECA calculations - these have no areas for nodes outside
          nodes.out2$V2[which(nodes.out2$V3==-1)]<-0
          out.distances.name<-paste0(out_folder3,"/",prefix,"_",suffix,".txt")
          write.table(rows.subset,out.distances.name,row.names=F, col.names=F)
          out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
          write.table(nodes.out2,out.nodes.name,row.names=F, col.names=F)   
          gc()
        }
      }
    }
    
  }
}
    






    #path where executable conefor version stored
    conefor_raw_path<-"C:/Data/cci_connectivity/raw/conefor"
    #the name of the conefor executable
    conefor_version<-"conefor_1_0_86_bcc_x86.exe"
    setwd(out_folder2)
    #check if conefor is in main folder and copy it there if not 
    if (file.exists(conefor_version)==FALSE){
      print ("Conefor software not present in folder. Copying version from conefor raw path")
      file.copy(paste0(conefor_raw_path,"/",conefor_version),conefor_version, recursive = FALSE,
                copy.mode = TRUE, copy.date = FALSE)
      print("File copied successfully")
    } else {
      print ("conefor version exists in folder")
    }
    

lineVarPC<-paste0("shell('",out_folder2,"/",conefor_version," -nodeFile nodes_* -conFile distances_* -t prob notall -prefix","')")
lineVarPC
shell('C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_node_varpc/ecoregions/West_Sudanian_savanna/t0/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_* -conFile distances_* -t prob notall -prefix')
lineECA<-paste0("shell('",out_folder3,"/",conefor_version," -nodeFile nodes_* -conFile distances_*", x[i,2],".txt -t prob notall onlyoverall -prefix ", x[i,2],"')")  
    
  
  
