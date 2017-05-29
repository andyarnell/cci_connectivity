
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


fromgridcellid.col=4
togridcellid.col=5

#split analysis by distance file (one per species id and season combination)
for (i in 1:length(x)){
  print (x[i])
  in.data<-read.table(x[i],header=FALSE)
  cells.from<-(unique(in.data[fromgridcellid.col]))
  cells.to<-(unique(in.data[togridcellid.col]))
  names(cells.to)<-names(cells.from)
  cells<-(unique(rbind(cells.from,cells.to)))
  ##split by grid cell id 
  for (j in 1:nrow(cells)){ 
    ##then for each grid cell select all distances with that grid cell id
    ##firstly select rows with that grid id in the "from" grid id column
    from.rows<-in.data[which(in.data[fromgridcellid.col]==cells[j,]), ]
    print(cells[j,])
    print(from.rows)
    ##then select rows with that grid id in the "to" grid id column
    to.rows<-in.data[which(in.data[fromgridcellid.col]==cells[j,]), ]
    print(cells[j,])
    print(to.rows)
    ##reorder columns in to.rows so formatting consistent with previous config (and keeping first 3 cols)
    #to.rows<-cbind(to.rows[2],to.rows[1],to.rows[3])
    to.rows<-cbind(to.rows[1],to.rows[2],to.rows[3])
    #but keep from rows the same (albeit only first 3 cols)
    from.rows<-cbind(from.rows[1],from.rows[2],from.rows[3])
    ##then append those in the "to" grid id column, 
    both.rows<-rbind(from.rows,to.rows)
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
    ##write to table in workingFolder_2
    out.distances.name<-paste0(workingFolder_2,"/",prefix,"_",suffix,".txt")
    out.nodes.name<-sub(distancesprefix,nodesprefix,out.distances.name)
    write.table(both.rows,out.distances.name,row.names=F, col.names=F)
    write.table(nodes.out,out.nodes.name,row.names=F, col.names=F)
    }
  }


