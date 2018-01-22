
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 0b 32 00 00       	call   f0103268 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 37 10 f0       	push   $0xf0103700
f010006f:	e8 a9 26 00 00       	call   f010271d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 ab 0f 00 00       	call   f0101024 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 11 07 00 00       	call   f0100797 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 1b 37 10 f0       	push   $0xf010371b
f01000b5:	e8 63 26 00 00       	call   f010271d <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 33 26 00 00       	call   f01026f7 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 c5 3e 10 f0 	movl   $0xf0103ec5,(%esp)
f01000cb:	e8 4d 26 00 00       	call   f010271d <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 ba 06 00 00       	call   f0100797 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 33 37 10 f0       	push   $0xf0103733
f01000f7:	e8 21 26 00 00       	call   f010271d <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ef 25 00 00       	call   f01026f7 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 c5 3e 10 f0 	movl   $0xf0103ec5,(%esp)
f010010f:	e8 09 26 00 00       	call   f010271d <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a a0 37 10 f0 	movzbl -0xfefc860(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 80 37 10 f0 	mov    -0xfefc880(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 4d 37 10 f0       	push   $0xf010374d
f0100265:	e8 b3 24 00 00       	call   f010271d <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 a2 2e 00 00       	call   f01032b5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 59 37 10 f0       	push   $0xf0103759
f01005e2:	e8 36 21 00 00       	call   f010271d <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 a0 39 10 f0       	push   $0xf01039a0
f0100628:	68 be 39 10 f0       	push   $0xf01039be
f010062d:	68 c3 39 10 f0       	push   $0xf01039c3
f0100632:	e8 e6 20 00 00       	call   f010271d <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 70 3a 10 f0       	push   $0xf0103a70
f010063f:	68 cc 39 10 f0       	push   $0xf01039cc
f0100644:	68 c3 39 10 f0       	push   $0xf01039c3
f0100649:	e8 cf 20 00 00       	call   f010271d <cprintf>
	return 0;
}
f010064e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065b:	68 d5 39 10 f0       	push   $0xf01039d5
f0100660:	e8 b8 20 00 00       	call   f010271d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 98 3a 10 f0       	push   $0xf0103a98
f0100672:	e8 a6 20 00 00       	call   f010271d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100689:	e8 8f 20 00 00       	call   f010271d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 f1 36 10 00       	push   $0x1036f1
f0100696:	68 f1 36 10 f0       	push   $0xf01036f1
f010069b:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01006a0:	e8 78 20 00 00       	call   f010271d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 63 11 00       	push   $0x116300
f01006ad:	68 00 63 11 f0       	push   $0xf0116300
f01006b2:	68 08 3b 10 f0       	push   $0xf0103b08
f01006b7:	e8 61 20 00 00       	call   f010271d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 69 11 00       	push   $0x116970
f01006c4:	68 70 69 11 f0       	push   $0xf0116970
f01006c9:	68 2c 3b 10 f0       	push   $0xf0103b2c
f01006ce:	e8 4a 20 00 00       	call   f010271d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006d8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	50                   	push   %eax
f01006f4:	68 50 3b 10 f0       	push   $0xf0103b50
f01006f9:	e8 1f 20 00 00       	call   f010271d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	57                   	push   %edi
f0100709:	56                   	push   %esi
f010070a:	53                   	push   %ebx
f010070b:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010070e:	89 ee                	mov    %ebp,%esi
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f0100710:	68 ee 39 10 f0       	push   $0xf01039ee
f0100715:	e8 03 20 00 00       	call   f010271d <cprintf>
	while (ebp) {
f010071a:	83 c4 10             	add    $0x10,%esp
f010071d:	eb 67                	jmp    f0100786 <mon_backtrace+0x81>
	    cprintf(" ebp %08x eip %08x args", ebp, ebp[1]);
f010071f:	83 ec 04             	sub    $0x4,%esp
f0100722:	ff 76 04             	pushl  0x4(%esi)
f0100725:	56                   	push   %esi
f0100726:	68 00 3a 10 f0       	push   $0xf0103a00
f010072b:	e8 ed 1f 00 00       	call   f010271d <cprintf>
f0100730:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100733:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100736:	83 c4 10             	add    $0x10,%esp
	    for (int j = 2; j != 7; ++j) {
		cprintf(" %08x", ebp[j]);   
f0100739:	83 ec 08             	sub    $0x8,%esp
f010073c:	ff 33                	pushl  (%ebx)
f010073e:	68 18 3a 10 f0       	push   $0xf0103a18
f0100743:	e8 d5 1f 00 00       	call   f010271d <cprintf>
f0100748:	83 c3 04             	add    $0x4,%ebx
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
	    cprintf(" ebp %08x eip %08x args", ebp, ebp[1]);
	    for (int j = 2; j != 7; ++j) {
f010074b:	83 c4 10             	add    $0x10,%esp
f010074e:	39 fb                	cmp    %edi,%ebx
f0100750:	75 e7                	jne    f0100739 <mon_backtrace+0x34>
		cprintf(" %08x", ebp[j]);   
	    }
	    debuginfo_eip(ebp[1], &info);
f0100752:	83 ec 08             	sub    $0x8,%esp
f0100755:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100758:	50                   	push   %eax
f0100759:	ff 76 04             	pushl  0x4(%esi)
f010075c:	e8 c6 20 00 00       	call   f0102827 <debuginfo_eip>
	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	8b 46 04             	mov    0x4(%esi),%eax
f0100767:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010076a:	50                   	push   %eax
f010076b:	ff 75 d8             	pushl  -0x28(%ebp)
f010076e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100771:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100774:	ff 75 d0             	pushl  -0x30(%ebp)
f0100777:	68 1e 3a 10 f0       	push   $0xf0103a1e
f010077c:	e8 9c 1f 00 00       	call   f010271d <cprintf>
	    ebp = (uint32_t *) (*ebp);
f0100781:	8b 36                	mov    (%esi),%esi
f0100783:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
f0100786:	85 f6                	test   %esi,%esi
f0100788:	75 95                	jne    f010071f <mon_backtrace+0x1a>
	    debuginfo_eip(ebp[1], &info);
	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
	    ebp = (uint32_t *) (*ebp);
	}
	return 0;
}
f010078a:	b8 00 00 00 00       	mov    $0x0,%eax
f010078f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100792:	5b                   	pop    %ebx
f0100793:	5e                   	pop    %esi
f0100794:	5f                   	pop    %edi
f0100795:	5d                   	pop    %ebp
f0100796:	c3                   	ret    

f0100797 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100797:	55                   	push   %ebp
f0100798:	89 e5                	mov    %esp,%ebp
f010079a:	57                   	push   %edi
f010079b:	56                   	push   %esi
f010079c:	53                   	push   %ebx
f010079d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a0:	68 7c 3b 10 f0       	push   $0xf0103b7c
f01007a5:	e8 73 1f 00 00       	call   f010271d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007aa:	c7 04 24 a0 3b 10 f0 	movl   $0xf0103ba0,(%esp)
f01007b1:	e8 67 1f 00 00       	call   f010271d <cprintf>
f01007b6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b9:	83 ec 0c             	sub    $0xc,%esp
f01007bc:	68 34 3a 10 f0       	push   $0xf0103a34
f01007c1:	e8 4b 28 00 00       	call   f0103011 <readline>
f01007c6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c8:	83 c4 10             	add    $0x10,%esp
f01007cb:	85 c0                	test   %eax,%eax
f01007cd:	74 ea                	je     f01007b9 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cf:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d6:	be 00 00 00 00       	mov    $0x0,%esi
f01007db:	eb 0a                	jmp    f01007e7 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007dd:	c6 03 00             	movb   $0x0,(%ebx)
f01007e0:	89 f7                	mov    %esi,%edi
f01007e2:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e5:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e7:	0f b6 03             	movzbl (%ebx),%eax
f01007ea:	84 c0                	test   %al,%al
f01007ec:	74 63                	je     f0100851 <monitor+0xba>
f01007ee:	83 ec 08             	sub    $0x8,%esp
f01007f1:	0f be c0             	movsbl %al,%eax
f01007f4:	50                   	push   %eax
f01007f5:	68 38 3a 10 f0       	push   $0xf0103a38
f01007fa:	e8 2c 2a 00 00       	call   f010322b <strchr>
f01007ff:	83 c4 10             	add    $0x10,%esp
f0100802:	85 c0                	test   %eax,%eax
f0100804:	75 d7                	jne    f01007dd <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100806:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100809:	74 46                	je     f0100851 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010080b:	83 fe 0f             	cmp    $0xf,%esi
f010080e:	75 14                	jne    f0100824 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	6a 10                	push   $0x10
f0100815:	68 3d 3a 10 f0       	push   $0xf0103a3d
f010081a:	e8 fe 1e 00 00       	call   f010271d <cprintf>
f010081f:	83 c4 10             	add    $0x10,%esp
f0100822:	eb 95                	jmp    f01007b9 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100824:	8d 7e 01             	lea    0x1(%esi),%edi
f0100827:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010082b:	eb 03                	jmp    f0100830 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100830:	0f b6 03             	movzbl (%ebx),%eax
f0100833:	84 c0                	test   %al,%al
f0100835:	74 ae                	je     f01007e5 <monitor+0x4e>
f0100837:	83 ec 08             	sub    $0x8,%esp
f010083a:	0f be c0             	movsbl %al,%eax
f010083d:	50                   	push   %eax
f010083e:	68 38 3a 10 f0       	push   $0xf0103a38
f0100843:	e8 e3 29 00 00       	call   f010322b <strchr>
f0100848:	83 c4 10             	add    $0x10,%esp
f010084b:	85 c0                	test   %eax,%eax
f010084d:	74 de                	je     f010082d <monitor+0x96>
f010084f:	eb 94                	jmp    f01007e5 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100851:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100858:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100859:	85 f6                	test   %esi,%esi
f010085b:	0f 84 58 ff ff ff    	je     f01007b9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100861:	83 ec 08             	sub    $0x8,%esp
f0100864:	68 be 39 10 f0       	push   $0xf01039be
f0100869:	ff 75 a8             	pushl  -0x58(%ebp)
f010086c:	e8 5c 29 00 00       	call   f01031cd <strcmp>
f0100871:	83 c4 10             	add    $0x10,%esp
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 1e                	je     f0100896 <monitor+0xff>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	68 cc 39 10 f0       	push   $0xf01039cc
f0100880:	ff 75 a8             	pushl  -0x58(%ebp)
f0100883:	e8 45 29 00 00       	call   f01031cd <strcmp>
f0100888:	83 c4 10             	add    $0x10,%esp
f010088b:	85 c0                	test   %eax,%eax
f010088d:	75 2f                	jne    f01008be <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010088f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100894:	eb 05                	jmp    f010089b <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100896:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010089b:	83 ec 04             	sub    $0x4,%esp
f010089e:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a1:	01 d0                	add    %edx,%eax
f01008a3:	ff 75 08             	pushl  0x8(%ebp)
f01008a6:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008a9:	51                   	push   %ecx
f01008aa:	56                   	push   %esi
f01008ab:	ff 14 85 d0 3b 10 f0 	call   *-0xfefc430(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b2:	83 c4 10             	add    $0x10,%esp
f01008b5:	85 c0                	test   %eax,%eax
f01008b7:	78 1d                	js     f01008d6 <monitor+0x13f>
f01008b9:	e9 fb fe ff ff       	jmp    f01007b9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008be:	83 ec 08             	sub    $0x8,%esp
f01008c1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c4:	68 5a 3a 10 f0       	push   $0xf0103a5a
f01008c9:	e8 4f 1e 00 00       	call   f010271d <cprintf>
f01008ce:	83 c4 10             	add    $0x10,%esp
f01008d1:	e9 e3 fe ff ff       	jmp    f01007b9 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d9:	5b                   	pop    %ebx
f01008da:	5e                   	pop    %esi
f01008db:	5f                   	pop    %edi
f01008dc:	5d                   	pop    %ebp
f01008dd:	c3                   	ret    

f01008de <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008de:	55                   	push   %ebp
f01008df:	89 e5                	mov    %esp,%ebp
f01008e1:	53                   	push   %ebx
f01008e2:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008e5:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008ec:	75 11                	jne    f01008ff <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ee:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f01008f3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008f9:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008ff:	8b 1d 38 65 11 f0    	mov    0xf0116538,%ebx
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
f0100905:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f010090c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100912:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f0100918:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010091e:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0100924:	c1 e1 0c             	shl    $0xc,%ecx
f0100927:	39 ca                	cmp    %ecx,%edx
f0100929:	76 14                	jbe    f010093f <boot_alloc+0x61>
		panic("Out of memory!\n");
f010092b:	83 ec 04             	sub    $0x4,%esp
f010092e:	68 e0 3b 10 f0       	push   $0xf0103be0
f0100933:	6a 68                	push   $0x68
f0100935:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010093a:	e8 4c f7 ff ff       	call   f010008b <_panic>
	return result;
}
f010093f:	89 d8                	mov    %ebx,%eax
f0100941:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100944:	c9                   	leave  
f0100945:	c3                   	ret    

f0100946 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100946:	89 d1                	mov    %edx,%ecx
f0100948:	c1 e9 16             	shr    $0x16,%ecx
f010094b:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010094e:	a8 01                	test   $0x1,%al
f0100950:	74 52                	je     f01009a4 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100952:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100957:	89 c1                	mov    %eax,%ecx
f0100959:	c1 e9 0c             	shr    $0xc,%ecx
f010095c:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0100962:	72 1b                	jb     f010097f <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
f0100967:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010096a:	50                   	push   %eax
f010096b:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0100970:	68 e5 02 00 00       	push   $0x2e5
f0100975:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010097a:	e8 0c f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010097f:	c1 ea 0c             	shr    $0xc,%edx
f0100982:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100988:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010098f:	89 c2                	mov    %eax,%edx
f0100991:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100994:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100999:	85 d2                	test   %edx,%edx
f010099b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009a0:	0f 44 c2             	cmove  %edx,%eax
f01009a3:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a9:	c3                   	ret    

f01009aa <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
f01009ad:	57                   	push   %edi
f01009ae:	56                   	push   %esi
f01009af:	53                   	push   %ebx
f01009b0:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009b3:	84 c0                	test   %al,%al
f01009b5:	0f 85 72 02 00 00    	jne    f0100c2d <check_page_free_list+0x283>
f01009bb:	e9 7f 02 00 00       	jmp    f0100c3f <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009c0:	83 ec 04             	sub    $0x4,%esp
f01009c3:	68 1c 3f 10 f0       	push   $0xf0103f1c
f01009c8:	68 28 02 00 00       	push   $0x228
f01009cd:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01009d2:	e8 b4 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009d7:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009da:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009dd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009e0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009e3:	89 c2                	mov    %eax,%edx
f01009e5:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01009eb:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009f1:	0f 95 c2             	setne  %dl
f01009f4:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009f7:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009fb:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009fd:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a01:	8b 00                	mov    (%eax),%eax
f0100a03:	85 c0                	test   %eax,%eax
f0100a05:	75 dc                	jne    f01009e3 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a0a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a10:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a13:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a16:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a18:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a1b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a20:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a25:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a2b:	eb 53                	jmp    f0100a80 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2d:	89 d8                	mov    %ebx,%eax
f0100a2f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100a35:	c1 f8 03             	sar    $0x3,%eax
f0100a38:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a3b:	89 c2                	mov    %eax,%edx
f0100a3d:	c1 ea 16             	shr    $0x16,%edx
f0100a40:	39 f2                	cmp    %esi,%edx
f0100a42:	73 3a                	jae    f0100a7e <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a44:	89 c2                	mov    %eax,%edx
f0100a46:	c1 ea 0c             	shr    $0xc,%edx
f0100a49:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a4f:	72 12                	jb     f0100a63 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a51:	50                   	push   %eax
f0100a52:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0100a57:	6a 52                	push   $0x52
f0100a59:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100a5e:	e8 28 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a63:	83 ec 04             	sub    $0x4,%esp
f0100a66:	68 80 00 00 00       	push   $0x80
f0100a6b:	68 97 00 00 00       	push   $0x97
f0100a70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a75:	50                   	push   %eax
f0100a76:	e8 ed 27 00 00       	call   f0103268 <memset>
f0100a7b:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a7e:	8b 1b                	mov    (%ebx),%ebx
f0100a80:	85 db                	test   %ebx,%ebx
f0100a82:	75 a9                	jne    f0100a2d <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a84:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a89:	e8 50 fe ff ff       	call   f01008de <boot_alloc>
f0100a8e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a91:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a97:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a9d:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100aa2:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100aa5:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aab:	be 00 00 00 00       	mov    $0x0,%esi
f0100ab0:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab3:	e9 30 01 00 00       	jmp    f0100be8 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab8:	39 ca                	cmp    %ecx,%edx
f0100aba:	73 19                	jae    f0100ad5 <check_page_free_list+0x12b>
f0100abc:	68 0a 3c 10 f0       	push   $0xf0103c0a
f0100ac1:	68 16 3c 10 f0       	push   $0xf0103c16
f0100ac6:	68 42 02 00 00       	push   $0x242
f0100acb:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100ad0:	e8 b6 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ad5:	39 fa                	cmp    %edi,%edx
f0100ad7:	72 19                	jb     f0100af2 <check_page_free_list+0x148>
f0100ad9:	68 2b 3c 10 f0       	push   $0xf0103c2b
f0100ade:	68 16 3c 10 f0       	push   $0xf0103c16
f0100ae3:	68 43 02 00 00       	push   $0x243
f0100ae8:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100aed:	e8 99 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100af2:	89 d0                	mov    %edx,%eax
f0100af4:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100af7:	a8 07                	test   $0x7,%al
f0100af9:	74 19                	je     f0100b14 <check_page_free_list+0x16a>
f0100afb:	68 40 3f 10 f0       	push   $0xf0103f40
f0100b00:	68 16 3c 10 f0       	push   $0xf0103c16
f0100b05:	68 44 02 00 00       	push   $0x244
f0100b0a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b0f:	e8 77 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b14:	c1 f8 03             	sar    $0x3,%eax
f0100b17:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b1a:	85 c0                	test   %eax,%eax
f0100b1c:	75 19                	jne    f0100b37 <check_page_free_list+0x18d>
f0100b1e:	68 3f 3c 10 f0       	push   $0xf0103c3f
f0100b23:	68 16 3c 10 f0       	push   $0xf0103c16
f0100b28:	68 47 02 00 00       	push   $0x247
f0100b2d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b32:	e8 54 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b37:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b3c:	75 19                	jne    f0100b57 <check_page_free_list+0x1ad>
f0100b3e:	68 50 3c 10 f0       	push   $0xf0103c50
f0100b43:	68 16 3c 10 f0       	push   $0xf0103c16
f0100b48:	68 48 02 00 00       	push   $0x248
f0100b4d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b52:	e8 34 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b57:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b5c:	75 19                	jne    f0100b77 <check_page_free_list+0x1cd>
f0100b5e:	68 74 3f 10 f0       	push   $0xf0103f74
f0100b63:	68 16 3c 10 f0       	push   $0xf0103c16
f0100b68:	68 49 02 00 00       	push   $0x249
f0100b6d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b72:	e8 14 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b77:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b7c:	75 19                	jne    f0100b97 <check_page_free_list+0x1ed>
f0100b7e:	68 69 3c 10 f0       	push   $0xf0103c69
f0100b83:	68 16 3c 10 f0       	push   $0xf0103c16
f0100b88:	68 4a 02 00 00       	push   $0x24a
f0100b8d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b92:	e8 f4 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b97:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b9c:	76 3f                	jbe    f0100bdd <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9e:	89 c3                	mov    %eax,%ebx
f0100ba0:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba3:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba6:	77 12                	ja     f0100bba <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba8:	50                   	push   %eax
f0100ba9:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0100bae:	6a 52                	push   $0x52
f0100bb0:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100bb5:	e8 d1 f4 ff ff       	call   f010008b <_panic>
f0100bba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bbf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bc2:	76 1e                	jbe    f0100be2 <check_page_free_list+0x238>
f0100bc4:	68 98 3f 10 f0       	push   $0xf0103f98
f0100bc9:	68 16 3c 10 f0       	push   $0xf0103c16
f0100bce:	68 4b 02 00 00       	push   $0x24b
f0100bd3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100bd8:	e8 ae f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bdd:	83 c6 01             	add    $0x1,%esi
f0100be0:	eb 04                	jmp    f0100be6 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100be2:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be6:	8b 12                	mov    (%edx),%edx
f0100be8:	85 d2                	test   %edx,%edx
f0100bea:	0f 85 c8 fe ff ff    	jne    f0100ab8 <check_page_free_list+0x10e>
f0100bf0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bf3:	85 f6                	test   %esi,%esi
f0100bf5:	7f 19                	jg     f0100c10 <check_page_free_list+0x266>
f0100bf7:	68 83 3c 10 f0       	push   $0xf0103c83
f0100bfc:	68 16 3c 10 f0       	push   $0xf0103c16
f0100c01:	68 53 02 00 00       	push   $0x253
f0100c06:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100c0b:	e8 7b f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c10:	85 db                	test   %ebx,%ebx
f0100c12:	7f 42                	jg     f0100c56 <check_page_free_list+0x2ac>
f0100c14:	68 95 3c 10 f0       	push   $0xf0103c95
f0100c19:	68 16 3c 10 f0       	push   $0xf0103c16
f0100c1e:	68 54 02 00 00       	push   $0x254
f0100c23:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100c28:	e8 5e f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c2d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c32:	85 c0                	test   %eax,%eax
f0100c34:	0f 85 9d fd ff ff    	jne    f01009d7 <check_page_free_list+0x2d>
f0100c3a:	e9 81 fd ff ff       	jmp    f01009c0 <check_page_free_list+0x16>
f0100c3f:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c46:	0f 84 74 fd ff ff    	je     f01009c0 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c4c:	be 00 04 00 00       	mov    $0x400,%esi
f0100c51:	e9 cf fd ff ff       	jmp    f0100a25 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c56:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c59:	5b                   	pop    %ebx
f0100c5a:	5e                   	pop    %esi
f0100c5b:	5f                   	pop    %edi
f0100c5c:	5d                   	pop    %ebp
f0100c5d:	c3                   	ret    

f0100c5e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c5e:	55                   	push   %ebp
f0100c5f:	89 e5                	mov    %esp,%ebp
f0100c61:	56                   	push   %esi
f0100c62:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100c63:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0100c6a:	00 00 00 

	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100c6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c72:	e8 67 fc ff ff       	call   f01008de <boot_alloc>
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	for(i=0; i<npages; i++)
f0100c77:	be 00 00 00 00       	mov    $0x0,%esi
f0100c7c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c81:	e9 9b 00 00 00       	jmp    f0100d21 <page_init+0xc3>
	{
		if(i==0){
f0100c86:	85 db                	test   %ebx,%ebx
f0100c88:	75 10                	jne    f0100c9a <page_init+0x3c>
			pages[i].pp_ref = 1;
f0100c8a:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c8f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0100c95:	e9 81 00 00 00       	jmp    f0100d1b <page_init+0xbd>
		} else if(1 <= i && i<npages_basemem){
f0100c9a:	3b 1d 40 65 11 f0    	cmp    0xf0116540,%ebx
f0100ca0:	73 25                	jae    f0100cc7 <page_init+0x69>
			pages[i].pp_ref = 0;
f0100ca2:	89 f0                	mov    %esi,%eax
f0100ca4:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100caa:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100cb0:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100cb6:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100cb8:	89 f0                	mov    %esi,%eax
f0100cba:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cc0:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
f0100cc5:	eb 54                	jmp    f0100d1b <page_init+0xbd>
		} else if(IOPHYSMEM/PGSIZE <= i && i < IOPHYSMEM/PGSIZE + ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE){
f0100cc7:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100ccd:	76 29                	jbe    f0100cf8 <page_init+0x9a>
f0100ccf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd4:	e8 05 fc ff ff       	call   f01008de <boot_alloc>
f0100cd9:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cde:	c1 e8 0c             	shr    $0xc,%eax
f0100ce1:	05 a0 00 00 00       	add    $0xa0,%eax
f0100ce6:	39 c3                	cmp    %eax,%ebx
f0100ce8:	73 0e                	jae    f0100cf8 <page_init+0x9a>
			pages[i].pp_ref = 1;
f0100cea:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100cef:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
f0100cf6:	eb 23                	jmp    f0100d1b <page_init+0xbd>
		} else {
			pages[i].pp_ref = 0;
f0100cf8:	89 f0                	mov    %esi,%eax
f0100cfa:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d00:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d06:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d0c:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d0e:	89 f0                	mov    %esi,%eax
f0100d10:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d16:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	for(i=0; i<npages; i++)
f0100d1b:	83 c3 01             	add    $0x1,%ebx
f0100d1e:	83 c6 08             	add    $0x8,%esi
f0100d21:	3b 1d 64 69 11 f0    	cmp    0xf0116964,%ebx
f0100d27:	0f 82 59 ff ff ff    	jb     f0100c86 <page_init+0x28>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d2d:	5b                   	pop    %ebx
f0100d2e:	5e                   	pop    %esi
f0100d2f:	5d                   	pop    %ebp
f0100d30:	c3                   	ret    

f0100d31 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d31:	55                   	push   %ebp
f0100d32:	89 e5                	mov    %esp,%ebp
f0100d34:	53                   	push   %ebx
f0100d35:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
    if (page_free_list == NULL)
f0100d38:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d3e:	85 db                	test   %ebx,%ebx
f0100d40:	74 58                	je     f0100d9a <page_alloc+0x69>
        return NULL;

      result= page_free_list;
      page_free_list = result->pp_link;
f0100d42:	8b 03                	mov    (%ebx),%eax
f0100d44:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
      result->pp_link = NULL;
f0100d49:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

    if (alloc_flags & ALLOC_ZERO)
f0100d4f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d53:	74 45                	je     f0100d9a <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d55:	89 d8                	mov    %ebx,%eax
f0100d57:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d5d:	c1 f8 03             	sar    $0x3,%eax
f0100d60:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d63:	89 c2                	mov    %eax,%edx
f0100d65:	c1 ea 0c             	shr    $0xc,%edx
f0100d68:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d6e:	72 12                	jb     f0100d82 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d70:	50                   	push   %eax
f0100d71:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0100d76:	6a 52                	push   $0x52
f0100d78:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100d7d:	e8 09 f3 ff ff       	call   f010008b <_panic>
        memset(page2kva(result), 0, PGSIZE); 
f0100d82:	83 ec 04             	sub    $0x4,%esp
f0100d85:	68 00 10 00 00       	push   $0x1000
f0100d8a:	6a 00                	push   $0x0
f0100d8c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d91:	50                   	push   %eax
f0100d92:	e8 d1 24 00 00       	call   f0103268 <memset>
f0100d97:	83 c4 10             	add    $0x10,%esp

      return result;
}
f0100d9a:	89 d8                	mov    %ebx,%eax
f0100d9c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d9f:	c9                   	leave  
f0100da0:	c3                   	ret    

f0100da1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100da1:	55                   	push   %ebp
f0100da2:	89 e5                	mov    %esp,%ebp
f0100da4:	83 ec 08             	sub    $0x8,%esp
f0100da7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0);
f0100daa:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100daf:	74 19                	je     f0100dca <page_free+0x29>
f0100db1:	68 a6 3c 10 f0       	push   $0xf0103ca6
f0100db6:	68 16 3c 10 f0       	push   $0xf0103c16
f0100dbb:	68 40 01 00 00       	push   $0x140
f0100dc0:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100dc5:	e8 c1 f2 ff ff       	call   f010008b <_panic>
      assert(pp->pp_link == NULL);
f0100dca:	83 38 00             	cmpl   $0x0,(%eax)
f0100dcd:	74 19                	je     f0100de8 <page_free+0x47>
f0100dcf:	68 b6 3c 10 f0       	push   $0xf0103cb6
f0100dd4:	68 16 3c 10 f0       	push   $0xf0103c16
f0100dd9:	68 41 01 00 00       	push   $0x141
f0100dde:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100de3:	e8 a3 f2 ff ff       	call   f010008b <_panic>

      pp->pp_link = page_free_list;
f0100de8:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100dee:	89 10                	mov    %edx,(%eax)
      page_free_list = pp;  
f0100df0:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100df5:	c9                   	leave  
f0100df6:	c3                   	ret    

f0100df7 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100df7:	55                   	push   %ebp
f0100df8:	89 e5                	mov    %esp,%ebp
f0100dfa:	83 ec 08             	sub    $0x8,%esp
f0100dfd:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e00:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e04:	83 e8 01             	sub    $0x1,%eax
f0100e07:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e0b:	66 85 c0             	test   %ax,%ax
f0100e0e:	75 0c                	jne    f0100e1c <page_decref+0x25>
		page_free(pp);
f0100e10:	83 ec 0c             	sub    $0xc,%esp
f0100e13:	52                   	push   %edx
f0100e14:	e8 88 ff ff ff       	call   f0100da1 <page_free>
f0100e19:	83 c4 10             	add    $0x10,%esp
}
f0100e1c:	c9                   	leave  
f0100e1d:	c3                   	ret    

f0100e1e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e1e:	55                   	push   %ebp
f0100e1f:	89 e5                	mov    %esp,%ebp
f0100e21:	56                   	push   %esi
f0100e22:	53                   	push   %ebx
f0100e23:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int page_off;
      pte_t * page_base = NULL;
      struct PageInfo* new_page = NULL;
      
      unsigned int dic_off = PDX(va);
      pde_t * dic_entry_ptr = pgdir + dic_off;
f0100e26:	89 f3                	mov    %esi,%ebx
f0100e28:	c1 eb 16             	shr    $0x16,%ebx
f0100e2b:	c1 e3 02             	shl    $0x2,%ebx
f0100e2e:	03 5d 08             	add    0x8(%ebp),%ebx

      if(!(*dic_entry_ptr & PTE_P))
f0100e31:	f6 03 01             	testb  $0x1,(%ebx)
f0100e34:	75 2d                	jne    f0100e63 <pgdir_walk+0x45>
      {
            if(create)
f0100e36:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e3a:	74 62                	je     f0100e9e <pgdir_walk+0x80>
            {
                   new_page = page_alloc(1);
f0100e3c:	83 ec 0c             	sub    $0xc,%esp
f0100e3f:	6a 01                	push   $0x1
f0100e41:	e8 eb fe ff ff       	call   f0100d31 <page_alloc>
                   if(new_page == NULL) return NULL;
f0100e46:	83 c4 10             	add    $0x10,%esp
f0100e49:	85 c0                	test   %eax,%eax
f0100e4b:	74 58                	je     f0100ea5 <pgdir_walk+0x87>
                   new_page->pp_ref++;
f0100e4d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
                   *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100e52:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100e58:	c1 f8 03             	sar    $0x3,%eax
f0100e5b:	c1 e0 0c             	shl    $0xc,%eax
f0100e5e:	83 c8 07             	or     $0x7,%eax
f0100e61:	89 03                	mov    %eax,(%ebx)
            }
           else
               return NULL;      
      }  
   
      page_off = PTX(va);
f0100e63:	c1 ee 0c             	shr    $0xc,%esi
f0100e66:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
      page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100e6c:	8b 03                	mov    (%ebx),%eax
f0100e6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e73:	89 c2                	mov    %eax,%edx
f0100e75:	c1 ea 0c             	shr    $0xc,%edx
f0100e78:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100e7e:	72 15                	jb     f0100e95 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e80:	50                   	push   %eax
f0100e81:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0100e86:	68 81 01 00 00       	push   $0x181
f0100e8b:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100e90:	e8 f6 f1 ff ff       	call   f010008b <_panic>
      return &page_base[page_off];
f0100e95:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e9c:	eb 0c                	jmp    f0100eaa <pgdir_walk+0x8c>
                   if(new_page == NULL) return NULL;
                   new_page->pp_ref++;
                   *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
            }
           else
               return NULL;      
f0100e9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea3:	eb 05                	jmp    f0100eaa <pgdir_walk+0x8c>
      if(!(*dic_entry_ptr & PTE_P))
      {
            if(create)
            {
                   new_page = page_alloc(1);
                   if(new_page == NULL) return NULL;
f0100ea5:	b8 00 00 00 00       	mov    $0x0,%eax
      }  
   
      page_off = PTX(va);
      page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
      return &page_base[page_off];
}
f0100eaa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ead:	5b                   	pop    %ebx
f0100eae:	5e                   	pop    %esi
f0100eaf:	5d                   	pop    %ebp
f0100eb0:	c3                   	ret    

f0100eb1 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100eb1:	55                   	push   %ebp
f0100eb2:	89 e5                	mov    %esp,%ebp
f0100eb4:	57                   	push   %edi
f0100eb5:	56                   	push   %esi
f0100eb6:	53                   	push   %ebx
f0100eb7:	83 ec 1c             	sub    $0x1c,%esp
f0100eba:	89 c7                	mov    %eax,%edi
f0100ebc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ebf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ec2:	bb 00 00 00 00       	mov    $0x0,%ebx
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
        *entry = (pa | perm | PTE_P);
f0100ec7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eca:	83 c8 01             	or     $0x1,%eax
f0100ecd:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ed0:	eb 1f                	jmp    f0100ef1 <boot_map_region+0x40>
    {
        entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f0100ed2:	83 ec 04             	sub    $0x4,%esp
f0100ed5:	6a 01                	push   $0x1
f0100ed7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eda:	01 d8                	add    %ebx,%eax
f0100edc:	50                   	push   %eax
f0100edd:	57                   	push   %edi
f0100ede:	e8 3b ff ff ff       	call   f0100e1e <pgdir_walk>
        *entry = (pa | perm | PTE_P);
f0100ee3:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100ee6:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
    pte_t *entry = NULL;
    for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ee8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100eee:	83 c4 10             	add    $0x10,%esp
f0100ef1:	89 de                	mov    %ebx,%esi
f0100ef3:	03 75 08             	add    0x8(%ebp),%esi
f0100ef6:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100ef9:	77 d7                	ja     f0100ed2 <boot_map_region+0x21>
        
        pa += PGSIZE;
        va += PGSIZE;
        
    } 
}
f0100efb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100efe:	5b                   	pop    %ebx
f0100eff:	5e                   	pop    %esi
f0100f00:	5f                   	pop    %edi
f0100f01:	5d                   	pop    %ebp
f0100f02:	c3                   	ret    

f0100f03 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f03:	55                   	push   %ebp
f0100f04:	89 e5                	mov    %esp,%ebp
f0100f06:	53                   	push   %ebx
f0100f07:	83 ec 08             	sub    $0x8,%esp
f0100f0a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
    struct PageInfo *ret = NULL;

    entry = pgdir_walk(pgdir, va, 0);
f0100f0d:	6a 00                	push   $0x0
f0100f0f:	ff 75 0c             	pushl  0xc(%ebp)
f0100f12:	ff 75 08             	pushl  0x8(%ebp)
f0100f15:	e8 04 ff ff ff       	call   f0100e1e <pgdir_walk>
    if(entry == NULL)
f0100f1a:	83 c4 10             	add    $0x10,%esp
f0100f1d:	85 c0                	test   %eax,%eax
f0100f1f:	74 38                	je     f0100f59 <page_lookup+0x56>
f0100f21:	89 c1                	mov    %eax,%ecx
        return NULL;
    if(!(*entry & PTE_P))
f0100f23:	8b 10                	mov    (%eax),%edx
f0100f25:	f6 c2 01             	test   $0x1,%dl
f0100f28:	74 36                	je     f0100f60 <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f2a:	c1 ea 0c             	shr    $0xc,%edx
f0100f2d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100f33:	72 14                	jb     f0100f49 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100f35:	83 ec 04             	sub    $0x4,%esp
f0100f38:	68 e0 3f 10 f0       	push   $0xf0103fe0
f0100f3d:	6a 4b                	push   $0x4b
f0100f3f:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100f44:	e8 42 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f49:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100f4e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        return NULL;
    
    ret = pa2page(PTE_ADDR(*entry));
    if(pte_store != NULL)
f0100f51:	85 db                	test   %ebx,%ebx
f0100f53:	74 10                	je     f0100f65 <page_lookup+0x62>
    {
        *pte_store = entry;
f0100f55:	89 0b                	mov    %ecx,(%ebx)
f0100f57:	eb 0c                	jmp    f0100f65 <page_lookup+0x62>
	pte_t *entry = NULL;
    struct PageInfo *ret = NULL;

    entry = pgdir_walk(pgdir, va, 0);
    if(entry == NULL)
        return NULL;
f0100f59:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5e:	eb 05                	jmp    f0100f65 <page_lookup+0x62>
    if(!(*entry & PTE_P))
        return NULL;
f0100f60:	b8 00 00 00 00       	mov    $0x0,%eax
    if(pte_store != NULL)
    {
        *pte_store = entry;
    }
    return ret;
}
f0100f65:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f68:	c9                   	leave  
f0100f69:	c3                   	ret    

f0100f6a <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f6a:	55                   	push   %ebp
f0100f6b:	89 e5                	mov    %esp,%ebp
f0100f6d:	53                   	push   %ebx
f0100f6e:	83 ec 18             	sub    $0x18,%esp
f0100f71:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function inpte_t* pte;  
	pte_t *pte = NULL;
f0100f74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0100f7b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f7e:	50                   	push   %eax
f0100f7f:	53                   	push   %ebx
f0100f80:	ff 75 08             	pushl  0x8(%ebp)
f0100f83:	e8 7b ff ff ff       	call   f0100f03 <page_lookup>
    if(page == NULL) return ;    
f0100f88:	83 c4 10             	add    $0x10,%esp
f0100f8b:	85 c0                	test   %eax,%eax
f0100f8d:	74 18                	je     f0100fa7 <page_remove+0x3d>
    
    page_decref(page);
f0100f8f:	83 ec 0c             	sub    $0xc,%esp
f0100f92:	50                   	push   %eax
f0100f93:	e8 5f fe ff ff       	call   f0100df7 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f98:	0f 01 3b             	invlpg (%ebx)
    tlb_invalidate(pgdir, va);
    *pte = 0;
f0100f9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f9e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fa4:	83 c4 10             	add    $0x10,%esp
}
f0100fa7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100faa:	c9                   	leave  
f0100fab:	c3                   	ret    

f0100fac <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fac:	55                   	push   %ebp
f0100fad:	89 e5                	mov    %esp,%ebp
f0100faf:	57                   	push   %edi
f0100fb0:	56                   	push   %esi
f0100fb1:	53                   	push   %ebx
f0100fb2:	83 ec 10             	sub    $0x10,%esp
f0100fb5:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fb8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
    entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
f0100fbb:	6a 01                	push   $0x1
f0100fbd:	ff 75 10             	pushl  0x10(%ebp)
f0100fc0:	56                   	push   %esi
f0100fc1:	e8 58 fe ff ff       	call   f0100e1e <pgdir_walk>
    if(entry == NULL) return -E_NO_MEM;
f0100fc6:	83 c4 10             	add    $0x10,%esp
f0100fc9:	85 c0                	test   %eax,%eax
f0100fcb:	74 4a                	je     f0101017 <page_insert+0x6b>
f0100fcd:	89 c7                	mov    %eax,%edi

    pp->pp_ref++;
f0100fcf:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    if((*entry) & PTE_P)             //If this virtual address is already mapped.
f0100fd4:	f6 00 01             	testb  $0x1,(%eax)
f0100fd7:	74 15                	je     f0100fee <page_insert+0x42>
f0100fd9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fdc:	0f 01 38             	invlpg (%eax)
    {
        tlb_invalidate(pgdir, va);
        page_remove(pgdir, va);
f0100fdf:	83 ec 08             	sub    $0x8,%esp
f0100fe2:	ff 75 10             	pushl  0x10(%ebp)
f0100fe5:	56                   	push   %esi
f0100fe6:	e8 7f ff ff ff       	call   f0100f6a <page_remove>
f0100feb:	83 c4 10             	add    $0x10,%esp
    }
    *entry = (page2pa(pp) | perm | PTE_P);
f0100fee:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100ff4:	c1 fb 03             	sar    $0x3,%ebx
f0100ff7:	c1 e3 0c             	shl    $0xc,%ebx
f0100ffa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffd:	83 c8 01             	or     $0x1,%eax
f0101000:	09 c3                	or     %eax,%ebx
f0101002:	89 1f                	mov    %ebx,(%edi)
    pgdir[PDX(va)] |= perm;                  //Remember this step!
f0101004:	8b 45 10             	mov    0x10(%ebp),%eax
f0101007:	c1 e8 16             	shr    $0x16,%eax
f010100a:	8b 55 14             	mov    0x14(%ebp),%edx
f010100d:	09 14 86             	or     %edx,(%esi,%eax,4)
        
    return 0;
f0101010:	b8 00 00 00 00       	mov    $0x0,%eax
f0101015:	eb 05                	jmp    f010101c <page_insert+0x70>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *entry = NULL;
    entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
    if(entry == NULL) return -E_NO_MEM;
f0101017:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *entry = (page2pa(pp) | perm | PTE_P);
    pgdir[PDX(va)] |= perm;                  //Remember this step!
        
    return 0;
}
f010101c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010101f:	5b                   	pop    %ebx
f0101020:	5e                   	pop    %esi
f0101021:	5f                   	pop    %edi
f0101022:	5d                   	pop    %ebp
f0101023:	c3                   	ret    

f0101024 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101024:	55                   	push   %ebp
f0101025:	89 e5                	mov    %esp,%ebp
f0101027:	57                   	push   %edi
f0101028:	56                   	push   %esi
f0101029:	53                   	push   %ebx
f010102a:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010102d:	6a 15                	push   $0x15
f010102f:	e8 82 16 00 00       	call   f01026b6 <mc146818_read>
f0101034:	89 c3                	mov    %eax,%ebx
f0101036:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010103d:	e8 74 16 00 00       	call   f01026b6 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101042:	c1 e0 08             	shl    $0x8,%eax
f0101045:	09 d8                	or     %ebx,%eax
f0101047:	c1 e0 0a             	shl    $0xa,%eax
f010104a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101050:	85 c0                	test   %eax,%eax
f0101052:	0f 48 c2             	cmovs  %edx,%eax
f0101055:	c1 f8 0c             	sar    $0xc,%eax
f0101058:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010105d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101064:	e8 4d 16 00 00       	call   f01026b6 <mc146818_read>
f0101069:	89 c3                	mov    %eax,%ebx
f010106b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101072:	e8 3f 16 00 00       	call   f01026b6 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101077:	c1 e0 08             	shl    $0x8,%eax
f010107a:	09 d8                	or     %ebx,%eax
f010107c:	c1 e0 0a             	shl    $0xa,%eax
f010107f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101085:	83 c4 10             	add    $0x10,%esp
f0101088:	85 c0                	test   %eax,%eax
f010108a:	0f 48 c2             	cmovs  %edx,%eax
f010108d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101090:	85 c0                	test   %eax,%eax
f0101092:	74 0e                	je     f01010a2 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101094:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010109a:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f01010a0:	eb 0c                	jmp    f01010ae <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010a2:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f01010a8:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010ae:	c1 e0 0c             	shl    $0xc,%eax
f01010b1:	c1 e8 0a             	shr    $0xa,%eax
f01010b4:	50                   	push   %eax
f01010b5:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f01010ba:	c1 e0 0c             	shl    $0xc,%eax
f01010bd:	c1 e8 0a             	shr    $0xa,%eax
f01010c0:	50                   	push   %eax
f01010c1:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01010c6:	c1 e0 0c             	shl    $0xc,%eax
f01010c9:	c1 e8 0a             	shr    $0xa,%eax
f01010cc:	50                   	push   %eax
f01010cd:	68 00 40 10 f0       	push   $0xf0104000
f01010d2:	e8 46 16 00 00       	call   f010271d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010d7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010dc:	e8 fd f7 ff ff       	call   f01008de <boot_alloc>
f01010e1:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010e6:	83 c4 0c             	add    $0xc,%esp
f01010e9:	68 00 10 00 00       	push   $0x1000
f01010ee:	6a 00                	push   $0x0
f01010f0:	50                   	push   %eax
f01010f1:	e8 72 21 00 00       	call   f0103268 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010f6:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010fb:	83 c4 10             	add    $0x10,%esp
f01010fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101103:	77 15                	ja     f010111a <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101105:	50                   	push   %eax
f0101106:	68 3c 40 10 f0       	push   $0xf010403c
f010110b:	68 8d 00 00 00       	push   $0x8d
f0101110:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101115:	e8 71 ef ff ff       	call   f010008b <_panic>
f010111a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101120:	83 ca 05             	or     $0x5,%edx
f0101123:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo*) boot_alloc(npages*sizeof(struct PageInfo));
f0101129:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010112e:	c1 e0 03             	shl    $0x3,%eax
f0101131:	e8 a8 f7 ff ff       	call   f01008de <boot_alloc>
f0101136:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010113b:	83 ec 04             	sub    $0x4,%esp
f010113e:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101144:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010114b:	52                   	push   %edx
f010114c:	6a 00                	push   $0x0
f010114e:	50                   	push   %eax
f010114f:	e8 14 21 00 00       	call   f0103268 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101154:	e8 05 fb ff ff       	call   f0100c5e <page_init>

	check_page_free_list(1);
f0101159:	b8 01 00 00 00       	mov    $0x1,%eax
f010115e:	e8 47 f8 ff ff       	call   f01009aa <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101163:	83 c4 10             	add    $0x10,%esp
f0101166:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f010116d:	75 17                	jne    f0101186 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f010116f:	83 ec 04             	sub    $0x4,%esp
f0101172:	68 ca 3c 10 f0       	push   $0xf0103cca
f0101177:	68 65 02 00 00       	push   $0x265
f010117c:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101181:	e8 05 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101186:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010118b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101190:	eb 05                	jmp    f0101197 <mem_init+0x173>
		++nfree;
f0101192:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101195:	8b 00                	mov    (%eax),%eax
f0101197:	85 c0                	test   %eax,%eax
f0101199:	75 f7                	jne    f0101192 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010119b:	83 ec 0c             	sub    $0xc,%esp
f010119e:	6a 00                	push   $0x0
f01011a0:	e8 8c fb ff ff       	call   f0100d31 <page_alloc>
f01011a5:	89 c7                	mov    %eax,%edi
f01011a7:	83 c4 10             	add    $0x10,%esp
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	75 19                	jne    f01011c7 <mem_init+0x1a3>
f01011ae:	68 e5 3c 10 f0       	push   $0xf0103ce5
f01011b3:	68 16 3c 10 f0       	push   $0xf0103c16
f01011b8:	68 6d 02 00 00       	push   $0x26d
f01011bd:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01011c2:	e8 c4 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011c7:	83 ec 0c             	sub    $0xc,%esp
f01011ca:	6a 00                	push   $0x0
f01011cc:	e8 60 fb ff ff       	call   f0100d31 <page_alloc>
f01011d1:	89 c6                	mov    %eax,%esi
f01011d3:	83 c4 10             	add    $0x10,%esp
f01011d6:	85 c0                	test   %eax,%eax
f01011d8:	75 19                	jne    f01011f3 <mem_init+0x1cf>
f01011da:	68 fb 3c 10 f0       	push   $0xf0103cfb
f01011df:	68 16 3c 10 f0       	push   $0xf0103c16
f01011e4:	68 6e 02 00 00       	push   $0x26e
f01011e9:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01011ee:	e8 98 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011f3:	83 ec 0c             	sub    $0xc,%esp
f01011f6:	6a 00                	push   $0x0
f01011f8:	e8 34 fb ff ff       	call   f0100d31 <page_alloc>
f01011fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101200:	83 c4 10             	add    $0x10,%esp
f0101203:	85 c0                	test   %eax,%eax
f0101205:	75 19                	jne    f0101220 <mem_init+0x1fc>
f0101207:	68 11 3d 10 f0       	push   $0xf0103d11
f010120c:	68 16 3c 10 f0       	push   $0xf0103c16
f0101211:	68 6f 02 00 00       	push   $0x26f
f0101216:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010121b:	e8 6b ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101220:	39 f7                	cmp    %esi,%edi
f0101222:	75 19                	jne    f010123d <mem_init+0x219>
f0101224:	68 27 3d 10 f0       	push   $0xf0103d27
f0101229:	68 16 3c 10 f0       	push   $0xf0103c16
f010122e:	68 72 02 00 00       	push   $0x272
f0101233:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101238:	e8 4e ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010123d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101240:	39 c6                	cmp    %eax,%esi
f0101242:	74 04                	je     f0101248 <mem_init+0x224>
f0101244:	39 c7                	cmp    %eax,%edi
f0101246:	75 19                	jne    f0101261 <mem_init+0x23d>
f0101248:	68 60 40 10 f0       	push   $0xf0104060
f010124d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101252:	68 73 02 00 00       	push   $0x273
f0101257:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010125c:	e8 2a ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101261:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101267:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f010126d:	c1 e2 0c             	shl    $0xc,%edx
f0101270:	89 f8                	mov    %edi,%eax
f0101272:	29 c8                	sub    %ecx,%eax
f0101274:	c1 f8 03             	sar    $0x3,%eax
f0101277:	c1 e0 0c             	shl    $0xc,%eax
f010127a:	39 d0                	cmp    %edx,%eax
f010127c:	72 19                	jb     f0101297 <mem_init+0x273>
f010127e:	68 39 3d 10 f0       	push   $0xf0103d39
f0101283:	68 16 3c 10 f0       	push   $0xf0103c16
f0101288:	68 74 02 00 00       	push   $0x274
f010128d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101297:	89 f0                	mov    %esi,%eax
f0101299:	29 c8                	sub    %ecx,%eax
f010129b:	c1 f8 03             	sar    $0x3,%eax
f010129e:	c1 e0 0c             	shl    $0xc,%eax
f01012a1:	39 c2                	cmp    %eax,%edx
f01012a3:	77 19                	ja     f01012be <mem_init+0x29a>
f01012a5:	68 56 3d 10 f0       	push   $0xf0103d56
f01012aa:	68 16 3c 10 f0       	push   $0xf0103c16
f01012af:	68 75 02 00 00       	push   $0x275
f01012b4:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01012b9:	e8 cd ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012c1:	29 c8                	sub    %ecx,%eax
f01012c3:	c1 f8 03             	sar    $0x3,%eax
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
f01012c9:	39 c2                	cmp    %eax,%edx
f01012cb:	77 19                	ja     f01012e6 <mem_init+0x2c2>
f01012cd:	68 73 3d 10 f0       	push   $0xf0103d73
f01012d2:	68 16 3c 10 f0       	push   $0xf0103c16
f01012d7:	68 76 02 00 00       	push   $0x276
f01012dc:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01012e1:	e8 a5 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012e6:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012ee:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012f5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012f8:	83 ec 0c             	sub    $0xc,%esp
f01012fb:	6a 00                	push   $0x0
f01012fd:	e8 2f fa ff ff       	call   f0100d31 <page_alloc>
f0101302:	83 c4 10             	add    $0x10,%esp
f0101305:	85 c0                	test   %eax,%eax
f0101307:	74 19                	je     f0101322 <mem_init+0x2fe>
f0101309:	68 90 3d 10 f0       	push   $0xf0103d90
f010130e:	68 16 3c 10 f0       	push   $0xf0103c16
f0101313:	68 7d 02 00 00       	push   $0x27d
f0101318:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010131d:	e8 69 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101322:	83 ec 0c             	sub    $0xc,%esp
f0101325:	57                   	push   %edi
f0101326:	e8 76 fa ff ff       	call   f0100da1 <page_free>
	page_free(pp1);
f010132b:	89 34 24             	mov    %esi,(%esp)
f010132e:	e8 6e fa ff ff       	call   f0100da1 <page_free>
	page_free(pp2);
f0101333:	83 c4 04             	add    $0x4,%esp
f0101336:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101339:	e8 63 fa ff ff       	call   f0100da1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101345:	e8 e7 f9 ff ff       	call   f0100d31 <page_alloc>
f010134a:	89 c6                	mov    %eax,%esi
f010134c:	83 c4 10             	add    $0x10,%esp
f010134f:	85 c0                	test   %eax,%eax
f0101351:	75 19                	jne    f010136c <mem_init+0x348>
f0101353:	68 e5 3c 10 f0       	push   $0xf0103ce5
f0101358:	68 16 3c 10 f0       	push   $0xf0103c16
f010135d:	68 84 02 00 00       	push   $0x284
f0101362:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101367:	e8 1f ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010136c:	83 ec 0c             	sub    $0xc,%esp
f010136f:	6a 00                	push   $0x0
f0101371:	e8 bb f9 ff ff       	call   f0100d31 <page_alloc>
f0101376:	89 c7                	mov    %eax,%edi
f0101378:	83 c4 10             	add    $0x10,%esp
f010137b:	85 c0                	test   %eax,%eax
f010137d:	75 19                	jne    f0101398 <mem_init+0x374>
f010137f:	68 fb 3c 10 f0       	push   $0xf0103cfb
f0101384:	68 16 3c 10 f0       	push   $0xf0103c16
f0101389:	68 85 02 00 00       	push   $0x285
f010138e:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101393:	e8 f3 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101398:	83 ec 0c             	sub    $0xc,%esp
f010139b:	6a 00                	push   $0x0
f010139d:	e8 8f f9 ff ff       	call   f0100d31 <page_alloc>
f01013a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013a5:	83 c4 10             	add    $0x10,%esp
f01013a8:	85 c0                	test   %eax,%eax
f01013aa:	75 19                	jne    f01013c5 <mem_init+0x3a1>
f01013ac:	68 11 3d 10 f0       	push   $0xf0103d11
f01013b1:	68 16 3c 10 f0       	push   $0xf0103c16
f01013b6:	68 86 02 00 00       	push   $0x286
f01013bb:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01013c0:	e8 c6 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c5:	39 fe                	cmp    %edi,%esi
f01013c7:	75 19                	jne    f01013e2 <mem_init+0x3be>
f01013c9:	68 27 3d 10 f0       	push   $0xf0103d27
f01013ce:	68 16 3c 10 f0       	push   $0xf0103c16
f01013d3:	68 88 02 00 00       	push   $0x288
f01013d8:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01013dd:	e8 a9 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013e5:	39 c7                	cmp    %eax,%edi
f01013e7:	74 04                	je     f01013ed <mem_init+0x3c9>
f01013e9:	39 c6                	cmp    %eax,%esi
f01013eb:	75 19                	jne    f0101406 <mem_init+0x3e2>
f01013ed:	68 60 40 10 f0       	push   $0xf0104060
f01013f2:	68 16 3c 10 f0       	push   $0xf0103c16
f01013f7:	68 89 02 00 00       	push   $0x289
f01013fc:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101401:	e8 85 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101406:	83 ec 0c             	sub    $0xc,%esp
f0101409:	6a 00                	push   $0x0
f010140b:	e8 21 f9 ff ff       	call   f0100d31 <page_alloc>
f0101410:	83 c4 10             	add    $0x10,%esp
f0101413:	85 c0                	test   %eax,%eax
f0101415:	74 19                	je     f0101430 <mem_init+0x40c>
f0101417:	68 90 3d 10 f0       	push   $0xf0103d90
f010141c:	68 16 3c 10 f0       	push   $0xf0103c16
f0101421:	68 8a 02 00 00       	push   $0x28a
f0101426:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010142b:	e8 5b ec ff ff       	call   f010008b <_panic>
f0101430:	89 f0                	mov    %esi,%eax
f0101432:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101438:	c1 f8 03             	sar    $0x3,%eax
f010143b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010143e:	89 c2                	mov    %eax,%edx
f0101440:	c1 ea 0c             	shr    $0xc,%edx
f0101443:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101449:	72 12                	jb     f010145d <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010144b:	50                   	push   %eax
f010144c:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101451:	6a 52                	push   $0x52
f0101453:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0101458:	e8 2e ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010145d:	83 ec 04             	sub    $0x4,%esp
f0101460:	68 00 10 00 00       	push   $0x1000
f0101465:	6a 01                	push   $0x1
f0101467:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010146c:	50                   	push   %eax
f010146d:	e8 f6 1d 00 00       	call   f0103268 <memset>
	page_free(pp0);
f0101472:	89 34 24             	mov    %esi,(%esp)
f0101475:	e8 27 f9 ff ff       	call   f0100da1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010147a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101481:	e8 ab f8 ff ff       	call   f0100d31 <page_alloc>
f0101486:	83 c4 10             	add    $0x10,%esp
f0101489:	85 c0                	test   %eax,%eax
f010148b:	75 19                	jne    f01014a6 <mem_init+0x482>
f010148d:	68 9f 3d 10 f0       	push   $0xf0103d9f
f0101492:	68 16 3c 10 f0       	push   $0xf0103c16
f0101497:	68 8f 02 00 00       	push   $0x28f
f010149c:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01014a1:	e8 e5 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014a6:	39 c6                	cmp    %eax,%esi
f01014a8:	74 19                	je     f01014c3 <mem_init+0x49f>
f01014aa:	68 bd 3d 10 f0       	push   $0xf0103dbd
f01014af:	68 16 3c 10 f0       	push   $0xf0103c16
f01014b4:	68 90 02 00 00       	push   $0x290
f01014b9:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01014be:	e8 c8 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c3:	89 f0                	mov    %esi,%eax
f01014c5:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014cb:	c1 f8 03             	sar    $0x3,%eax
f01014ce:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014d1:	89 c2                	mov    %eax,%edx
f01014d3:	c1 ea 0c             	shr    $0xc,%edx
f01014d6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014dc:	72 12                	jb     f01014f0 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014de:	50                   	push   %eax
f01014df:	68 f8 3e 10 f0       	push   $0xf0103ef8
f01014e4:	6a 52                	push   $0x52
f01014e6:	68 fc 3b 10 f0       	push   $0xf0103bfc
f01014eb:	e8 9b eb ff ff       	call   f010008b <_panic>
f01014f0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014f6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014fc:	80 38 00             	cmpb   $0x0,(%eax)
f01014ff:	74 19                	je     f010151a <mem_init+0x4f6>
f0101501:	68 cd 3d 10 f0       	push   $0xf0103dcd
f0101506:	68 16 3c 10 f0       	push   $0xf0103c16
f010150b:	68 93 02 00 00       	push   $0x293
f0101510:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101515:	e8 71 eb ff ff       	call   f010008b <_panic>
f010151a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010151d:	39 d0                	cmp    %edx,%eax
f010151f:	75 db                	jne    f01014fc <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101521:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101524:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101529:	83 ec 0c             	sub    $0xc,%esp
f010152c:	56                   	push   %esi
f010152d:	e8 6f f8 ff ff       	call   f0100da1 <page_free>
	page_free(pp1);
f0101532:	89 3c 24             	mov    %edi,(%esp)
f0101535:	e8 67 f8 ff ff       	call   f0100da1 <page_free>
	page_free(pp2);
f010153a:	83 c4 04             	add    $0x4,%esp
f010153d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101540:	e8 5c f8 ff ff       	call   f0100da1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101545:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010154a:	83 c4 10             	add    $0x10,%esp
f010154d:	eb 05                	jmp    f0101554 <mem_init+0x530>
		--nfree;
f010154f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101552:	8b 00                	mov    (%eax),%eax
f0101554:	85 c0                	test   %eax,%eax
f0101556:	75 f7                	jne    f010154f <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101558:	85 db                	test   %ebx,%ebx
f010155a:	74 19                	je     f0101575 <mem_init+0x551>
f010155c:	68 d7 3d 10 f0       	push   $0xf0103dd7
f0101561:	68 16 3c 10 f0       	push   $0xf0103c16
f0101566:	68 a0 02 00 00       	push   $0x2a0
f010156b:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101570:	e8 16 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101575:	83 ec 0c             	sub    $0xc,%esp
f0101578:	68 80 40 10 f0       	push   $0xf0104080
f010157d:	e8 9b 11 00 00       	call   f010271d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101582:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101589:	e8 a3 f7 ff ff       	call   f0100d31 <page_alloc>
f010158e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101591:	83 c4 10             	add    $0x10,%esp
f0101594:	85 c0                	test   %eax,%eax
f0101596:	75 19                	jne    f01015b1 <mem_init+0x58d>
f0101598:	68 e5 3c 10 f0       	push   $0xf0103ce5
f010159d:	68 16 3c 10 f0       	push   $0xf0103c16
f01015a2:	68 f9 02 00 00       	push   $0x2f9
f01015a7:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01015ac:	e8 da ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015b1:	83 ec 0c             	sub    $0xc,%esp
f01015b4:	6a 00                	push   $0x0
f01015b6:	e8 76 f7 ff ff       	call   f0100d31 <page_alloc>
f01015bb:	89 c3                	mov    %eax,%ebx
f01015bd:	83 c4 10             	add    $0x10,%esp
f01015c0:	85 c0                	test   %eax,%eax
f01015c2:	75 19                	jne    f01015dd <mem_init+0x5b9>
f01015c4:	68 fb 3c 10 f0       	push   $0xf0103cfb
f01015c9:	68 16 3c 10 f0       	push   $0xf0103c16
f01015ce:	68 fa 02 00 00       	push   $0x2fa
f01015d3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01015d8:	e8 ae ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015dd:	83 ec 0c             	sub    $0xc,%esp
f01015e0:	6a 00                	push   $0x0
f01015e2:	e8 4a f7 ff ff       	call   f0100d31 <page_alloc>
f01015e7:	89 c6                	mov    %eax,%esi
f01015e9:	83 c4 10             	add    $0x10,%esp
f01015ec:	85 c0                	test   %eax,%eax
f01015ee:	75 19                	jne    f0101609 <mem_init+0x5e5>
f01015f0:	68 11 3d 10 f0       	push   $0xf0103d11
f01015f5:	68 16 3c 10 f0       	push   $0xf0103c16
f01015fa:	68 fb 02 00 00       	push   $0x2fb
f01015ff:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101604:	e8 82 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101609:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010160c:	75 19                	jne    f0101627 <mem_init+0x603>
f010160e:	68 27 3d 10 f0       	push   $0xf0103d27
f0101613:	68 16 3c 10 f0       	push   $0xf0103c16
f0101618:	68 fe 02 00 00       	push   $0x2fe
f010161d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101622:	e8 64 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101627:	39 c3                	cmp    %eax,%ebx
f0101629:	74 05                	je     f0101630 <mem_init+0x60c>
f010162b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010162e:	75 19                	jne    f0101649 <mem_init+0x625>
f0101630:	68 60 40 10 f0       	push   $0xf0104060
f0101635:	68 16 3c 10 f0       	push   $0xf0103c16
f010163a:	68 ff 02 00 00       	push   $0x2ff
f010163f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101644:	e8 42 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101649:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010164e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101651:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101658:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010165b:	83 ec 0c             	sub    $0xc,%esp
f010165e:	6a 00                	push   $0x0
f0101660:	e8 cc f6 ff ff       	call   f0100d31 <page_alloc>
f0101665:	83 c4 10             	add    $0x10,%esp
f0101668:	85 c0                	test   %eax,%eax
f010166a:	74 19                	je     f0101685 <mem_init+0x661>
f010166c:	68 90 3d 10 f0       	push   $0xf0103d90
f0101671:	68 16 3c 10 f0       	push   $0xf0103c16
f0101676:	68 06 03 00 00       	push   $0x306
f010167b:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101680:	e8 06 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101685:	83 ec 04             	sub    $0x4,%esp
f0101688:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010168b:	50                   	push   %eax
f010168c:	6a 00                	push   $0x0
f010168e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101694:	e8 6a f8 ff ff       	call   f0100f03 <page_lookup>
f0101699:	83 c4 10             	add    $0x10,%esp
f010169c:	85 c0                	test   %eax,%eax
f010169e:	74 19                	je     f01016b9 <mem_init+0x695>
f01016a0:	68 a0 40 10 f0       	push   $0xf01040a0
f01016a5:	68 16 3c 10 f0       	push   $0xf0103c16
f01016aa:	68 09 03 00 00       	push   $0x309
f01016af:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01016b4:	e8 d2 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016b9:	6a 02                	push   $0x2
f01016bb:	6a 00                	push   $0x0
f01016bd:	53                   	push   %ebx
f01016be:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016c4:	e8 e3 f8 ff ff       	call   f0100fac <page_insert>
f01016c9:	83 c4 10             	add    $0x10,%esp
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	78 19                	js     f01016e9 <mem_init+0x6c5>
f01016d0:	68 d8 40 10 f0       	push   $0xf01040d8
f01016d5:	68 16 3c 10 f0       	push   $0xf0103c16
f01016da:	68 0c 03 00 00       	push   $0x30c
f01016df:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01016e4:	e8 a2 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016e9:	83 ec 0c             	sub    $0xc,%esp
f01016ec:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016ef:	e8 ad f6 ff ff       	call   f0100da1 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016f4:	6a 02                	push   $0x2
f01016f6:	6a 00                	push   $0x0
f01016f8:	53                   	push   %ebx
f01016f9:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016ff:	e8 a8 f8 ff ff       	call   f0100fac <page_insert>
f0101704:	83 c4 20             	add    $0x20,%esp
f0101707:	85 c0                	test   %eax,%eax
f0101709:	74 19                	je     f0101724 <mem_init+0x700>
f010170b:	68 08 41 10 f0       	push   $0xf0104108
f0101710:	68 16 3c 10 f0       	push   $0xf0103c16
f0101715:	68 10 03 00 00       	push   $0x310
f010171a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010171f:	e8 67 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101724:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010172a:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010172f:	89 c1                	mov    %eax,%ecx
f0101731:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101734:	8b 17                	mov    (%edi),%edx
f0101736:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010173c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010173f:	29 c8                	sub    %ecx,%eax
f0101741:	c1 f8 03             	sar    $0x3,%eax
f0101744:	c1 e0 0c             	shl    $0xc,%eax
f0101747:	39 c2                	cmp    %eax,%edx
f0101749:	74 19                	je     f0101764 <mem_init+0x740>
f010174b:	68 38 41 10 f0       	push   $0xf0104138
f0101750:	68 16 3c 10 f0       	push   $0xf0103c16
f0101755:	68 11 03 00 00       	push   $0x311
f010175a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010175f:	e8 27 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101764:	ba 00 00 00 00       	mov    $0x0,%edx
f0101769:	89 f8                	mov    %edi,%eax
f010176b:	e8 d6 f1 ff ff       	call   f0100946 <check_va2pa>
f0101770:	89 da                	mov    %ebx,%edx
f0101772:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101775:	c1 fa 03             	sar    $0x3,%edx
f0101778:	c1 e2 0c             	shl    $0xc,%edx
f010177b:	39 d0                	cmp    %edx,%eax
f010177d:	74 19                	je     f0101798 <mem_init+0x774>
f010177f:	68 60 41 10 f0       	push   $0xf0104160
f0101784:	68 16 3c 10 f0       	push   $0xf0103c16
f0101789:	68 12 03 00 00       	push   $0x312
f010178e:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101793:	e8 f3 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101798:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010179d:	74 19                	je     f01017b8 <mem_init+0x794>
f010179f:	68 e2 3d 10 f0       	push   $0xf0103de2
f01017a4:	68 16 3c 10 f0       	push   $0xf0103c16
f01017a9:	68 13 03 00 00       	push   $0x313
f01017ae:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01017b3:	e8 d3 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017bb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017c0:	74 19                	je     f01017db <mem_init+0x7b7>
f01017c2:	68 f3 3d 10 f0       	push   $0xf0103df3
f01017c7:	68 16 3c 10 f0       	push   $0xf0103c16
f01017cc:	68 14 03 00 00       	push   $0x314
f01017d1:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01017d6:	e8 b0 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017db:	6a 02                	push   $0x2
f01017dd:	68 00 10 00 00       	push   $0x1000
f01017e2:	56                   	push   %esi
f01017e3:	57                   	push   %edi
f01017e4:	e8 c3 f7 ff ff       	call   f0100fac <page_insert>
f01017e9:	83 c4 10             	add    $0x10,%esp
f01017ec:	85 c0                	test   %eax,%eax
f01017ee:	74 19                	je     f0101809 <mem_init+0x7e5>
f01017f0:	68 90 41 10 f0       	push   $0xf0104190
f01017f5:	68 16 3c 10 f0       	push   $0xf0103c16
f01017fa:	68 17 03 00 00       	push   $0x317
f01017ff:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101804:	e8 82 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101809:	ba 00 10 00 00       	mov    $0x1000,%edx
f010180e:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101813:	e8 2e f1 ff ff       	call   f0100946 <check_va2pa>
f0101818:	89 f2                	mov    %esi,%edx
f010181a:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101820:	c1 fa 03             	sar    $0x3,%edx
f0101823:	c1 e2 0c             	shl    $0xc,%edx
f0101826:	39 d0                	cmp    %edx,%eax
f0101828:	74 19                	je     f0101843 <mem_init+0x81f>
f010182a:	68 cc 41 10 f0       	push   $0xf01041cc
f010182f:	68 16 3c 10 f0       	push   $0xf0103c16
f0101834:	68 18 03 00 00       	push   $0x318
f0101839:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010183e:	e8 48 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101843:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101848:	74 19                	je     f0101863 <mem_init+0x83f>
f010184a:	68 04 3e 10 f0       	push   $0xf0103e04
f010184f:	68 16 3c 10 f0       	push   $0xf0103c16
f0101854:	68 19 03 00 00       	push   $0x319
f0101859:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010185e:	e8 28 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101863:	83 ec 0c             	sub    $0xc,%esp
f0101866:	6a 00                	push   $0x0
f0101868:	e8 c4 f4 ff ff       	call   f0100d31 <page_alloc>
f010186d:	83 c4 10             	add    $0x10,%esp
f0101870:	85 c0                	test   %eax,%eax
f0101872:	74 19                	je     f010188d <mem_init+0x869>
f0101874:	68 90 3d 10 f0       	push   $0xf0103d90
f0101879:	68 16 3c 10 f0       	push   $0xf0103c16
f010187e:	68 1c 03 00 00       	push   $0x31c
f0101883:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101888:	e8 fe e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010188d:	6a 02                	push   $0x2
f010188f:	68 00 10 00 00       	push   $0x1000
f0101894:	56                   	push   %esi
f0101895:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010189b:	e8 0c f7 ff ff       	call   f0100fac <page_insert>
f01018a0:	83 c4 10             	add    $0x10,%esp
f01018a3:	85 c0                	test   %eax,%eax
f01018a5:	74 19                	je     f01018c0 <mem_init+0x89c>
f01018a7:	68 90 41 10 f0       	push   $0xf0104190
f01018ac:	68 16 3c 10 f0       	push   $0xf0103c16
f01018b1:	68 1f 03 00 00       	push   $0x31f
f01018b6:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01018bb:	e8 cb e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018c0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018c5:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018ca:	e8 77 f0 ff ff       	call   f0100946 <check_va2pa>
f01018cf:	89 f2                	mov    %esi,%edx
f01018d1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018d7:	c1 fa 03             	sar    $0x3,%edx
f01018da:	c1 e2 0c             	shl    $0xc,%edx
f01018dd:	39 d0                	cmp    %edx,%eax
f01018df:	74 19                	je     f01018fa <mem_init+0x8d6>
f01018e1:	68 cc 41 10 f0       	push   $0xf01041cc
f01018e6:	68 16 3c 10 f0       	push   $0xf0103c16
f01018eb:	68 20 03 00 00       	push   $0x320
f01018f0:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01018f5:	e8 91 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018fa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018ff:	74 19                	je     f010191a <mem_init+0x8f6>
f0101901:	68 04 3e 10 f0       	push   $0xf0103e04
f0101906:	68 16 3c 10 f0       	push   $0xf0103c16
f010190b:	68 21 03 00 00       	push   $0x321
f0101910:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101915:	e8 71 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010191a:	83 ec 0c             	sub    $0xc,%esp
f010191d:	6a 00                	push   $0x0
f010191f:	e8 0d f4 ff ff       	call   f0100d31 <page_alloc>
f0101924:	83 c4 10             	add    $0x10,%esp
f0101927:	85 c0                	test   %eax,%eax
f0101929:	74 19                	je     f0101944 <mem_init+0x920>
f010192b:	68 90 3d 10 f0       	push   $0xf0103d90
f0101930:	68 16 3c 10 f0       	push   $0xf0103c16
f0101935:	68 25 03 00 00       	push   $0x325
f010193a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010193f:	e8 47 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101944:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f010194a:	8b 02                	mov    (%edx),%eax
f010194c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101951:	89 c1                	mov    %eax,%ecx
f0101953:	c1 e9 0c             	shr    $0xc,%ecx
f0101956:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f010195c:	72 15                	jb     f0101973 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010195e:	50                   	push   %eax
f010195f:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101964:	68 28 03 00 00       	push   $0x328
f0101969:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010196e:	e8 18 e7 ff ff       	call   f010008b <_panic>
f0101973:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101978:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010197b:	83 ec 04             	sub    $0x4,%esp
f010197e:	6a 00                	push   $0x0
f0101980:	68 00 10 00 00       	push   $0x1000
f0101985:	52                   	push   %edx
f0101986:	e8 93 f4 ff ff       	call   f0100e1e <pgdir_walk>
f010198b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010198e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101991:	83 c4 10             	add    $0x10,%esp
f0101994:	39 d0                	cmp    %edx,%eax
f0101996:	74 19                	je     f01019b1 <mem_init+0x98d>
f0101998:	68 fc 41 10 f0       	push   $0xf01041fc
f010199d:	68 16 3c 10 f0       	push   $0xf0103c16
f01019a2:	68 29 03 00 00       	push   $0x329
f01019a7:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01019ac:	e8 da e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019b1:	6a 06                	push   $0x6
f01019b3:	68 00 10 00 00       	push   $0x1000
f01019b8:	56                   	push   %esi
f01019b9:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01019bf:	e8 e8 f5 ff ff       	call   f0100fac <page_insert>
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	85 c0                	test   %eax,%eax
f01019c9:	74 19                	je     f01019e4 <mem_init+0x9c0>
f01019cb:	68 3c 42 10 f0       	push   $0xf010423c
f01019d0:	68 16 3c 10 f0       	push   $0xf0103c16
f01019d5:	68 2c 03 00 00       	push   $0x32c
f01019da:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01019df:	e8 a7 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019e4:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019ea:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019ef:	89 f8                	mov    %edi,%eax
f01019f1:	e8 50 ef ff ff       	call   f0100946 <check_va2pa>
f01019f6:	89 f2                	mov    %esi,%edx
f01019f8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019fe:	c1 fa 03             	sar    $0x3,%edx
f0101a01:	c1 e2 0c             	shl    $0xc,%edx
f0101a04:	39 d0                	cmp    %edx,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x9fd>
f0101a08:	68 cc 41 10 f0       	push   $0xf01041cc
f0101a0d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101a12:	68 2d 03 00 00       	push   $0x32d
f0101a17:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101a1c:	e8 6a e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a21:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a26:	74 19                	je     f0101a41 <mem_init+0xa1d>
f0101a28:	68 04 3e 10 f0       	push   $0xf0103e04
f0101a2d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101a32:	68 2e 03 00 00       	push   $0x32e
f0101a37:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101a3c:	e8 4a e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a41:	83 ec 04             	sub    $0x4,%esp
f0101a44:	6a 00                	push   $0x0
f0101a46:	68 00 10 00 00       	push   $0x1000
f0101a4b:	57                   	push   %edi
f0101a4c:	e8 cd f3 ff ff       	call   f0100e1e <pgdir_walk>
f0101a51:	83 c4 10             	add    $0x10,%esp
f0101a54:	f6 00 04             	testb  $0x4,(%eax)
f0101a57:	75 19                	jne    f0101a72 <mem_init+0xa4e>
f0101a59:	68 7c 42 10 f0       	push   $0xf010427c
f0101a5e:	68 16 3c 10 f0       	push   $0xf0103c16
f0101a63:	68 2f 03 00 00       	push   $0x32f
f0101a68:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101a6d:	e8 19 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a72:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a77:	f6 00 04             	testb  $0x4,(%eax)
f0101a7a:	75 19                	jne    f0101a95 <mem_init+0xa71>
f0101a7c:	68 15 3e 10 f0       	push   $0xf0103e15
f0101a81:	68 16 3c 10 f0       	push   $0xf0103c16
f0101a86:	68 30 03 00 00       	push   $0x330
f0101a8b:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101a90:	e8 f6 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a95:	6a 02                	push   $0x2
f0101a97:	68 00 10 00 00       	push   $0x1000
f0101a9c:	56                   	push   %esi
f0101a9d:	50                   	push   %eax
f0101a9e:	e8 09 f5 ff ff       	call   f0100fac <page_insert>
f0101aa3:	83 c4 10             	add    $0x10,%esp
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	74 19                	je     f0101ac3 <mem_init+0xa9f>
f0101aaa:	68 90 41 10 f0       	push   $0xf0104190
f0101aaf:	68 16 3c 10 f0       	push   $0xf0103c16
f0101ab4:	68 33 03 00 00       	push   $0x333
f0101ab9:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101abe:	e8 c8 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ac3:	83 ec 04             	sub    $0x4,%esp
f0101ac6:	6a 00                	push   $0x0
f0101ac8:	68 00 10 00 00       	push   $0x1000
f0101acd:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ad3:	e8 46 f3 ff ff       	call   f0100e1e <pgdir_walk>
f0101ad8:	83 c4 10             	add    $0x10,%esp
f0101adb:	f6 00 02             	testb  $0x2,(%eax)
f0101ade:	75 19                	jne    f0101af9 <mem_init+0xad5>
f0101ae0:	68 b0 42 10 f0       	push   $0xf01042b0
f0101ae5:	68 16 3c 10 f0       	push   $0xf0103c16
f0101aea:	68 34 03 00 00       	push   $0x334
f0101aef:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101af4:	e8 92 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101af9:	83 ec 04             	sub    $0x4,%esp
f0101afc:	6a 00                	push   $0x0
f0101afe:	68 00 10 00 00       	push   $0x1000
f0101b03:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b09:	e8 10 f3 ff ff       	call   f0100e1e <pgdir_walk>
f0101b0e:	83 c4 10             	add    $0x10,%esp
f0101b11:	f6 00 04             	testb  $0x4,(%eax)
f0101b14:	74 19                	je     f0101b2f <mem_init+0xb0b>
f0101b16:	68 e4 42 10 f0       	push   $0xf01042e4
f0101b1b:	68 16 3c 10 f0       	push   $0xf0103c16
f0101b20:	68 35 03 00 00       	push   $0x335
f0101b25:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101b2a:	e8 5c e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b2f:	6a 02                	push   $0x2
f0101b31:	68 00 00 40 00       	push   $0x400000
f0101b36:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b39:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b3f:	e8 68 f4 ff ff       	call   f0100fac <page_insert>
f0101b44:	83 c4 10             	add    $0x10,%esp
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	78 19                	js     f0101b64 <mem_init+0xb40>
f0101b4b:	68 1c 43 10 f0       	push   $0xf010431c
f0101b50:	68 16 3c 10 f0       	push   $0xf0103c16
f0101b55:	68 38 03 00 00       	push   $0x338
f0101b5a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101b5f:	e8 27 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b64:	6a 02                	push   $0x2
f0101b66:	68 00 10 00 00       	push   $0x1000
f0101b6b:	53                   	push   %ebx
f0101b6c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b72:	e8 35 f4 ff ff       	call   f0100fac <page_insert>
f0101b77:	83 c4 10             	add    $0x10,%esp
f0101b7a:	85 c0                	test   %eax,%eax
f0101b7c:	74 19                	je     f0101b97 <mem_init+0xb73>
f0101b7e:	68 54 43 10 f0       	push   $0xf0104354
f0101b83:	68 16 3c 10 f0       	push   $0xf0103c16
f0101b88:	68 3b 03 00 00       	push   $0x33b
f0101b8d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101b92:	e8 f4 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b97:	83 ec 04             	sub    $0x4,%esp
f0101b9a:	6a 00                	push   $0x0
f0101b9c:	68 00 10 00 00       	push   $0x1000
f0101ba1:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ba7:	e8 72 f2 ff ff       	call   f0100e1e <pgdir_walk>
f0101bac:	83 c4 10             	add    $0x10,%esp
f0101baf:	f6 00 04             	testb  $0x4,(%eax)
f0101bb2:	74 19                	je     f0101bcd <mem_init+0xba9>
f0101bb4:	68 e4 42 10 f0       	push   $0xf01042e4
f0101bb9:	68 16 3c 10 f0       	push   $0xf0103c16
f0101bbe:	68 3c 03 00 00       	push   $0x33c
f0101bc3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101bc8:	e8 be e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bcd:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bd3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd8:	89 f8                	mov    %edi,%eax
f0101bda:	e8 67 ed ff ff       	call   f0100946 <check_va2pa>
f0101bdf:	89 c1                	mov    %eax,%ecx
f0101be1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101be4:	89 d8                	mov    %ebx,%eax
f0101be6:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bec:	c1 f8 03             	sar    $0x3,%eax
f0101bef:	c1 e0 0c             	shl    $0xc,%eax
f0101bf2:	39 c1                	cmp    %eax,%ecx
f0101bf4:	74 19                	je     f0101c0f <mem_init+0xbeb>
f0101bf6:	68 90 43 10 f0       	push   $0xf0104390
f0101bfb:	68 16 3c 10 f0       	push   $0xf0103c16
f0101c00:	68 3f 03 00 00       	push   $0x33f
f0101c05:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101c0a:	e8 7c e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c0f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c14:	89 f8                	mov    %edi,%eax
f0101c16:	e8 2b ed ff ff       	call   f0100946 <check_va2pa>
f0101c1b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c1e:	74 19                	je     f0101c39 <mem_init+0xc15>
f0101c20:	68 bc 43 10 f0       	push   $0xf01043bc
f0101c25:	68 16 3c 10 f0       	push   $0xf0103c16
f0101c2a:	68 40 03 00 00       	push   $0x340
f0101c2f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101c34:	e8 52 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c39:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c3e:	74 19                	je     f0101c59 <mem_init+0xc35>
f0101c40:	68 2b 3e 10 f0       	push   $0xf0103e2b
f0101c45:	68 16 3c 10 f0       	push   $0xf0103c16
f0101c4a:	68 42 03 00 00       	push   $0x342
f0101c4f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101c54:	e8 32 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c59:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c5e:	74 19                	je     f0101c79 <mem_init+0xc55>
f0101c60:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101c65:	68 16 3c 10 f0       	push   $0xf0103c16
f0101c6a:	68 43 03 00 00       	push   $0x343
f0101c6f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101c74:	e8 12 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c79:	83 ec 0c             	sub    $0xc,%esp
f0101c7c:	6a 00                	push   $0x0
f0101c7e:	e8 ae f0 ff ff       	call   f0100d31 <page_alloc>
f0101c83:	83 c4 10             	add    $0x10,%esp
f0101c86:	85 c0                	test   %eax,%eax
f0101c88:	74 04                	je     f0101c8e <mem_init+0xc6a>
f0101c8a:	39 c6                	cmp    %eax,%esi
f0101c8c:	74 19                	je     f0101ca7 <mem_init+0xc83>
f0101c8e:	68 ec 43 10 f0       	push   $0xf01043ec
f0101c93:	68 16 3c 10 f0       	push   $0xf0103c16
f0101c98:	68 46 03 00 00       	push   $0x346
f0101c9d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101ca2:	e8 e4 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ca7:	83 ec 08             	sub    $0x8,%esp
f0101caa:	6a 00                	push   $0x0
f0101cac:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101cb2:	e8 b3 f2 ff ff       	call   f0100f6a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cb7:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101cbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc2:	89 f8                	mov    %edi,%eax
f0101cc4:	e8 7d ec ff ff       	call   f0100946 <check_va2pa>
f0101cc9:	83 c4 10             	add    $0x10,%esp
f0101ccc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ccf:	74 19                	je     f0101cea <mem_init+0xcc6>
f0101cd1:	68 10 44 10 f0       	push   $0xf0104410
f0101cd6:	68 16 3c 10 f0       	push   $0xf0103c16
f0101cdb:	68 4a 03 00 00       	push   $0x34a
f0101ce0:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101ce5:	e8 a1 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cef:	89 f8                	mov    %edi,%eax
f0101cf1:	e8 50 ec ff ff       	call   f0100946 <check_va2pa>
f0101cf6:	89 da                	mov    %ebx,%edx
f0101cf8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cfe:	c1 fa 03             	sar    $0x3,%edx
f0101d01:	c1 e2 0c             	shl    $0xc,%edx
f0101d04:	39 d0                	cmp    %edx,%eax
f0101d06:	74 19                	je     f0101d21 <mem_init+0xcfd>
f0101d08:	68 bc 43 10 f0       	push   $0xf01043bc
f0101d0d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101d12:	68 4b 03 00 00       	push   $0x34b
f0101d17:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101d1c:	e8 6a e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d21:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d26:	74 19                	je     f0101d41 <mem_init+0xd1d>
f0101d28:	68 e2 3d 10 f0       	push   $0xf0103de2
f0101d2d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101d32:	68 4c 03 00 00       	push   $0x34c
f0101d37:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101d3c:	e8 4a e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d41:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d46:	74 19                	je     f0101d61 <mem_init+0xd3d>
f0101d48:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101d4d:	68 16 3c 10 f0       	push   $0xf0103c16
f0101d52:	68 4d 03 00 00       	push   $0x34d
f0101d57:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101d5c:	e8 2a e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d61:	6a 00                	push   $0x0
f0101d63:	68 00 10 00 00       	push   $0x1000
f0101d68:	53                   	push   %ebx
f0101d69:	57                   	push   %edi
f0101d6a:	e8 3d f2 ff ff       	call   f0100fac <page_insert>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	85 c0                	test   %eax,%eax
f0101d74:	74 19                	je     f0101d8f <mem_init+0xd6b>
f0101d76:	68 34 44 10 f0       	push   $0xf0104434
f0101d7b:	68 16 3c 10 f0       	push   $0xf0103c16
f0101d80:	68 50 03 00 00       	push   $0x350
f0101d85:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101d8a:	e8 fc e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d8f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d94:	75 19                	jne    f0101daf <mem_init+0xd8b>
f0101d96:	68 4d 3e 10 f0       	push   $0xf0103e4d
f0101d9b:	68 16 3c 10 f0       	push   $0xf0103c16
f0101da0:	68 51 03 00 00       	push   $0x351
f0101da5:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101daa:	e8 dc e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101daf:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101db2:	74 19                	je     f0101dcd <mem_init+0xda9>
f0101db4:	68 59 3e 10 f0       	push   $0xf0103e59
f0101db9:	68 16 3c 10 f0       	push   $0xf0103c16
f0101dbe:	68 52 03 00 00       	push   $0x352
f0101dc3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101dc8:	e8 be e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dcd:	83 ec 08             	sub    $0x8,%esp
f0101dd0:	68 00 10 00 00       	push   $0x1000
f0101dd5:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ddb:	e8 8a f1 ff ff       	call   f0100f6a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101de0:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101de6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101deb:	89 f8                	mov    %edi,%eax
f0101ded:	e8 54 eb ff ff       	call   f0100946 <check_va2pa>
f0101df2:	83 c4 10             	add    $0x10,%esp
f0101df5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df8:	74 19                	je     f0101e13 <mem_init+0xdef>
f0101dfa:	68 10 44 10 f0       	push   $0xf0104410
f0101dff:	68 16 3c 10 f0       	push   $0xf0103c16
f0101e04:	68 56 03 00 00       	push   $0x356
f0101e09:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101e0e:	e8 78 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e13:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e18:	89 f8                	mov    %edi,%eax
f0101e1a:	e8 27 eb ff ff       	call   f0100946 <check_va2pa>
f0101e1f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e22:	74 19                	je     f0101e3d <mem_init+0xe19>
f0101e24:	68 6c 44 10 f0       	push   $0xf010446c
f0101e29:	68 16 3c 10 f0       	push   $0xf0103c16
f0101e2e:	68 57 03 00 00       	push   $0x357
f0101e33:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e3d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e42:	74 19                	je     f0101e5d <mem_init+0xe39>
f0101e44:	68 6e 3e 10 f0       	push   $0xf0103e6e
f0101e49:	68 16 3c 10 f0       	push   $0xf0103c16
f0101e4e:	68 58 03 00 00       	push   $0x358
f0101e53:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101e58:	e8 2e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e5d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e62:	74 19                	je     f0101e7d <mem_init+0xe59>
f0101e64:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101e69:	68 16 3c 10 f0       	push   $0xf0103c16
f0101e6e:	68 59 03 00 00       	push   $0x359
f0101e73:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101e78:	e8 0e e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e7d:	83 ec 0c             	sub    $0xc,%esp
f0101e80:	6a 00                	push   $0x0
f0101e82:	e8 aa ee ff ff       	call   f0100d31 <page_alloc>
f0101e87:	83 c4 10             	add    $0x10,%esp
f0101e8a:	39 c3                	cmp    %eax,%ebx
f0101e8c:	75 04                	jne    f0101e92 <mem_init+0xe6e>
f0101e8e:	85 c0                	test   %eax,%eax
f0101e90:	75 19                	jne    f0101eab <mem_init+0xe87>
f0101e92:	68 94 44 10 f0       	push   $0xf0104494
f0101e97:	68 16 3c 10 f0       	push   $0xf0103c16
f0101e9c:	68 5c 03 00 00       	push   $0x35c
f0101ea1:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101ea6:	e8 e0 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eab:	83 ec 0c             	sub    $0xc,%esp
f0101eae:	6a 00                	push   $0x0
f0101eb0:	e8 7c ee ff ff       	call   f0100d31 <page_alloc>
f0101eb5:	83 c4 10             	add    $0x10,%esp
f0101eb8:	85 c0                	test   %eax,%eax
f0101eba:	74 19                	je     f0101ed5 <mem_init+0xeb1>
f0101ebc:	68 90 3d 10 f0       	push   $0xf0103d90
f0101ec1:	68 16 3c 10 f0       	push   $0xf0103c16
f0101ec6:	68 5f 03 00 00       	push   $0x35f
f0101ecb:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101ed0:	e8 b6 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ed5:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101edb:	8b 11                	mov    (%ecx),%edx
f0101edd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ee3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee6:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101eec:	c1 f8 03             	sar    $0x3,%eax
f0101eef:	c1 e0 0c             	shl    $0xc,%eax
f0101ef2:	39 c2                	cmp    %eax,%edx
f0101ef4:	74 19                	je     f0101f0f <mem_init+0xeeb>
f0101ef6:	68 38 41 10 f0       	push   $0xf0104138
f0101efb:	68 16 3c 10 f0       	push   $0xf0103c16
f0101f00:	68 62 03 00 00       	push   $0x362
f0101f05:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101f0a:	e8 7c e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f0f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f18:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f1d:	74 19                	je     f0101f38 <mem_init+0xf14>
f0101f1f:	68 f3 3d 10 f0       	push   $0xf0103df3
f0101f24:	68 16 3c 10 f0       	push   $0xf0103c16
f0101f29:	68 64 03 00 00       	push   $0x364
f0101f2e:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101f33:	e8 53 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f3b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f41:	83 ec 0c             	sub    $0xc,%esp
f0101f44:	50                   	push   %eax
f0101f45:	e8 57 ee ff ff       	call   f0100da1 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f4a:	83 c4 0c             	add    $0xc,%esp
f0101f4d:	6a 01                	push   $0x1
f0101f4f:	68 00 10 40 00       	push   $0x401000
f0101f54:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f5a:	e8 bf ee ff ff       	call   f0100e1e <pgdir_walk>
f0101f5f:	89 c7                	mov    %eax,%edi
f0101f61:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f64:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f69:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f6c:	8b 40 04             	mov    0x4(%eax),%eax
f0101f6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f74:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f7a:	89 c2                	mov    %eax,%edx
f0101f7c:	c1 ea 0c             	shr    $0xc,%edx
f0101f7f:	83 c4 10             	add    $0x10,%esp
f0101f82:	39 ca                	cmp    %ecx,%edx
f0101f84:	72 15                	jb     f0101f9b <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f86:	50                   	push   %eax
f0101f87:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101f8c:	68 6b 03 00 00       	push   $0x36b
f0101f91:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101f96:	e8 f0 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f9b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fa0:	39 c7                	cmp    %eax,%edi
f0101fa2:	74 19                	je     f0101fbd <mem_init+0xf99>
f0101fa4:	68 7f 3e 10 f0       	push   $0xf0103e7f
f0101fa9:	68 16 3c 10 f0       	push   $0xf0103c16
f0101fae:	68 6c 03 00 00       	push   $0x36c
f0101fb3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0101fb8:	e8 ce e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fbd:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fc0:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fca:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fd0:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fd6:	c1 f8 03             	sar    $0x3,%eax
f0101fd9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fdc:	89 c2                	mov    %eax,%edx
f0101fde:	c1 ea 0c             	shr    $0xc,%edx
f0101fe1:	39 d1                	cmp    %edx,%ecx
f0101fe3:	77 12                	ja     f0101ff7 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe5:	50                   	push   %eax
f0101fe6:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101feb:	6a 52                	push   $0x52
f0101fed:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0101ff2:	e8 94 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ff7:	83 ec 04             	sub    $0x4,%esp
f0101ffa:	68 00 10 00 00       	push   $0x1000
f0101fff:	68 ff 00 00 00       	push   $0xff
f0102004:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102009:	50                   	push   %eax
f010200a:	e8 59 12 00 00       	call   f0103268 <memset>
	page_free(pp0);
f010200f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102012:	89 3c 24             	mov    %edi,(%esp)
f0102015:	e8 87 ed ff ff       	call   f0100da1 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010201a:	83 c4 0c             	add    $0xc,%esp
f010201d:	6a 01                	push   $0x1
f010201f:	6a 00                	push   $0x0
f0102021:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102027:	e8 f2 ed ff ff       	call   f0100e1e <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202c:	89 fa                	mov    %edi,%edx
f010202e:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102034:	c1 fa 03             	sar    $0x3,%edx
f0102037:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010203a:	89 d0                	mov    %edx,%eax
f010203c:	c1 e8 0c             	shr    $0xc,%eax
f010203f:	83 c4 10             	add    $0x10,%esp
f0102042:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0102048:	72 12                	jb     f010205c <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010204a:	52                   	push   %edx
f010204b:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0102050:	6a 52                	push   $0x52
f0102052:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0102057:	e8 2f e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010205c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102062:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102065:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010206b:	f6 00 01             	testb  $0x1,(%eax)
f010206e:	74 19                	je     f0102089 <mem_init+0x1065>
f0102070:	68 97 3e 10 f0       	push   $0xf0103e97
f0102075:	68 16 3c 10 f0       	push   $0xf0103c16
f010207a:	68 76 03 00 00       	push   $0x376
f010207f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102084:	e8 02 e0 ff ff       	call   f010008b <_panic>
f0102089:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010208c:	39 d0                	cmp    %edx,%eax
f010208e:	75 db                	jne    f010206b <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102090:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102095:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010209b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020a4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020a7:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020ad:	83 ec 0c             	sub    $0xc,%esp
f01020b0:	50                   	push   %eax
f01020b1:	e8 eb ec ff ff       	call   f0100da1 <page_free>
	page_free(pp1);
f01020b6:	89 1c 24             	mov    %ebx,(%esp)
f01020b9:	e8 e3 ec ff ff       	call   f0100da1 <page_free>
	page_free(pp2);
f01020be:	89 34 24             	mov    %esi,(%esp)
f01020c1:	e8 db ec ff ff       	call   f0100da1 <page_free>

	cprintf("check_page() succeeded!\n");
f01020c6:	c7 04 24 ae 3e 10 f0 	movl   $0xf0103eae,(%esp)
f01020cd:	e8 4b 06 00 00       	call   f010271d <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020d2:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020d7:	83 c4 10             	add    $0x10,%esp
f01020da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020df:	77 15                	ja     f01020f6 <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020e1:	50                   	push   %eax
f01020e2:	68 3c 40 10 f0       	push   $0xf010403c
f01020e7:	68 af 00 00 00       	push   $0xaf
f01020ec:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01020f1:	e8 95 df ff ff       	call   f010008b <_panic>
f01020f6:	83 ec 08             	sub    $0x8,%esp
f01020f9:	6a 04                	push   $0x4
f01020fb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102100:	50                   	push   %eax
f0102101:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102106:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010210b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102110:	e8 9c ed ff ff       	call   f0100eb1 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102115:	83 c4 10             	add    $0x10,%esp
f0102118:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f010211d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102122:	77 15                	ja     f0102139 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102124:	50                   	push   %eax
f0102125:	68 3c 40 10 f0       	push   $0xf010403c
f010212a:	68 bb 00 00 00       	push   $0xbb
f010212f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102134:	e8 52 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102139:	83 ec 08             	sub    $0x8,%esp
f010213c:	6a 02                	push   $0x2
f010213e:	68 00 c0 10 00       	push   $0x10c000
f0102143:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102148:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010214d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102152:	e8 5a ed ff ff       	call   f0100eb1 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102157:	83 c4 08             	add    $0x8,%esp
f010215a:	6a 02                	push   $0x2
f010215c:	6a 00                	push   $0x0
f010215e:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102163:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102168:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010216d:	e8 3f ed ff ff       	call   f0100eb1 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102172:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102178:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010217d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102180:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102187:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010218c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010218f:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102195:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102198:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010219b:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021a0:	eb 55                	jmp    f01021f7 <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021a2:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021a8:	89 f0                	mov    %esi,%eax
f01021aa:	e8 97 e7 ff ff       	call   f0100946 <check_va2pa>
f01021af:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021b6:	77 15                	ja     f01021cd <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021b8:	57                   	push   %edi
f01021b9:	68 3c 40 10 f0       	push   $0xf010403c
f01021be:	68 b8 02 00 00       	push   $0x2b8
f01021c3:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01021c8:	e8 be de ff ff       	call   f010008b <_panic>
f01021cd:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021d4:	39 c2                	cmp    %eax,%edx
f01021d6:	74 19                	je     f01021f1 <mem_init+0x11cd>
f01021d8:	68 b8 44 10 f0       	push   $0xf01044b8
f01021dd:	68 16 3c 10 f0       	push   $0xf0103c16
f01021e2:	68 b8 02 00 00       	push   $0x2b8
f01021e7:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01021ec:	e8 9a de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021f1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021f7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021fa:	77 a6                	ja     f01021a2 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021fc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021ff:	c1 e7 0c             	shl    $0xc,%edi
f0102202:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102207:	eb 30                	jmp    f0102239 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102209:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010220f:	89 f0                	mov    %esi,%eax
f0102211:	e8 30 e7 ff ff       	call   f0100946 <check_va2pa>
f0102216:	39 c3                	cmp    %eax,%ebx
f0102218:	74 19                	je     f0102233 <mem_init+0x120f>
f010221a:	68 ec 44 10 f0       	push   $0xf01044ec
f010221f:	68 16 3c 10 f0       	push   $0xf0103c16
f0102224:	68 bd 02 00 00       	push   $0x2bd
f0102229:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010222e:	e8 58 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102233:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102239:	39 fb                	cmp    %edi,%ebx
f010223b:	72 cc                	jb     f0102209 <mem_init+0x11e5>
f010223d:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102242:	89 da                	mov    %ebx,%edx
f0102244:	89 f0                	mov    %esi,%eax
f0102246:	e8 fb e6 ff ff       	call   f0100946 <check_va2pa>
f010224b:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102251:	39 c2                	cmp    %eax,%edx
f0102253:	74 19                	je     f010226e <mem_init+0x124a>
f0102255:	68 14 45 10 f0       	push   $0xf0104514
f010225a:	68 16 3c 10 f0       	push   $0xf0103c16
f010225f:	68 c1 02 00 00       	push   $0x2c1
f0102264:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102269:	e8 1d de ff ff       	call   f010008b <_panic>
f010226e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102274:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f010227a:	75 c6                	jne    f0102242 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010227c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102281:	89 f0                	mov    %esi,%eax
f0102283:	e8 be e6 ff ff       	call   f0100946 <check_va2pa>
f0102288:	83 f8 ff             	cmp    $0xffffffff,%eax
f010228b:	74 51                	je     f01022de <mem_init+0x12ba>
f010228d:	68 5c 45 10 f0       	push   $0xf010455c
f0102292:	68 16 3c 10 f0       	push   $0xf0103c16
f0102297:	68 c2 02 00 00       	push   $0x2c2
f010229c:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01022a1:	e8 e5 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022a6:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022ab:	72 36                	jb     f01022e3 <mem_init+0x12bf>
f01022ad:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022b2:	76 07                	jbe    f01022bb <mem_init+0x1297>
f01022b4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022b9:	75 28                	jne    f01022e3 <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022bb:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022bf:	0f 85 83 00 00 00    	jne    f0102348 <mem_init+0x1324>
f01022c5:	68 c7 3e 10 f0       	push   $0xf0103ec7
f01022ca:	68 16 3c 10 f0       	push   $0xf0103c16
f01022cf:	68 ca 02 00 00       	push   $0x2ca
f01022d4:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01022d9:	e8 ad dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022de:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022e3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022e8:	76 3f                	jbe    f0102329 <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022ea:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022ed:	f6 c2 01             	test   $0x1,%dl
f01022f0:	75 19                	jne    f010230b <mem_init+0x12e7>
f01022f2:	68 c7 3e 10 f0       	push   $0xf0103ec7
f01022f7:	68 16 3c 10 f0       	push   $0xf0103c16
f01022fc:	68 ce 02 00 00       	push   $0x2ce
f0102301:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102306:	e8 80 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010230b:	f6 c2 02             	test   $0x2,%dl
f010230e:	75 38                	jne    f0102348 <mem_init+0x1324>
f0102310:	68 d8 3e 10 f0       	push   $0xf0103ed8
f0102315:	68 16 3c 10 f0       	push   $0xf0103c16
f010231a:	68 cf 02 00 00       	push   $0x2cf
f010231f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102324:	e8 62 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102329:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010232d:	74 19                	je     f0102348 <mem_init+0x1324>
f010232f:	68 e9 3e 10 f0       	push   $0xf0103ee9
f0102334:	68 16 3c 10 f0       	push   $0xf0103c16
f0102339:	68 d1 02 00 00       	push   $0x2d1
f010233e:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102343:	e8 43 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102348:	83 c0 01             	add    $0x1,%eax
f010234b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102350:	0f 86 50 ff ff ff    	jbe    f01022a6 <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102356:	83 ec 0c             	sub    $0xc,%esp
f0102359:	68 8c 45 10 f0       	push   $0xf010458c
f010235e:	e8 ba 03 00 00       	call   f010271d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102363:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102368:	83 c4 10             	add    $0x10,%esp
f010236b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102370:	77 15                	ja     f0102387 <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102372:	50                   	push   %eax
f0102373:	68 3c 40 10 f0       	push   $0xf010403c
f0102378:	68 cf 00 00 00       	push   $0xcf
f010237d:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102387:	05 00 00 00 10       	add    $0x10000000,%eax
f010238c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010238f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102394:	e8 11 e6 ff ff       	call   f01009aa <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102399:	0f 20 c0             	mov    %cr0,%eax
f010239c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010239f:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023a4:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023a7:	83 ec 0c             	sub    $0xc,%esp
f01023aa:	6a 00                	push   $0x0
f01023ac:	e8 80 e9 ff ff       	call   f0100d31 <page_alloc>
f01023b1:	89 c3                	mov    %eax,%ebx
f01023b3:	83 c4 10             	add    $0x10,%esp
f01023b6:	85 c0                	test   %eax,%eax
f01023b8:	75 19                	jne    f01023d3 <mem_init+0x13af>
f01023ba:	68 e5 3c 10 f0       	push   $0xf0103ce5
f01023bf:	68 16 3c 10 f0       	push   $0xf0103c16
f01023c4:	68 91 03 00 00       	push   $0x391
f01023c9:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01023ce:	e8 b8 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023d3:	83 ec 0c             	sub    $0xc,%esp
f01023d6:	6a 00                	push   $0x0
f01023d8:	e8 54 e9 ff ff       	call   f0100d31 <page_alloc>
f01023dd:	89 c7                	mov    %eax,%edi
f01023df:	83 c4 10             	add    $0x10,%esp
f01023e2:	85 c0                	test   %eax,%eax
f01023e4:	75 19                	jne    f01023ff <mem_init+0x13db>
f01023e6:	68 fb 3c 10 f0       	push   $0xf0103cfb
f01023eb:	68 16 3c 10 f0       	push   $0xf0103c16
f01023f0:	68 92 03 00 00       	push   $0x392
f01023f5:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01023fa:	e8 8c dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023ff:	83 ec 0c             	sub    $0xc,%esp
f0102402:	6a 00                	push   $0x0
f0102404:	e8 28 e9 ff ff       	call   f0100d31 <page_alloc>
f0102409:	89 c6                	mov    %eax,%esi
f010240b:	83 c4 10             	add    $0x10,%esp
f010240e:	85 c0                	test   %eax,%eax
f0102410:	75 19                	jne    f010242b <mem_init+0x1407>
f0102412:	68 11 3d 10 f0       	push   $0xf0103d11
f0102417:	68 16 3c 10 f0       	push   $0xf0103c16
f010241c:	68 93 03 00 00       	push   $0x393
f0102421:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102426:	e8 60 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010242b:	83 ec 0c             	sub    $0xc,%esp
f010242e:	53                   	push   %ebx
f010242f:	e8 6d e9 ff ff       	call   f0100da1 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102434:	89 f8                	mov    %edi,%eax
f0102436:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010243c:	c1 f8 03             	sar    $0x3,%eax
f010243f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102442:	89 c2                	mov    %eax,%edx
f0102444:	c1 ea 0c             	shr    $0xc,%edx
f0102447:	83 c4 10             	add    $0x10,%esp
f010244a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102450:	72 12                	jb     f0102464 <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102452:	50                   	push   %eax
f0102453:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0102458:	6a 52                	push   $0x52
f010245a:	68 fc 3b 10 f0       	push   $0xf0103bfc
f010245f:	e8 27 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102464:	83 ec 04             	sub    $0x4,%esp
f0102467:	68 00 10 00 00       	push   $0x1000
f010246c:	6a 01                	push   $0x1
f010246e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102473:	50                   	push   %eax
f0102474:	e8 ef 0d 00 00       	call   f0103268 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102479:	89 f0                	mov    %esi,%eax
f010247b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102481:	c1 f8 03             	sar    $0x3,%eax
f0102484:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102487:	89 c2                	mov    %eax,%edx
f0102489:	c1 ea 0c             	shr    $0xc,%edx
f010248c:	83 c4 10             	add    $0x10,%esp
f010248f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102495:	72 12                	jb     f01024a9 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102497:	50                   	push   %eax
f0102498:	68 f8 3e 10 f0       	push   $0xf0103ef8
f010249d:	6a 52                	push   $0x52
f010249f:	68 fc 3b 10 f0       	push   $0xf0103bfc
f01024a4:	e8 e2 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024a9:	83 ec 04             	sub    $0x4,%esp
f01024ac:	68 00 10 00 00       	push   $0x1000
f01024b1:	6a 02                	push   $0x2
f01024b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024b8:	50                   	push   %eax
f01024b9:	e8 aa 0d 00 00       	call   f0103268 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024be:	6a 02                	push   $0x2
f01024c0:	68 00 10 00 00       	push   $0x1000
f01024c5:	57                   	push   %edi
f01024c6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024cc:	e8 db ea ff ff       	call   f0100fac <page_insert>
	assert(pp1->pp_ref == 1);
f01024d1:	83 c4 20             	add    $0x20,%esp
f01024d4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024d9:	74 19                	je     f01024f4 <mem_init+0x14d0>
f01024db:	68 e2 3d 10 f0       	push   $0xf0103de2
f01024e0:	68 16 3c 10 f0       	push   $0xf0103c16
f01024e5:	68 98 03 00 00       	push   $0x398
f01024ea:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01024ef:	e8 97 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024f4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024fb:	01 01 01 
f01024fe:	74 19                	je     f0102519 <mem_init+0x14f5>
f0102500:	68 ac 45 10 f0       	push   $0xf01045ac
f0102505:	68 16 3c 10 f0       	push   $0xf0103c16
f010250a:	68 99 03 00 00       	push   $0x399
f010250f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102514:	e8 72 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102519:	6a 02                	push   $0x2
f010251b:	68 00 10 00 00       	push   $0x1000
f0102520:	56                   	push   %esi
f0102521:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102527:	e8 80 ea ff ff       	call   f0100fac <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010252c:	83 c4 10             	add    $0x10,%esp
f010252f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102536:	02 02 02 
f0102539:	74 19                	je     f0102554 <mem_init+0x1530>
f010253b:	68 d0 45 10 f0       	push   $0xf01045d0
f0102540:	68 16 3c 10 f0       	push   $0xf0103c16
f0102545:	68 9b 03 00 00       	push   $0x39b
f010254a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010254f:	e8 37 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102554:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102559:	74 19                	je     f0102574 <mem_init+0x1550>
f010255b:	68 04 3e 10 f0       	push   $0xf0103e04
f0102560:	68 16 3c 10 f0       	push   $0xf0103c16
f0102565:	68 9c 03 00 00       	push   $0x39c
f010256a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010256f:	e8 17 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102574:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102579:	74 19                	je     f0102594 <mem_init+0x1570>
f010257b:	68 6e 3e 10 f0       	push   $0xf0103e6e
f0102580:	68 16 3c 10 f0       	push   $0xf0103c16
f0102585:	68 9d 03 00 00       	push   $0x39d
f010258a:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010258f:	e8 f7 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102594:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010259b:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010259e:	89 f0                	mov    %esi,%eax
f01025a0:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01025a6:	c1 f8 03             	sar    $0x3,%eax
f01025a9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025ac:	89 c2                	mov    %eax,%edx
f01025ae:	c1 ea 0c             	shr    $0xc,%edx
f01025b1:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01025b7:	72 12                	jb     f01025cb <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b9:	50                   	push   %eax
f01025ba:	68 f8 3e 10 f0       	push   $0xf0103ef8
f01025bf:	6a 52                	push   $0x52
f01025c1:	68 fc 3b 10 f0       	push   $0xf0103bfc
f01025c6:	e8 c0 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025cb:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025d2:	03 03 03 
f01025d5:	74 19                	je     f01025f0 <mem_init+0x15cc>
f01025d7:	68 f4 45 10 f0       	push   $0xf01045f4
f01025dc:	68 16 3c 10 f0       	push   $0xf0103c16
f01025e1:	68 9f 03 00 00       	push   $0x39f
f01025e6:	68 f0 3b 10 f0       	push   $0xf0103bf0
f01025eb:	e8 9b da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025f0:	83 ec 08             	sub    $0x8,%esp
f01025f3:	68 00 10 00 00       	push   $0x1000
f01025f8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025fe:	e8 67 e9 ff ff       	call   f0100f6a <page_remove>
	assert(pp2->pp_ref == 0);
f0102603:	83 c4 10             	add    $0x10,%esp
f0102606:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010260b:	74 19                	je     f0102626 <mem_init+0x1602>
f010260d:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0102612:	68 16 3c 10 f0       	push   $0xf0103c16
f0102617:	68 a1 03 00 00       	push   $0x3a1
f010261c:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102621:	e8 65 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102626:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f010262c:	8b 11                	mov    (%ecx),%edx
f010262e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102634:	89 d8                	mov    %ebx,%eax
f0102636:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010263c:	c1 f8 03             	sar    $0x3,%eax
f010263f:	c1 e0 0c             	shl    $0xc,%eax
f0102642:	39 c2                	cmp    %eax,%edx
f0102644:	74 19                	je     f010265f <mem_init+0x163b>
f0102646:	68 38 41 10 f0       	push   $0xf0104138
f010264b:	68 16 3c 10 f0       	push   $0xf0103c16
f0102650:	68 a4 03 00 00       	push   $0x3a4
f0102655:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010265a:	e8 2c da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010265f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102665:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010266a:	74 19                	je     f0102685 <mem_init+0x1661>
f010266c:	68 f3 3d 10 f0       	push   $0xf0103df3
f0102671:	68 16 3c 10 f0       	push   $0xf0103c16
f0102676:	68 a6 03 00 00       	push   $0x3a6
f010267b:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0102680:	e8 06 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102685:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010268b:	83 ec 0c             	sub    $0xc,%esp
f010268e:	53                   	push   %ebx
f010268f:	e8 0d e7 ff ff       	call   f0100da1 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102694:	c7 04 24 20 46 10 f0 	movl   $0xf0104620,(%esp)
f010269b:	e8 7d 00 00 00       	call   f010271d <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026a0:	83 c4 10             	add    $0x10,%esp
f01026a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026a6:	5b                   	pop    %ebx
f01026a7:	5e                   	pop    %esi
f01026a8:	5f                   	pop    %edi
f01026a9:	5d                   	pop    %ebp
f01026aa:	c3                   	ret    

f01026ab <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026ab:	55                   	push   %ebp
f01026ac:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026b1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026b4:	5d                   	pop    %ebp
f01026b5:	c3                   	ret    

f01026b6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026b6:	55                   	push   %ebp
f01026b7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b9:	ba 70 00 00 00       	mov    $0x70,%edx
f01026be:	8b 45 08             	mov    0x8(%ebp),%eax
f01026c1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026c2:	ba 71 00 00 00       	mov    $0x71,%edx
f01026c7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026c8:	0f b6 c0             	movzbl %al,%eax
}
f01026cb:	5d                   	pop    %ebp
f01026cc:	c3                   	ret    

f01026cd <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026cd:	55                   	push   %ebp
f01026ce:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026d0:	ba 70 00 00 00       	mov    $0x70,%edx
f01026d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01026d8:	ee                   	out    %al,(%dx)
f01026d9:	ba 71 00 00 00       	mov    $0x71,%edx
f01026de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026e1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026e2:	5d                   	pop    %ebp
f01026e3:	c3                   	ret    

f01026e4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026e4:	55                   	push   %ebp
f01026e5:	89 e5                	mov    %esp,%ebp
f01026e7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026ea:	ff 75 08             	pushl  0x8(%ebp)
f01026ed:	e8 00 df ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01026f2:	83 c4 10             	add    $0x10,%esp
f01026f5:	c9                   	leave  
f01026f6:	c3                   	ret    

f01026f7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026f7:	55                   	push   %ebp
f01026f8:	89 e5                	mov    %esp,%ebp
f01026fa:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102704:	ff 75 0c             	pushl  0xc(%ebp)
f0102707:	ff 75 08             	pushl  0x8(%ebp)
f010270a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010270d:	50                   	push   %eax
f010270e:	68 e4 26 10 f0       	push   $0xf01026e4
f0102713:	e8 37 04 00 00       	call   f0102b4f <vprintfmt>
	return cnt;
}
f0102718:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010271b:	c9                   	leave  
f010271c:	c3                   	ret    

f010271d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010271d:	55                   	push   %ebp
f010271e:	89 e5                	mov    %esp,%ebp
f0102720:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102723:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102726:	50                   	push   %eax
f0102727:	ff 75 08             	pushl  0x8(%ebp)
f010272a:	e8 c8 ff ff ff       	call   f01026f7 <vcprintf>
	va_end(ap);

	return cnt;
}
f010272f:	c9                   	leave  
f0102730:	c3                   	ret    

f0102731 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102731:	55                   	push   %ebp
f0102732:	89 e5                	mov    %esp,%ebp
f0102734:	57                   	push   %edi
f0102735:	56                   	push   %esi
f0102736:	53                   	push   %ebx
f0102737:	83 ec 14             	sub    $0x14,%esp
f010273a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010273d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102740:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102743:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102746:	8b 1a                	mov    (%edx),%ebx
f0102748:	8b 01                	mov    (%ecx),%eax
f010274a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010274d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102754:	eb 7f                	jmp    f01027d5 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102756:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102759:	01 d8                	add    %ebx,%eax
f010275b:	89 c6                	mov    %eax,%esi
f010275d:	c1 ee 1f             	shr    $0x1f,%esi
f0102760:	01 c6                	add    %eax,%esi
f0102762:	d1 fe                	sar    %esi
f0102764:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102767:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010276a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010276d:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010276f:	eb 03                	jmp    f0102774 <stab_binsearch+0x43>
			m--;
f0102771:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102774:	39 c3                	cmp    %eax,%ebx
f0102776:	7f 0d                	jg     f0102785 <stab_binsearch+0x54>
f0102778:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010277c:	83 ea 0c             	sub    $0xc,%edx
f010277f:	39 f9                	cmp    %edi,%ecx
f0102781:	75 ee                	jne    f0102771 <stab_binsearch+0x40>
f0102783:	eb 05                	jmp    f010278a <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102785:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102788:	eb 4b                	jmp    f01027d5 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010278a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010278d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102790:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102794:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102797:	76 11                	jbe    f01027aa <stab_binsearch+0x79>
			*region_left = m;
f0102799:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010279c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010279e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027a1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027a8:	eb 2b                	jmp    f01027d5 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027aa:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027ad:	73 14                	jae    f01027c3 <stab_binsearch+0x92>
			*region_right = m - 1;
f01027af:	83 e8 01             	sub    $0x1,%eax
f01027b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027b5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027b8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ba:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027c1:	eb 12                	jmp    f01027d5 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027c3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027c6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027c8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027cc:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ce:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027d5:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027d8:	0f 8e 78 ff ff ff    	jle    f0102756 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027de:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027e2:	75 0f                	jne    f01027f3 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027e7:	8b 00                	mov    (%eax),%eax
f01027e9:	83 e8 01             	sub    $0x1,%eax
f01027ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027ef:	89 06                	mov    %eax,(%esi)
f01027f1:	eb 2c                	jmp    f010281f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027f6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027f8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027fb:	8b 0e                	mov    (%esi),%ecx
f01027fd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102800:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102803:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102806:	eb 03                	jmp    f010280b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102808:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010280b:	39 c8                	cmp    %ecx,%eax
f010280d:	7e 0b                	jle    f010281a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010280f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102813:	83 ea 0c             	sub    $0xc,%edx
f0102816:	39 df                	cmp    %ebx,%edi
f0102818:	75 ee                	jne    f0102808 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010281a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010281d:	89 06                	mov    %eax,(%esi)
	}
}
f010281f:	83 c4 14             	add    $0x14,%esp
f0102822:	5b                   	pop    %ebx
f0102823:	5e                   	pop    %esi
f0102824:	5f                   	pop    %edi
f0102825:	5d                   	pop    %ebp
f0102826:	c3                   	ret    

f0102827 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102827:	55                   	push   %ebp
f0102828:	89 e5                	mov    %esp,%ebp
f010282a:	57                   	push   %edi
f010282b:	56                   	push   %esi
f010282c:	53                   	push   %ebx
f010282d:	83 ec 3c             	sub    $0x3c,%esp
f0102830:	8b 75 08             	mov    0x8(%ebp),%esi
f0102833:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102836:	c7 03 4c 46 10 f0    	movl   $0xf010464c,(%ebx)
	info->eip_line = 0;
f010283c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102843:	c7 43 08 4c 46 10 f0 	movl   $0xf010464c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010284a:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102851:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102854:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010285b:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102861:	76 11                	jbe    f0102874 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102863:	b8 c7 be 10 f0       	mov    $0xf010bec7,%eax
f0102868:	3d 11 a1 10 f0       	cmp    $0xf010a111,%eax
f010286d:	77 19                	ja     f0102888 <debuginfo_eip+0x61>
f010286f:	e9 c9 01 00 00       	jmp    f0102a3d <debuginfo_eip+0x216>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102874:	83 ec 04             	sub    $0x4,%esp
f0102877:	68 56 46 10 f0       	push   $0xf0104656
f010287c:	6a 7f                	push   $0x7f
f010287e:	68 63 46 10 f0       	push   $0xf0104663
f0102883:	e8 03 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102888:	80 3d c6 be 10 f0 00 	cmpb   $0x0,0xf010bec6
f010288f:	0f 85 af 01 00 00    	jne    f0102a44 <debuginfo_eip+0x21d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102895:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010289c:	b8 10 a1 10 f0       	mov    $0xf010a110,%eax
f01028a1:	2d 90 48 10 f0       	sub    $0xf0104890,%eax
f01028a6:	c1 f8 02             	sar    $0x2,%eax
f01028a9:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028af:	83 e8 01             	sub    $0x1,%eax
f01028b2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028b5:	83 ec 08             	sub    $0x8,%esp
f01028b8:	56                   	push   %esi
f01028b9:	6a 64                	push   $0x64
f01028bb:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028be:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028c1:	b8 90 48 10 f0       	mov    $0xf0104890,%eax
f01028c6:	e8 66 fe ff ff       	call   f0102731 <stab_binsearch>
	if (lfile == 0)
f01028cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028ce:	83 c4 10             	add    $0x10,%esp
f01028d1:	85 c0                	test   %eax,%eax
f01028d3:	0f 84 72 01 00 00    	je     f0102a4b <debuginfo_eip+0x224>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028df:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028e2:	83 ec 08             	sub    $0x8,%esp
f01028e5:	56                   	push   %esi
f01028e6:	6a 24                	push   $0x24
f01028e8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028eb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028ee:	b8 90 48 10 f0       	mov    $0xf0104890,%eax
f01028f3:	e8 39 fe ff ff       	call   f0102731 <stab_binsearch>

	if (lfun <= rfun) {
f01028f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028fb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028fe:	83 c4 10             	add    $0x10,%esp
f0102901:	39 d0                	cmp    %edx,%eax
f0102903:	7f 40                	jg     f0102945 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102905:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102908:	c1 e1 02             	shl    $0x2,%ecx
f010290b:	8d b9 90 48 10 f0    	lea    -0xfefb770(%ecx),%edi
f0102911:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102914:	8b b9 90 48 10 f0    	mov    -0xfefb770(%ecx),%edi
f010291a:	b9 c7 be 10 f0       	mov    $0xf010bec7,%ecx
f010291f:	81 e9 11 a1 10 f0    	sub    $0xf010a111,%ecx
f0102925:	39 cf                	cmp    %ecx,%edi
f0102927:	73 09                	jae    f0102932 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102929:	81 c7 11 a1 10 f0    	add    $0xf010a111,%edi
f010292f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102932:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102935:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102938:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010293b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010293d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102940:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102943:	eb 0f                	jmp    f0102954 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102945:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102948:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010294b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010294e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102951:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102954:	83 ec 08             	sub    $0x8,%esp
f0102957:	6a 3a                	push   $0x3a
f0102959:	ff 73 08             	pushl  0x8(%ebx)
f010295c:	e8 eb 08 00 00       	call   f010324c <strfind>
f0102961:	2b 43 08             	sub    0x8(%ebx),%eax
f0102964:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;
f0102967:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010296a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010296d:	8b 04 85 90 48 10 f0 	mov    -0xfefb770(,%eax,4),%eax
f0102974:	05 11 a1 10 f0       	add    $0xf010a111,%eax
f0102979:	89 03                	mov    %eax,(%ebx)

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010297b:	83 c4 08             	add    $0x8,%esp
f010297e:	56                   	push   %esi
f010297f:	6a 44                	push   $0x44
f0102981:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102984:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102987:	b8 90 48 10 f0       	mov    $0xf0104890,%eax
f010298c:	e8 a0 fd ff ff       	call   f0102731 <stab_binsearch>
	if (lline > rline) {
f0102991:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102994:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102997:	83 c4 10             	add    $0x10,%esp
f010299a:	39 d0                	cmp    %edx,%eax
f010299c:	0f 8f b0 00 00 00    	jg     f0102a52 <debuginfo_eip+0x22b>
	    return -1;
	} else {
	    info->eip_line = stabs[rline].n_desc;
f01029a2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029a5:	0f b7 14 95 96 48 10 	movzwl -0xfefb76a(,%edx,4),%edx
f01029ac:	f0 
f01029ad:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029b3:	89 c2                	mov    %eax,%edx
f01029b5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01029b8:	8d 04 85 90 48 10 f0 	lea    -0xfefb770(,%eax,4),%eax
f01029bf:	eb 06                	jmp    f01029c7 <debuginfo_eip+0x1a0>
f01029c1:	83 ea 01             	sub    $0x1,%edx
f01029c4:	83 e8 0c             	sub    $0xc,%eax
f01029c7:	39 d7                	cmp    %edx,%edi
f01029c9:	7f 34                	jg     f01029ff <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01029cb:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029cf:	80 f9 84             	cmp    $0x84,%cl
f01029d2:	74 0b                	je     f01029df <debuginfo_eip+0x1b8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029d4:	80 f9 64             	cmp    $0x64,%cl
f01029d7:	75 e8                	jne    f01029c1 <debuginfo_eip+0x19a>
f01029d9:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029dd:	74 e2                	je     f01029c1 <debuginfo_eip+0x19a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029df:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029e2:	8b 14 85 90 48 10 f0 	mov    -0xfefb770(,%eax,4),%edx
f01029e9:	b8 c7 be 10 f0       	mov    $0xf010bec7,%eax
f01029ee:	2d 11 a1 10 f0       	sub    $0xf010a111,%eax
f01029f3:	39 c2                	cmp    %eax,%edx
f01029f5:	73 08                	jae    f01029ff <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029f7:	81 c2 11 a1 10 f0    	add    $0xf010a111,%edx
f01029fd:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029ff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a02:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a05:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a0a:	39 f2                	cmp    %esi,%edx
f0102a0c:	7d 50                	jge    f0102a5e <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f0102a0e:	83 c2 01             	add    $0x1,%edx
f0102a11:	89 d0                	mov    %edx,%eax
f0102a13:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a16:	8d 14 95 90 48 10 f0 	lea    -0xfefb770(,%edx,4),%edx
f0102a1d:	eb 04                	jmp    f0102a23 <debuginfo_eip+0x1fc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a1f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a23:	39 c6                	cmp    %eax,%esi
f0102a25:	7e 32                	jle    f0102a59 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a27:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a2b:	83 c0 01             	add    $0x1,%eax
f0102a2e:	83 c2 0c             	add    $0xc,%edx
f0102a31:	80 f9 a0             	cmp    $0xa0,%cl
f0102a34:	74 e9                	je     f0102a1f <debuginfo_eip+0x1f8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a36:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a3b:	eb 21                	jmp    f0102a5e <debuginfo_eip+0x237>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a42:	eb 1a                	jmp    f0102a5e <debuginfo_eip+0x237>
f0102a44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a49:	eb 13                	jmp    f0102a5e <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a50:	eb 0c                	jmp    f0102a5e <debuginfo_eip+0x237>
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline) {
	    return -1;
f0102a52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a57:	eb 05                	jmp    f0102a5e <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a59:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a61:	5b                   	pop    %ebx
f0102a62:	5e                   	pop    %esi
f0102a63:	5f                   	pop    %edi
f0102a64:	5d                   	pop    %ebp
f0102a65:	c3                   	ret    

f0102a66 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a66:	55                   	push   %ebp
f0102a67:	89 e5                	mov    %esp,%ebp
f0102a69:	57                   	push   %edi
f0102a6a:	56                   	push   %esi
f0102a6b:	53                   	push   %ebx
f0102a6c:	83 ec 1c             	sub    $0x1c,%esp
f0102a6f:	89 c7                	mov    %eax,%edi
f0102a71:	89 d6                	mov    %edx,%esi
f0102a73:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a76:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a79:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a7c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a82:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a87:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a8a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a8d:	39 d3                	cmp    %edx,%ebx
f0102a8f:	72 05                	jb     f0102a96 <printnum+0x30>
f0102a91:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a94:	77 45                	ja     f0102adb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a96:	83 ec 0c             	sub    $0xc,%esp
f0102a99:	ff 75 18             	pushl  0x18(%ebp)
f0102a9c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a9f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102aa2:	53                   	push   %ebx
f0102aa3:	ff 75 10             	pushl  0x10(%ebp)
f0102aa6:	83 ec 08             	sub    $0x8,%esp
f0102aa9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aac:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aaf:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ab2:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ab5:	e8 b6 09 00 00       	call   f0103470 <__udivdi3>
f0102aba:	83 c4 18             	add    $0x18,%esp
f0102abd:	52                   	push   %edx
f0102abe:	50                   	push   %eax
f0102abf:	89 f2                	mov    %esi,%edx
f0102ac1:	89 f8                	mov    %edi,%eax
f0102ac3:	e8 9e ff ff ff       	call   f0102a66 <printnum>
f0102ac8:	83 c4 20             	add    $0x20,%esp
f0102acb:	eb 18                	jmp    f0102ae5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102acd:	83 ec 08             	sub    $0x8,%esp
f0102ad0:	56                   	push   %esi
f0102ad1:	ff 75 18             	pushl  0x18(%ebp)
f0102ad4:	ff d7                	call   *%edi
f0102ad6:	83 c4 10             	add    $0x10,%esp
f0102ad9:	eb 03                	jmp    f0102ade <printnum+0x78>
f0102adb:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ade:	83 eb 01             	sub    $0x1,%ebx
f0102ae1:	85 db                	test   %ebx,%ebx
f0102ae3:	7f e8                	jg     f0102acd <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ae5:	83 ec 08             	sub    $0x8,%esp
f0102ae8:	56                   	push   %esi
f0102ae9:	83 ec 04             	sub    $0x4,%esp
f0102aec:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aef:	ff 75 e0             	pushl  -0x20(%ebp)
f0102af2:	ff 75 dc             	pushl  -0x24(%ebp)
f0102af5:	ff 75 d8             	pushl  -0x28(%ebp)
f0102af8:	e8 a3 0a 00 00       	call   f01035a0 <__umoddi3>
f0102afd:	83 c4 14             	add    $0x14,%esp
f0102b00:	0f be 80 71 46 10 f0 	movsbl -0xfefb98f(%eax),%eax
f0102b07:	50                   	push   %eax
f0102b08:	ff d7                	call   *%edi
}
f0102b0a:	83 c4 10             	add    $0x10,%esp
f0102b0d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b10:	5b                   	pop    %ebx
f0102b11:	5e                   	pop    %esi
f0102b12:	5f                   	pop    %edi
f0102b13:	5d                   	pop    %ebp
f0102b14:	c3                   	ret    

f0102b15 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b15:	55                   	push   %ebp
f0102b16:	89 e5                	mov    %esp,%ebp
f0102b18:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b1b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b1f:	8b 10                	mov    (%eax),%edx
f0102b21:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b24:	73 0a                	jae    f0102b30 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b26:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b29:	89 08                	mov    %ecx,(%eax)
f0102b2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b2e:	88 02                	mov    %al,(%edx)
}
f0102b30:	5d                   	pop    %ebp
f0102b31:	c3                   	ret    

f0102b32 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b32:	55                   	push   %ebp
f0102b33:	89 e5                	mov    %esp,%ebp
f0102b35:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b38:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b3b:	50                   	push   %eax
f0102b3c:	ff 75 10             	pushl  0x10(%ebp)
f0102b3f:	ff 75 0c             	pushl  0xc(%ebp)
f0102b42:	ff 75 08             	pushl  0x8(%ebp)
f0102b45:	e8 05 00 00 00       	call   f0102b4f <vprintfmt>
	va_end(ap);
}
f0102b4a:	83 c4 10             	add    $0x10,%esp
f0102b4d:	c9                   	leave  
f0102b4e:	c3                   	ret    

f0102b4f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b4f:	55                   	push   %ebp
f0102b50:	89 e5                	mov    %esp,%ebp
f0102b52:	57                   	push   %edi
f0102b53:	56                   	push   %esi
f0102b54:	53                   	push   %ebx
f0102b55:	83 ec 2c             	sub    $0x2c,%esp
f0102b58:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b5e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b61:	eb 12                	jmp    f0102b75 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b63:	85 c0                	test   %eax,%eax
f0102b65:	0f 84 36 04 00 00    	je     f0102fa1 <vprintfmt+0x452>
				return;
			putch(ch, putdat);
f0102b6b:	83 ec 08             	sub    $0x8,%esp
f0102b6e:	53                   	push   %ebx
f0102b6f:	50                   	push   %eax
f0102b70:	ff d6                	call   *%esi
f0102b72:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b75:	83 c7 01             	add    $0x1,%edi
f0102b78:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b7c:	83 f8 25             	cmp    $0x25,%eax
f0102b7f:	75 e2                	jne    f0102b63 <vprintfmt+0x14>
f0102b81:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b85:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b8c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b93:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b9a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b9f:	eb 07                	jmp    f0102ba8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ba4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba8:	8d 47 01             	lea    0x1(%edi),%eax
f0102bab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bae:	0f b6 07             	movzbl (%edi),%eax
f0102bb1:	0f b6 d0             	movzbl %al,%edx
f0102bb4:	83 e8 23             	sub    $0x23,%eax
f0102bb7:	3c 55                	cmp    $0x55,%al
f0102bb9:	0f 87 c7 03 00 00    	ja     f0102f86 <vprintfmt+0x437>
f0102bbf:	0f b6 c0             	movzbl %al,%eax
f0102bc2:	ff 24 85 00 47 10 f0 	jmp    *-0xfefb900(,%eax,4)
f0102bc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bcc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bd0:	eb d6                	jmp    f0102ba8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bda:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bdd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102be0:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102be4:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102be7:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102bea:	83 f9 09             	cmp    $0x9,%ecx
f0102bed:	77 3f                	ja     f0102c2e <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bef:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bf2:	eb e9                	jmp    f0102bdd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bf4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf7:	8b 00                	mov    (%eax),%eax
f0102bf9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bff:	8d 40 04             	lea    0x4(%eax),%eax
f0102c02:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c08:	eb 2a                	jmp    f0102c34 <vprintfmt+0xe5>
f0102c0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c0d:	85 c0                	test   %eax,%eax
f0102c0f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c14:	0f 49 d0             	cmovns %eax,%edx
f0102c17:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c1d:	eb 89                	jmp    f0102ba8 <vprintfmt+0x59>
f0102c1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c22:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c29:	e9 7a ff ff ff       	jmp    f0102ba8 <vprintfmt+0x59>
f0102c2e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c31:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c34:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c38:	0f 89 6a ff ff ff    	jns    f0102ba8 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c44:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c4b:	e9 58 ff ff ff       	jmp    f0102ba8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c50:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c56:	e9 4d ff ff ff       	jmp    f0102ba8 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5e:	8d 78 04             	lea    0x4(%eax),%edi
f0102c61:	83 ec 08             	sub    $0x8,%esp
f0102c64:	53                   	push   %ebx
f0102c65:	ff 30                	pushl  (%eax)
f0102c67:	ff d6                	call   *%esi
			break;
f0102c69:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c6c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c72:	e9 fe fe ff ff       	jmp    f0102b75 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c77:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7a:	8d 78 04             	lea    0x4(%eax),%edi
f0102c7d:	8b 00                	mov    (%eax),%eax
f0102c7f:	99                   	cltd   
f0102c80:	31 d0                	xor    %edx,%eax
f0102c82:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c84:	83 f8 07             	cmp    $0x7,%eax
f0102c87:	7f 0b                	jg     f0102c94 <vprintfmt+0x145>
f0102c89:	8b 14 85 60 48 10 f0 	mov    -0xfefb7a0(,%eax,4),%edx
f0102c90:	85 d2                	test   %edx,%edx
f0102c92:	75 1b                	jne    f0102caf <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102c94:	50                   	push   %eax
f0102c95:	68 89 46 10 f0       	push   $0xf0104689
f0102c9a:	53                   	push   %ebx
f0102c9b:	56                   	push   %esi
f0102c9c:	e8 91 fe ff ff       	call   f0102b32 <printfmt>
f0102ca1:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ca4:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ca7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102caa:	e9 c6 fe ff ff       	jmp    f0102b75 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102caf:	52                   	push   %edx
f0102cb0:	68 28 3c 10 f0       	push   $0xf0103c28
f0102cb5:	53                   	push   %ebx
f0102cb6:	56                   	push   %esi
f0102cb7:	e8 76 fe ff ff       	call   f0102b32 <printfmt>
f0102cbc:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cbf:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cc5:	e9 ab fe ff ff       	jmp    f0102b75 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cca:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ccd:	83 c0 04             	add    $0x4,%eax
f0102cd0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102cd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cd8:	85 ff                	test   %edi,%edi
f0102cda:	b8 82 46 10 f0       	mov    $0xf0104682,%eax
f0102cdf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102ce2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ce6:	0f 8e 94 00 00 00    	jle    f0102d80 <vprintfmt+0x231>
f0102cec:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cf0:	0f 84 98 00 00 00    	je     f0102d8e <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf6:	83 ec 08             	sub    $0x8,%esp
f0102cf9:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cfc:	57                   	push   %edi
f0102cfd:	e8 00 04 00 00       	call   f0103102 <strnlen>
f0102d02:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d05:	29 c1                	sub    %eax,%ecx
f0102d07:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d0a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d0d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d11:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d14:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d17:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d19:	eb 0f                	jmp    f0102d2a <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d1b:	83 ec 08             	sub    $0x8,%esp
f0102d1e:	53                   	push   %ebx
f0102d1f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d22:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d24:	83 ef 01             	sub    $0x1,%edi
f0102d27:	83 c4 10             	add    $0x10,%esp
f0102d2a:	85 ff                	test   %edi,%edi
f0102d2c:	7f ed                	jg     f0102d1b <vprintfmt+0x1cc>
f0102d2e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d31:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d34:	85 c9                	test   %ecx,%ecx
f0102d36:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d3b:	0f 49 c1             	cmovns %ecx,%eax
f0102d3e:	29 c1                	sub    %eax,%ecx
f0102d40:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d43:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d46:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d49:	89 cb                	mov    %ecx,%ebx
f0102d4b:	eb 4d                	jmp    f0102d9a <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d4d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d51:	74 1b                	je     f0102d6e <vprintfmt+0x21f>
f0102d53:	0f be c0             	movsbl %al,%eax
f0102d56:	83 e8 20             	sub    $0x20,%eax
f0102d59:	83 f8 5e             	cmp    $0x5e,%eax
f0102d5c:	76 10                	jbe    f0102d6e <vprintfmt+0x21f>
					putch('?', putdat);
f0102d5e:	83 ec 08             	sub    $0x8,%esp
f0102d61:	ff 75 0c             	pushl  0xc(%ebp)
f0102d64:	6a 3f                	push   $0x3f
f0102d66:	ff 55 08             	call   *0x8(%ebp)
f0102d69:	83 c4 10             	add    $0x10,%esp
f0102d6c:	eb 0d                	jmp    f0102d7b <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d6e:	83 ec 08             	sub    $0x8,%esp
f0102d71:	ff 75 0c             	pushl  0xc(%ebp)
f0102d74:	52                   	push   %edx
f0102d75:	ff 55 08             	call   *0x8(%ebp)
f0102d78:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d7b:	83 eb 01             	sub    $0x1,%ebx
f0102d7e:	eb 1a                	jmp    f0102d9a <vprintfmt+0x24b>
f0102d80:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d83:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d86:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d89:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d8c:	eb 0c                	jmp    f0102d9a <vprintfmt+0x24b>
f0102d8e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d91:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d94:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d97:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d9a:	83 c7 01             	add    $0x1,%edi
f0102d9d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102da1:	0f be d0             	movsbl %al,%edx
f0102da4:	85 d2                	test   %edx,%edx
f0102da6:	74 23                	je     f0102dcb <vprintfmt+0x27c>
f0102da8:	85 f6                	test   %esi,%esi
f0102daa:	78 a1                	js     f0102d4d <vprintfmt+0x1fe>
f0102dac:	83 ee 01             	sub    $0x1,%esi
f0102daf:	79 9c                	jns    f0102d4d <vprintfmt+0x1fe>
f0102db1:	89 df                	mov    %ebx,%edi
f0102db3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102db6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db9:	eb 18                	jmp    f0102dd3 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dbb:	83 ec 08             	sub    $0x8,%esp
f0102dbe:	53                   	push   %ebx
f0102dbf:	6a 20                	push   $0x20
f0102dc1:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102dc3:	83 ef 01             	sub    $0x1,%edi
f0102dc6:	83 c4 10             	add    $0x10,%esp
f0102dc9:	eb 08                	jmp    f0102dd3 <vprintfmt+0x284>
f0102dcb:	89 df                	mov    %ebx,%edi
f0102dcd:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dd0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dd3:	85 ff                	test   %edi,%edi
f0102dd5:	7f e4                	jg     f0102dbb <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dd7:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102dda:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ddd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102de0:	e9 90 fd ff ff       	jmp    f0102b75 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102de5:	83 f9 01             	cmp    $0x1,%ecx
f0102de8:	7e 19                	jle    f0102e03 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102dea:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ded:	8b 50 04             	mov    0x4(%eax),%edx
f0102df0:	8b 00                	mov    (%eax),%eax
f0102df2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102df8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dfb:	8d 40 08             	lea    0x8(%eax),%eax
f0102dfe:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e01:	eb 38                	jmp    f0102e3b <vprintfmt+0x2ec>
	else if (lflag)
f0102e03:	85 c9                	test   %ecx,%ecx
f0102e05:	74 1b                	je     f0102e22 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e07:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e0a:	8b 00                	mov    (%eax),%eax
f0102e0c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e0f:	89 c1                	mov    %eax,%ecx
f0102e11:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e14:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1a:	8d 40 04             	lea    0x4(%eax),%eax
f0102e1d:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e20:	eb 19                	jmp    f0102e3b <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e22:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e25:	8b 00                	mov    (%eax),%eax
f0102e27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e2a:	89 c1                	mov    %eax,%ecx
f0102e2c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e2f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e32:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e35:	8d 40 04             	lea    0x4(%eax),%eax
f0102e38:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e3b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e3e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e41:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e46:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e4a:	0f 89 02 01 00 00    	jns    f0102f52 <vprintfmt+0x403>
				putch('-', putdat);
f0102e50:	83 ec 08             	sub    $0x8,%esp
f0102e53:	53                   	push   %ebx
f0102e54:	6a 2d                	push   $0x2d
f0102e56:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e58:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e5b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e5e:	f7 da                	neg    %edx
f0102e60:	83 d1 00             	adc    $0x0,%ecx
f0102e63:	f7 d9                	neg    %ecx
f0102e65:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e68:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e6d:	e9 e0 00 00 00       	jmp    f0102f52 <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e72:	83 f9 01             	cmp    $0x1,%ecx
f0102e75:	7e 18                	jle    f0102e8f <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e77:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e7a:	8b 10                	mov    (%eax),%edx
f0102e7c:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e7f:	8d 40 08             	lea    0x8(%eax),%eax
f0102e82:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e85:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e8a:	e9 c3 00 00 00       	jmp    f0102f52 <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e8f:	85 c9                	test   %ecx,%ecx
f0102e91:	74 1a                	je     f0102ead <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102e93:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e96:	8b 10                	mov    (%eax),%edx
f0102e98:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e9d:	8d 40 04             	lea    0x4(%eax),%eax
f0102ea0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ea3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ea8:	e9 a5 00 00 00       	jmp    f0102f52 <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102ead:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eb0:	8b 10                	mov    (%eax),%edx
f0102eb2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102eb7:	8d 40 04             	lea    0x4(%eax),%eax
f0102eba:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ebd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ec2:	e9 8b 00 00 00       	jmp    f0102f52 <vprintfmt+0x403>
		case 'o':
			// Replace this with your code.
			// putch('0', putdat);
			// putch('X', putdat);
			// putch('X', putdat);
			num = (unsigned long long)
f0102ec7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eca:	8b 10                	mov    (%eax),%edx
f0102ecc:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0102ed1:	8d 40 04             	lea    0x4(%eax),%eax
f0102ed4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102ed7:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102edc:	eb 74                	jmp    f0102f52 <vprintfmt+0x403>
			// break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102ede:	83 ec 08             	sub    $0x8,%esp
f0102ee1:	53                   	push   %ebx
f0102ee2:	6a 30                	push   $0x30
f0102ee4:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ee6:	83 c4 08             	add    $0x8,%esp
f0102ee9:	53                   	push   %ebx
f0102eea:	6a 78                	push   $0x78
f0102eec:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102eee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef1:	8b 10                	mov    (%eax),%edx
f0102ef3:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ef8:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102efb:	8d 40 04             	lea    0x4(%eax),%eax
f0102efe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102f01:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102f06:	eb 4a                	jmp    f0102f52 <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f08:	83 f9 01             	cmp    $0x1,%ecx
f0102f0b:	7e 15                	jle    f0102f22 <vprintfmt+0x3d3>
		return va_arg(*ap, unsigned long long);
f0102f0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f10:	8b 10                	mov    (%eax),%edx
f0102f12:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f15:	8d 40 08             	lea    0x8(%eax),%eax
f0102f18:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f1b:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f20:	eb 30                	jmp    f0102f52 <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f22:	85 c9                	test   %ecx,%ecx
f0102f24:	74 17                	je     f0102f3d <vprintfmt+0x3ee>
		return va_arg(*ap, unsigned long);
f0102f26:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f29:	8b 10                	mov    (%eax),%edx
f0102f2b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f30:	8d 40 04             	lea    0x4(%eax),%eax
f0102f33:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f36:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f3b:	eb 15                	jmp    f0102f52 <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f40:	8b 10                	mov    (%eax),%edx
f0102f42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f47:	8d 40 04             	lea    0x4(%eax),%eax
f0102f4a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f4d:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f52:	83 ec 0c             	sub    $0xc,%esp
f0102f55:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f59:	57                   	push   %edi
f0102f5a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f5d:	50                   	push   %eax
f0102f5e:	51                   	push   %ecx
f0102f5f:	52                   	push   %edx
f0102f60:	89 da                	mov    %ebx,%edx
f0102f62:	89 f0                	mov    %esi,%eax
f0102f64:	e8 fd fa ff ff       	call   f0102a66 <printnum>
			break;
f0102f69:	83 c4 20             	add    $0x20,%esp
f0102f6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f6f:	e9 01 fc ff ff       	jmp    f0102b75 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f74:	83 ec 08             	sub    $0x8,%esp
f0102f77:	53                   	push   %ebx
f0102f78:	52                   	push   %edx
f0102f79:	ff d6                	call   *%esi
			break;
f0102f7b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f81:	e9 ef fb ff ff       	jmp    f0102b75 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f86:	83 ec 08             	sub    $0x8,%esp
f0102f89:	53                   	push   %ebx
f0102f8a:	6a 25                	push   $0x25
f0102f8c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f8e:	83 c4 10             	add    $0x10,%esp
f0102f91:	eb 03                	jmp    f0102f96 <vprintfmt+0x447>
f0102f93:	83 ef 01             	sub    $0x1,%edi
f0102f96:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f9a:	75 f7                	jne    f0102f93 <vprintfmt+0x444>
f0102f9c:	e9 d4 fb ff ff       	jmp    f0102b75 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102fa1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fa4:	5b                   	pop    %ebx
f0102fa5:	5e                   	pop    %esi
f0102fa6:	5f                   	pop    %edi
f0102fa7:	5d                   	pop    %ebp
f0102fa8:	c3                   	ret    

f0102fa9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102fa9:	55                   	push   %ebp
f0102faa:	89 e5                	mov    %esp,%ebp
f0102fac:	83 ec 18             	sub    $0x18,%esp
f0102faf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fb2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fb5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fb8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fbc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fbf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fc6:	85 c0                	test   %eax,%eax
f0102fc8:	74 26                	je     f0102ff0 <vsnprintf+0x47>
f0102fca:	85 d2                	test   %edx,%edx
f0102fcc:	7e 22                	jle    f0102ff0 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fce:	ff 75 14             	pushl  0x14(%ebp)
f0102fd1:	ff 75 10             	pushl  0x10(%ebp)
f0102fd4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fd7:	50                   	push   %eax
f0102fd8:	68 15 2b 10 f0       	push   $0xf0102b15
f0102fdd:	e8 6d fb ff ff       	call   f0102b4f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fe2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fe5:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102feb:	83 c4 10             	add    $0x10,%esp
f0102fee:	eb 05                	jmp    f0102ff5 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102ff0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102ff5:	c9                   	leave  
f0102ff6:	c3                   	ret    

f0102ff7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ff7:	55                   	push   %ebp
f0102ff8:	89 e5                	mov    %esp,%ebp
f0102ffa:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102ffd:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103000:	50                   	push   %eax
f0103001:	ff 75 10             	pushl  0x10(%ebp)
f0103004:	ff 75 0c             	pushl  0xc(%ebp)
f0103007:	ff 75 08             	pushl  0x8(%ebp)
f010300a:	e8 9a ff ff ff       	call   f0102fa9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010300f:	c9                   	leave  
f0103010:	c3                   	ret    

f0103011 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103011:	55                   	push   %ebp
f0103012:	89 e5                	mov    %esp,%ebp
f0103014:	57                   	push   %edi
f0103015:	56                   	push   %esi
f0103016:	53                   	push   %ebx
f0103017:	83 ec 0c             	sub    $0xc,%esp
f010301a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010301d:	85 c0                	test   %eax,%eax
f010301f:	74 11                	je     f0103032 <readline+0x21>
		cprintf("%s", prompt);
f0103021:	83 ec 08             	sub    $0x8,%esp
f0103024:	50                   	push   %eax
f0103025:	68 28 3c 10 f0       	push   $0xf0103c28
f010302a:	e8 ee f6 ff ff       	call   f010271d <cprintf>
f010302f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103032:	83 ec 0c             	sub    $0xc,%esp
f0103035:	6a 00                	push   $0x0
f0103037:	e8 d7 d5 ff ff       	call   f0100613 <iscons>
f010303c:	89 c7                	mov    %eax,%edi
f010303e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103041:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103046:	e8 b7 d5 ff ff       	call   f0100602 <getchar>
f010304b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010304d:	85 c0                	test   %eax,%eax
f010304f:	79 18                	jns    f0103069 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103051:	83 ec 08             	sub    $0x8,%esp
f0103054:	50                   	push   %eax
f0103055:	68 80 48 10 f0       	push   $0xf0104880
f010305a:	e8 be f6 ff ff       	call   f010271d <cprintf>
			return NULL;
f010305f:	83 c4 10             	add    $0x10,%esp
f0103062:	b8 00 00 00 00       	mov    $0x0,%eax
f0103067:	eb 79                	jmp    f01030e2 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103069:	83 f8 08             	cmp    $0x8,%eax
f010306c:	0f 94 c2             	sete   %dl
f010306f:	83 f8 7f             	cmp    $0x7f,%eax
f0103072:	0f 94 c0             	sete   %al
f0103075:	08 c2                	or     %al,%dl
f0103077:	74 1a                	je     f0103093 <readline+0x82>
f0103079:	85 f6                	test   %esi,%esi
f010307b:	7e 16                	jle    f0103093 <readline+0x82>
			if (echoing)
f010307d:	85 ff                	test   %edi,%edi
f010307f:	74 0d                	je     f010308e <readline+0x7d>
				cputchar('\b');
f0103081:	83 ec 0c             	sub    $0xc,%esp
f0103084:	6a 08                	push   $0x8
f0103086:	e8 67 d5 ff ff       	call   f01005f2 <cputchar>
f010308b:	83 c4 10             	add    $0x10,%esp
			i--;
f010308e:	83 ee 01             	sub    $0x1,%esi
f0103091:	eb b3                	jmp    f0103046 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103093:	83 fb 1f             	cmp    $0x1f,%ebx
f0103096:	7e 23                	jle    f01030bb <readline+0xaa>
f0103098:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010309e:	7f 1b                	jg     f01030bb <readline+0xaa>
			if (echoing)
f01030a0:	85 ff                	test   %edi,%edi
f01030a2:	74 0c                	je     f01030b0 <readline+0x9f>
				cputchar(c);
f01030a4:	83 ec 0c             	sub    $0xc,%esp
f01030a7:	53                   	push   %ebx
f01030a8:	e8 45 d5 ff ff       	call   f01005f2 <cputchar>
f01030ad:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030b0:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f01030b6:	8d 76 01             	lea    0x1(%esi),%esi
f01030b9:	eb 8b                	jmp    f0103046 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030bb:	83 fb 0a             	cmp    $0xa,%ebx
f01030be:	74 05                	je     f01030c5 <readline+0xb4>
f01030c0:	83 fb 0d             	cmp    $0xd,%ebx
f01030c3:	75 81                	jne    f0103046 <readline+0x35>
			if (echoing)
f01030c5:	85 ff                	test   %edi,%edi
f01030c7:	74 0d                	je     f01030d6 <readline+0xc5>
				cputchar('\n');
f01030c9:	83 ec 0c             	sub    $0xc,%esp
f01030cc:	6a 0a                	push   $0xa
f01030ce:	e8 1f d5 ff ff       	call   f01005f2 <cputchar>
f01030d3:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030d6:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f01030dd:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f01030e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030e5:	5b                   	pop    %ebx
f01030e6:	5e                   	pop    %esi
f01030e7:	5f                   	pop    %edi
f01030e8:	5d                   	pop    %ebp
f01030e9:	c3                   	ret    

f01030ea <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030ea:	55                   	push   %ebp
f01030eb:	89 e5                	mov    %esp,%ebp
f01030ed:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01030f5:	eb 03                	jmp    f01030fa <strlen+0x10>
		n++;
f01030f7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030fa:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030fe:	75 f7                	jne    f01030f7 <strlen+0xd>
		n++;
	return n;
}
f0103100:	5d                   	pop    %ebp
f0103101:	c3                   	ret    

f0103102 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103102:	55                   	push   %ebp
f0103103:	89 e5                	mov    %esp,%ebp
f0103105:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103108:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010310b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103110:	eb 03                	jmp    f0103115 <strnlen+0x13>
		n++;
f0103112:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103115:	39 c2                	cmp    %eax,%edx
f0103117:	74 08                	je     f0103121 <strnlen+0x1f>
f0103119:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010311d:	75 f3                	jne    f0103112 <strnlen+0x10>
f010311f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103121:	5d                   	pop    %ebp
f0103122:	c3                   	ret    

f0103123 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103123:	55                   	push   %ebp
f0103124:	89 e5                	mov    %esp,%ebp
f0103126:	53                   	push   %ebx
f0103127:	8b 45 08             	mov    0x8(%ebp),%eax
f010312a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010312d:	89 c2                	mov    %eax,%edx
f010312f:	83 c2 01             	add    $0x1,%edx
f0103132:	83 c1 01             	add    $0x1,%ecx
f0103135:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103139:	88 5a ff             	mov    %bl,-0x1(%edx)
f010313c:	84 db                	test   %bl,%bl
f010313e:	75 ef                	jne    f010312f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103140:	5b                   	pop    %ebx
f0103141:	5d                   	pop    %ebp
f0103142:	c3                   	ret    

f0103143 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103143:	55                   	push   %ebp
f0103144:	89 e5                	mov    %esp,%ebp
f0103146:	53                   	push   %ebx
f0103147:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010314a:	53                   	push   %ebx
f010314b:	e8 9a ff ff ff       	call   f01030ea <strlen>
f0103150:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103153:	ff 75 0c             	pushl  0xc(%ebp)
f0103156:	01 d8                	add    %ebx,%eax
f0103158:	50                   	push   %eax
f0103159:	e8 c5 ff ff ff       	call   f0103123 <strcpy>
	return dst;
}
f010315e:	89 d8                	mov    %ebx,%eax
f0103160:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103163:	c9                   	leave  
f0103164:	c3                   	ret    

f0103165 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103165:	55                   	push   %ebp
f0103166:	89 e5                	mov    %esp,%ebp
f0103168:	56                   	push   %esi
f0103169:	53                   	push   %ebx
f010316a:	8b 75 08             	mov    0x8(%ebp),%esi
f010316d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103170:	89 f3                	mov    %esi,%ebx
f0103172:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103175:	89 f2                	mov    %esi,%edx
f0103177:	eb 0f                	jmp    f0103188 <strncpy+0x23>
		*dst++ = *src;
f0103179:	83 c2 01             	add    $0x1,%edx
f010317c:	0f b6 01             	movzbl (%ecx),%eax
f010317f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103182:	80 39 01             	cmpb   $0x1,(%ecx)
f0103185:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103188:	39 da                	cmp    %ebx,%edx
f010318a:	75 ed                	jne    f0103179 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010318c:	89 f0                	mov    %esi,%eax
f010318e:	5b                   	pop    %ebx
f010318f:	5e                   	pop    %esi
f0103190:	5d                   	pop    %ebp
f0103191:	c3                   	ret    

f0103192 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103192:	55                   	push   %ebp
f0103193:	89 e5                	mov    %esp,%ebp
f0103195:	56                   	push   %esi
f0103196:	53                   	push   %ebx
f0103197:	8b 75 08             	mov    0x8(%ebp),%esi
f010319a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010319d:	8b 55 10             	mov    0x10(%ebp),%edx
f01031a0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031a2:	85 d2                	test   %edx,%edx
f01031a4:	74 21                	je     f01031c7 <strlcpy+0x35>
f01031a6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031aa:	89 f2                	mov    %esi,%edx
f01031ac:	eb 09                	jmp    f01031b7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031ae:	83 c2 01             	add    $0x1,%edx
f01031b1:	83 c1 01             	add    $0x1,%ecx
f01031b4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031b7:	39 c2                	cmp    %eax,%edx
f01031b9:	74 09                	je     f01031c4 <strlcpy+0x32>
f01031bb:	0f b6 19             	movzbl (%ecx),%ebx
f01031be:	84 db                	test   %bl,%bl
f01031c0:	75 ec                	jne    f01031ae <strlcpy+0x1c>
f01031c2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031c4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031c7:	29 f0                	sub    %esi,%eax
}
f01031c9:	5b                   	pop    %ebx
f01031ca:	5e                   	pop    %esi
f01031cb:	5d                   	pop    %ebp
f01031cc:	c3                   	ret    

f01031cd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031cd:	55                   	push   %ebp
f01031ce:	89 e5                	mov    %esp,%ebp
f01031d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031d6:	eb 06                	jmp    f01031de <strcmp+0x11>
		p++, q++;
f01031d8:	83 c1 01             	add    $0x1,%ecx
f01031db:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031de:	0f b6 01             	movzbl (%ecx),%eax
f01031e1:	84 c0                	test   %al,%al
f01031e3:	74 04                	je     f01031e9 <strcmp+0x1c>
f01031e5:	3a 02                	cmp    (%edx),%al
f01031e7:	74 ef                	je     f01031d8 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031e9:	0f b6 c0             	movzbl %al,%eax
f01031ec:	0f b6 12             	movzbl (%edx),%edx
f01031ef:	29 d0                	sub    %edx,%eax
}
f01031f1:	5d                   	pop    %ebp
f01031f2:	c3                   	ret    

f01031f3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031f3:	55                   	push   %ebp
f01031f4:	89 e5                	mov    %esp,%ebp
f01031f6:	53                   	push   %ebx
f01031f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031fd:	89 c3                	mov    %eax,%ebx
f01031ff:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103202:	eb 06                	jmp    f010320a <strncmp+0x17>
		n--, p++, q++;
f0103204:	83 c0 01             	add    $0x1,%eax
f0103207:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010320a:	39 d8                	cmp    %ebx,%eax
f010320c:	74 15                	je     f0103223 <strncmp+0x30>
f010320e:	0f b6 08             	movzbl (%eax),%ecx
f0103211:	84 c9                	test   %cl,%cl
f0103213:	74 04                	je     f0103219 <strncmp+0x26>
f0103215:	3a 0a                	cmp    (%edx),%cl
f0103217:	74 eb                	je     f0103204 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103219:	0f b6 00             	movzbl (%eax),%eax
f010321c:	0f b6 12             	movzbl (%edx),%edx
f010321f:	29 d0                	sub    %edx,%eax
f0103221:	eb 05                	jmp    f0103228 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103223:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103228:	5b                   	pop    %ebx
f0103229:	5d                   	pop    %ebp
f010322a:	c3                   	ret    

f010322b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010322b:	55                   	push   %ebp
f010322c:	89 e5                	mov    %esp,%ebp
f010322e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103231:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103235:	eb 07                	jmp    f010323e <strchr+0x13>
		if (*s == c)
f0103237:	38 ca                	cmp    %cl,%dl
f0103239:	74 0f                	je     f010324a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010323b:	83 c0 01             	add    $0x1,%eax
f010323e:	0f b6 10             	movzbl (%eax),%edx
f0103241:	84 d2                	test   %dl,%dl
f0103243:	75 f2                	jne    f0103237 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103245:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010324a:	5d                   	pop    %ebp
f010324b:	c3                   	ret    

f010324c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010324c:	55                   	push   %ebp
f010324d:	89 e5                	mov    %esp,%ebp
f010324f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103252:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103256:	eb 03                	jmp    f010325b <strfind+0xf>
f0103258:	83 c0 01             	add    $0x1,%eax
f010325b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010325e:	38 ca                	cmp    %cl,%dl
f0103260:	74 04                	je     f0103266 <strfind+0x1a>
f0103262:	84 d2                	test   %dl,%dl
f0103264:	75 f2                	jne    f0103258 <strfind+0xc>
			break;
	return (char *) s;
}
f0103266:	5d                   	pop    %ebp
f0103267:	c3                   	ret    

f0103268 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103268:	55                   	push   %ebp
f0103269:	89 e5                	mov    %esp,%ebp
f010326b:	57                   	push   %edi
f010326c:	56                   	push   %esi
f010326d:	53                   	push   %ebx
f010326e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103271:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103274:	85 c9                	test   %ecx,%ecx
f0103276:	74 36                	je     f01032ae <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103278:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010327e:	75 28                	jne    f01032a8 <memset+0x40>
f0103280:	f6 c1 03             	test   $0x3,%cl
f0103283:	75 23                	jne    f01032a8 <memset+0x40>
		c &= 0xFF;
f0103285:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103289:	89 d3                	mov    %edx,%ebx
f010328b:	c1 e3 08             	shl    $0x8,%ebx
f010328e:	89 d6                	mov    %edx,%esi
f0103290:	c1 e6 18             	shl    $0x18,%esi
f0103293:	89 d0                	mov    %edx,%eax
f0103295:	c1 e0 10             	shl    $0x10,%eax
f0103298:	09 f0                	or     %esi,%eax
f010329a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010329c:	89 d8                	mov    %ebx,%eax
f010329e:	09 d0                	or     %edx,%eax
f01032a0:	c1 e9 02             	shr    $0x2,%ecx
f01032a3:	fc                   	cld    
f01032a4:	f3 ab                	rep stos %eax,%es:(%edi)
f01032a6:	eb 06                	jmp    f01032ae <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ab:	fc                   	cld    
f01032ac:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01032ae:	89 f8                	mov    %edi,%eax
f01032b0:	5b                   	pop    %ebx
f01032b1:	5e                   	pop    %esi
f01032b2:	5f                   	pop    %edi
f01032b3:	5d                   	pop    %ebp
f01032b4:	c3                   	ret    

f01032b5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032b5:	55                   	push   %ebp
f01032b6:	89 e5                	mov    %esp,%ebp
f01032b8:	57                   	push   %edi
f01032b9:	56                   	push   %esi
f01032ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01032bd:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032c3:	39 c6                	cmp    %eax,%esi
f01032c5:	73 35                	jae    f01032fc <memmove+0x47>
f01032c7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032ca:	39 d0                	cmp    %edx,%eax
f01032cc:	73 2e                	jae    f01032fc <memmove+0x47>
		s += n;
		d += n;
f01032ce:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032d1:	89 d6                	mov    %edx,%esi
f01032d3:	09 fe                	or     %edi,%esi
f01032d5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032db:	75 13                	jne    f01032f0 <memmove+0x3b>
f01032dd:	f6 c1 03             	test   $0x3,%cl
f01032e0:	75 0e                	jne    f01032f0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032e2:	83 ef 04             	sub    $0x4,%edi
f01032e5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032e8:	c1 e9 02             	shr    $0x2,%ecx
f01032eb:	fd                   	std    
f01032ec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032ee:	eb 09                	jmp    f01032f9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032f0:	83 ef 01             	sub    $0x1,%edi
f01032f3:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032f6:	fd                   	std    
f01032f7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032f9:	fc                   	cld    
f01032fa:	eb 1d                	jmp    f0103319 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032fc:	89 f2                	mov    %esi,%edx
f01032fe:	09 c2                	or     %eax,%edx
f0103300:	f6 c2 03             	test   $0x3,%dl
f0103303:	75 0f                	jne    f0103314 <memmove+0x5f>
f0103305:	f6 c1 03             	test   $0x3,%cl
f0103308:	75 0a                	jne    f0103314 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010330a:	c1 e9 02             	shr    $0x2,%ecx
f010330d:	89 c7                	mov    %eax,%edi
f010330f:	fc                   	cld    
f0103310:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103312:	eb 05                	jmp    f0103319 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103314:	89 c7                	mov    %eax,%edi
f0103316:	fc                   	cld    
f0103317:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103319:	5e                   	pop    %esi
f010331a:	5f                   	pop    %edi
f010331b:	5d                   	pop    %ebp
f010331c:	c3                   	ret    

f010331d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010331d:	55                   	push   %ebp
f010331e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103320:	ff 75 10             	pushl  0x10(%ebp)
f0103323:	ff 75 0c             	pushl  0xc(%ebp)
f0103326:	ff 75 08             	pushl  0x8(%ebp)
f0103329:	e8 87 ff ff ff       	call   f01032b5 <memmove>
}
f010332e:	c9                   	leave  
f010332f:	c3                   	ret    

f0103330 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103330:	55                   	push   %ebp
f0103331:	89 e5                	mov    %esp,%ebp
f0103333:	56                   	push   %esi
f0103334:	53                   	push   %ebx
f0103335:	8b 45 08             	mov    0x8(%ebp),%eax
f0103338:	8b 55 0c             	mov    0xc(%ebp),%edx
f010333b:	89 c6                	mov    %eax,%esi
f010333d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103340:	eb 1a                	jmp    f010335c <memcmp+0x2c>
		if (*s1 != *s2)
f0103342:	0f b6 08             	movzbl (%eax),%ecx
f0103345:	0f b6 1a             	movzbl (%edx),%ebx
f0103348:	38 d9                	cmp    %bl,%cl
f010334a:	74 0a                	je     f0103356 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010334c:	0f b6 c1             	movzbl %cl,%eax
f010334f:	0f b6 db             	movzbl %bl,%ebx
f0103352:	29 d8                	sub    %ebx,%eax
f0103354:	eb 0f                	jmp    f0103365 <memcmp+0x35>
		s1++, s2++;
f0103356:	83 c0 01             	add    $0x1,%eax
f0103359:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010335c:	39 f0                	cmp    %esi,%eax
f010335e:	75 e2                	jne    f0103342 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103360:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103365:	5b                   	pop    %ebx
f0103366:	5e                   	pop    %esi
f0103367:	5d                   	pop    %ebp
f0103368:	c3                   	ret    

f0103369 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103369:	55                   	push   %ebp
f010336a:	89 e5                	mov    %esp,%ebp
f010336c:	53                   	push   %ebx
f010336d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103370:	89 c1                	mov    %eax,%ecx
f0103372:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103375:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103379:	eb 0a                	jmp    f0103385 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010337b:	0f b6 10             	movzbl (%eax),%edx
f010337e:	39 da                	cmp    %ebx,%edx
f0103380:	74 07                	je     f0103389 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103382:	83 c0 01             	add    $0x1,%eax
f0103385:	39 c8                	cmp    %ecx,%eax
f0103387:	72 f2                	jb     f010337b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103389:	5b                   	pop    %ebx
f010338a:	5d                   	pop    %ebp
f010338b:	c3                   	ret    

f010338c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010338c:	55                   	push   %ebp
f010338d:	89 e5                	mov    %esp,%ebp
f010338f:	57                   	push   %edi
f0103390:	56                   	push   %esi
f0103391:	53                   	push   %ebx
f0103392:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103395:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103398:	eb 03                	jmp    f010339d <strtol+0x11>
		s++;
f010339a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010339d:	0f b6 01             	movzbl (%ecx),%eax
f01033a0:	3c 20                	cmp    $0x20,%al
f01033a2:	74 f6                	je     f010339a <strtol+0xe>
f01033a4:	3c 09                	cmp    $0x9,%al
f01033a6:	74 f2                	je     f010339a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033a8:	3c 2b                	cmp    $0x2b,%al
f01033aa:	75 0a                	jne    f01033b6 <strtol+0x2a>
		s++;
f01033ac:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033af:	bf 00 00 00 00       	mov    $0x0,%edi
f01033b4:	eb 11                	jmp    f01033c7 <strtol+0x3b>
f01033b6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033bb:	3c 2d                	cmp    $0x2d,%al
f01033bd:	75 08                	jne    f01033c7 <strtol+0x3b>
		s++, neg = 1;
f01033bf:	83 c1 01             	add    $0x1,%ecx
f01033c2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033c7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033cd:	75 15                	jne    f01033e4 <strtol+0x58>
f01033cf:	80 39 30             	cmpb   $0x30,(%ecx)
f01033d2:	75 10                	jne    f01033e4 <strtol+0x58>
f01033d4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033d8:	75 7c                	jne    f0103456 <strtol+0xca>
		s += 2, base = 16;
f01033da:	83 c1 02             	add    $0x2,%ecx
f01033dd:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033e2:	eb 16                	jmp    f01033fa <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033e4:	85 db                	test   %ebx,%ebx
f01033e6:	75 12                	jne    f01033fa <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033e8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033ed:	80 39 30             	cmpb   $0x30,(%ecx)
f01033f0:	75 08                	jne    f01033fa <strtol+0x6e>
		s++, base = 8;
f01033f2:	83 c1 01             	add    $0x1,%ecx
f01033f5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01033ff:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103402:	0f b6 11             	movzbl (%ecx),%edx
f0103405:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103408:	89 f3                	mov    %esi,%ebx
f010340a:	80 fb 09             	cmp    $0x9,%bl
f010340d:	77 08                	ja     f0103417 <strtol+0x8b>
			dig = *s - '0';
f010340f:	0f be d2             	movsbl %dl,%edx
f0103412:	83 ea 30             	sub    $0x30,%edx
f0103415:	eb 22                	jmp    f0103439 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103417:	8d 72 9f             	lea    -0x61(%edx),%esi
f010341a:	89 f3                	mov    %esi,%ebx
f010341c:	80 fb 19             	cmp    $0x19,%bl
f010341f:	77 08                	ja     f0103429 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103421:	0f be d2             	movsbl %dl,%edx
f0103424:	83 ea 57             	sub    $0x57,%edx
f0103427:	eb 10                	jmp    f0103439 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103429:	8d 72 bf             	lea    -0x41(%edx),%esi
f010342c:	89 f3                	mov    %esi,%ebx
f010342e:	80 fb 19             	cmp    $0x19,%bl
f0103431:	77 16                	ja     f0103449 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103433:	0f be d2             	movsbl %dl,%edx
f0103436:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103439:	3b 55 10             	cmp    0x10(%ebp),%edx
f010343c:	7d 0b                	jge    f0103449 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010343e:	83 c1 01             	add    $0x1,%ecx
f0103441:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103445:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103447:	eb b9                	jmp    f0103402 <strtol+0x76>

	if (endptr)
f0103449:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010344d:	74 0d                	je     f010345c <strtol+0xd0>
		*endptr = (char *) s;
f010344f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103452:	89 0e                	mov    %ecx,(%esi)
f0103454:	eb 06                	jmp    f010345c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103456:	85 db                	test   %ebx,%ebx
f0103458:	74 98                	je     f01033f2 <strtol+0x66>
f010345a:	eb 9e                	jmp    f01033fa <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010345c:	89 c2                	mov    %eax,%edx
f010345e:	f7 da                	neg    %edx
f0103460:	85 ff                	test   %edi,%edi
f0103462:	0f 45 c2             	cmovne %edx,%eax
}
f0103465:	5b                   	pop    %ebx
f0103466:	5e                   	pop    %esi
f0103467:	5f                   	pop    %edi
f0103468:	5d                   	pop    %ebp
f0103469:	c3                   	ret    
f010346a:	66 90                	xchg   %ax,%ax
f010346c:	66 90                	xchg   %ax,%ax
f010346e:	66 90                	xchg   %ax,%ax

f0103470 <__udivdi3>:
f0103470:	55                   	push   %ebp
f0103471:	57                   	push   %edi
f0103472:	56                   	push   %esi
f0103473:	53                   	push   %ebx
f0103474:	83 ec 1c             	sub    $0x1c,%esp
f0103477:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010347b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010347f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103483:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103487:	85 f6                	test   %esi,%esi
f0103489:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010348d:	89 ca                	mov    %ecx,%edx
f010348f:	89 f8                	mov    %edi,%eax
f0103491:	75 3d                	jne    f01034d0 <__udivdi3+0x60>
f0103493:	39 cf                	cmp    %ecx,%edi
f0103495:	0f 87 c5 00 00 00    	ja     f0103560 <__udivdi3+0xf0>
f010349b:	85 ff                	test   %edi,%edi
f010349d:	89 fd                	mov    %edi,%ebp
f010349f:	75 0b                	jne    f01034ac <__udivdi3+0x3c>
f01034a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034a6:	31 d2                	xor    %edx,%edx
f01034a8:	f7 f7                	div    %edi
f01034aa:	89 c5                	mov    %eax,%ebp
f01034ac:	89 c8                	mov    %ecx,%eax
f01034ae:	31 d2                	xor    %edx,%edx
f01034b0:	f7 f5                	div    %ebp
f01034b2:	89 c1                	mov    %eax,%ecx
f01034b4:	89 d8                	mov    %ebx,%eax
f01034b6:	89 cf                	mov    %ecx,%edi
f01034b8:	f7 f5                	div    %ebp
f01034ba:	89 c3                	mov    %eax,%ebx
f01034bc:	89 d8                	mov    %ebx,%eax
f01034be:	89 fa                	mov    %edi,%edx
f01034c0:	83 c4 1c             	add    $0x1c,%esp
f01034c3:	5b                   	pop    %ebx
f01034c4:	5e                   	pop    %esi
f01034c5:	5f                   	pop    %edi
f01034c6:	5d                   	pop    %ebp
f01034c7:	c3                   	ret    
f01034c8:	90                   	nop
f01034c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034d0:	39 ce                	cmp    %ecx,%esi
f01034d2:	77 74                	ja     f0103548 <__udivdi3+0xd8>
f01034d4:	0f bd fe             	bsr    %esi,%edi
f01034d7:	83 f7 1f             	xor    $0x1f,%edi
f01034da:	0f 84 98 00 00 00    	je     f0103578 <__udivdi3+0x108>
f01034e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034e5:	89 f9                	mov    %edi,%ecx
f01034e7:	89 c5                	mov    %eax,%ebp
f01034e9:	29 fb                	sub    %edi,%ebx
f01034eb:	d3 e6                	shl    %cl,%esi
f01034ed:	89 d9                	mov    %ebx,%ecx
f01034ef:	d3 ed                	shr    %cl,%ebp
f01034f1:	89 f9                	mov    %edi,%ecx
f01034f3:	d3 e0                	shl    %cl,%eax
f01034f5:	09 ee                	or     %ebp,%esi
f01034f7:	89 d9                	mov    %ebx,%ecx
f01034f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034fd:	89 d5                	mov    %edx,%ebp
f01034ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103503:	d3 ed                	shr    %cl,%ebp
f0103505:	89 f9                	mov    %edi,%ecx
f0103507:	d3 e2                	shl    %cl,%edx
f0103509:	89 d9                	mov    %ebx,%ecx
f010350b:	d3 e8                	shr    %cl,%eax
f010350d:	09 c2                	or     %eax,%edx
f010350f:	89 d0                	mov    %edx,%eax
f0103511:	89 ea                	mov    %ebp,%edx
f0103513:	f7 f6                	div    %esi
f0103515:	89 d5                	mov    %edx,%ebp
f0103517:	89 c3                	mov    %eax,%ebx
f0103519:	f7 64 24 0c          	mull   0xc(%esp)
f010351d:	39 d5                	cmp    %edx,%ebp
f010351f:	72 10                	jb     f0103531 <__udivdi3+0xc1>
f0103521:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103525:	89 f9                	mov    %edi,%ecx
f0103527:	d3 e6                	shl    %cl,%esi
f0103529:	39 c6                	cmp    %eax,%esi
f010352b:	73 07                	jae    f0103534 <__udivdi3+0xc4>
f010352d:	39 d5                	cmp    %edx,%ebp
f010352f:	75 03                	jne    f0103534 <__udivdi3+0xc4>
f0103531:	83 eb 01             	sub    $0x1,%ebx
f0103534:	31 ff                	xor    %edi,%edi
f0103536:	89 d8                	mov    %ebx,%eax
f0103538:	89 fa                	mov    %edi,%edx
f010353a:	83 c4 1c             	add    $0x1c,%esp
f010353d:	5b                   	pop    %ebx
f010353e:	5e                   	pop    %esi
f010353f:	5f                   	pop    %edi
f0103540:	5d                   	pop    %ebp
f0103541:	c3                   	ret    
f0103542:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103548:	31 ff                	xor    %edi,%edi
f010354a:	31 db                	xor    %ebx,%ebx
f010354c:	89 d8                	mov    %ebx,%eax
f010354e:	89 fa                	mov    %edi,%edx
f0103550:	83 c4 1c             	add    $0x1c,%esp
f0103553:	5b                   	pop    %ebx
f0103554:	5e                   	pop    %esi
f0103555:	5f                   	pop    %edi
f0103556:	5d                   	pop    %ebp
f0103557:	c3                   	ret    
f0103558:	90                   	nop
f0103559:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103560:	89 d8                	mov    %ebx,%eax
f0103562:	f7 f7                	div    %edi
f0103564:	31 ff                	xor    %edi,%edi
f0103566:	89 c3                	mov    %eax,%ebx
f0103568:	89 d8                	mov    %ebx,%eax
f010356a:	89 fa                	mov    %edi,%edx
f010356c:	83 c4 1c             	add    $0x1c,%esp
f010356f:	5b                   	pop    %ebx
f0103570:	5e                   	pop    %esi
f0103571:	5f                   	pop    %edi
f0103572:	5d                   	pop    %ebp
f0103573:	c3                   	ret    
f0103574:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103578:	39 ce                	cmp    %ecx,%esi
f010357a:	72 0c                	jb     f0103588 <__udivdi3+0x118>
f010357c:	31 db                	xor    %ebx,%ebx
f010357e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103582:	0f 87 34 ff ff ff    	ja     f01034bc <__udivdi3+0x4c>
f0103588:	bb 01 00 00 00       	mov    $0x1,%ebx
f010358d:	e9 2a ff ff ff       	jmp    f01034bc <__udivdi3+0x4c>
f0103592:	66 90                	xchg   %ax,%ax
f0103594:	66 90                	xchg   %ax,%ax
f0103596:	66 90                	xchg   %ax,%ax
f0103598:	66 90                	xchg   %ax,%ax
f010359a:	66 90                	xchg   %ax,%ax
f010359c:	66 90                	xchg   %ax,%ax
f010359e:	66 90                	xchg   %ax,%ax

f01035a0 <__umoddi3>:
f01035a0:	55                   	push   %ebp
f01035a1:	57                   	push   %edi
f01035a2:	56                   	push   %esi
f01035a3:	53                   	push   %ebx
f01035a4:	83 ec 1c             	sub    $0x1c,%esp
f01035a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035b7:	85 d2                	test   %edx,%edx
f01035b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035c1:	89 f3                	mov    %esi,%ebx
f01035c3:	89 3c 24             	mov    %edi,(%esp)
f01035c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035ca:	75 1c                	jne    f01035e8 <__umoddi3+0x48>
f01035cc:	39 f7                	cmp    %esi,%edi
f01035ce:	76 50                	jbe    f0103620 <__umoddi3+0x80>
f01035d0:	89 c8                	mov    %ecx,%eax
f01035d2:	89 f2                	mov    %esi,%edx
f01035d4:	f7 f7                	div    %edi
f01035d6:	89 d0                	mov    %edx,%eax
f01035d8:	31 d2                	xor    %edx,%edx
f01035da:	83 c4 1c             	add    $0x1c,%esp
f01035dd:	5b                   	pop    %ebx
f01035de:	5e                   	pop    %esi
f01035df:	5f                   	pop    %edi
f01035e0:	5d                   	pop    %ebp
f01035e1:	c3                   	ret    
f01035e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035e8:	39 f2                	cmp    %esi,%edx
f01035ea:	89 d0                	mov    %edx,%eax
f01035ec:	77 52                	ja     f0103640 <__umoddi3+0xa0>
f01035ee:	0f bd ea             	bsr    %edx,%ebp
f01035f1:	83 f5 1f             	xor    $0x1f,%ebp
f01035f4:	75 5a                	jne    f0103650 <__umoddi3+0xb0>
f01035f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035fa:	0f 82 e0 00 00 00    	jb     f01036e0 <__umoddi3+0x140>
f0103600:	39 0c 24             	cmp    %ecx,(%esp)
f0103603:	0f 86 d7 00 00 00    	jbe    f01036e0 <__umoddi3+0x140>
f0103609:	8b 44 24 08          	mov    0x8(%esp),%eax
f010360d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103611:	83 c4 1c             	add    $0x1c,%esp
f0103614:	5b                   	pop    %ebx
f0103615:	5e                   	pop    %esi
f0103616:	5f                   	pop    %edi
f0103617:	5d                   	pop    %ebp
f0103618:	c3                   	ret    
f0103619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103620:	85 ff                	test   %edi,%edi
f0103622:	89 fd                	mov    %edi,%ebp
f0103624:	75 0b                	jne    f0103631 <__umoddi3+0x91>
f0103626:	b8 01 00 00 00       	mov    $0x1,%eax
f010362b:	31 d2                	xor    %edx,%edx
f010362d:	f7 f7                	div    %edi
f010362f:	89 c5                	mov    %eax,%ebp
f0103631:	89 f0                	mov    %esi,%eax
f0103633:	31 d2                	xor    %edx,%edx
f0103635:	f7 f5                	div    %ebp
f0103637:	89 c8                	mov    %ecx,%eax
f0103639:	f7 f5                	div    %ebp
f010363b:	89 d0                	mov    %edx,%eax
f010363d:	eb 99                	jmp    f01035d8 <__umoddi3+0x38>
f010363f:	90                   	nop
f0103640:	89 c8                	mov    %ecx,%eax
f0103642:	89 f2                	mov    %esi,%edx
f0103644:	83 c4 1c             	add    $0x1c,%esp
f0103647:	5b                   	pop    %ebx
f0103648:	5e                   	pop    %esi
f0103649:	5f                   	pop    %edi
f010364a:	5d                   	pop    %ebp
f010364b:	c3                   	ret    
f010364c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103650:	8b 34 24             	mov    (%esp),%esi
f0103653:	bf 20 00 00 00       	mov    $0x20,%edi
f0103658:	89 e9                	mov    %ebp,%ecx
f010365a:	29 ef                	sub    %ebp,%edi
f010365c:	d3 e0                	shl    %cl,%eax
f010365e:	89 f9                	mov    %edi,%ecx
f0103660:	89 f2                	mov    %esi,%edx
f0103662:	d3 ea                	shr    %cl,%edx
f0103664:	89 e9                	mov    %ebp,%ecx
f0103666:	09 c2                	or     %eax,%edx
f0103668:	89 d8                	mov    %ebx,%eax
f010366a:	89 14 24             	mov    %edx,(%esp)
f010366d:	89 f2                	mov    %esi,%edx
f010366f:	d3 e2                	shl    %cl,%edx
f0103671:	89 f9                	mov    %edi,%ecx
f0103673:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103677:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010367b:	d3 e8                	shr    %cl,%eax
f010367d:	89 e9                	mov    %ebp,%ecx
f010367f:	89 c6                	mov    %eax,%esi
f0103681:	d3 e3                	shl    %cl,%ebx
f0103683:	89 f9                	mov    %edi,%ecx
f0103685:	89 d0                	mov    %edx,%eax
f0103687:	d3 e8                	shr    %cl,%eax
f0103689:	89 e9                	mov    %ebp,%ecx
f010368b:	09 d8                	or     %ebx,%eax
f010368d:	89 d3                	mov    %edx,%ebx
f010368f:	89 f2                	mov    %esi,%edx
f0103691:	f7 34 24             	divl   (%esp)
f0103694:	89 d6                	mov    %edx,%esi
f0103696:	d3 e3                	shl    %cl,%ebx
f0103698:	f7 64 24 04          	mull   0x4(%esp)
f010369c:	39 d6                	cmp    %edx,%esi
f010369e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036a2:	89 d1                	mov    %edx,%ecx
f01036a4:	89 c3                	mov    %eax,%ebx
f01036a6:	72 08                	jb     f01036b0 <__umoddi3+0x110>
f01036a8:	75 11                	jne    f01036bb <__umoddi3+0x11b>
f01036aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036ae:	73 0b                	jae    f01036bb <__umoddi3+0x11b>
f01036b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036b4:	1b 14 24             	sbb    (%esp),%edx
f01036b7:	89 d1                	mov    %edx,%ecx
f01036b9:	89 c3                	mov    %eax,%ebx
f01036bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036bf:	29 da                	sub    %ebx,%edx
f01036c1:	19 ce                	sbb    %ecx,%esi
f01036c3:	89 f9                	mov    %edi,%ecx
f01036c5:	89 f0                	mov    %esi,%eax
f01036c7:	d3 e0                	shl    %cl,%eax
f01036c9:	89 e9                	mov    %ebp,%ecx
f01036cb:	d3 ea                	shr    %cl,%edx
f01036cd:	89 e9                	mov    %ebp,%ecx
f01036cf:	d3 ee                	shr    %cl,%esi
f01036d1:	09 d0                	or     %edx,%eax
f01036d3:	89 f2                	mov    %esi,%edx
f01036d5:	83 c4 1c             	add    $0x1c,%esp
f01036d8:	5b                   	pop    %ebx
f01036d9:	5e                   	pop    %esi
f01036da:	5f                   	pop    %edi
f01036db:	5d                   	pop    %ebp
f01036dc:	c3                   	ret    
f01036dd:	8d 76 00             	lea    0x0(%esi),%esi
f01036e0:	29 f9                	sub    %edi,%ecx
f01036e2:	19 d6                	sbb    %edx,%esi
f01036e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036ec:	e9 18 ff ff ff       	jmp    f0103609 <__umoddi3+0x69>
