#useful for working out what multiple of dispersal dsitance to use to get a specific probability threshold 

dispConst=200
inP=0.36788
#distance
newP=0.0001
newDist<-((log(newP)))/-(-1*(log(inP)/dispConst))
newDist

#and in reverse
p = exp(-(-1*(log(inP)/dispConst)) * newDist)


