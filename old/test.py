import math

dispConst = 200
inP = 0.5

k=-1*(math.log(inP)/dispConst)

print k 

nodeDist=1000
p = math.exp(-k *nodeDist)

print p

