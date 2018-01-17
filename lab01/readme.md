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

> Q: We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment.
```
// unsigned decimal
case 'u':
	num = getuint(&ap, lflag);
	base = 10;
	goto number;
//unsigned octal
case 'o':
	num = getuint(&ap, lflag);
	base = 8;
	goto number;
照着unsigned decimal做
```

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

```
1. fmt-->"x %d, y %x, z %d\n" , ap---->x,y,z
2. cons_putc-->int ch, va_arg-->va_list ap, type.调用之前指向x,调用之后指向y,再调用之后指向z. vcprintf-->fmt:"x %d, y %x, z %d\n" , ap:x,y,z
```
>Q： Run the following code.
   ``` 
   unsigned int i = 0x00646c72;
   cprintf("H%x Wo%s", 57616, &i);
   ```
What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise. Here's an ASCII table that maps bytes to characters.
The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?
```
output:He110, World
```
>Q:In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?
    cprintf("x=%d y=%d", 3);
```
the first is 3, the second is random number
```
> Q:Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?
```
va_start, va_arg and va_end macros need to be changed to decrease the point every time they fetching a new argument from the stack.
```
### Exercise9
> Q: Determine where the kernel initializes its stack, and exactly where in memory its stack is located. How does the kernel reserve space for its stack? And at which "end" of this reserved area is the stack pointer initialized to point to?
```
movl	$0x0,%ebp
movl	$(bootstacktop),%esp
```
>
### Exercise 10
>Q:To become familiar with the C calling conventions on the x86, find the address of the test_backtrace function in obj/kern/kernel.asm, set a breakpoint there, and examine what happens each time it gets called after the kernel starts. How many 32-bit words does each recursive nesting level of test_backtrace push on the stack, and what are those words?
```
8 个32bit 字
```
### Exercise 11
> Q:Implement the backtrace function as specified above. Use the same format as in the example, since otherwise the grading script will be confused. When you think you have it working right, run make grade to see if its output conforms to what our grading script expects, and fix it if it doesn't. After you have handed in your Lab 1 code, you are welcome to change the output format of the backtrace function any way you like.
```
要想理解此段代码，需先熟悉ebp, eip, 参数在内存中的排列顺序
补全代码:
int 
mon_backtrace(int argc, char ** argv, struct Trapframe *tf){
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:");
	while(ebp!=0){
		uint32_t eip = *(uint32_t*)(ebp+0x4);
		cprintf("  ebp %x  eip %x args %x %x %x %x %x\n", ebp, eip,\
			*(uint32_t *)(ebp+0x8), *(uint32_t *)(ebp+0xc),\
			*(uint32_t *)(ebp+0x10), *(uint32_t *)(ebp+0x14),\
			*(uint32_t *)(ebp+0x18));
		ebp=*(uint32_t *)(ebp);
	}
	return 0;
}
```
### Exercise 12
Q: 输入`backstrace`,打印如下内容(补一个命令):
```
K> backtrace
Stack backtrace:
  ebp f010ff78  eip f01008ae  args 00000001 f010ff8c 00000000 f0110580 00000000
         kern/monitor.c:143: monitor+106
  ebp f010ffd8  eip f0100193  args 00000000 00001aac 00000660 00000000 00000000
         kern/init.c:49: i386_init+59
  ebp f010fff8  eip f010003d  args 00000000 00000000 0000ffff 10cf9a00 0000ffff
         kern/entry.S:70: <unknown>+0
```
#### Answer:
> 1.在命令列表中添加该命令，与相关函数相关联。
```
static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "backtrace", "Display the information tracked",backtrace },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
};
```
> 2.修改mon_backtrace为backtrace.
```
int 
backtrace(int argc, char **argv, struct Trapframe *tf)
{
	//Your code here
	uint32_t* ebp = (uint32_t *)read_ebp();
	/*
		将read_ebp()返回的内容强制转换成一个指针，就像是一个数组一样，这个数组的内容一次是ebp(0),eip(1),argv1(2)……， 这个思路非常新颖
	*/
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while(ebp!=0){
		uint32_t eip = ebp[1];
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08.x  eip %08.x  args %08.x %08.x %08.x %08.x %08.x\n\t%s:%d: %.*s+%d\n", ebp, eip,\
				ebp[2], ebp[3], ebp[4], ebp[5], ebp[6], info.eip_file, info.eip_line, \
				info.eip_fn_namelen, info.eip_fn_name,	eip-info.eip_fn_addr);
		ebp =(uint32_t *)*ebp;
	}
	return 0;
}

```
> 3.修改kdebug.c
```
...
stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr);
if(lline > rline){
	return -1;
} else {
	info->eip_line = stabs[lline].n_desc;    //n_desc属性就是line number
}
...
```
> 4.修改init.c
```
void
test_backtrace(int x)
{
	cprintf("entering test_backtrace %d\n", x);
	if (x > 0)
		test_backtrace(x-1);
	else
		backtrace(0, 0, 0);		//虚拟机直接先执行backtrac命令.
	cprintf("leaving test_backtrace %d\n", x);
}
```
