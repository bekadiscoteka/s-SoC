# Bootloader handshake process
All the communication is through UART and in little endian type 
CRC32 is zlib.crc32

1. After succesfull boot, CPU sends "ready" signal: '>' 
2. Host PC starts with a header:
	2.1: 6 byte magic string: "listen". 
	2.2: 32 bit aligned addr: from where to start loading? CPU will jump to this address after load. 
	2.3: 16 bit size of the program in bytes ( not including CRC and the end )
	2.4: 32 bit CRC for the whole header

3. bootloader responds if stage 2 is successfull:
- YES = 'Y'
- NO  = 'N'

4. Host PC starts sending the program 
At the end it will send CRC32 for the whole program  

5. Program answers if that was successfull. 
- YES = 'Y'
- NO  = 'N'

After any 'NO', bootloader is reset to initial stage
during the handshake, if any bytes are delayed from Host side, bootloader at max waits 50ms, after which it will send 'N' and reset
reset means bootloader will wait the line to be quiet (50ms as well), and then sends ready signal '>' again, starting from 1 stage

the whole program size should satisfy: addr - 0x80000000 + size <= 31KB
# There is no CPU instruction cache reset yet, and transformation to VexRV should consider it !


