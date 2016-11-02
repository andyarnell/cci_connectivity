import math

dispConst = 100000
inP = 0.36788

k=(-1*(math.log(inP)/dispConst))
#print k 
nodeDist=1000
p = math.exp(-k *nodeDist)

print p

p = math.exp(-(-1*(math.log(inP)/dispConst)) *nodeDist)
