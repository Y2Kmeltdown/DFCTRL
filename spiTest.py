import spidev
import time

bus = 0
device = 1
import spidev
spi = spidev.SpiDev()
spi.open(bus, device)

# Settings (for example)
spi.max_speed_hz = 4000000
spi.mode = 0b00

# 10001100
# 00000000
# 00000001

# 10101100
# 00000000
# 00000000

# testWrite = [
#     0x8C,
#     0x00,
#     0x01
# ]

# testRead = [
#     0x8C,
#     0x00,
#     0x00,
#     0x00
# ]

# resp1 = spi.xfer2(testWrite.copy())
# resp2 = spi.xfer2(testRead.copy())
# print(resp1)
# print(resp2)
# resp1 = spi.xfer2(testWrite.copy())
# resp2 = spi.xfer2(testRead.copy())
# print(resp1)
# print(resp2)

# 10011101
# 00000011
# 00000000
# 00000000
# 00000001
# 00000010
# 00000011
# 00000100

# 10111101
# 00000011
# 00000000
# 00000000
# 00000000
# 00000000
# 00000000
# 00000000


testBurstWrite = [
    0x9D,
    0x03,
    0x00,
    0x00,
    0x01,
    0x02,
    0x03,
    0x04
]
testBurstRead = [
    0xBD,
    0x03,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00
]

resp1 = spi.xfer2(testBurstWrite.copy())
resp2 = spi.xfer2(testBurstRead.copy())
print(resp1)
print(resp2)
#resp1 = spi.xfer2(testBurstWrite.copy())
#resp2 = spi.xfer2(testBurstRead.copy())
#print(resp1)
#print(resp2)


# while (True):
#     try:
#         resp1 = spi.xfer2(testWrite)
#         resp2 = spi.xfer2(testRead)
#         print(resp1)
#         print(resp2)

#         time.sleep(0.5)
        
#     except KeyboardInterrupt:
#         spi.close()



