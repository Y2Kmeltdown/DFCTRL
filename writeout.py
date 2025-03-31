import spidev

bus = 0
device = 1
spi = spidev.SpiDev()
spi.open(bus, device)

# Settings
spi.max_speed_hz = 4000000
spi.mode = 0b00

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


resp2 = spi.xfer2(testBurstRead.copy())
print(resp2)