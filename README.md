## SPI Bus Information
The SPI bus on the crazy fly processor has a control mechanism that allows it to operate in multiple different modes depending on the first byte you send in a packet. The header packet determines which memory you access, whether you read or write to the memory and how much data you read or write.

| Header Byte        | Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Activation Memory  | 1     | 0     | x     | x     | x     | x     | x     | x     |
| Instruction Memory | 1     | 1     | x     | x     | x     | x     | x     | x     |
| Parameter Memory   | 0     | 1     | x     | x     | x     | x     | x     | x     |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Write Mode         | x     | x     | 0     | x     | x     | x     | x     | x     |
| Read Mode          | x     | x     | 1     | x     | x     | x     | x     | x     |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Burst Mode         | x     | x     | x     | 1     | x     | x     | x     | x     |
| Single Mode        | x     | x     | x     | 0     | x     | x     | x     | x     |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Burst Length       | x     | x     | x     | x     | x     | x     | 0/1   | 0/1   |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Header Identifier  | x     | x     | x     | x     | 1     | 1     | x     | x     |
| ------------------ | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| Processor Resest   | 0     | 0     | x     | x     | x     | x     | x     | 1     |
| Processor Enable   | 0     | 0     | x     | x     | x     | x     | 1     | x     |
| Processor Disable  | 0     | 0     | x     | x     | x     | x     | 0     | x     |

### Memory Selection
In order to accomodate the three memory types on the crazy flie processor, the spi bus can be configured to allow for 3 Memory modes. Bit 7 and Bit 6 are used to select the memory that is being accessed The above table defines the appropriate bits to send to access specific memories.

### Read/Write Mode
The SPI bus allows for either read or write operations but not simultaneous operations. To specify the type of operation set bit 5 to 0 to write to the SPI bus or 1 to read from the bus. If you are reading from the bus it is important to keep the bus active by sending bytes of 0 through SPI for the expected amount of byte you want to read.

### Burst Mode
To improve SPI bus efficiency you can read and write in burst mode which allows you to read or write from sequential locations in memory without having to specify a new address. 
To enable this set bit 4 to 1 and then set the number of burst bytes that you are sending after the header. When in burst mode, bits 1 and 0 determine how many of the bytes following the header are used to determine the burst length ranging from 1-3 bytes. 
This is neccessary to enable burst operations that are large enough to make substantial speed differences.
It is important to make sure you send the specified number of burst bytes after the header byte otherwise the bus will be unrecoverable and a reset is required.

### Register Mode
If Byte 7 and Byte 6 are both set to 0 this will put the spi bus in register mode which can be used to send control signals to the processor. 
In this mode bit 1 will control a processor enable register allowing you to enable and disable the processor.
Bit 0 will control a processor reset line. Setting bit 0 to 1 will temporarily trigger a processor reset for around 16 clock cycles and then the register will be set back to 0.
Setting bit 0 to 0 in this mode does nothing.

## SPI Packet structure
### Writing
| Header Byte | 0-3 Burst Bytes | 1-2 Address Bytes | Write Bytes |
### Reading
| Header Byte | 0-3 Burst Bytes | 1-2 Address Bytes | Filler Bytes |
