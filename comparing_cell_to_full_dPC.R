setwd("C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/eca_test")
comp<-read.csv("comparison.csv")
head(comp)
plot(comp$pc_by_awp~comp$dPC)
plot(comp$varPC.1~comp$varPC)

