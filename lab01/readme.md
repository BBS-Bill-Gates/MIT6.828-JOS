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

Before enter JOS Kernel 
```
(gdb) x/20x 0x00100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
0x100040:	0x53e58955	0x8b0cec83	0x6853085d	0xf0101980
(gdb) x/20x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100010 <entry+4>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100020 <entry+20>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100030 <relocated+1>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100040 <test_backtrace>:	0x00000000	0x00000000	0x00000000	0x00000000
```
After enter JOS Kernel
```
(gdb) x/20x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100010 <entry+4>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100020 <entry+20>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100030 <relocated+1>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100040 <test_backtrace>:	0x00000000	0x00000000	0x00000000	0x00000000
(gdb) x/20x 0x00100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
0x100040:	0x53e58955	0x8b0cec83	0x6853085d	0xf0101980

```
before executing the instruction :  movl %eax, %cr0
```
(gdb) x/20x 0x00100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
0x100040:	0x53e58955	0x8b0cec83	0x6853085d	0xf0101980
(gdb) x/20x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100010 <entry+4>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100020 <entry+20>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100030 <relocated+1>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100040 <test_backtrace>:	0x00000000	0x00000000	0x00000000	0x00000000
```
After executing the instruction :  movl %eax, %cr0
```
(gdb) x/20x 0xf0100000
0xf0100000 <_start+4026531828>:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0xf0100010 <entry+4>:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0xf0100020 <entry+20>:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0xf0100030 <relocated+1>:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
0xf0100040 <test_backtrace>:	0x53e58955	0x8b0cec83	0x6853085d	0xf0101980
(gdb) x/20x 0x00100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
0x100040:	0x53e58955	0x8b0cec83	0x6853085d	0xf0101980
```
#### Summary
> `movl %eax, %cr0`， 开启了分页机制， 使用虚拟内存。执行这条汇编指令之后，0xf0100000和0x00100000的物理地址是一样的。
```
Prior to enabling paging, 0x00100000 consists kernel instructions while 0xf0100000 remains empty. After paging is enabled, virtual addresses in the range 0xf0000000 through 0xf0400000 have been translated into physical addresses 0x00000000 through 0x00400000. Thus, 0xf0100000 points to the same memory as 0x00100000.
```
### Exercise8
> Q:Explain the interface between printf.c and console.c. Specifically, what function does console.c export? How is this function used by printf.c?
```
console.c主要屏蔽硬件，提供的主要函数就是cons_putc(int c),prinf.c提供的主要函数就是cprintf(const char* fmt,...).
cprintf函数会调用conputc函数和printfmt.c文件中的函数。我们主要使用的函数也是cprintf.
```
>Q:Explain the following from console.c:
```
1      if (crt_pos >= CRT_SIZE) {
2              int i;
3              memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
4              for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
5                      crt_buf[i] = 0x0700 | ' ';
6              crt_pos -= CRT_COLS;
7      }
```
```
换行
```
Q:For the following questions you might wish to consult the notes for Lecture 2. These notes cover GCC's calling convention on the x86.
Trace the execution of the following code step-by-step:
```
int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
```
- In the call to cprintf(), to what does fmt point? To what does ap point?
- List (in order of execution) each call to cons_putc, va_arg, and vcprintf. For cons_putc, list its argument as well. For va_arg, list what ap points to before and after the call. For vcprintf list the values of its two arguments.






