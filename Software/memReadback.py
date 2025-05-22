import math

def flatten(xss):
    return [x for xs in xss for x in xs]

def convertBinaryList(binList):
    return [int(i, 2) for i in binList]

def listsplit(a:list, n:int):
    k, m = divmod(len(a), n)
    return (list(a[i*k+min(i, m):(i+1)*k+min(i+1, m)] for i in range(n)))

def packetGenerator(data:str, packetType:str, read:bool = False, startAddress = None, messageSize = None):
    if packetType == "instruction":
        memoryHeader = 192 #11
        addressWidth = 6
        dataWidth = 80
    elif packetType == "parameter":
        memoryHeader = 64 #01
        addressWidth = 15
        dataWidth = 128
    elif packetType == "activation":
        memoryHeader = 128 #10
        addressWidth = 12
        dataWidth = 8

    if read:
        readHeader = 32 #1
        dataList = ["0"*addressWidth]*messageSize
    else:
        readHeader = 0 #0
        dataList = data.split("\n")
        dataList = list(filter(None, dataList))

    if messageSize:
        dataPacketSize = messageSize
    else:
        dataPacketSize = len(dataList)
    if startAddress is None:
        startAddress = 0
    spi_packet_address = startAddress
    burstTop = (dataPacketSize >> 16) & 0xff
    burstMiddle = (dataPacketSize >> 8) & 0xff
    burstBottom = (dataPacketSize & 0xff) -1
    if burstTop:
        burstHeader = 16 # 1
        burstCount = 3
        burst = [burstTop,burstMiddle,burstBottom]
    elif ~burstTop and burstMiddle:
        burstHeader = 16 # 1
        burstCount = 2
        burst = [burstMiddle,burstBottom]
    elif ~burstTop and ~burstMiddle and burstBottom:
        burstHeader = 16 # 1
        burstCount = 1
        burst = [burstBottom]
    else:
        burstHeader = 0 # 1
        burstCount = 0
        burst = []
    
    headerIdentifier = 12

    header = memoryHeader + readHeader + burstHeader + headerIdentifier + burstCount
    



    if packetType == "instruction":
        address = [spi_packet_address]
    else:
        addressTop = (spi_packet_address >> 8) & 0xff
        addressBottom = spi_packet_address & 0xff
        address = [addressTop, addressBottom]

    if read:
        outputData = [0]*(dataPacketSize+1)
    else:
        outputData = []
        n = 8
        
        for word in data.split("\n"):
            outputData.extend([int(word[i:i+n],2) for i in range(0, len(word), n)])

    spiOut = [header] + burst + address + outputData

    return spiOut

instructionMemory = "data/14052025_instruction_data.txt"
parameterMemory = "data/14052025_parameter_data.txt"
activationMemory = "data/14052025_activation_data.txt"

instructionSPI = "data/instructionSPI.txt"
parameterSPI = "data/parameterSPI.txt"
activationSPI = "data/activationSPI.txt"

with open(instructionMemory, "r") as fin, open(instructionSPI, "w") as fout:
    data = fin.read()
    spiData = packetGenerator(data, "instruction")
    for line in spiData:
        fout.write(f"{format(line, '#010b')[2:]}\n")
    

with open(parameterMemory, "r") as fin, open(parameterSPI, "w") as fout:
    data = fin.read()
    spiData = packetGenerator(data, "parameter")
    for line in spiData:
        fout.write(f"{format(line, '#010b')[2:]}\n")
    

with open(activationMemory, "r") as fin, open(activationSPI, "w") as fout:
    data = fin.read()
    spiData = packetGenerator(data, "activation")
    for line in spiData:
        fout.write(f"{format(line, '#010b')[2:]}\n")
    


data = packetGenerator("", "activation", True,0, 4095)


filename = "data\Memory_Readback.txt"
with open(filename, "w") as fout:
    for line in data:
        fout.write(f"{format(line, '#010b')[2:]}\n")


