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

    
    
    #print(dataList)

    if messageSize:
        dataPacketSize = messageSize
    else:
        dataPacketSize = len(dataList)-1

    numBytes = (dataWidth)//8
    # print("Number of bytes in a data word")
    # print(numBytes) # Numebr of bytes in data word

    # print("########################")

    numWords = 350//numBytes
    # print("Number of words per SPI packet")
    # print(numWords) # Number of words that can fit in an SPI packet

    # print("Number of words required to send")
    # print(dataPacketSize) # Number of words required to send

    numPackets = math.ceil(dataPacketSize/numWords)
    # print("Number of packets required to send")
    # print(numPackets) # Number of words required to send


    SPI_Packet_list = listsplit(dataList, numPackets)
    # print("Number of words sent in each SPI packet")
    # print(len(SPI_Packet_list[-1]))
    # print("########################")

    outputDataList = []
    if startAddress is None:
        startAddress = 0
    spi_packet_address = startAddress
    packetSize = 0
    for packetNum, packet in enumerate(SPI_Packet_list):
        spi_packet_address += packetSize
        packetSize = len(packet)
        burstTop = (packetSize >> 16) & 0xff
        burstMiddle = (packetSize >> 8) & 0xff
        burstBottom = (packetSize & 0xff) -1
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
            
        
    
        # print("###### BURST #######")
        # print(burst)
        # print("#############")

        headerIdentifier = 12

        header = memoryHeader + readHeader + burstHeader + headerIdentifier + burstCount


        if packetType == "instruction":
            address = [spi_packet_address]
        else:
            addressTop = (spi_packet_address >> 8) & 0xff
            addressBottom = spi_packet_address & 0xff
            address = [addressTop, addressBottom]

        
        # print("###### ADDRESS #######")
        # print(address)
        # print("#############")

        if read:
            outputData = [0]*(packetSize+1)
        else:
            outputData = []
            n = 8
            for word in packet:
                outputData.extend([int(word[i:i+n],2) for i in range(0, len(word), n)])

        spiOut = [header] + burst + address + outputData
        outputDataList.append(spiOut)

    return outputDataList

data = flatten(packetGenerator("", "activation", True,0, 4095))
print(data)


filename = "data\Memory_Readback.txt"
with open(filename, "w") as f:
    for line in data:
        f.write(f"{line}\n")
