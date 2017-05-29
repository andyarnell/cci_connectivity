  
  ####################
  ##Aim: split the distnaces and nodes files that are inputs to conefor
  ###into smaller chunks based on grid cells
  ###these are split into two sets of files:
  ###1) for modelling the node dpc/varpc values within a grid cell 
  ###where nodes within max distance outside grid cell are included
  ###and area/quality of all nodes included,
  
  ###2) for preparing runs for conefor to get the ECA for the grid cell
  ###where nodes within max distance outside grid cell are included
  ###but area/quality only included for nodes within grid cell (and outside coded as zero)
  
  ###3) for creating area-weighted distances between grid cells (as per supplementary material in Santini et al., 2016)
  ###this involves distance and nodes files from step 1.
  
  ###detail for 1:
  ###loop through distances file in the input folder (one per species)
  ###Requirements for input file:
  ###distances file requires grid ids for the from and to nodes
  ###and areas/quality for the from and to nodes
  ###if dpc/varpc are to be run for specific nodes only then requires extra (wdpa) column
  ###split by grid cell id so that for each grid cell..
  ###select all distances with that grid cell id
  ###by selecting rows with that grid id in the "from" grid id column
  ###and then append those in the "to" grid id column, 
  ###thus all distances for nodes in that grid cell are selected
  ###and then write this into a distances file for that grid cell id
  ###then create accompanying nodes file from the distances file 
  ###this requires including the area column and removing duplicates
  ###then saving distances and nodes in workingFolder_2 with a grid cell suffix
  ###this allows conefor runs to provide node importance files
  ###add third colum to node file coded so only nodes for that grid cell are run in conefor
  
  ###for 2:
  ###copy distances and nodes file from wokringfolder_2 to workingFolder_3
  ###using gridcell suffix from the nodes filename
  ###for all nodes not having that gridcell id, 
  ###replace values for area/quality with zero 
  ###thus allowing eca values for the gridcells to be created in conefor
  
  ###for 3 
  rm(list=ls())
  ls()
  
  workingFolder_1<-"C:/Data/cci_connectivity/scratch/conefor_inputs/by_species"
  workingFolder_2<-"C:/Data/cci_connectivity/scratch/conefor_inputs/nested/for_node_varpc"
  workingFolder_3<-"C:/Data/cci_connectivity/scratch/conefor_inputs/nested/for_gridcell_eca"
  setwd(workingFolder_1)
  
  file_list <- list.files()
  
  distancesprefix<-"distances_lut"
  nodesprefix<-"nodes"
  
  #selecting files, based on string recognition to select outputs
  stringPattern<-distancesprefix
  stringPattern<-paste0(substr(stringPattern,1,nchar(stringPattern)-1),"*")
  file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
  file_list<-unique(file_list)
  file_list
  
  x<-file_list
  
  ###loop through distances file in the input folder (one per species)
  ###split by grid cell id 
  ###then for each grid cell select all distances with that grid cell id
  ###by selecting rows with that grid id in the "from" grid id column
  ###and then append those in the "to" grid id column, 
  ###thus all distances for nodes in that grid cell are selected
  x[i]
  
  #Extended version where larger number of nodes may be included
  #i.e. the inclusion distance for nodes surrounding grid cell for pc/dpc calculations, 
  #is made from any nodes touching (i.e, zero distance) nodes in target grid cell and not just the grid cell nodes
  #this is iterative so nodes touching these extras will be included too until no zero distances are found
  #(the inclusion distance used is then based on max dispersal estimate for species - 8 x dispersal max distance)
  
  #Optional parameter to Use extended version? should be more accurate, but slower - as will often include more nodes
  extended_inclusion_dist<-TRUE
  write.table(paste0("extended version==",extended_inclusion_dist, " i.e., if true (and file creation times match this log file) then using extended version where larger number of nodes may be included - slower, but should be more accurate"),paste0(workingFolder_2,"/1_log.txt"),row.names = FALSE,col.names = FALSE)
  write.table(paste0("extended version==",extended_inclusion_dist, " i.e., if true (and file creation times match this log file) then using extended version where larger number of nodes may be included - slower, but should be more accurate"),paste0(workingFolder_3,"/1_log.txt"),row.names = FALSE,col.names = FALSE)
  
  fromgridcellid.col=4
  togridcellid.col=5
  i=1
  j=1
  
  #split analysis by distance file (one per species id and season combination)
  for (i in 1:length(x)){
    print (x[i])
    in.data<-read.table(x[i],header=FALSE)
    cells.from<-(unique(in.data[fromgridcellid.col]))
    cells.to<-(unique(in.data[togridcellid.col]))
    names(cells.to)<-names(cells.from)
    cells<-(unique(rbind(cells.from,cells.to)))
    cells<-droplevels(cells)
    ##split by grid cell id 
    for (j in 1:nrow(cells)){ 
      ##then for each grid cell select all distances with that grid cell id
      
      ##firstly select rows with that grid id in the "from" grid id column
      from.rows<-in.data[which(in.data[fromgridcellid.col]==cells[j,]), ]
      print(cells[j,])
      print(from.rows)
      ##then select rows with that grid id in the "to" grid id column
      to.rows<-in.data[which(in.data[togridcellid.col]==cells[j,]), ]
      print(cells[j,])
      print(to.rows)
      from.gridcell.nodes<-in.data[1][which(in.data[fromgridcellid.col]==cells[j,]), ]
      from.gridcell.nodes<-data.frame(from.gridcell.nodes)
      to.gridcell.nodes<-in.data[2][which(in.data[togridcellid.col]==cells[j,]), ]
      to.gridcell.nodes<-data.frame(to.gridcell.nodes)
      names(from.gridcell.nodes)<-"V1"
      names(to.gridcell.nodes)<-names(from.gridcell.nodes)
      gridcell.nodes<-unique(rbind(from.gridcell.nodes,to.gridcell.nodes))
      ##then append those in the "to" grid id column, 
      rows.subset<-unique(rbind(from.rows,to.rows))
      #rows.subset<-cbind(rows.subset[1:3])
      ##then write all distances with selected grid id to a table 
      ##table name will have prefix of species id (and season code) from input file (and removing ".txt" ending)
      prefix<-substr(x[i],1,nchar(x[i])-4)
      ##and suffix from the grid cell id 
      suffix<-cells[j,]
      in.nodes<-read.table(sub(distancesprefix,nodesprefix,x[i]))
      rows.subset<-cbind(rows.subset[1:3])
      ##write to table in workingFolder_2
      out.distances.name<-paste0(workingFolder_2,"/",prefix,"_",suffix,".txt")
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
      gridcell.nodes$V2<-1
      #str(gridcell.nodes)
      #str(nodes.out)
      nodes.out<-merge(nodes.out,gridcell.nodes,by.x="V1",by.y="V1",all.x=TRUE)
      names(nodes.out)<-c("V1","V2","V3","V4")
      nodes.out$V3[which(is.na(nodes.out$V4))] <--1
      nodes.out$V3[which(nodes.out$V4==1)] <-1
      nodes.out<-cbind(nodes.out[1:3])
      write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
      #write second table to text file for ECA calculations - these have no areas for nodes outside
      nodes.out<-nodes.out
      nodes.out$V2[which(nodes.out$V3==-1)]<-0
      out.distances.name<-paste0(workingFolder_3,"/",prefix,"_",suffix,".txt")
      write.table(rows.subset,out.distances.name,row.names=F, col.names=F)
      out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
      write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
      #################
      #adding extras
      rows.subset1<-rows.subset
      k=0
      zero.rows<-rows.subset1
      print ("extended inclusion distance:")
      print (extended_inclusion_dist)
      while (nrow(zero.rows)>=1 & extended_inclusion_dist==TRUE){
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
        
      }
      #print(rows.subset)
      rows.subset2<-unique(rbind(zero.rows1,rows.subset))
      rows.subset2<-cbind(rows.subset2[1:3])
      ##write extended outputs to table in workingFolder_2 
      ##i.e. now with all distances to nodes in max dist of nodes touching / zero distance from grid cell
      out.distances.name<-paste0(workingFolder_2,"/",prefix,"_",suffix,".txt")
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
      out.distances.name<-paste0(workingFolder_3,"/",prefix,"_",suffix,".txt")
      write.table(rows.subset,out.distances.name,row.names=F, col.names=F)
      out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
      write.table(nodes.out2,out.nodes.name,row.names=F, col.names=F)   
      
      }
    }
