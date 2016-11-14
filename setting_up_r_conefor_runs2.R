#call conefor batch mode
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test")

shell("conefor_1_0_86_bcc_x86.exe -nodeFile nodes_  -conFile distances_ -* -confAdj 21000 -IIC -nodetypes")

shell("conefor_1_0_86_bcc_x86.exe -nodeFile nodes_ -conFile distances_ -* -confProb 7112.854473 0.36788 -PC onlyoverall")

shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor_1.0.85_X64.exe -nodeFile nodes_3_columns -t dist notall -confProb 7112.854473 0.36788 -PC -nodetypes")

shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor_1.0.85_X64.exe -nodeFile nodes -t dist notall -confProb 7112.854473 0.36788 -PC -nodetypes")

shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor_1_0_86_bcc_x86.exe -nodeFile nodes_sp_22678736_1 -conFile distances_sp_22678736_1 -t dist notall -confProb 7112.854473 0.36788 -PC -nodetypes")

shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor.exe -nodeFile nodes -conFile distances -* -t dist notall -confAdj -confProb 100000 0.36788 -PC -nodeTypes -prefix sp_22678748_1")
shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor.exe -nodeFile nodes -conFile distances -* -t dist notall -confAdj -confProb 100000 0.36788 -PC -nodeTypes -prefix sp_22678752_1")
shell("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/conefor.exe -nodeFile nodes -conFile distances -* -t dist notall -confAdj -confProb 100000 0.36788 -PC -nodeTypes -prefix sp_22678760_1")


par(mfrow=c(3,1))
res.PC<-read.table("C:/Users/andya/Desktop/CCI_connectivity_proposal_2014/gis_test/results_all_EC(PC).txt", header=TRUE, sep="\t")
hist(log(res.PC$EC.PC.),xlim=c(0,35),ylim=c(0,3000))
res.IIC<-read.table("C:/Users/andya/Desktop/CCI_connectivity_proposal_2014/gis_test/results_all_EC(IIC).txt", header=TRUE, sep="\t")
hist(log(res.IIC$EC.IIC.),xlim=c(0,35),ylim=c(0,3000))
res.all<-read.table("C:/Users/andya/Desktop/CCI_connectivity_proposal_2014/gis_test/results_all_overall_indices.txt", header=FALSE, sep="\t")
head(res.all)
res.allsub<-subset(res.all,res.all[2]==100000 & V4=="PCnum")
head(res.allsub)
hist(log(res.allsub$V5),xlim=c(0,35), ylim=c(0,3000))
summary(res.PC)


?lapply


#resmean<-aggregate(nodes,by=list(nodes$sciname),FUN=mean)

