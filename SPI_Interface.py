import spidev
import RPi.GPIO as GPIO
import math
import time



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
        burstBottom = packetSize & 0xff -1
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

class crazy_processor():
    
    def __init__(
        self,
        instruction_file:str,
        parameter_file:str = None,
        spi_bus:int = 0, 
        spi_device:int = 1, 
        spi_speed:int = 7500000,
        spi_mode:int = 0b00,
        interrupt_pin:int = 16,
        ):
        self._bus = spi_bus
        self._device = spi_device
        self._spi = spidev.SpiDev()
        self._spi_speed = spi_speed
        self._spi_mode = spi_mode
        self._interrupt_pin = interrupt_pin
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self._interrupt_pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        self.processor_reset()
        self.processor_init(instruction_file, parameter_file)


    def spi_decorator(func):
        def wrapper(self, *args,**kwargs):
            self._spi.open(self._bus, self._device)
            self._spi.max_speed_hz = self._spi_speed
            self._spi.mode = self._spi_mode
            out = func(self, *args,**kwargs)
            self._spi.close()
            return out
        return wrapper
    
    @spi_decorator
    def processor_init(self, instruction_file, parameter_file):

        with open(instruction_file, "r") as f:
            data = f.read()
        spiData = packetGenerator(data, "instruction")
        for packet in spiData:
            resp = self._spi.xfer2(packet)

        # with open(parameter_file, "r") as f:
        #     data = f.read()
        # spiData = packetGenerator(data, "parameter")
        # for packet in spiData:
        #     resp = self._spi.xfer2(packet)

    @spi_decorator
    def processor_reset(self): 
        resp = self._spi.xfer2([int("00001101", 2)])

    @spi_decorator
    def processor_enable(self):
        resp = self._spi.xfer2([int("00001110", 2)])

    @spi_decorator
    def processor_disable(self):
        resp = self._spi.xfer2([int("00001100", 2)])

    @spi_decorator
    def _send_activation(self, data):
        spiData = packetGenerator(data, "activation")
        for packet in spiData:
            resp = self._spi.xfer2(packet)

    @spi_decorator
    def _read_output(self, startAddress, outputLength):
        spiData = packetGenerator("", "activation", True,startAddress, outputLength)
        outputData = []
        for packet in spiData:
            resp = self._spi.xfer2(packet)
            outputData.extend(resp[-outputLength:])
        return outputData

    
    def processor_run(self, activation_data, outputLength:int = 4, startAddress:int = 0):
        self._send_activation(activation_data)
        self.processor_reset()
        self.processor_enable()
        GPIO.wait_for_edge(self._interrupt_pin, GPIO.RISING)
        outputData = self._read_output(startAddress,outputLength)
        self.processor_disable()
        self.processor_reset()
        return outputData
                

if __name__ == "__main__":
    #TODO modify code to accept main data type that is planning on being used

    instructionMemory = "data/instruction_data.txt"
    parameterMemory = "data/parameter_data.txt"
    activationMemory = "data/activation_data.txt"

    crazy_proc = crazy_processor(instructionMemory, parameterMemory)

    with open(activationMemory, "r") as f:
        data = f.read()

    starttime = time.monotonic_ns()
    outputData = crazy_proc.processor_run(data)
    endtime = time.monotonic_ns()

    timeTaken = (endtime - starttime)/1000000000
    print("Output Bytes")
    print(outputData)
    print("Processing time")
    print(timeTaken)
