

##can be used in conjuction with the grouping script - but hard to control numbers of groups automatically so manual grouping option chosen

sp_list1<-data.frame(paste0(sp_list$id_no1,"_",sp_list$season))

sp_list1$Disp_mean<-(sp_list$Disp_mean)
names(sp_list1)<-c("id","Disp_mean")
#sp_list1$Disp_mean<-as.numeric(sp_list1$Disp_mean)
str(sp_list1)
sp_list1<-data.frame(paste0(sp_list$id_no1,"_",sp_list$season))

sp_list1$Disp_mean<-(sp_list$Disp_mean)
names(sp_list1)<-c("id","Disp_mean")
#sp_list1$Disp_mean<-as.numeric(sp_list1$Disp_mean)
str(sp_list1)

#   #clustering tests
#   wine<-sp_list1
#   #normalising 
#   wine.stand <- scale(wine[-1])
#   
  #kmeans
  
  k.means.fit <- kmeans(wine.stand, 6)
  

  head(wine)
  k.means.fit$size
  
  wssplot <- function(data, nc=6, seed=1234){
    wss <- (nrow(data)-1)*sum(apply(data,2,var))
    for (i in 2:nc){
      set.seed(seed)
      wss[i] <- sum(kmeans(data, centers=i)$withinss)}
    plot(1:nc, wss, type="b", xlab="Number of Clusters",
         ylab="Within groups sum of squares")}
  
  wssplot(wine.stand, nc=10) 
  
  #https://rstudio-pubs-static.s3.amazonaws.com/33876_1d7794d9a86647ca90c4f182df93f0e8.html
  k.means.fit <- kmeans(wine.stand, 6)
  wine$cluster<-k.means.fit$cluster
  plot(wine$cluster~wine$Disp_mean)
  wine
  #wine.order<-wine[order(wine$Disp_mean),]
  #wine.order
  
  
  wine.mean<-aggregate(wine$Disp_mean, list(wine$cluster), mean)
  wine.comb<-merge(wine,wine.mean,by.x="cluster",by.y="Group.1")
  names(wine.comb)<-c(names(wine.comb[1:3]),"group")
  str(wine.comb)
  wine.comb$diff<-wine.comb$group/wine.comb$Disp_mean
  min(wine.comb$diff)
  max(wine.comb$diff)
  wine.comb
  wine.comb$group[(which(wine.comb$diff<lowerbound | wine.comb$diff>upperbound))]<-wine.comb$Disp_mean[(which(wine.comb$diff<lowerbound | wine.comb$diff>upperbound))]
  
  wine.order<-wine.comb[order(wine.comb$Disp_mean),]
  length(unique(wine.order$group))
  plot(wine.order$group~wine.order$Disp_mean)
  

#hierarchical
#   d <- dist(wine.stand, method = "euclidean")
#   
#   H.fit <- hclust(d, method="ward.D")
#   plot(H.fit) # display dendogram
#   groups <- cutree(H.fit, k=10) # cut tree into 5 clusters
#   # draw dendogram with red borders around the 5 clusters
#   rect.hclust(H.fit, k=10, border="red") 
#   table(wine[,1],groups)
#   

#looping through sp_list dataframe 
#for each row seeing if disp_mean of any others in list (hence the secnod loop) are within upper and lower bounds (see start of script for these)
#