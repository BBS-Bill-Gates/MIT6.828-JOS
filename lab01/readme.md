# lab01

### Exercise3
> Question1:	At what point does the processor start executing 32-bit code?
>  What exactly causes the switch from 16-bit to 32-bit mode?
```
A20地址线开启，系统从实模式切换到保护模式，从16bit切换到32bit

 # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60
  ...
  lgdt    gdtdesc
  movl    %cr0, %eax    ; eax是32bit的寄存器,所以是从此开始执行32bit的code
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0
```
>Question2:What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?
```
The last struction:((void (*)(void)) (ELFHDR->e_entry))();  ---->boot/boot.S
The first struction:movw	$0x1234,0x472 ---->kern/entry.S
```
> Question3:Where is the first instruction of the kernel?
```
0x0010000c: 66 c7 05 72 04 00 00  movw   $0x1234,0x472
```
>Question4:How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?
```
ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
```
**The number of sector:sizeof(eph-ph)/sizeof(ph)**

![elf.png](https://github.com/Clann24/jos/raw/master/lab1/assets/elf.png)
### Exercise6
> Question: Example the 8 words of memory at 0x00100000 at the point the BIOS enters the boot loader
They all zeros
>Question: and then again at the point the boot loader enters the kernel
They are the first few instructions of the kernel
```
(gdb) x/8x 0x00100000
0x100000: 0x1badb002  0x00000000  0xe4524ffe  0x7205c766
0x100010: 0x34000004  0x6000b812  0x220f0011  0xc0200fd8
(gdb) x/8i 0x00100000
0x100000: add    0x1bad(%eax),%dh
0x100006: add    %al,(%eax)
0x100008: decb   0x52(%edi)
0x10000b: in     $0x66,%al
0x10000d: movl   $0xb81234,0x472
0x100017: pusha 
0x100018: adc    %eax,(%eax)
0x10001a: mov    %eax,%cr3
(gdb) 
```
### Exercise7
>Q: Use QEMU and GDB to trace into the JOS kernel and stop at the movl %eax, %cr0. Examine memory at 0x00100000 and at 0xf0100000. Now, single step over that instruction using the stepi GDB command. Again, examine memory at 0x00100000 and at 0xf0100000. Make sure you understand what just happened.
```

```











