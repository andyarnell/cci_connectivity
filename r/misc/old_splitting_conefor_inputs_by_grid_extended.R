
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

workingFolder_1<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species"
workingFolder_2<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_node_varpc"
workingFolder_3<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_eca"

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
x[1]


fromgridcellid.col=4
togridcellid.col=5

i=2
j=2


#split analysis by distance file (one per species id and season combination)
for (i in 1:2){#length(x)){
  print (x[i])
  in.data<-read.table(x[i],header=FALSE)
  cells.from<-(unique(in.data[fromgridcellid.col]))
  cells.to<-(unique(in.data[togridcellid.col]))
  names(cells.to)<-names(cells.from)
  cells<-(unique(rbind(cells.from,cells.to)))
  print(cells)
  ##split by grid cell id 
  for (j in 1:nrow(cells)){
    ##then for each grid cell select all distances with that grid cell id
    ##firstly select rows with that grid id in the "from" grid id column
    #from.nodes<-in.data[1][which(in.data[fromgridcellid.col]==cells[j,]), ]
    from.nodes<-subset(in.data[1],in.data[fromgridcellid.col]==cells[j,])
    ##then select rows with that grid id in the "to" grid id column
    #to.nodes<-in.data[2][which(in.data[fromgridcellid.col]==cells[j,]), ]
    to.nodes<-subset(in.data[2],in.data[fromgridcellid.col]==cells[j,])
    #both.nodes<-c(to.nodes,from.nodes)
    names(to.nodes)<-names(from.nodes)    
    #append to each other and remove duplicates
    both.nodes<-unique(rbind(to.nodes,from.nodes))
    class(both.nodes)
    
    k=0
    #for (k in 1:nrow(both.nodes)){
    while (nrow(both.nodes)>=1){
      print (k)
      k=k+1
      #from.rows<-in.data[which(in.data[1]==both.nodes[k])]
      from.rows<-subset(in.data,in.data$V1==both.nodes$V1[k])
      #print(from.rows)
#      #keep only first 3 cols (no ned for grid cell ids)
      #from.rows<-cbind(from.rows[1],from.rows[2],from.rows[3])
      to.rows<-subset(in.data,in.data$V2==both.nodes$V1[k])
      #print(to.rows)
#      to.rows<-in.data[which(in.data[2]==both.nodes[k])]
      #to.rows<-cbind(to.rows[1],to.rows[2],to.rows[3])
#      ##then append those in the "to" grid id column, 
      both.rows1<-rbind(from.rows,to.rows)
      both.rows1<-cbind(both.rows1[1:3])
      both.rows1<-unique(both.rows1)
      #get nodes with zero distance
      if (k==1){
      both.rows<-both.rows1 
      print ("first run")
      } else {
      print ("not first run - looping through others")##
      both.rows<-cbind(both.rows[1:3])
      both.rows<-rbind(both.rows,both.rows1)
      }
      #select all that have zero distances
      zero.dist1<-subset(both.rows[1],both.rows$V3==0)
      zero.dist2<-subset(both.rows[2],both.rows$V3==0)
      names(zero.dist2)<-names(zero.dist1)
      zero.dist<-rbind(zero.dist1,zero.dist2)
      zero.dist<-unique(subset(zero.dist, !is.na(zero.dist)))
      str(both.nodes)
      str(zero.dist)
      #both.nodes<-c(both.nodes)
      #select only those nodes that aren't in the cell of interest
      zero.dist<-subset(zero.dist,zero.dist$V1 %in% both.nodes$V1 ==FALSE)

      both.nodes<-rbind(both.nodes,zero.dist)
      #both.nodes<-c(both.nodes)
      #both.nodes<-unique(subset(both.nodes$V1,both.nodes$V1 %in% both.nodes$V1[k] ==FALSE))
      both.nodes<-unique(subset(both.nodes,both.nodes$V1 %in% both.nodes$V1[k] ==FALSE))
        
    }
    print(both.rows)
    ##then write all distances with selected grid id to a table
    ##table name will have prefix of species id (and season code) from input file (and removing ".txt" ending)
    prefix<-substr(x[i],1,nchar(x[i])-4)
    ##and suffix from the grid cell id 
    suffix<-cells[j,]
    in.nodes<-read.table(sub(distancesprefix,nodesprefix,x[i]))
    r1<-both.rows[2]
    r2<-both.rows[1]
    names(r1)<-names(r2)
    node.subset<-unique(as.vector(rbind(r1,r2)))
    nodes.out<-merge(node.subset,in.nodes,by="V1")
    #make a list of nodes  - 1st loop just those within grid cell, but 2nd loop nodes within distance of 0... repeating...
    ##rbind here    
    ##write to table in workingFolder_2
    out.distances.name<-paste0(workingFolder_3,"/",prefix,"_",suffix,".txt")
    out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
    write.table(both.rows,out.distances.name,row.names=F, col.names=F)
    write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
  }
}


