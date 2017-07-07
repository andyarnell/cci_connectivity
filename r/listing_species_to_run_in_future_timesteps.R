
#Aim: loops through time periods and checks if nodes and areas (i.e. the node file) has changed between time periods. By default uses difference between subsequent time steps in the time_periods list

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
#install.packages("compare")
library(compare)
###########################
# input folders  
in_folder_1<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/ecoregions"
in_folder_2<-"C:/Data/cci_connectivity/scratch/dispersal" ###contains dispersal distances if running probabilities 


#get list of ecoregions to loop through
a<-read.csv("C:/Data/cci_connectivity/scratch/nodes/corridors/eco_nodecount.csv",header=TRUE)
#select subset those that have input folders already

combine_with_groupings_output<-TRUE #if true then will combine with the groupings output (from seperate script) so time savings from both are made
##################

setwd(in_folder_1)

file_list1<- list.files()
str(file_list1)
file_list1<-data.frame(file_list1)
file_list1$file_list1<-as.character(file_list1$file_list1)
a$eco_name<-as.character(a$eco_name)

str(file_list1)

a<-merge(a,file_list1,by.x="eco_name",by.y="file_list1")

a

time_periods<-c("t0","t1","t2")

y=1
k=1


for (y in 1:length(a$eco_id)){
  for (k in 1:(length(time_periods)-1)){
    #setwd(in_folder_1)
    #first time period
    dir.create(file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k]), recursive = TRUE)
    
    out_folder1<-file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k])

    dir.create(file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k+1]), recursive = TRUE)
    
    out_folder2<-file.path(in_folder_1,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), time_periods[k+1])
    
    
    
    print (out_folder1)
    print (out_folder2)
    #######################
    #start timestep
    setwd(out_folder1)
    file_list <- list.files()
       
    #file_list    #selecting files, based on string recognition to select outputs
    stringPattern<-"nodes" #distancesprefix
    
    #get list of species files    
    file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
    #file_list<-unique(file_list)
    file_list.df<-data.frame(file_list)
    
    #next time step
    setwd(out_folder2)
    file_list2 <- list.files()
    
    #file_list2    #selecting files, based on string recognition to select outputs
    stringPattern<-"nodes" #distancesprefix
    
    #get list of species files    
    file_list2<-file_list2[lapply(file_list2,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
    #file_list<-unique(file_list)
    file_list2.df<-data.frame(file_list2)
   
    #make open clean list
    X<-list()
    #iterator start position
    p=1
    
    #loops through two folders (different time steps) and checks whether the corresponding node file is the same. 
    #If same then no need to run so adds zero to df
    for (e in 1:length(file_list)){
      e.df<-read.table(file.path(out_folder1,file_list[e]))
      e.df[order(e.df[1],e.df[2]),]
      for (f in 1:length(file_list2)){
        if (file_list[e] == file_list[f]){
          f.df<-read.table(file.path(out_folder2,file_list2[f]))
          f.df[order(f.df[1],f.df[2]),]
          test<-all.equal(e.df,f.df)
          if (test[1] == TRUE){
            file_list.df$to_run[p]<-0
          }
          else
          {
            file_list.df$to_run[p]<-1
          }
          p=p+1
          #print(y)
          }
      }
    }
    #feedback
    num_sp_no_change<-length(file_list.df$to_run) - sum(file_list.df$to_run)
    print (paste0("Time periods ", time_periods[k]," to ",time_periods[k+1],": ",num_sp_no_change," species not impacted"))
    
    #to get sp_id and season columns from nodes
    for (r in 1:nrow(file_list.df[1])){
      dt<- strsplit(gsub(".txt","",as.character(file_list.df[r,1])),"_")[[1]]#splits string
      dt<-dt[c(FALSE,TRUE,TRUE,FALSE)]#chooses certain part to keep
      file_list.df$id_no[r]<-dt[1]
      file_list.df$season[r]<-dt[2]
      }

  
    if (combine_with_groupings_output){
      #combining with groupings output
      setwd(out_folder2)
      #combining with grouping output csv to make a combined list in a csv (all_final_to_run_list.csv) of species not to run (to_run field to be used in later steps)
      grouped.df<-read.csv("all_groupings_to_run.csv",header=TRUE)
      joined.df<-merge(file_list.df,grouped.df,by=c("id_no","season"))
      str(file_list.df)
      str(grouped.df)
      str(joined.df)
      names(joined.df)[4]<-"to_run_timestep_filter"
      names(joined.df)[10]<-"to_run_grouped_filter"
      joined.df$to_run<-1
      #if no change between time periods then don't run
      joined.df$to_run[which(joined.df$to_run_timestep_filter==0)]<-0
      #if change between time periods then treat use groupings column
      joined.df$to_run[which(joined.df$to_run_timestep_filter==1 & joined.df$to_run_grouped_filter==1)]<-1
      joined.df$to_run[which(joined.df$to_run_timestep_filter==1 & joined.df$to_run_grouped_filter==0)]<-0
      write.csv(joined.df,"all_final_to_run_list.csv",row.names=FALSE)
      joined.df$to_run
      total_length<-length(joined.df$to_run)
      num_sp_no_change<-total_length - sum(joined.df$to_run)
      percent<-round((num_sp_no_change/total_length*100),2)
      print (paste0(a$eco_name[y]," - time periods ", time_periods[k]," to ",time_periods[k+1],": ",num_sp_no_change," out of ", total_length," (",percent,"%) species not run"))
      
      #copy file from t1 into t0 and make all in the "to_run" field set as 1.
      t1file_list.df<-file_list.df
      t1file_list.df$to_run<-1
      t1file_list.df
      setwd(out_folder1)
      write.csv(t1file_list.df,"all_final_to_run_list.csv",row.names=FALSE)
      setwd(out_folder2)
    }else {
      print ("Not combining with grouping output")
      #copy impacted file to "all_final_to_run_list.csv" for t1,t2 etc so final csv can be used
      setwd(out_folder2)
      write.csv(file_list.df,"all_final_to_run_list.csv",row.names=FALSE)
      
      #copy file from t1 into t0 and make all in the "to_run" field set as 1.
      setwd(out_folder1)
      t1file_list.df<-file_list.df
      t1file_list.df$to_run<-1
      t1file_list.df
      write.csv(t1file_list.df,"all_final_to_run_list.csv",row.names=FALSE)
      
      setwd(out_folder2)
      #useful code for deleting files if needed  
      #fn<-"filename_here"
      #if (file.exists(fn)) file.remove(fn)
    }
 
  }
}

