#########################################
## Analyze CS - LCP - distances ###
#########################################

###28-06-16#############

#### Load Circuit Scape table ####

setwd("C:/Users/scienceintern/Documents/AndreaCB/CircuitScape/output/")

c22681841res<-read.table(file="22681841ccs_resistances_3columns", header=FALSE)

head(c22681841res)
colnames(c22681841res)[1] <- "node1"
colnames(c22681841res)[2] <- "node2"
colnames(c22681841res)[3] <- "csDist"

#create a column for link

c22681841res$link<-with(c22681841res, interaction(node1, node2))
c22681841res<-c22681841res[c("link","node1","node2","csDist")]

View(c22681841res)

#### Load Linkage Mapper table #####

# setwd("C:/Users/scienceintern/Documents/AndreaCB/LinkageMapper1_0_9/testing/l_22678883/output")
# 
# lm22678883<-read.csv(file="l_22678883_linkTable_s5.csv", header=TRUE)
# 
# View(lm22678883)
# lm22678883<-lm22678883[-c(10, 11, 12), ] 
# 
# View(lm22678883)

## extract columns that I need  "eucDist" ,  "lcDist"  ##

names(lm22678883)
lm22678883<-lm22678883[c(1,2,3,7,8)]
lm22678883$link<-with(lm22678883, interaction(coreId1, coreId2))
lm22678883<-lm22678883[c("link","coreId1","coreId2", "eucDist" ,"lcDist")]

##### MERGE CS table and LCP table ##

names(cs22678883res)
names(lm22678883)
D22678883<-merge(cs22678883res, lm22678883, by.x="link", by.y="link", all=FALSE)

View(D22678883)
names(D22678883)
D22678883<-D22678883[c("link","node1","node2","csDist", "eucDist" ,"lcDist")]
                

plot(D22678883$eucDist,D22678883$csDist)    
plot(D22678883$eucDist,D22678883$lcDist)   
plot(D22678883$csDist,D22678883$lcDist)  
