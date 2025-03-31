packetSize = 1000000
burstHeader = 16 # 1
burstTop = (packetSize >> 16) & 0xff
burstMiddle = (packetSize >> 8) & 0xff
burstBottom = packetSize & 0xff
if burstTop:
    burstCount = 3
elif ~burstTop and burstMiddle:
    burstCount = 2
elif ~burstTop and ~burstMiddle and burstBottom:
    burstCount = 1
else:
    burstCount = 0

print(burstCount)
