

rm(list=ls())
ls()

#import library
library(foreign)
#install.packages("fpc")
library(fpc)
#install.packages("pvclust")
library(pvclust)
#install.packages('rattle')
library(rattle)
###########################
# input folders  
in_folder_1<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/ecoregions"
in_folder_2<-"C:/Data/cci_connectivity/scratch/dispersal" ###contains dispersal distances if running probabilities 


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

#get dispersal constants by species
setwd(in_folder_2)
Dist<- read.csv("dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "disp_mean"
str(Dist)

pcent_bounds<-10

lowerbound<-1-(pcent_bounds/100)
upperbound<-1+(pcent_bounds/100)

time_periods<-c("t0","t1")
y=1
k=1
for (y in 1:length(a$eco_id)){
  for (k in 1:length(time_periods)){
    dir.create(file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k]), recursive = TRUE)
    
    out_folder1<-file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k])
    
    print (out_folder1)

    #######################
    setwd(out_folder1)
    file_list <- list.files()
    
   
    file_list    #selecting files, based on string recognition to select outputs
    stringPattern<-"nodes" #distancesprefix
    
    #get list of species files    
    file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
    #file_list<-unique(file_list)
    file_list.df<-data.frame(file_list)
    p=1
    x<-list()
    for (m in 1:length(file_list)){
      m.df<-read.table(file_list[m])
      file_list.df$count[m]<-nrow(m.df)
      x[[p]]<-m.df[1]
      p<-p+1
    }

    ux<-unique(x)
    node_group<-match(x,ux)
    node_group
    file_list.df$node_group<-node_group
    str(file_list.df)

    #to get sp_id and season columns from nodes
    for (r in 1:nrow(file_list.df[1])){
      dt<- strsplit(gsub(".txt","",as.character(file_list.df[r,1])),"_")[[1]]#splits string
      dt<-dt[c(FALSE,TRUE,TRUE,FALSE)]#chooses certain part to keep
      file_list.df$id_no[r]<-dt[1]
      file_list.df$season[r]<-dt[2]
      }


    Com<- merge(file_list.df, Dist, by="id_no")
    str(Com)
    # comparing row numbers before and after - a simple check to find how many files have been dropped due to missing diseprsal links (no matching IDs)
    missed_joins=length(file_list.df[,1])-length(Com[,1])
    print (paste0("missed joins:" ,missed_joins))

    file_list.df<-data.frame(cbind(Com$id_no,Com$season,Com$count,Com$disp_mean,Com$node_group))
    names(file_list.df)<-c("id_no","season","count","disp_mean","node_group")
    #file_list.df$disp_mean<-as.numeric(file_list.df$disp_mean)
    #file_list.df$count<-as.integer(file_list.df$count)
    str(file_list.df)
    file_list.df<-droplevels.data.frame(file_list.df)
    #file_list.df$count<-as.integer.factor(file_list.df$count)
    #file_list.df$disp_mean<-as.numeric.factor(file_list.df$disp_mean)

    groups<-unique(file_list.df$node_group)
    comb_data.all<-list()
    q=1
    as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}
    as.integer.factor <- function(x) {as.integer(levels(x))[x]}
    for (q in 1:length(unique(groups))){
          file_list.dfsub<-file_list.df[which(file_list.df$node_group %in% groups[q]),]
          file_list.dfsub<-droplevels.data.frame(file_list.dfsub)
          file_list.dfsub
          str(file_list.dfsub)
          print (a$eco_id[y])
          setwd(file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])]))))
          print (getwd())
#          mdata<-read.csv("mdata.csv")
#           maxnodes<-a$count[y]
#           maxnodes
#           maxnodes<-maxnodes[y]
#           mdata[order(mdata$count),]
#           maxnodes<-max(mdata$count)
#           maxnodes
#           mdata.maxnodes<-subset(mdata,mdata$count == maxnodes)
#           #max.sp<-unique(mdata.maxnodes$disp_mean)
#           sp_list<-mdata.maxnodes
          #sp_list<-file_list.dfsub[order(file_list.dfsub$id_no,file_list.dfsub$season),] 
          sp_list<-file_list.dfsub
          sp_list<-droplevels.data.frame(sp_list)
          sp_list$count<-as.integer.factor(sp_list$count)
          sp_list$disp_mean<-as.numeric.factor(sp_list$disp_mean)
          str(sp_list)
          #   if (nrow(sp_list)<=2){
          #     print("skipping grouping for ecoregion: not enough species with same distribution (i.e. all ecoregion)")
           #    } else {
          
    datalist = list()
    #make two loops 
    for (i in 1:nrow(sp_list)){
      for (j in 1:nrow(sp_list)){
        ratio<-sp_list$disp_mean[i]/sp_list$disp_mean[j]
              if (ratio >0.9 & ratio < 1.1 ){ 
                
                r<- (cbind(sp_list[j,],sp_list[i,4]))
                
                print (r)
                names(r)<-c(names(r[1:5]),"dist_group")
#                 if(i==1){
#                   all_r<-r}
#                 else { 
#                   all_r<--rbind(all_r,r)
#                 }
                datalist[[j]] <- r
                
              }
            }
          }
          
          #creating a new dataframe of species with their dispersal groups
          comb_data = do.call(rbind, datalist)
          comb_data<-comb_data[order(comb_data$dist_group),]
          #cleaning up for dataframe so those that whose values disp_mean values were used for dist_group (they had different value in dist_group so this fixes that so they are in the groups too)
          indices<-which(comb_data$disp_mean %in% unique(comb_data$dist_group[duplicated(comb_data$dist_group)]))
          comb_data$dist_group[indices]<-comb_data$disp_mean[indices]
          length(unique(comb_data$dist_group))
          str(comb_data)
          #comb_data
          ###optional - make a mean for each group (not used as easier to use values already have)
          # comb_data.mean<-aggregate(comb_data$disp_mean, list(comb_data$dist_group), mean)
          # comb_data.comb<-merge(comb_data,comb_data.mean,by.x="dist_group",by.y="Group.1")
          # names(comb_data.comb)<-c(names(comb_data.comb[1:5]),"optional_group")
          # comb_data<-comb_data.comb
          
          ##adding percentage difference column
          #str(comb_data.comb)
          comb_data$pcentdiff<-(1-comb_data$dist_group/comb_data$disp_mean)*100
          summary(comb_data$pcentdiff)
          #comb_data$group[(which(comb_data$pcentdiff<lowerbound | comb_data$pcentdiff>upperbound))]<-comb_data$disp_mean[(which(comb_data$pcentdiff<lowerbound | comb_data$pcentdiff>upperbound))]
          comb_data.order<-comb_data[order(comb_data$disp_mean),]
          length(unique(comb_data.order$dist_group))
          plot(comb_data.order$dist_group~comb_data.order$disp_mean)
          


          #head(comb_data)
          comb_data.all[[q]] <- comb_data
          
      }
      comb_data.sp = do.call(rbind, comb_data.all)
      comb_data.sp
      #marking species to run and not to run
          if(max(comb_data.sp$count<1000)){
#            comb_data.sp$to_run[which(comb_data.sp$pcentdiff==0)]<-1
#             comb_data.sp$to_run[which(comb_data.sp$pcentdiff!=0)]<-0
#           } else {
            comb_data.sp$to_run[which(comb_data.sp$pcentdiff==0)]<-1
           comb_data.sp$to_run[which(comb_data.sp$pcentdiff!=0 & comb_data.sp$count>=1000)]<-0
             comb_data.sp$to_run[which(comb_data.sp$pcentdiff!=0 & comb_data.sp$count<1000)]<-1
#            comb_data$to_run[which(comb_data$pcentdiff!=0 & comb_data$count<1000 & (comb_data$pcentdiff<1|comb_data$pcentdiff>-1))]<-0
#            comb_data$to_run[which(comb_data$pcentdiff!=0 & comb_data$count<1000 & (comb_data$pcentdiff>=1 | comb_data$pcentdiff<=-1))]<-1
  }

      #nrow(unique(comb_data.sp[1]))
      comb_data.sp<-comb_data.sp[order(comb_data.sp$count,comb_data.sp$dist_group,comb_data.sp$disp_mean),]
      setwd(out_folder1)
      write.csv(comb_data.sp,"all_groupings_to_run.csv",row.names=FALSE)
    }
}

