#Aim: calculate the area weighted probability of dispersal between cells based on the individual distances between all the nodes in the cells.
#Andy Arnell 25/02/2016
#install.packages("gdata")



##UNFINISHED

library(gdata) 
rm(list=ls())

setwd("C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs")
getwd()
inCSV<-"results_all_EC(PC).txt"
cells<-read.table(inCSV,header=T)
str(cells)
head(cells)
cells$Prefix<-sub("dis_sp_","",cells$Prefix)
cells$Prefix<-sub("\\.txt_*","",cells$Prefix)
cells$Prefix<-sub("_*\\.","",cells$Prefix)
