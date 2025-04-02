simulationFile = "RTL_op_layer12.txt"

realFile = "ACT.hex"

with open(simulationFile) as sim:
    simData = []
    for line in sim:
        simData.append(line[0:2].upper())


with open(realFile) as real:
    realData = []
    for line in real:
        realData.append(line[9:11])

match = []
for i in range(len(simData)):
    if simData[i] == realData[i]:
        match.append(True)
    else:
        print(i)
        match.append(False)

print(match)
