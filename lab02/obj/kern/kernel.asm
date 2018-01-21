
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 63 32 00 00       	call   f01032c0 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 37 10 f0       	push   $0xf0103760
f010006f:	e8 01 27 00 00       	call   f0102775 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 3a 10 00 00       	call   f01010b3 <mem_init>
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
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

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
f01000b0:	68 7b 37 10 f0       	push   $0xf010377b
f01000b5:	e8 bb 26 00 00       	call   f0102775 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 8b 26 00 00       	call   f010274f <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 4a 3f 10 f0 	movl   $0xf0103f4a,(%esp)
f01000cb:	e8 a5 26 00 00       	call   f0102775 <cprintf>
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
f01000f2:	68 93 37 10 f0       	push   $0xf0103793
f01000f7:	e8 79 26 00 00       	call   f0102775 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 47 26 00 00       	call   f010274f <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 4a 3f 10 f0 	movl   $0xf0103f4a,(%esp)
f010010f:	e8 61 26 00 00       	call   f0102775 <cprintf>
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
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
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
f0100198:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
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
f01001b0:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a 00 38 10 f0 	movzbl -0xfefc800(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d e0 37 10 f0 	mov    -0xfefc820(,%ecx,4),%ecx
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
f0100260:	68 ad 37 10 f0       	push   $0xf01037ad
f0100265:	e8 0b 25 00 00       	call   f0102775 <cprintf>
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
f0100346:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01003d0:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 fa 2e 00 00       	call   f010330d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
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
f0100434:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
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
f0100472:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
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
f01004b0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004b5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004c6:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
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
f01004d7:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
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
f0100510:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
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
f0100528:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
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
f0100537:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
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
f010055c:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01005c8:	0f 95 05 34 75 11 f0 	setne  0xf0117534
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
f01005dd:	68 b9 37 10 f0       	push   $0xf01037b9
f01005e2:	e8 8e 21 00 00       	call   f0102775 <cprintf>
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
f0100623:	68 00 3a 10 f0       	push   $0xf0103a00
f0100628:	68 1e 3a 10 f0       	push   $0xf0103a1e
f010062d:	68 23 3a 10 f0       	push   $0xf0103a23
f0100632:	e8 3e 21 00 00       	call   f0102775 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 d0 3a 10 f0       	push   $0xf0103ad0
f010063f:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100644:	68 23 3a 10 f0       	push   $0xf0103a23
f0100649:	e8 27 21 00 00       	call   f0102775 <cprintf>
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
f010065b:	68 35 3a 10 f0       	push   $0xf0103a35
f0100660:	e8 10 21 00 00       	call   f0102775 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 f8 3a 10 f0       	push   $0xf0103af8
f0100672:	e8 fe 20 00 00       	call   f0102775 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 20 3b 10 f0       	push   $0xf0103b20
f0100689:	e8 e7 20 00 00       	call   f0102775 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 51 37 10 00       	push   $0x103751
f0100696:	68 51 37 10 f0       	push   $0xf0103751
f010069b:	68 44 3b 10 f0       	push   $0xf0103b44
f01006a0:	e8 d0 20 00 00       	call   f0102775 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 73 11 00       	push   $0x117300
f01006ad:	68 00 73 11 f0       	push   $0xf0117300
f01006b2:	68 68 3b 10 f0       	push   $0xf0103b68
f01006b7:	e8 b9 20 00 00       	call   f0102775 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 79 11 00       	push   $0x117970
f01006c4:	68 70 79 11 f0       	push   $0xf0117970
f01006c9:	68 8c 3b 10 f0       	push   $0xf0103b8c
f01006ce:	e8 a2 20 00 00       	call   f0102775 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
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
f01006f4:	68 b0 3b 10 f0       	push   $0xf0103bb0
f01006f9:	e8 77 20 00 00       	call   f0102775 <cprintf>
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
f0100710:	68 4e 3a 10 f0       	push   $0xf0103a4e
f0100715:	e8 5b 20 00 00       	call   f0102775 <cprintf>
	while (ebp) {
f010071a:	83 c4 10             	add    $0x10,%esp
f010071d:	eb 67                	jmp    f0100786 <mon_backtrace+0x81>
	    cprintf(" ebp %08x eip %08x args", ebp, ebp[1]);
f010071f:	83 ec 04             	sub    $0x4,%esp
f0100722:	ff 76 04             	pushl  0x4(%esi)
f0100725:	56                   	push   %esi
f0100726:	68 60 3a 10 f0       	push   $0xf0103a60
f010072b:	e8 45 20 00 00       	call   f0102775 <cprintf>
f0100730:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100733:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100736:	83 c4 10             	add    $0x10,%esp
	    for (int j = 2; j != 7; ++j) {
		cprintf(" %08x", ebp[j]);   
f0100739:	83 ec 08             	sub    $0x8,%esp
f010073c:	ff 33                	pushl  (%ebx)
f010073e:	68 78 3a 10 f0       	push   $0xf0103a78
f0100743:	e8 2d 20 00 00       	call   f0102775 <cprintf>
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
f010075c:	e8 1e 21 00 00       	call   f010287f <debuginfo_eip>
	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	8b 46 04             	mov    0x4(%esi),%eax
f0100767:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010076a:	50                   	push   %eax
f010076b:	ff 75 d8             	pushl  -0x28(%ebp)
f010076e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100771:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100774:	ff 75 d0             	pushl  -0x30(%ebp)
f0100777:	68 7e 3a 10 f0       	push   $0xf0103a7e
f010077c:	e8 f4 1f 00 00       	call   f0102775 <cprintf>
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
f01007a0:	68 dc 3b 10 f0       	push   $0xf0103bdc
f01007a5:	e8 cb 1f 00 00       	call   f0102775 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007aa:	c7 04 24 00 3c 10 f0 	movl   $0xf0103c00,(%esp)
f01007b1:	e8 bf 1f 00 00       	call   f0102775 <cprintf>
f01007b6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b9:	83 ec 0c             	sub    $0xc,%esp
f01007bc:	68 94 3a 10 f0       	push   $0xf0103a94
f01007c1:	e8 a3 28 00 00       	call   f0103069 <readline>
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
f01007f5:	68 98 3a 10 f0       	push   $0xf0103a98
f01007fa:	e8 84 2a 00 00       	call   f0103283 <strchr>
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
f0100815:	68 9d 3a 10 f0       	push   $0xf0103a9d
f010081a:	e8 56 1f 00 00       	call   f0102775 <cprintf>
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
f010083e:	68 98 3a 10 f0       	push   $0xf0103a98
f0100843:	e8 3b 2a 00 00       	call   f0103283 <strchr>
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
f0100864:	68 1e 3a 10 f0       	push   $0xf0103a1e
f0100869:	ff 75 a8             	pushl  -0x58(%ebp)
f010086c:	e8 b4 29 00 00       	call   f0103225 <strcmp>
f0100871:	83 c4 10             	add    $0x10,%esp
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 1e                	je     f0100896 <monitor+0xff>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100880:	ff 75 a8             	pushl  -0x58(%ebp)
f0100883:	e8 9d 29 00 00       	call   f0103225 <strcmp>
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
f01008ab:	ff 14 85 30 3c 10 f0 	call   *-0xfefc3d0(,%eax,4)


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
f01008c4:	68 ba 3a 10 f0       	push   $0xf0103aba
f01008c9:	e8 a7 1e 00 00       	call   f0102775 <cprintf>
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
f01008e5:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01008ec:	75 11                	jne    f01008ff <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ee:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f01008f3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008f9:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	//#define KERNBASE 0xF0000000
	//#define PGSIZE 4096
	result = nextfree;
f01008ff:	8b 1d 38 75 11 f0    	mov    0xf0117538,%ebx
	nextfree = ROUNDUP(nextfree+n,PGSIZE);
f0100905:	8d 8c 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%ecx
f010090c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100912:	89 0d 38 75 11 f0    	mov    %ecx,0xf0117538
	if((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)){
f0100918:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010091d:	8d 90 00 00 0f 00    	lea    0xf0000(%eax),%edx
f0100923:	c1 e2 0c             	shl    $0xc,%edx
f0100926:	39 d1                	cmp    %edx,%ecx
f0100928:	76 14                	jbe    f010093e <boot_alloc+0x60>
		panic("Out of memory\n");
f010092a:	83 ec 04             	sub    $0x4,%esp
f010092d:	68 40 3c 10 f0       	push   $0xf0103c40
f0100932:	6a 6a                	push   $0x6a
f0100934:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100939:	e8 4d f7 ff ff       	call   f010008b <_panic>
	}
	return result;
}
f010093e:	89 d8                	mov    %ebx,%eax
f0100940:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100943:	c9                   	leave  
f0100944:	c3                   	ret    

f0100945 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100945:	89 d1                	mov    %edx,%ecx
f0100947:	c1 e9 16             	shr    $0x16,%ecx
f010094a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010094d:	a8 01                	test   $0x1,%al
f010094f:	74 52                	je     f01009a3 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100951:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100956:	89 c1                	mov    %eax,%ecx
f0100958:	c1 e9 0c             	shr    $0xc,%ecx
f010095b:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100961:	72 1b                	jb     f010097e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100963:	55                   	push   %ebp
f0100964:	89 e5                	mov    %esp,%ebp
f0100966:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100969:	50                   	push   %eax
f010096a:	68 7c 3f 10 f0       	push   $0xf0103f7c
f010096f:	68 01 03 00 00       	push   $0x301
f0100974:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100979:	e8 0d f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010097e:	c1 ea 0c             	shr    $0xc,%edx
f0100981:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100987:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010098e:	89 c2                	mov    %eax,%edx
f0100990:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100993:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100998:	85 d2                	test   %edx,%edx
f010099a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010099f:	0f 44 c2             	cmove  %edx,%eax
f01009a2:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a8:	c3                   	ret    

f01009a9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009a9:	55                   	push   %ebp
f01009aa:	89 e5                	mov    %esp,%ebp
f01009ac:	57                   	push   %edi
f01009ad:	56                   	push   %esi
f01009ae:	53                   	push   %ebx
f01009af:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009b2:	84 c0                	test   %al,%al
f01009b4:	0f 85 81 02 00 00    	jne    f0100c3b <check_page_free_list+0x292>
f01009ba:	e9 8e 02 00 00       	jmp    f0100c4d <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009bf:	83 ec 04             	sub    $0x4,%esp
f01009c2:	68 a0 3f 10 f0       	push   $0xf0103fa0
f01009c7:	68 43 02 00 00       	push   $0x243
f01009cc:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01009d1:	e8 b5 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009d6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009d9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009dc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009df:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009e2:	89 c2                	mov    %eax,%edx
f01009e4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01009ea:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009f0:	0f 95 c2             	setne  %dl
f01009f3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009f6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009fa:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009fc:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a00:	8b 00                	mov    (%eax),%eax
f0100a02:	85 c0                	test   %eax,%eax
f0100a04:	75 dc                	jne    f01009e2 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a09:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a12:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a15:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a17:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a1a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a1f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a24:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a2a:	eb 53                	jmp    f0100a7f <check_page_free_list+0xd6>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2c:	89 d8                	mov    %ebx,%eax
f0100a2e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a34:	c1 f8 03             	sar    $0x3,%eax
f0100a37:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a3a:	89 c2                	mov    %eax,%edx
f0100a3c:	c1 ea 16             	shr    $0x16,%edx
f0100a3f:	39 f2                	cmp    %esi,%edx
f0100a41:	73 3a                	jae    f0100a7d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a43:	89 c2                	mov    %eax,%edx
f0100a45:	c1 ea 0c             	shr    $0xc,%edx
f0100a48:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a4e:	72 12                	jb     f0100a62 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a50:	50                   	push   %eax
f0100a51:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100a56:	6a 59                	push   $0x59
f0100a58:	68 5b 3c 10 f0       	push   $0xf0103c5b
f0100a5d:	e8 29 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a62:	83 ec 04             	sub    $0x4,%esp
f0100a65:	68 80 00 00 00       	push   $0x80
f0100a6a:	68 97 00 00 00       	push   $0x97
f0100a6f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a74:	50                   	push   %eax
f0100a75:	e8 46 28 00 00       	call   f01032c0 <memset>
f0100a7a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a7d:	8b 1b                	mov    (%ebx),%ebx
f0100a7f:	85 db                	test   %ebx,%ebx
f0100a81:	75 a9                	jne    f0100a2c <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a83:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a88:	e8 51 fe ff ff       	call   f01008de <boot_alloc>
f0100a8d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a90:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a96:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100a9c:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100aa1:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100aa4:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aaa:	be 00 00 00 00       	mov    $0x0,%esi
f0100aaf:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab2:	e9 30 01 00 00       	jmp    f0100be7 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab7:	39 ca                	cmp    %ecx,%edx
f0100ab9:	73 19                	jae    f0100ad4 <check_page_free_list+0x12b>
f0100abb:	68 69 3c 10 f0       	push   $0xf0103c69
f0100ac0:	68 75 3c 10 f0       	push   $0xf0103c75
f0100ac5:	68 5d 02 00 00       	push   $0x25d
f0100aca:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100acf:	e8 b7 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ad4:	39 fa                	cmp    %edi,%edx
f0100ad6:	72 19                	jb     f0100af1 <check_page_free_list+0x148>
f0100ad8:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100add:	68 75 3c 10 f0       	push   $0xf0103c75
f0100ae2:	68 5e 02 00 00       	push   $0x25e
f0100ae7:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100aec:	e8 9a f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100af1:	89 d0                	mov    %edx,%eax
f0100af3:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100af6:	a8 07                	test   $0x7,%al
f0100af8:	74 19                	je     f0100b13 <check_page_free_list+0x16a>
f0100afa:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0100aff:	68 75 3c 10 f0       	push   $0xf0103c75
f0100b04:	68 5f 02 00 00       	push   $0x25f
f0100b09:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100b0e:	e8 78 f5 ff ff       	call   f010008b <_panic>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b13:	c1 f8 03             	sar    $0x3,%eax
f0100b16:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b19:	85 c0                	test   %eax,%eax
f0100b1b:	75 19                	jne    f0100b36 <check_page_free_list+0x18d>
f0100b1d:	68 9e 3c 10 f0       	push   $0xf0103c9e
f0100b22:	68 75 3c 10 f0       	push   $0xf0103c75
f0100b27:	68 62 02 00 00       	push   $0x262
f0100b2c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100b31:	e8 55 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b36:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b3b:	75 19                	jne    f0100b56 <check_page_free_list+0x1ad>
f0100b3d:	68 af 3c 10 f0       	push   $0xf0103caf
f0100b42:	68 75 3c 10 f0       	push   $0xf0103c75
f0100b47:	68 63 02 00 00       	push   $0x263
f0100b4c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100b51:	e8 35 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b56:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b5b:	75 19                	jne    f0100b76 <check_page_free_list+0x1cd>
f0100b5d:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0100b62:	68 75 3c 10 f0       	push   $0xf0103c75
f0100b67:	68 64 02 00 00       	push   $0x264
f0100b6c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100b71:	e8 15 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b76:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b7b:	75 19                	jne    f0100b96 <check_page_free_list+0x1ed>
f0100b7d:	68 c8 3c 10 f0       	push   $0xf0103cc8
f0100b82:	68 75 3c 10 f0       	push   $0xf0103c75
f0100b87:	68 65 02 00 00       	push   $0x265
f0100b8c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100b91:	e8 f5 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b96:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b9b:	76 3f                	jbe    f0100bdc <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9d:	89 c3                	mov    %eax,%ebx
f0100b9f:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba2:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba5:	77 12                	ja     f0100bb9 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba7:	50                   	push   %eax
f0100ba8:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100bad:	6a 59                	push   $0x59
f0100baf:	68 5b 3c 10 f0       	push   $0xf0103c5b
f0100bb4:	e8 d2 f4 ff ff       	call   f010008b <_panic>
f0100bb9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bbe:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bc1:	76 1e                	jbe    f0100be1 <check_page_free_list+0x238>
f0100bc3:	68 1c 40 10 f0       	push   $0xf010401c
f0100bc8:	68 75 3c 10 f0       	push   $0xf0103c75
f0100bcd:	68 66 02 00 00       	push   $0x266
f0100bd2:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100bd7:	e8 af f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bdc:	83 c6 01             	add    $0x1,%esi
f0100bdf:	eb 04                	jmp    f0100be5 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100be1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be5:	8b 12                	mov    (%edx),%edx
f0100be7:	85 d2                	test   %edx,%edx
f0100be9:	0f 85 c8 fe ff ff    	jne    f0100ab7 <check_page_free_list+0x10e>
f0100bef:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bf2:	85 f6                	test   %esi,%esi
f0100bf4:	7f 19                	jg     f0100c0f <check_page_free_list+0x266>
f0100bf6:	68 e2 3c 10 f0       	push   $0xf0103ce2
f0100bfb:	68 75 3c 10 f0       	push   $0xf0103c75
f0100c00:	68 6e 02 00 00       	push   $0x26e
f0100c05:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100c0a:	e8 7c f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c0f:	85 db                	test   %ebx,%ebx
f0100c11:	7f 19                	jg     f0100c2c <check_page_free_list+0x283>
f0100c13:	68 f4 3c 10 f0       	push   $0xf0103cf4
f0100c18:	68 75 3c 10 f0       	push   $0xf0103c75
f0100c1d:	68 6f 02 00 00       	push   $0x26f
f0100c22:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100c27:	e8 5f f4 ff ff       	call   f010008b <_panic>
	cprintf("check_page_free_list done\n");
f0100c2c:	83 ec 0c             	sub    $0xc,%esp
f0100c2f:	68 05 3d 10 f0       	push   $0xf0103d05
f0100c34:	e8 3c 1b 00 00       	call   f0102775 <cprintf>
}
f0100c39:	eb 29                	jmp    f0100c64 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c3b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c40:	85 c0                	test   %eax,%eax
f0100c42:	0f 85 8e fd ff ff    	jne    f01009d6 <check_page_free_list+0x2d>
f0100c48:	e9 72 fd ff ff       	jmp    f01009bf <check_page_free_list+0x16>
f0100c4d:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c54:	0f 84 65 fd ff ff    	je     f01009bf <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c5a:	be 00 04 00 00       	mov    $0x400,%esi
f0100c5f:	e9 c0 fd ff ff       	jmp    f0100a24 <check_page_free_list+0x7b>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list done\n");
}
f0100c64:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c67:	5b                   	pop    %ebx
f0100c68:	5e                   	pop    %esi
f0100c69:	5f                   	pop    %edi
f0100c6a:	5d                   	pop    %ebp
f0100c6b:	c3                   	ret    

f0100c6c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)  //error01
{
f0100c6c:	55                   	push   %ebp
f0100c6d:	89 e5                	mov    %esp,%ebp
f0100c6f:	56                   	push   %esi
f0100c70:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	// base memory is the first 640k of the memory on IBM PC or compatible system
	// #define IOPHYSMEM 0xA0000, #define EXTPHYSMEM 0x100000
	size_t i;
	page_free_list = NULL;
f0100c71:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0100c78:	00 00 00 
	for(i=0; i<npages; i++){
f0100c7b:	be 00 00 00 00       	mov    $0x0,%esi
f0100c80:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c85:	e9 d5 00 00 00       	jmp    f0100d5f <page_init+0xf3>
		if(i == 0){
f0100c8a:	85 db                	test   %ebx,%ebx
f0100c8c:	75 10                	jne    f0100c9e <page_init+0x32>
			pages[i].pp_ref = 1;
f0100c8e:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100c93:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0100c99:	e9 bb 00 00 00       	jmp    f0100d59 <page_init+0xed>
		} else if(i < npages_basemem){
f0100c9e:	3b 1d 40 75 11 f0    	cmp    0xf0117540,%ebx
f0100ca4:	73 28                	jae    f0100cce <page_init+0x62>
			pages[i].pp_ref = 0;
f0100ca6:	89 f0                	mov    %esi,%eax
f0100ca8:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cae:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100cb4:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100cba:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100cbc:	89 f0                	mov    %esi,%eax
f0100cbe:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cc4:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100cc9:	e9 8b 00 00 00       	jmp    f0100d59 <page_init+0xed>
		} else if(IOPHYSMEM / PGSIZE <= i && i < EXTPHYSMEM / PGSIZE){
f0100cce:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cd4:	83 f8 5f             	cmp    $0x5f,%eax
f0100cd7:	77 0e                	ja     f0100ce7 <page_init+0x7b>
			pages[i].pp_ref = 1;
f0100cd9:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100cde:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
f0100ce5:	eb 72                	jmp    f0100d59 <page_init+0xed>
		} else if(EXTPHYSMEM / PGSIZE <= i && i < PADDR(boot_alloc(0))/PGSIZE){
f0100ce7:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100ced:	76 47                	jbe    f0100d36 <page_init+0xca>
f0100cef:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cf4:	e8 e5 fb ff ff       	call   f01008de <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cf9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cfe:	77 15                	ja     f0100d15 <page_init+0xa9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d00:	50                   	push   %eax
f0100d01:	68 64 40 10 f0       	push   $0xf0104064
f0100d06:	68 1c 01 00 00       	push   $0x11c
f0100d0b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100d10:	e8 76 f3 ff ff       	call   f010008b <_panic>
f0100d15:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d1a:	c1 e8 0c             	shr    $0xc,%eax
f0100d1d:	39 c3                	cmp    %eax,%ebx
f0100d1f:	73 15                	jae    f0100d36 <page_init+0xca>
			pages[i].pp_ref++;
f0100d21:	89 f0                	mov    %esi,%eax
f0100d23:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d29:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100d2e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d34:	eb 23                	jmp    f0100d59 <page_init+0xed>
		} else {
			pages[i].pp_ref = 0;
f0100d36:	89 f0                	mov    %esi,%eax
f0100d38:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d3e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d44:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d4a:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d4c:	89 f0                	mov    %esi,%eax
f0100d4e:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d54:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// free pages!
	// base memory is the first 640k of the memory on IBM PC or compatible system
	// #define IOPHYSMEM 0xA0000, #define EXTPHYSMEM 0x100000
	size_t i;
	page_free_list = NULL;
	for(i=0; i<npages; i++){
f0100d59:	83 c3 01             	add    $0x1,%ebx
f0100d5c:	83 c6 08             	add    $0x8,%esi
f0100d5f:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100d65:	0f 82 1f ff ff ff    	jb     f0100c8a <page_init+0x1e>
			page_free_list = &pages[i];
		}
	}


}
f0100d6b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d6e:	5b                   	pop    %ebx
f0100d6f:	5e                   	pop    %esi
f0100d70:	5d                   	pop    %ebp
f0100d71:	c3                   	ret    

f0100d72 <page_alloc>:
//
// Hint: use page2kva and memset
// Both page_alloc and page_free, page_init are about the operation of linked list;
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d72:	55                   	push   %ebp
f0100d73:	89 e5                	mov    %esp,%ebp
f0100d75:	53                   	push   %ebx
f0100d76:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo *pg;
	if(page_free_list == NULL){
f0100d79:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d7f:	85 db                	test   %ebx,%ebx
f0100d81:	74 58                	je     f0100ddb <page_alloc+0x69>
		return NULL;
	}
	pg = page_free_list;
	page_free_list = pg->pp_link;
f0100d83:	8b 03                	mov    (%ebx),%eax
f0100d85:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pg->pp_link = NULL;
f0100d8a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO){
f0100d90:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d94:	74 45                	je     f0100ddb <page_alloc+0x69>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d96:	89 d8                	mov    %ebx,%eax
f0100d98:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d9e:	c1 f8 03             	sar    $0x3,%eax
f0100da1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da4:	89 c2                	mov    %eax,%edx
f0100da6:	c1 ea 0c             	shr    $0xc,%edx
f0100da9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100daf:	72 12                	jb     f0100dc3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db1:	50                   	push   %eax
f0100db2:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100db7:	6a 59                	push   $0x59
f0100db9:	68 5b 3c 10 f0       	push   $0xf0103c5b
f0100dbe:	e8 c8 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(pg), 0, PGSIZE);
f0100dc3:	83 ec 04             	sub    $0x4,%esp
f0100dc6:	68 00 10 00 00       	push   $0x1000
f0100dcb:	6a 00                	push   $0x0
f0100dcd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dd2:	50                   	push   %eax
f0100dd3:	e8 e8 24 00 00       	call   f01032c0 <memset>
f0100dd8:	83 c4 10             	add    $0x10,%esp
	}
	return pg;
}
f0100ddb:	89 d8                	mov    %ebx,%eax
f0100ddd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de0:	c9                   	leave  
f0100de1:	c3                   	ret    

f0100de2 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100de2:	55                   	push   %ebp
f0100de3:	89 e5                	mov    %esp,%ebp
f0100de5:	83 ec 08             	sub    $0x8,%esp
f0100de8:	8b 45 08             	mov    0x8(%ebp),%eax
	//Fill this function in
	//Hint : You may want to panic if pp->pp_ref is 
	//nonzero of pp->pp_link is not NULL
	assert(pp->pp_ref == 0);
f0100deb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100df0:	74 19                	je     f0100e0b <page_free+0x29>
f0100df2:	68 20 3d 10 f0       	push   $0xf0103d20
f0100df7:	68 75 3c 10 f0       	push   $0xf0103c75
f0100dfc:	68 4c 01 00 00       	push   $0x14c
f0100e01:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100e06:	e8 80 f2 ff ff       	call   f010008b <_panic>
	assert(pp->pp_link == NULL);
f0100e0b:	83 38 00             	cmpl   $0x0,(%eax)
f0100e0e:	74 19                	je     f0100e29 <page_free+0x47>
f0100e10:	68 30 3d 10 f0       	push   $0xf0103d30
f0100e15:	68 75 3c 10 f0       	push   $0xf0103c75
f0100e1a:	68 4d 01 00 00       	push   $0x14d
f0100e1f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100e24:	e8 62 f2 ff ff       	call   f010008b <_panic>
	

	pp->pp_link = page_free_list;
f0100e29:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e2f:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;	
f0100e31:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e36:	c9                   	leave  
f0100e37:	c3                   	ret    

f0100e38 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e38:	55                   	push   %ebp
f0100e39:	89 e5                	mov    %esp,%ebp
f0100e3b:	83 ec 08             	sub    $0x8,%esp
f0100e3e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e41:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e45:	83 e8 01             	sub    $0x1,%eax
f0100e48:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e4c:	66 85 c0             	test   %ax,%ax
f0100e4f:	75 0c                	jne    f0100e5d <page_decref+0x25>
		page_free(pp);
f0100e51:	83 ec 0c             	sub    $0xc,%esp
f0100e54:	52                   	push   %edx
f0100e55:	e8 88 ff ff ff       	call   f0100de2 <page_free>
f0100e5a:	83 c4 10             	add    $0x10,%esp
}
f0100e5d:	c9                   	leave  
f0100e5e:	c3                   	ret    

f0100e5f <pgdir_walk>:
 * page2pa(struct PageInfo* pp) --> map a struct PageInfo* to the corresponding physical address
 * 
 */
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e5f:	55                   	push   %ebp
f0100e60:	89 e5                	mov    %esp,%ebp
f0100e62:	56                   	push   %esi
f0100e63:	53                   	push   %ebx
f0100e64:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	uint32_t dic_off = PDX(va);
	uint32_t tab_off = PTX(va);
f0100e67:	89 de                	mov    %ebx,%esi
f0100e69:	c1 ee 0c             	shr    $0xc,%esi
f0100e6c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t* page_base = NULL;
	struct PageInfo* new_page = NULL;
	pte_t* dic_entry_ptr = pgdir + dic_off;
f0100e72:	c1 eb 16             	shr    $0x16,%ebx
f0100e75:	c1 e3 02             	shl    $0x2,%ebx
f0100e78:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*dic_entry_ptr & PTE_P)){ //if the corresponding page dictory entry not exist
f0100e7b:	f6 03 01             	testb  $0x1,(%ebx)
f0100e7e:	75 2d                	jne    f0100ead <pgdir_walk+0x4e>
		if(create){
f0100e80:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e84:	74 59                	je     f0100edf <pgdir_walk+0x80>
			new_page = page_alloc(1);
f0100e86:	83 ec 0c             	sub    $0xc,%esp
f0100e89:	6a 01                	push   $0x1
f0100e8b:	e8 e2 fe ff ff       	call   f0100d72 <page_alloc>
			if(new_page == NULL){ //if failed
f0100e90:	83 c4 10             	add    $0x10,%esp
f0100e93:	85 c0                	test   %eax,%eax
f0100e95:	74 4f                	je     f0100ee6 <pgdir_walk+0x87>
				return NULL;
			}
			new_page->pp_ref++;
f0100e97:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100e9c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ea2:	c1 f8 03             	sar    $0x3,%eax
f0100ea5:	c1 e0 0c             	shl    $0xc,%eax
f0100ea8:	83 c8 07             	or     $0x7,%eax
f0100eab:	89 03                	mov    %eax,(%ebx)
	//
	/* (inc/mmu.h)#define PTE_ADDR(pte) ((physadd_t) (pte) & ~0xFF) -> Address in page table or page directory entry
	 * (kern/pmap.h)#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa) -> take a physical address, return the 
	 * corresponding kernel virtual address.
	 */
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100ead:	8b 03                	mov    (%ebx),%eax
f0100eaf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb4:	89 c2                	mov    %eax,%edx
f0100eb6:	c1 ea 0c             	shr    $0xc,%edx
f0100eb9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ebf:	72 15                	jb     f0100ed6 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec1:	50                   	push   %eax
f0100ec2:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100ec7:	68 9a 01 00 00       	push   $0x19a
f0100ecc:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100ed1:	e8 b5 f1 ff ff       	call   f010008b <_panic>
	return &page_base[tab_off];
f0100ed6:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100edd:	eb 0c                	jmp    f0100eeb <pgdir_walk+0x8c>
			if(new_page == NULL){ //if failed
				return NULL;
			}
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		} else return NULL;
f0100edf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee4:	eb 05                	jmp    f0100eeb <pgdir_walk+0x8c>
	pte_t* dic_entry_ptr = pgdir + dic_off;
	if(!(*dic_entry_ptr & PTE_P)){ //if the corresponding page dictory entry not exist
		if(create){
			new_page = page_alloc(1);
			if(new_page == NULL){ //if failed
				return NULL;
f0100ee6:	b8 00 00 00 00       	mov    $0x0,%eax
	 * (kern/pmap.h)#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa) -> take a physical address, return the 
	 * corresponding kernel virtual address.
	 */
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[tab_off];
}
f0100eeb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100eee:	5b                   	pop    %ebx
f0100eef:	5e                   	pop    %esi
f0100ef0:	5d                   	pop    %ebp
f0100ef1:	c3                   	ret    

f0100ef2 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ef2:	55                   	push   %ebp
f0100ef3:	89 e5                	mov    %esp,%ebp
f0100ef5:	57                   	push   %edi
f0100ef6:	56                   	push   %esi
f0100ef7:	53                   	push   %ebx
f0100ef8:	83 ec 20             	sub    $0x20,%esp
f0100efb:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100efe:	89 d6                	mov    %edx,%esi
f0100f00:	89 cb                	mov    %ecx,%ebx
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f0100f02:	ff 75 08             	pushl  0x8(%ebp)
f0100f05:	52                   	push   %edx
f0100f06:	68 88 40 10 f0       	push   $0xf0104088
f0100f0b:	e8 65 18 00 00       	call   f0102775 <cprintf>
f0100f10:	c1 eb 0c             	shr    $0xc,%ebx
f0100f13:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	for(i = 0; i < size/PGSIZE; i++, pa+=PGSIZE, va+=PGSIZE){
f0100f16:	83 c4 10             	add    $0x10,%esp
f0100f19:	89 f3                	mov    %esi,%ebx
f0100f1b:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f20:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f23:	29 f0                	sub    %esi,%eax
f0100f25:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(void*)va, 1);
		if(!pte) {
			panic("boot_map_region panic, out of memory");
		}
		*pte = pa | perm | PTE_P;
f0100f28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f2b:	83 c8 01             	or     $0x1,%eax
f0100f2e:	89 45 d8             	mov    %eax,-0x28(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(i = 0; i < size/PGSIZE; i++, pa+=PGSIZE, va+=PGSIZE){
f0100f31:	eb 3a                	jmp    f0100f6d <boot_map_region+0x7b>
		pte_t* pte = pgdir_walk(pgdir,(void*)va, 1);
f0100f33:	83 ec 04             	sub    $0x4,%esp
f0100f36:	6a 01                	push   $0x1
f0100f38:	53                   	push   %ebx
f0100f39:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f3c:	e8 1e ff ff ff       	call   f0100e5f <pgdir_walk>
		if(!pte) {
f0100f41:	83 c4 10             	add    $0x10,%esp
f0100f44:	85 c0                	test   %eax,%eax
f0100f46:	75 17                	jne    f0100f5f <boot_map_region+0x6d>
			panic("boot_map_region panic, out of memory");
f0100f48:	83 ec 04             	sub    $0x4,%esp
f0100f4b:	68 bc 40 10 f0       	push   $0xf01040bc
f0100f50:	68 b0 01 00 00       	push   $0x1b0
f0100f55:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0100f5a:	e8 2c f1 ff ff       	call   f010008b <_panic>
		}
		*pte = pa | perm | PTE_P;
f0100f5f:	0b 75 d8             	or     -0x28(%ebp),%esi
f0100f62:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(i = 0; i < size/PGSIZE; i++, pa+=PGSIZE, va+=PGSIZE){
f0100f64:	83 c7 01             	add    $0x1,%edi
f0100f67:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f6d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f70:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f0100f73:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100f76:	75 bb                	jne    f0100f33 <boot_map_region+0x41>
		if(!pte) {
			panic("boot_map_region panic, out of memory");
		}
		*pte = pa | perm | PTE_P;
	}
	cprintf("Virtual Address %x mapped to Physical memory %x\n", va, pa);
f0100f78:	83 ec 04             	sub    $0x4,%esp
f0100f7b:	56                   	push   %esi
f0100f7c:	53                   	push   %ebx
f0100f7d:	68 e4 40 10 f0       	push   $0xf01040e4
f0100f82:	e8 ee 17 00 00       	call   f0102775 <cprintf>
}
f0100f87:	83 c4 10             	add    $0x10,%esp
f0100f8a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f8d:	5b                   	pop    %ebx
f0100f8e:	5e                   	pop    %esi
f0100f8f:	5f                   	pop    %edi
f0100f90:	5d                   	pop    %ebp
f0100f91:	c3                   	ret    

f0100f92 <page_lookup>:
 *
 */
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store) //error 02
{
f0100f92:	55                   	push   %ebp
f0100f93:	89 e5                	mov    %esp,%ebp
f0100f95:	53                   	push   %ebx
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte = pgdir_walk(pgdir, va, 0); // not create
f0100f9c:	6a 00                	push   $0x0
f0100f9e:	ff 75 0c             	pushl  0xc(%ebp)
f0100fa1:	ff 75 08             	pushl  0x8(%ebp)
f0100fa4:	e8 b6 fe ff ff       	call   f0100e5f <pgdir_walk>
	if(!(pte) || !(*pte & PTE_P)){
f0100fa9:	83 c4 10             	add    $0x10,%esp
f0100fac:	85 c0                	test   %eax,%eax
f0100fae:	74 37                	je     f0100fe7 <page_lookup+0x55>
f0100fb0:	f6 00 01             	testb  $0x1,(%eax)
f0100fb3:	74 39                	je     f0100fee <page_lookup+0x5c>
		return NULL;
	} 
	if(pte_store){
f0100fb5:	85 db                	test   %ebx,%ebx
f0100fb7:	74 02                	je     f0100fbb <page_lookup+0x29>
		*pte_store = pte;
f0100fb9:	89 03                	mov    %eax,(%ebx)

//return the element of pages[] that contains physical address 'pa'
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fbb:	8b 00                	mov    (%eax),%eax
f0100fbd:	c1 e8 0c             	shr    $0xc,%eax
f0100fc0:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fc6:	72 14                	jb     f0100fdc <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100fc8:	83 ec 04             	sub    $0x4,%esp
f0100fcb:	68 18 41 10 f0       	push   $0xf0104118
f0100fd0:	6a 4f                	push   $0x4f
f0100fd2:	68 5b 3c 10 f0       	push   $0xf0103c5b
f0100fd7:	e8 af f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fdc:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100fe2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	/*
	 * return a Page pointer, points va corresponding Physical page
	 */
	return pa2page(PTE_ADDR(*pte));
f0100fe5:	eb 0c                	jmp    f0100ff3 <page_lookup+0x61>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store) //error 02
{
	pte_t* pte = pgdir_walk(pgdir, va, 0); // not create
	if(!(pte) || !(*pte & PTE_P)){
		return NULL;
f0100fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fec:	eb 05                	jmp    f0100ff3 <page_lookup+0x61>
f0100fee:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	/*
	 * return a Page pointer, points va corresponding Physical page
	 */
	return pa2page(PTE_ADDR(*pte));
}
f0100ff3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ff6:	c9                   	leave  
f0100ff7:	c3                   	ret    

f0100ff8 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va) //error 03
{
f0100ff8:	55                   	push   %ebp
f0100ff9:	89 e5                	mov    %esp,%ebp
f0100ffb:	53                   	push   %ebx
f0100ffc:	83 ec 18             	sub    $0x18,%esp
f0100fff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo* pg = page_lookup(pgdir, va, &pte); //search
f0101002:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101005:	50                   	push   %eax
f0101006:	53                   	push   %ebx
f0101007:	ff 75 08             	pushl  0x8(%ebp)
f010100a:	e8 83 ff ff ff       	call   f0100f92 <page_lookup>
	if(!pg || !(*pte & PTE_P)){		// not exist, return
f010100f:	83 c4 10             	add    $0x10,%esp
f0101012:	85 c0                	test   %eax,%eax
f0101014:	74 20                	je     f0101036 <page_remove+0x3e>
f0101016:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101019:	f6 02 01             	testb  $0x1,(%edx)
f010101c:	74 18                	je     f0101036 <page_remove+0x3e>
		return;
	}
	page_decref(pg);			//decrease pg
f010101e:	83 ec 0c             	sub    $0xc,%esp
f0101021:	50                   	push   %eax
f0101022:	e8 11 fe ff ff       	call   f0100e38 <page_decref>
	*pte = 0;				// set page table entry 0
f0101027:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010102a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101030:	0f 01 3b             	invlpg (%ebx)
f0101033:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir ,va);		// TLB invalidate
}
f0101036:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101039:	c9                   	leave  
f010103a:	c3                   	ret    

f010103b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010103b:	55                   	push   %ebp
f010103c:	89 e5                	mov    %esp,%ebp
f010103e:	57                   	push   %edi
f010103f:	56                   	push   %esi
f0101040:	53                   	push   %ebx
f0101041:	83 ec 10             	sub    $0x10,%esp
f0101044:	8b 75 08             	mov    0x8(%ebp),%esi
f0101047:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = NULL;
	pte = pgdir_walk(pgdir, va, 1); //return va corresponding pte pointer
f010104a:	6a 01                	push   $0x1
f010104c:	ff 75 10             	pushl  0x10(%ebp)
f010104f:	56                   	push   %esi
f0101050:	e8 0a fe ff ff       	call   f0100e5f <pgdir_walk>
	if(pte == NULL){		//if failed to create
f0101055:	83 c4 10             	add    $0x10,%esp
f0101058:	85 c0                	test   %eax,%eax
f010105a:	74 4a                	je     f01010a6 <page_insert+0x6b>
f010105c:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f010105e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*pte) & PTE_P){		// already mapped
f0101063:	f6 00 01             	testb  $0x1,(%eax)
f0101066:	74 15                	je     f010107d <page_insert+0x42>
f0101068:	8b 45 10             	mov    0x10(%ebp),%eax
f010106b:	0f 01 38             	invlpg (%eax)
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f010106e:	83 ec 08             	sub    $0x8,%esp
f0101071:	ff 75 10             	pushl  0x10(%ebp)
f0101074:	56                   	push   %esi
f0101075:	e8 7e ff ff ff       	call   f0100ff8 <page_remove>
f010107a:	83 c4 10             	add    $0x10,%esp
	}
	*pte = (page2pa(pp) | perm | PTE_P); //PageInfo *pp assigned *pte
f010107d:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f0101083:	c1 fb 03             	sar    $0x3,%ebx
f0101086:	c1 e3 0c             	shl    $0xc,%ebx
f0101089:	8b 45 14             	mov    0x14(%ebp),%eax
f010108c:	83 c8 01             	or     $0x1,%eax
f010108f:	09 c3                	or     %eax,%ebx
f0101091:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;
f0101093:	8b 45 10             	mov    0x10(%ebp),%eax
f0101096:	c1 e8 16             	shr    $0x16,%eax
f0101099:	8b 55 14             	mov    0x14(%ebp),%edx
f010109c:	09 14 86             	or     %edx,(%esi,%eax,4)

	return 0;
f010109f:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a4:	eb 05                	jmp    f01010ab <page_insert+0x70>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte = NULL;
	pte = pgdir_walk(pgdir, va, 1); //return va corresponding pte pointer
	if(pte == NULL){		//if failed to create
		return -E_NO_MEM;
f01010a6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = (page2pa(pp) | perm | PTE_P); //PageInfo *pp assigned *pte
	pgdir[PDX(va)] |= perm;

	return 0;
}
f01010ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ae:	5b                   	pop    %ebx
f01010af:	5e                   	pop    %esi
f01010b0:	5f                   	pop    %edi
f01010b1:	5d                   	pop    %ebp
f01010b2:	c3                   	ret    

f01010b3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010b3:	55                   	push   %ebp
f01010b4:	89 e5                	mov    %esp,%ebp
f01010b6:	57                   	push   %edi
f01010b7:	56                   	push   %esi
f01010b8:	53                   	push   %ebx
f01010b9:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010bc:	6a 15                	push   $0x15
f01010be:	e8 4b 16 00 00       	call   f010270e <mc146818_read>
f01010c3:	89 c3                	mov    %eax,%ebx
f01010c5:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010cc:	e8 3d 16 00 00       	call   f010270e <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010d1:	c1 e0 08             	shl    $0x8,%eax
f01010d4:	09 d8                	or     %ebx,%eax
f01010d6:	c1 e0 0a             	shl    $0xa,%eax
f01010d9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010df:	85 c0                	test   %eax,%eax
f01010e1:	0f 48 c2             	cmovs  %edx,%eax
f01010e4:	c1 f8 0c             	sar    $0xc,%eax
f01010e7:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010ec:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010f3:	e8 16 16 00 00       	call   f010270e <mc146818_read>
f01010f8:	89 c3                	mov    %eax,%ebx
f01010fa:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101101:	e8 08 16 00 00       	call   f010270e <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101106:	c1 e0 08             	shl    $0x8,%eax
f0101109:	09 d8                	or     %ebx,%eax
f010110b:	c1 e0 0a             	shl    $0xa,%eax
f010110e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101114:	83 c4 10             	add    $0x10,%esp
f0101117:	85 c0                	test   %eax,%eax
f0101119:	0f 48 c2             	cmovs  %edx,%eax
f010111c:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010111f:	85 c0                	test   %eax,%eax
f0101121:	74 0e                	je     f0101131 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101123:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101129:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f010112f:	eb 0c                	jmp    f010113d <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101131:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0101137:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010113d:	c1 e0 0c             	shl    $0xc,%eax
f0101140:	c1 e8 0a             	shr    $0xa,%eax
f0101143:	50                   	push   %eax
f0101144:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101149:	c1 e0 0c             	shl    $0xc,%eax
f010114c:	c1 e8 0a             	shr    $0xa,%eax
f010114f:	50                   	push   %eax
f0101150:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101155:	c1 e0 0c             	shl    $0xc,%eax
f0101158:	c1 e8 0a             	shr    $0xa,%eax
f010115b:	50                   	push   %eax
f010115c:	68 38 41 10 f0       	push   $0xf0104138
f0101161:	e8 0f 16 00 00       	call   f0102775 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101166:	b8 00 10 00 00       	mov    $0x1000,%eax
f010116b:	e8 6e f7 ff ff       	call   f01008de <boot_alloc>
f0101170:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101175:	83 c4 0c             	add    $0xc,%esp
f0101178:	68 00 10 00 00       	push   $0x1000
f010117d:	6a 00                	push   $0x0
f010117f:	50                   	push   %eax
f0101180:	e8 3b 21 00 00       	call   f01032c0 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101185:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010118a:	83 c4 10             	add    $0x10,%esp
f010118d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101192:	77 15                	ja     f01011a9 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101194:	50                   	push   %eax
f0101195:	68 64 40 10 f0       	push   $0xf0104064
f010119a:	68 91 00 00 00       	push   $0x91
f010119f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01011a4:	e8 e2 ee ff ff       	call   f010008b <_panic>
f01011a9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011af:	83 ca 05             	or     $0x5,%edx
f01011b2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01011b8:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01011bd:	c1 e0 03             	shl    $0x3,%eax
f01011c0:	e8 19 f7 ff ff       	call   f01008de <boot_alloc>
f01011c5:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01011ca:	83 ec 04             	sub    $0x4,%esp
f01011cd:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01011d3:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011da:	52                   	push   %edx
f01011db:	6a 00                	push   $0x0
f01011dd:	50                   	push   %eax
f01011de:	e8 dd 20 00 00       	call   f01032c0 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011e3:	e8 84 fa ff ff       	call   f0100c6c <page_init>

	check_page_free_list(1);
f01011e8:	b8 01 00 00 00       	mov    $0x1,%eax
f01011ed:	e8 b7 f7 ff ff       	call   f01009a9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011f2:	83 c4 10             	add    $0x10,%esp
f01011f5:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01011fc:	75 17                	jne    f0101215 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01011fe:	83 ec 04             	sub    $0x4,%esp
f0101201:	68 44 3d 10 f0       	push   $0xf0103d44
f0101206:	68 81 02 00 00       	push   $0x281
f010120b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101210:	e8 76 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101215:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010121a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010121f:	eb 05                	jmp    f0101226 <mem_init+0x173>
		++nfree;
f0101221:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101224:	8b 00                	mov    (%eax),%eax
f0101226:	85 c0                	test   %eax,%eax
f0101228:	75 f7                	jne    f0101221 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010122a:	83 ec 0c             	sub    $0xc,%esp
f010122d:	6a 00                	push   $0x0
f010122f:	e8 3e fb ff ff       	call   f0100d72 <page_alloc>
f0101234:	89 c7                	mov    %eax,%edi
f0101236:	83 c4 10             	add    $0x10,%esp
f0101239:	85 c0                	test   %eax,%eax
f010123b:	75 19                	jne    f0101256 <mem_init+0x1a3>
f010123d:	68 5f 3d 10 f0       	push   $0xf0103d5f
f0101242:	68 75 3c 10 f0       	push   $0xf0103c75
f0101247:	68 89 02 00 00       	push   $0x289
f010124c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101251:	e8 35 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101256:	83 ec 0c             	sub    $0xc,%esp
f0101259:	6a 00                	push   $0x0
f010125b:	e8 12 fb ff ff       	call   f0100d72 <page_alloc>
f0101260:	89 c6                	mov    %eax,%esi
f0101262:	83 c4 10             	add    $0x10,%esp
f0101265:	85 c0                	test   %eax,%eax
f0101267:	75 19                	jne    f0101282 <mem_init+0x1cf>
f0101269:	68 75 3d 10 f0       	push   $0xf0103d75
f010126e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101273:	68 8a 02 00 00       	push   $0x28a
f0101278:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010127d:	e8 09 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101282:	83 ec 0c             	sub    $0xc,%esp
f0101285:	6a 00                	push   $0x0
f0101287:	e8 e6 fa ff ff       	call   f0100d72 <page_alloc>
f010128c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010128f:	83 c4 10             	add    $0x10,%esp
f0101292:	85 c0                	test   %eax,%eax
f0101294:	75 19                	jne    f01012af <mem_init+0x1fc>
f0101296:	68 8b 3d 10 f0       	push   $0xf0103d8b
f010129b:	68 75 3c 10 f0       	push   $0xf0103c75
f01012a0:	68 8b 02 00 00       	push   $0x28b
f01012a5:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01012aa:	e8 dc ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012af:	39 f7                	cmp    %esi,%edi
f01012b1:	75 19                	jne    f01012cc <mem_init+0x219>
f01012b3:	68 a1 3d 10 f0       	push   $0xf0103da1
f01012b8:	68 75 3c 10 f0       	push   $0xf0103c75
f01012bd:	68 8e 02 00 00       	push   $0x28e
f01012c2:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01012c7:	e8 bf ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012cf:	39 c6                	cmp    %eax,%esi
f01012d1:	74 04                	je     f01012d7 <mem_init+0x224>
f01012d3:	39 c7                	cmp    %eax,%edi
f01012d5:	75 19                	jne    f01012f0 <mem_init+0x23d>
f01012d7:	68 74 41 10 f0       	push   $0xf0104174
f01012dc:	68 75 3c 10 f0       	push   $0xf0103c75
f01012e1:	68 8f 02 00 00       	push   $0x28f
f01012e6:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01012eb:	e8 9b ed ff ff       	call   f010008b <_panic>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012f0:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012f6:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01012fc:	c1 e2 0c             	shl    $0xc,%edx
f01012ff:	89 f8                	mov    %edi,%eax
f0101301:	29 c8                	sub    %ecx,%eax
f0101303:	c1 f8 03             	sar    $0x3,%eax
f0101306:	c1 e0 0c             	shl    $0xc,%eax
f0101309:	39 d0                	cmp    %edx,%eax
f010130b:	72 19                	jb     f0101326 <mem_init+0x273>
f010130d:	68 b3 3d 10 f0       	push   $0xf0103db3
f0101312:	68 75 3c 10 f0       	push   $0xf0103c75
f0101317:	68 90 02 00 00       	push   $0x290
f010131c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101321:	e8 65 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101326:	89 f0                	mov    %esi,%eax
f0101328:	29 c8                	sub    %ecx,%eax
f010132a:	c1 f8 03             	sar    $0x3,%eax
f010132d:	c1 e0 0c             	shl    $0xc,%eax
f0101330:	39 c2                	cmp    %eax,%edx
f0101332:	77 19                	ja     f010134d <mem_init+0x29a>
f0101334:	68 d0 3d 10 f0       	push   $0xf0103dd0
f0101339:	68 75 3c 10 f0       	push   $0xf0103c75
f010133e:	68 91 02 00 00       	push   $0x291
f0101343:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101348:	e8 3e ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010134d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101350:	29 c8                	sub    %ecx,%eax
f0101352:	c1 f8 03             	sar    $0x3,%eax
f0101355:	c1 e0 0c             	shl    $0xc,%eax
f0101358:	39 c2                	cmp    %eax,%edx
f010135a:	77 19                	ja     f0101375 <mem_init+0x2c2>
f010135c:	68 ed 3d 10 f0       	push   $0xf0103ded
f0101361:	68 75 3c 10 f0       	push   $0xf0103c75
f0101366:	68 92 02 00 00       	push   $0x292
f010136b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101370:	e8 16 ed ff ff       	call   f010008b <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101375:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010137a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010137d:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101384:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101387:	83 ec 0c             	sub    $0xc,%esp
f010138a:	6a 00                	push   $0x0
f010138c:	e8 e1 f9 ff ff       	call   f0100d72 <page_alloc>
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	85 c0                	test   %eax,%eax
f0101396:	74 19                	je     f01013b1 <mem_init+0x2fe>
f0101398:	68 0a 3e 10 f0       	push   $0xf0103e0a
f010139d:	68 75 3c 10 f0       	push   $0xf0103c75
f01013a2:	68 9a 02 00 00       	push   $0x29a
f01013a7:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01013ac:	e8 da ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013b1:	83 ec 0c             	sub    $0xc,%esp
f01013b4:	57                   	push   %edi
f01013b5:	e8 28 fa ff ff       	call   f0100de2 <page_free>
	page_free(pp1);
f01013ba:	89 34 24             	mov    %esi,(%esp)
f01013bd:	e8 20 fa ff ff       	call   f0100de2 <page_free>
	page_free(pp2);
f01013c2:	83 c4 04             	add    $0x4,%esp
f01013c5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013c8:	e8 15 fa ff ff       	call   f0100de2 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013d4:	e8 99 f9 ff ff       	call   f0100d72 <page_alloc>
f01013d9:	89 c6                	mov    %eax,%esi
f01013db:	83 c4 10             	add    $0x10,%esp
f01013de:	85 c0                	test   %eax,%eax
f01013e0:	75 19                	jne    f01013fb <mem_init+0x348>
f01013e2:	68 5f 3d 10 f0       	push   $0xf0103d5f
f01013e7:	68 75 3c 10 f0       	push   $0xf0103c75
f01013ec:	68 a1 02 00 00       	push   $0x2a1
f01013f1:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01013f6:	e8 90 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013fb:	83 ec 0c             	sub    $0xc,%esp
f01013fe:	6a 00                	push   $0x0
f0101400:	e8 6d f9 ff ff       	call   f0100d72 <page_alloc>
f0101405:	89 c7                	mov    %eax,%edi
f0101407:	83 c4 10             	add    $0x10,%esp
f010140a:	85 c0                	test   %eax,%eax
f010140c:	75 19                	jne    f0101427 <mem_init+0x374>
f010140e:	68 75 3d 10 f0       	push   $0xf0103d75
f0101413:	68 75 3c 10 f0       	push   $0xf0103c75
f0101418:	68 a2 02 00 00       	push   $0x2a2
f010141d:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101427:	83 ec 0c             	sub    $0xc,%esp
f010142a:	6a 00                	push   $0x0
f010142c:	e8 41 f9 ff ff       	call   f0100d72 <page_alloc>
f0101431:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101434:	83 c4 10             	add    $0x10,%esp
f0101437:	85 c0                	test   %eax,%eax
f0101439:	75 19                	jne    f0101454 <mem_init+0x3a1>
f010143b:	68 8b 3d 10 f0       	push   $0xf0103d8b
f0101440:	68 75 3c 10 f0       	push   $0xf0103c75
f0101445:	68 a3 02 00 00       	push   $0x2a3
f010144a:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010144f:	e8 37 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101454:	39 fe                	cmp    %edi,%esi
f0101456:	75 19                	jne    f0101471 <mem_init+0x3be>
f0101458:	68 a1 3d 10 f0       	push   $0xf0103da1
f010145d:	68 75 3c 10 f0       	push   $0xf0103c75
f0101462:	68 a5 02 00 00       	push   $0x2a5
f0101467:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010146c:	e8 1a ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101471:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101474:	39 c7                	cmp    %eax,%edi
f0101476:	74 04                	je     f010147c <mem_init+0x3c9>
f0101478:	39 c6                	cmp    %eax,%esi
f010147a:	75 19                	jne    f0101495 <mem_init+0x3e2>
f010147c:	68 74 41 10 f0       	push   $0xf0104174
f0101481:	68 75 3c 10 f0       	push   $0xf0103c75
f0101486:	68 a6 02 00 00       	push   $0x2a6
f010148b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101490:	e8 f6 eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101495:	83 ec 0c             	sub    $0xc,%esp
f0101498:	6a 00                	push   $0x0
f010149a:	e8 d3 f8 ff ff       	call   f0100d72 <page_alloc>
f010149f:	83 c4 10             	add    $0x10,%esp
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	74 19                	je     f01014bf <mem_init+0x40c>
f01014a6:	68 0a 3e 10 f0       	push   $0xf0103e0a
f01014ab:	68 75 3c 10 f0       	push   $0xf0103c75
f01014b0:	68 a7 02 00 00       	push   $0x2a7
f01014b5:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01014ba:	e8 cc eb ff ff       	call   f010008b <_panic>
f01014bf:	89 f0                	mov    %esi,%eax
f01014c1:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01014c7:	c1 f8 03             	sar    $0x3,%eax
f01014ca:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014cd:	89 c2                	mov    %eax,%edx
f01014cf:	c1 ea 0c             	shr    $0xc,%edx
f01014d2:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014d8:	72 12                	jb     f01014ec <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014da:	50                   	push   %eax
f01014db:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01014e0:	6a 59                	push   $0x59
f01014e2:	68 5b 3c 10 f0       	push   $0xf0103c5b
f01014e7:	e8 9f eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014ec:	83 ec 04             	sub    $0x4,%esp
f01014ef:	68 00 10 00 00       	push   $0x1000
f01014f4:	6a 01                	push   $0x1
f01014f6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014fb:	50                   	push   %eax
f01014fc:	e8 bf 1d 00 00       	call   f01032c0 <memset>
	page_free(pp0);
f0101501:	89 34 24             	mov    %esi,(%esp)
f0101504:	e8 d9 f8 ff ff       	call   f0100de2 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101509:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101510:	e8 5d f8 ff ff       	call   f0100d72 <page_alloc>
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	85 c0                	test   %eax,%eax
f010151a:	75 19                	jne    f0101535 <mem_init+0x482>
f010151c:	68 19 3e 10 f0       	push   $0xf0103e19
f0101521:	68 75 3c 10 f0       	push   $0xf0103c75
f0101526:	68 ac 02 00 00       	push   $0x2ac
f010152b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101530:	e8 56 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101535:	39 c6                	cmp    %eax,%esi
f0101537:	74 19                	je     f0101552 <mem_init+0x49f>
f0101539:	68 37 3e 10 f0       	push   $0xf0103e37
f010153e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101543:	68 ad 02 00 00       	push   $0x2ad
f0101548:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010154d:	e8 39 eb ff ff       	call   f010008b <_panic>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101552:	89 f0                	mov    %esi,%eax
f0101554:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010155a:	c1 f8 03             	sar    $0x3,%eax
f010155d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101560:	89 c2                	mov    %eax,%edx
f0101562:	c1 ea 0c             	shr    $0xc,%edx
f0101565:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010156b:	72 12                	jb     f010157f <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010156d:	50                   	push   %eax
f010156e:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101573:	6a 59                	push   $0x59
f0101575:	68 5b 3c 10 f0       	push   $0xf0103c5b
f010157a:	e8 0c eb ff ff       	call   f010008b <_panic>
f010157f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101585:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010158b:	80 38 00             	cmpb   $0x0,(%eax)
f010158e:	74 19                	je     f01015a9 <mem_init+0x4f6>
f0101590:	68 47 3e 10 f0       	push   $0xf0103e47
f0101595:	68 75 3c 10 f0       	push   $0xf0103c75
f010159a:	68 b0 02 00 00       	push   $0x2b0
f010159f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01015a4:	e8 e2 ea ff ff       	call   f010008b <_panic>
f01015a9:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015ac:	39 d0                	cmp    %edx,%eax
f01015ae:	75 db                	jne    f010158b <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015b0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015b3:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01015b8:	83 ec 0c             	sub    $0xc,%esp
f01015bb:	56                   	push   %esi
f01015bc:	e8 21 f8 ff ff       	call   f0100de2 <page_free>
	page_free(pp1);
f01015c1:	89 3c 24             	mov    %edi,(%esp)
f01015c4:	e8 19 f8 ff ff       	call   f0100de2 <page_free>
	page_free(pp2);
f01015c9:	83 c4 04             	add    $0x4,%esp
f01015cc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015cf:	e8 0e f8 ff ff       	call   f0100de2 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015d4:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015d9:	83 c4 10             	add    $0x10,%esp
f01015dc:	eb 05                	jmp    f01015e3 <mem_init+0x530>
		--nfree;
f01015de:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015e1:	8b 00                	mov    (%eax),%eax
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	75 f7                	jne    f01015de <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01015e7:	85 db                	test   %ebx,%ebx
f01015e9:	74 19                	je     f0101604 <mem_init+0x551>
f01015eb:	68 51 3e 10 f0       	push   $0xf0103e51
f01015f0:	68 75 3c 10 f0       	push   $0xf0103c75
f01015f5:	68 bd 02 00 00       	push   $0x2bd
f01015fa:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01015ff:	e8 87 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101604:	83 ec 0c             	sub    $0xc,%esp
f0101607:	68 94 41 10 f0       	push   $0xf0104194
f010160c:	e8 64 11 00 00       	call   f0102775 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101611:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101618:	e8 55 f7 ff ff       	call   f0100d72 <page_alloc>
f010161d:	89 c6                	mov    %eax,%esi
f010161f:	83 c4 10             	add    $0x10,%esp
f0101622:	85 c0                	test   %eax,%eax
f0101624:	75 19                	jne    f010163f <mem_init+0x58c>
f0101626:	68 5f 3d 10 f0       	push   $0xf0103d5f
f010162b:	68 75 3c 10 f0       	push   $0xf0103c75
f0101630:	68 15 03 00 00       	push   $0x315
f0101635:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010163a:	e8 4c ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010163f:	83 ec 0c             	sub    $0xc,%esp
f0101642:	6a 00                	push   $0x0
f0101644:	e8 29 f7 ff ff       	call   f0100d72 <page_alloc>
f0101649:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010164c:	83 c4 10             	add    $0x10,%esp
f010164f:	85 c0                	test   %eax,%eax
f0101651:	75 19                	jne    f010166c <mem_init+0x5b9>
f0101653:	68 75 3d 10 f0       	push   $0xf0103d75
f0101658:	68 75 3c 10 f0       	push   $0xf0103c75
f010165d:	68 16 03 00 00       	push   $0x316
f0101662:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101667:	e8 1f ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010166c:	83 ec 0c             	sub    $0xc,%esp
f010166f:	6a 00                	push   $0x0
f0101671:	e8 fc f6 ff ff       	call   f0100d72 <page_alloc>
f0101676:	89 c3                	mov    %eax,%ebx
f0101678:	83 c4 10             	add    $0x10,%esp
f010167b:	85 c0                	test   %eax,%eax
f010167d:	75 19                	jne    f0101698 <mem_init+0x5e5>
f010167f:	68 8b 3d 10 f0       	push   $0xf0103d8b
f0101684:	68 75 3c 10 f0       	push   $0xf0103c75
f0101689:	68 17 03 00 00       	push   $0x317
f010168e:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101693:	e8 f3 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101698:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010169b:	75 19                	jne    f01016b6 <mem_init+0x603>
f010169d:	68 a1 3d 10 f0       	push   $0xf0103da1
f01016a2:	68 75 3c 10 f0       	push   $0xf0103c75
f01016a7:	68 1a 03 00 00       	push   $0x31a
f01016ac:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01016b1:	e8 d5 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016b6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016b9:	74 04                	je     f01016bf <mem_init+0x60c>
f01016bb:	39 c6                	cmp    %eax,%esi
f01016bd:	75 19                	jne    f01016d8 <mem_init+0x625>
f01016bf:	68 74 41 10 f0       	push   $0xf0104174
f01016c4:	68 75 3c 10 f0       	push   $0xf0103c75
f01016c9:	68 1b 03 00 00       	push   $0x31b
f01016ce:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01016d3:	e8 b3 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016d8:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016dd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016e0:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016e7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016ea:	83 ec 0c             	sub    $0xc,%esp
f01016ed:	6a 00                	push   $0x0
f01016ef:	e8 7e f6 ff ff       	call   f0100d72 <page_alloc>
f01016f4:	83 c4 10             	add    $0x10,%esp
f01016f7:	85 c0                	test   %eax,%eax
f01016f9:	74 19                	je     f0101714 <mem_init+0x661>
f01016fb:	68 0a 3e 10 f0       	push   $0xf0103e0a
f0101700:	68 75 3c 10 f0       	push   $0xf0103c75
f0101705:	68 22 03 00 00       	push   $0x322
f010170a:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010170f:	e8 77 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101714:	83 ec 04             	sub    $0x4,%esp
f0101717:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010171a:	50                   	push   %eax
f010171b:	6a 00                	push   $0x0
f010171d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101723:	e8 6a f8 ff ff       	call   f0100f92 <page_lookup>
f0101728:	83 c4 10             	add    $0x10,%esp
f010172b:	85 c0                	test   %eax,%eax
f010172d:	74 19                	je     f0101748 <mem_init+0x695>
f010172f:	68 b4 41 10 f0       	push   $0xf01041b4
f0101734:	68 75 3c 10 f0       	push   $0xf0103c75
f0101739:	68 25 03 00 00       	push   $0x325
f010173e:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101743:	e8 43 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101748:	6a 02                	push   $0x2
f010174a:	6a 00                	push   $0x0
f010174c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010174f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101755:	e8 e1 f8 ff ff       	call   f010103b <page_insert>
f010175a:	83 c4 10             	add    $0x10,%esp
f010175d:	85 c0                	test   %eax,%eax
f010175f:	78 19                	js     f010177a <mem_init+0x6c7>
f0101761:	68 ec 41 10 f0       	push   $0xf01041ec
f0101766:	68 75 3c 10 f0       	push   $0xf0103c75
f010176b:	68 28 03 00 00       	push   $0x328
f0101770:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101775:	e8 11 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010177a:	83 ec 0c             	sub    $0xc,%esp
f010177d:	56                   	push   %esi
f010177e:	e8 5f f6 ff ff       	call   f0100de2 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101783:	6a 02                	push   $0x2
f0101785:	6a 00                	push   $0x0
f0101787:	ff 75 d4             	pushl  -0x2c(%ebp)
f010178a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101790:	e8 a6 f8 ff ff       	call   f010103b <page_insert>
f0101795:	83 c4 20             	add    $0x20,%esp
f0101798:	85 c0                	test   %eax,%eax
f010179a:	74 19                	je     f01017b5 <mem_init+0x702>
f010179c:	68 1c 42 10 f0       	push   $0xf010421c
f01017a1:	68 75 3c 10 f0       	push   $0xf0103c75
f01017a6:	68 2c 03 00 00       	push   $0x32c
f01017ab:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01017b0:	e8 d6 e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017b5:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017bb:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01017c0:	89 c1                	mov    %eax,%ecx
f01017c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017c5:	8b 17                	mov    (%edi),%edx
f01017c7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017cd:	89 f0                	mov    %esi,%eax
f01017cf:	29 c8                	sub    %ecx,%eax
f01017d1:	c1 f8 03             	sar    $0x3,%eax
f01017d4:	c1 e0 0c             	shl    $0xc,%eax
f01017d7:	39 c2                	cmp    %eax,%edx
f01017d9:	74 19                	je     f01017f4 <mem_init+0x741>
f01017db:	68 4c 42 10 f0       	push   $0xf010424c
f01017e0:	68 75 3c 10 f0       	push   $0xf0103c75
f01017e5:	68 2d 03 00 00       	push   $0x32d
f01017ea:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01017ef:	e8 97 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01017f9:	89 f8                	mov    %edi,%eax
f01017fb:	e8 45 f1 ff ff       	call   f0100945 <check_va2pa>
f0101800:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101803:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101806:	c1 fa 03             	sar    $0x3,%edx
f0101809:	c1 e2 0c             	shl    $0xc,%edx
f010180c:	39 d0                	cmp    %edx,%eax
f010180e:	74 19                	je     f0101829 <mem_init+0x776>
f0101810:	68 74 42 10 f0       	push   $0xf0104274
f0101815:	68 75 3c 10 f0       	push   $0xf0103c75
f010181a:	68 2e 03 00 00       	push   $0x32e
f010181f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101824:	e8 62 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101829:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101831:	74 19                	je     f010184c <mem_init+0x799>
f0101833:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101838:	68 75 3c 10 f0       	push   $0xf0103c75
f010183d:	68 2f 03 00 00       	push   $0x32f
f0101842:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101847:	e8 3f e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010184c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101851:	74 19                	je     f010186c <mem_init+0x7b9>
f0101853:	68 6d 3e 10 f0       	push   $0xf0103e6d
f0101858:	68 75 3c 10 f0       	push   $0xf0103c75
f010185d:	68 30 03 00 00       	push   $0x330
f0101862:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101867:	e8 1f e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010186c:	6a 02                	push   $0x2
f010186e:	68 00 10 00 00       	push   $0x1000
f0101873:	53                   	push   %ebx
f0101874:	57                   	push   %edi
f0101875:	e8 c1 f7 ff ff       	call   f010103b <page_insert>
f010187a:	83 c4 10             	add    $0x10,%esp
f010187d:	85 c0                	test   %eax,%eax
f010187f:	74 19                	je     f010189a <mem_init+0x7e7>
f0101881:	68 a4 42 10 f0       	push   $0xf01042a4
f0101886:	68 75 3c 10 f0       	push   $0xf0103c75
f010188b:	68 33 03 00 00       	push   $0x333
f0101890:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101895:	e8 f1 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010189a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01018a4:	e8 9c f0 ff ff       	call   f0100945 <check_va2pa>
f01018a9:	89 da                	mov    %ebx,%edx
f01018ab:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01018b1:	c1 fa 03             	sar    $0x3,%edx
f01018b4:	c1 e2 0c             	shl    $0xc,%edx
f01018b7:	39 d0                	cmp    %edx,%eax
f01018b9:	74 19                	je     f01018d4 <mem_init+0x821>
f01018bb:	68 e0 42 10 f0       	push   $0xf01042e0
f01018c0:	68 75 3c 10 f0       	push   $0xf0103c75
f01018c5:	68 34 03 00 00       	push   $0x334
f01018ca:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01018cf:	e8 b7 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018d4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018d9:	74 19                	je     f01018f4 <mem_init+0x841>
f01018db:	68 7e 3e 10 f0       	push   $0xf0103e7e
f01018e0:	68 75 3c 10 f0       	push   $0xf0103c75
f01018e5:	68 35 03 00 00       	push   $0x335
f01018ea:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01018ef:	e8 97 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018f4:	83 ec 0c             	sub    $0xc,%esp
f01018f7:	6a 00                	push   $0x0
f01018f9:	e8 74 f4 ff ff       	call   f0100d72 <page_alloc>
f01018fe:	83 c4 10             	add    $0x10,%esp
f0101901:	85 c0                	test   %eax,%eax
f0101903:	74 19                	je     f010191e <mem_init+0x86b>
f0101905:	68 0a 3e 10 f0       	push   $0xf0103e0a
f010190a:	68 75 3c 10 f0       	push   $0xf0103c75
f010190f:	68 38 03 00 00       	push   $0x338
f0101914:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101919:	e8 6d e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010191e:	6a 02                	push   $0x2
f0101920:	68 00 10 00 00       	push   $0x1000
f0101925:	53                   	push   %ebx
f0101926:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010192c:	e8 0a f7 ff ff       	call   f010103b <page_insert>
f0101931:	83 c4 10             	add    $0x10,%esp
f0101934:	85 c0                	test   %eax,%eax
f0101936:	74 19                	je     f0101951 <mem_init+0x89e>
f0101938:	68 a4 42 10 f0       	push   $0xf01042a4
f010193d:	68 75 3c 10 f0       	push   $0xf0103c75
f0101942:	68 3b 03 00 00       	push   $0x33b
f0101947:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010194c:	e8 3a e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101951:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101956:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010195b:	e8 e5 ef ff ff       	call   f0100945 <check_va2pa>
f0101960:	89 da                	mov    %ebx,%edx
f0101962:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101968:	c1 fa 03             	sar    $0x3,%edx
f010196b:	c1 e2 0c             	shl    $0xc,%edx
f010196e:	39 d0                	cmp    %edx,%eax
f0101970:	74 19                	je     f010198b <mem_init+0x8d8>
f0101972:	68 e0 42 10 f0       	push   $0xf01042e0
f0101977:	68 75 3c 10 f0       	push   $0xf0103c75
f010197c:	68 3c 03 00 00       	push   $0x33c
f0101981:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101986:	e8 00 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010198b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101990:	74 19                	je     f01019ab <mem_init+0x8f8>
f0101992:	68 7e 3e 10 f0       	push   $0xf0103e7e
f0101997:	68 75 3c 10 f0       	push   $0xf0103c75
f010199c:	68 3d 03 00 00       	push   $0x33d
f01019a1:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01019a6:	e8 e0 e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019ab:	83 ec 0c             	sub    $0xc,%esp
f01019ae:	6a 00                	push   $0x0
f01019b0:	e8 bd f3 ff ff       	call   f0100d72 <page_alloc>
f01019b5:	83 c4 10             	add    $0x10,%esp
f01019b8:	85 c0                	test   %eax,%eax
f01019ba:	74 19                	je     f01019d5 <mem_init+0x922>
f01019bc:	68 0a 3e 10 f0       	push   $0xf0103e0a
f01019c1:	68 75 3c 10 f0       	push   $0xf0103c75
f01019c6:	68 41 03 00 00       	push   $0x341
f01019cb:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01019d0:	e8 b6 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019d5:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01019db:	8b 02                	mov    (%edx),%eax
f01019dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019e2:	89 c1                	mov    %eax,%ecx
f01019e4:	c1 e9 0c             	shr    $0xc,%ecx
f01019e7:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f01019ed:	72 15                	jb     f0101a04 <mem_init+0x951>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019ef:	50                   	push   %eax
f01019f0:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01019f5:	68 44 03 00 00       	push   $0x344
f01019fa:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01019ff:	e8 87 e6 ff ff       	call   f010008b <_panic>
f0101a04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a0c:	83 ec 04             	sub    $0x4,%esp
f0101a0f:	6a 00                	push   $0x0
f0101a11:	68 00 10 00 00       	push   $0x1000
f0101a16:	52                   	push   %edx
f0101a17:	e8 43 f4 ff ff       	call   f0100e5f <pgdir_walk>
f0101a1c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101a1f:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a22:	83 c4 10             	add    $0x10,%esp
f0101a25:	39 d0                	cmp    %edx,%eax
f0101a27:	74 19                	je     f0101a42 <mem_init+0x98f>
f0101a29:	68 10 43 10 f0       	push   $0xf0104310
f0101a2e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101a33:	68 45 03 00 00       	push   $0x345
f0101a38:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101a3d:	e8 49 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a42:	6a 06                	push   $0x6
f0101a44:	68 00 10 00 00       	push   $0x1000
f0101a49:	53                   	push   %ebx
f0101a4a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a50:	e8 e6 f5 ff ff       	call   f010103b <page_insert>
f0101a55:	83 c4 10             	add    $0x10,%esp
f0101a58:	85 c0                	test   %eax,%eax
f0101a5a:	74 19                	je     f0101a75 <mem_init+0x9c2>
f0101a5c:	68 50 43 10 f0       	push   $0xf0104350
f0101a61:	68 75 3c 10 f0       	push   $0xf0103c75
f0101a66:	68 48 03 00 00       	push   $0x348
f0101a6b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101a70:	e8 16 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a75:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101a7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a80:	89 f8                	mov    %edi,%eax
f0101a82:	e8 be ee ff ff       	call   f0100945 <check_va2pa>
f0101a87:	89 da                	mov    %ebx,%edx
f0101a89:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a8f:	c1 fa 03             	sar    $0x3,%edx
f0101a92:	c1 e2 0c             	shl    $0xc,%edx
f0101a95:	39 d0                	cmp    %edx,%eax
f0101a97:	74 19                	je     f0101ab2 <mem_init+0x9ff>
f0101a99:	68 e0 42 10 f0       	push   $0xf01042e0
f0101a9e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101aa3:	68 49 03 00 00       	push   $0x349
f0101aa8:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101aad:	e8 d9 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101ab2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ab7:	74 19                	je     f0101ad2 <mem_init+0xa1f>
f0101ab9:	68 7e 3e 10 f0       	push   $0xf0103e7e
f0101abe:	68 75 3c 10 f0       	push   $0xf0103c75
f0101ac3:	68 4a 03 00 00       	push   $0x34a
f0101ac8:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101acd:	e8 b9 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ad2:	83 ec 04             	sub    $0x4,%esp
f0101ad5:	6a 00                	push   $0x0
f0101ad7:	68 00 10 00 00       	push   $0x1000
f0101adc:	57                   	push   %edi
f0101add:	e8 7d f3 ff ff       	call   f0100e5f <pgdir_walk>
f0101ae2:	83 c4 10             	add    $0x10,%esp
f0101ae5:	f6 00 04             	testb  $0x4,(%eax)
f0101ae8:	75 19                	jne    f0101b03 <mem_init+0xa50>
f0101aea:	68 90 43 10 f0       	push   $0xf0104390
f0101aef:	68 75 3c 10 f0       	push   $0xf0103c75
f0101af4:	68 4b 03 00 00       	push   $0x34b
f0101af9:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101afe:	e8 88 e5 ff ff       	call   f010008b <_panic>
	cprintf("pp2 %x\n", pp2);
f0101b03:	83 ec 08             	sub    $0x8,%esp
f0101b06:	53                   	push   %ebx
f0101b07:	68 8f 3e 10 f0       	push   $0xf0103e8f
f0101b0c:	e8 64 0c 00 00       	call   f0102775 <cprintf>
	cprintf("kern_pgdir %x\n", kern_pgdir);
f0101b11:	83 c4 08             	add    $0x8,%esp
f0101b14:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b1a:	68 97 3e 10 f0       	push   $0xf0103e97
f0101b1f:	e8 51 0c 00 00       	call   f0102775 <cprintf>
	cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
f0101b24:	83 c4 08             	add    $0x8,%esp
f0101b27:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b2c:	ff 30                	pushl  (%eax)
f0101b2e:	68 a6 3e 10 f0       	push   $0xf0103ea6
f0101b33:	e8 3d 0c 00 00       	call   f0102775 <cprintf>
	assert(kern_pgdir[0] & PTE_U);
f0101b38:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b3d:	83 c4 10             	add    $0x10,%esp
f0101b40:	f6 00 04             	testb  $0x4,(%eax)
f0101b43:	75 19                	jne    f0101b5e <mem_init+0xaab>
f0101b45:	68 bb 3e 10 f0       	push   $0xf0103ebb
f0101b4a:	68 75 3c 10 f0       	push   $0xf0103c75
f0101b4f:	68 4f 03 00 00       	push   $0x34f
f0101b54:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101b59:	e8 2d e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b5e:	6a 02                	push   $0x2
f0101b60:	68 00 10 00 00       	push   $0x1000
f0101b65:	53                   	push   %ebx
f0101b66:	50                   	push   %eax
f0101b67:	e8 cf f4 ff ff       	call   f010103b <page_insert>
f0101b6c:	83 c4 10             	add    $0x10,%esp
f0101b6f:	85 c0                	test   %eax,%eax
f0101b71:	74 19                	je     f0101b8c <mem_init+0xad9>
f0101b73:	68 a4 42 10 f0       	push   $0xf01042a4
f0101b78:	68 75 3c 10 f0       	push   $0xf0103c75
f0101b7d:	68 52 03 00 00       	push   $0x352
f0101b82:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101b87:	e8 ff e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b8c:	83 ec 04             	sub    $0x4,%esp
f0101b8f:	6a 00                	push   $0x0
f0101b91:	68 00 10 00 00       	push   $0x1000
f0101b96:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b9c:	e8 be f2 ff ff       	call   f0100e5f <pgdir_walk>
f0101ba1:	83 c4 10             	add    $0x10,%esp
f0101ba4:	f6 00 02             	testb  $0x2,(%eax)
f0101ba7:	75 19                	jne    f0101bc2 <mem_init+0xb0f>
f0101ba9:	68 c4 43 10 f0       	push   $0xf01043c4
f0101bae:	68 75 3c 10 f0       	push   $0xf0103c75
f0101bb3:	68 53 03 00 00       	push   $0x353
f0101bb8:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101bbd:	e8 c9 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bc2:	83 ec 04             	sub    $0x4,%esp
f0101bc5:	6a 00                	push   $0x0
f0101bc7:	68 00 10 00 00       	push   $0x1000
f0101bcc:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bd2:	e8 88 f2 ff ff       	call   f0100e5f <pgdir_walk>
f0101bd7:	83 c4 10             	add    $0x10,%esp
f0101bda:	f6 00 04             	testb  $0x4,(%eax)
f0101bdd:	74 19                	je     f0101bf8 <mem_init+0xb45>
f0101bdf:	68 f8 43 10 f0       	push   $0xf01043f8
f0101be4:	68 75 3c 10 f0       	push   $0xf0103c75
f0101be9:	68 54 03 00 00       	push   $0x354
f0101bee:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bf8:	6a 02                	push   $0x2
f0101bfa:	68 00 00 40 00       	push   $0x400000
f0101bff:	56                   	push   %esi
f0101c00:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c06:	e8 30 f4 ff ff       	call   f010103b <page_insert>
f0101c0b:	83 c4 10             	add    $0x10,%esp
f0101c0e:	85 c0                	test   %eax,%eax
f0101c10:	78 19                	js     f0101c2b <mem_init+0xb78>
f0101c12:	68 30 44 10 f0       	push   $0xf0104430
f0101c17:	68 75 3c 10 f0       	push   $0xf0103c75
f0101c1c:	68 57 03 00 00       	push   $0x357
f0101c21:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101c26:	e8 60 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c2b:	6a 02                	push   $0x2
f0101c2d:	68 00 10 00 00       	push   $0x1000
f0101c32:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c35:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c3b:	e8 fb f3 ff ff       	call   f010103b <page_insert>
f0101c40:	83 c4 10             	add    $0x10,%esp
f0101c43:	85 c0                	test   %eax,%eax
f0101c45:	74 19                	je     f0101c60 <mem_init+0xbad>
f0101c47:	68 68 44 10 f0       	push   $0xf0104468
f0101c4c:	68 75 3c 10 f0       	push   $0xf0103c75
f0101c51:	68 5a 03 00 00       	push   $0x35a
f0101c56:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101c5b:	e8 2b e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c60:	83 ec 04             	sub    $0x4,%esp
f0101c63:	6a 00                	push   $0x0
f0101c65:	68 00 10 00 00       	push   $0x1000
f0101c6a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c70:	e8 ea f1 ff ff       	call   f0100e5f <pgdir_walk>
f0101c75:	83 c4 10             	add    $0x10,%esp
f0101c78:	f6 00 04             	testb  $0x4,(%eax)
f0101c7b:	74 19                	je     f0101c96 <mem_init+0xbe3>
f0101c7d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101c82:	68 75 3c 10 f0       	push   $0xf0103c75
f0101c87:	68 5b 03 00 00       	push   $0x35b
f0101c8c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101c91:	e8 f5 e3 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c96:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca1:	89 f8                	mov    %edi,%eax
f0101ca3:	e8 9d ec ff ff       	call   f0100945 <check_va2pa>
f0101ca8:	89 c1                	mov    %eax,%ecx
f0101caa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cb0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101cb6:	c1 f8 03             	sar    $0x3,%eax
f0101cb9:	c1 e0 0c             	shl    $0xc,%eax
f0101cbc:	39 c1                	cmp    %eax,%ecx
f0101cbe:	74 19                	je     f0101cd9 <mem_init+0xc26>
f0101cc0:	68 a4 44 10 f0       	push   $0xf01044a4
f0101cc5:	68 75 3c 10 f0       	push   $0xf0103c75
f0101cca:	68 5e 03 00 00       	push   $0x35e
f0101ccf:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101cd4:	e8 b2 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cd9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cde:	89 f8                	mov    %edi,%eax
f0101ce0:	e8 60 ec ff ff       	call   f0100945 <check_va2pa>
f0101ce5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ce8:	74 19                	je     f0101d03 <mem_init+0xc50>
f0101cea:	68 d0 44 10 f0       	push   $0xf01044d0
f0101cef:	68 75 3c 10 f0       	push   $0xf0103c75
f0101cf4:	68 5f 03 00 00       	push   $0x35f
f0101cf9:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101cfe:	e8 88 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d03:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d06:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101d0b:	74 19                	je     f0101d26 <mem_init+0xc73>
f0101d0d:	68 d1 3e 10 f0       	push   $0xf0103ed1
f0101d12:	68 75 3c 10 f0       	push   $0xf0103c75
f0101d17:	68 61 03 00 00       	push   $0x361
f0101d1c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101d21:	e8 65 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d26:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d2b:	74 19                	je     f0101d46 <mem_init+0xc93>
f0101d2d:	68 e2 3e 10 f0       	push   $0xf0103ee2
f0101d32:	68 75 3c 10 f0       	push   $0xf0103c75
f0101d37:	68 62 03 00 00       	push   $0x362
f0101d3c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101d41:	e8 45 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d46:	83 ec 0c             	sub    $0xc,%esp
f0101d49:	6a 00                	push   $0x0
f0101d4b:	e8 22 f0 ff ff       	call   f0100d72 <page_alloc>
f0101d50:	83 c4 10             	add    $0x10,%esp
f0101d53:	85 c0                	test   %eax,%eax
f0101d55:	74 04                	je     f0101d5b <mem_init+0xca8>
f0101d57:	39 c3                	cmp    %eax,%ebx
f0101d59:	74 19                	je     f0101d74 <mem_init+0xcc1>
f0101d5b:	68 00 45 10 f0       	push   $0xf0104500
f0101d60:	68 75 3c 10 f0       	push   $0xf0103c75
f0101d65:	68 65 03 00 00       	push   $0x365
f0101d6a:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101d6f:	e8 17 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d74:	83 ec 08             	sub    $0x8,%esp
f0101d77:	6a 00                	push   $0x0
f0101d79:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d7f:	e8 74 f2 ff ff       	call   f0100ff8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d84:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d8f:	89 f8                	mov    %edi,%eax
f0101d91:	e8 af eb ff ff       	call   f0100945 <check_va2pa>
f0101d96:	83 c4 10             	add    $0x10,%esp
f0101d99:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d9c:	74 19                	je     f0101db7 <mem_init+0xd04>
f0101d9e:	68 24 45 10 f0       	push   $0xf0104524
f0101da3:	68 75 3c 10 f0       	push   $0xf0103c75
f0101da8:	68 69 03 00 00       	push   $0x369
f0101dad:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101db2:	e8 d4 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101db7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dbc:	89 f8                	mov    %edi,%eax
f0101dbe:	e8 82 eb ff ff       	call   f0100945 <check_va2pa>
f0101dc3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101dc6:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dcc:	c1 fa 03             	sar    $0x3,%edx
f0101dcf:	c1 e2 0c             	shl    $0xc,%edx
f0101dd2:	39 d0                	cmp    %edx,%eax
f0101dd4:	74 19                	je     f0101def <mem_init+0xd3c>
f0101dd6:	68 d0 44 10 f0       	push   $0xf01044d0
f0101ddb:	68 75 3c 10 f0       	push   $0xf0103c75
f0101de0:	68 6a 03 00 00       	push   $0x36a
f0101de5:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101dea:	e8 9c e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101def:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101df7:	74 19                	je     f0101e12 <mem_init+0xd5f>
f0101df9:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101dfe:	68 75 3c 10 f0       	push   $0xf0103c75
f0101e03:	68 6b 03 00 00       	push   $0x36b
f0101e08:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101e0d:	e8 79 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e12:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e17:	74 19                	je     f0101e32 <mem_init+0xd7f>
f0101e19:	68 e2 3e 10 f0       	push   $0xf0103ee2
f0101e1e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101e23:	68 6c 03 00 00       	push   $0x36c
f0101e28:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101e2d:	e8 59 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e32:	83 ec 08             	sub    $0x8,%esp
f0101e35:	68 00 10 00 00       	push   $0x1000
f0101e3a:	57                   	push   %edi
f0101e3b:	e8 b8 f1 ff ff       	call   f0100ff8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e40:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e46:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e4b:	89 f8                	mov    %edi,%eax
f0101e4d:	e8 f3 ea ff ff       	call   f0100945 <check_va2pa>
f0101e52:	83 c4 10             	add    $0x10,%esp
f0101e55:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e58:	74 19                	je     f0101e73 <mem_init+0xdc0>
f0101e5a:	68 24 45 10 f0       	push   $0xf0104524
f0101e5f:	68 75 3c 10 f0       	push   $0xf0103c75
f0101e64:	68 70 03 00 00       	push   $0x370
f0101e69:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101e6e:	e8 18 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e73:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e78:	89 f8                	mov    %edi,%eax
f0101e7a:	e8 c6 ea ff ff       	call   f0100945 <check_va2pa>
f0101e7f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e82:	74 19                	je     f0101e9d <mem_init+0xdea>
f0101e84:	68 48 45 10 f0       	push   $0xf0104548
f0101e89:	68 75 3c 10 f0       	push   $0xf0103c75
f0101e8e:	68 71 03 00 00       	push   $0x371
f0101e93:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101e98:	e8 ee e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101ea5:	74 19                	je     f0101ec0 <mem_init+0xe0d>
f0101ea7:	68 f3 3e 10 f0       	push   $0xf0103ef3
f0101eac:	68 75 3c 10 f0       	push   $0xf0103c75
f0101eb1:	68 72 03 00 00       	push   $0x372
f0101eb6:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101ebb:	e8 cb e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ec0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ec5:	74 19                	je     f0101ee0 <mem_init+0xe2d>
f0101ec7:	68 e2 3e 10 f0       	push   $0xf0103ee2
f0101ecc:	68 75 3c 10 f0       	push   $0xf0103c75
f0101ed1:	68 73 03 00 00       	push   $0x373
f0101ed6:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101edb:	e8 ab e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ee0:	83 ec 0c             	sub    $0xc,%esp
f0101ee3:	6a 00                	push   $0x0
f0101ee5:	e8 88 ee ff ff       	call   f0100d72 <page_alloc>
f0101eea:	83 c4 10             	add    $0x10,%esp
f0101eed:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ef0:	75 04                	jne    f0101ef6 <mem_init+0xe43>
f0101ef2:	85 c0                	test   %eax,%eax
f0101ef4:	75 19                	jne    f0101f0f <mem_init+0xe5c>
f0101ef6:	68 70 45 10 f0       	push   $0xf0104570
f0101efb:	68 75 3c 10 f0       	push   $0xf0103c75
f0101f00:	68 76 03 00 00       	push   $0x376
f0101f05:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101f0a:	e8 7c e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f0f:	83 ec 0c             	sub    $0xc,%esp
f0101f12:	6a 00                	push   $0x0
f0101f14:	e8 59 ee ff ff       	call   f0100d72 <page_alloc>
f0101f19:	83 c4 10             	add    $0x10,%esp
f0101f1c:	85 c0                	test   %eax,%eax
f0101f1e:	74 19                	je     f0101f39 <mem_init+0xe86>
f0101f20:	68 0a 3e 10 f0       	push   $0xf0103e0a
f0101f25:	68 75 3c 10 f0       	push   $0xf0103c75
f0101f2a:	68 79 03 00 00       	push   $0x379
f0101f2f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101f34:	e8 52 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f39:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101f3f:	8b 11                	mov    (%ecx),%edx
f0101f41:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f47:	89 f0                	mov    %esi,%eax
f0101f49:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f4f:	c1 f8 03             	sar    $0x3,%eax
f0101f52:	c1 e0 0c             	shl    $0xc,%eax
f0101f55:	39 c2                	cmp    %eax,%edx
f0101f57:	74 19                	je     f0101f72 <mem_init+0xebf>
f0101f59:	68 4c 42 10 f0       	push   $0xf010424c
f0101f5e:	68 75 3c 10 f0       	push   $0xf0103c75
f0101f63:	68 7c 03 00 00       	push   $0x37c
f0101f68:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101f6d:	e8 19 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f72:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f78:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f7d:	74 19                	je     f0101f98 <mem_init+0xee5>
f0101f7f:	68 6d 3e 10 f0       	push   $0xf0103e6d
f0101f84:	68 75 3c 10 f0       	push   $0xf0103c75
f0101f89:	68 7e 03 00 00       	push   $0x37e
f0101f8e:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101f93:	e8 f3 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f98:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f9e:	83 ec 0c             	sub    $0xc,%esp
f0101fa1:	56                   	push   %esi
f0101fa2:	e8 3b ee ff ff       	call   f0100de2 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fa7:	83 c4 0c             	add    $0xc,%esp
f0101faa:	6a 01                	push   $0x1
f0101fac:	68 00 10 40 00       	push   $0x401000
f0101fb1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fb7:	e8 a3 ee ff ff       	call   f0100e5f <pgdir_walk>
f0101fbc:	89 c7                	mov    %eax,%edi
f0101fbe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fc1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fc9:	8b 40 04             	mov    0x4(%eax),%eax
f0101fcc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd1:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101fd7:	89 c2                	mov    %eax,%edx
f0101fd9:	c1 ea 0c             	shr    $0xc,%edx
f0101fdc:	83 c4 10             	add    $0x10,%esp
f0101fdf:	39 ca                	cmp    %ecx,%edx
f0101fe1:	72 15                	jb     f0101ff8 <mem_init+0xf45>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe3:	50                   	push   %eax
f0101fe4:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101fe9:	68 85 03 00 00       	push   $0x385
f0101fee:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0101ff3:	e8 93 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ff8:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ffd:	39 c7                	cmp    %eax,%edi
f0101fff:	74 19                	je     f010201a <mem_init+0xf67>
f0102001:	68 04 3f 10 f0       	push   $0xf0103f04
f0102006:	68 75 3c 10 f0       	push   $0xf0103c75
f010200b:	68 86 03 00 00       	push   $0x386
f0102010:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102015:	e8 71 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010201a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010201d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102024:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202a:	89 f0                	mov    %esi,%eax
f010202c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102032:	c1 f8 03             	sar    $0x3,%eax
f0102035:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102038:	89 c2                	mov    %eax,%edx
f010203a:	c1 ea 0c             	shr    $0xc,%edx
f010203d:	39 d1                	cmp    %edx,%ecx
f010203f:	77 12                	ja     f0102053 <mem_init+0xfa0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102041:	50                   	push   %eax
f0102042:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0102047:	6a 59                	push   $0x59
f0102049:	68 5b 3c 10 f0       	push   $0xf0103c5b
f010204e:	e8 38 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102053:	83 ec 04             	sub    $0x4,%esp
f0102056:	68 00 10 00 00       	push   $0x1000
f010205b:	68 ff 00 00 00       	push   $0xff
f0102060:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102065:	50                   	push   %eax
f0102066:	e8 55 12 00 00       	call   f01032c0 <memset>
	page_free(pp0);
f010206b:	89 34 24             	mov    %esi,(%esp)
f010206e:	e8 6f ed ff ff       	call   f0100de2 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102073:	83 c4 0c             	add    $0xc,%esp
f0102076:	6a 01                	push   $0x1
f0102078:	6a 00                	push   $0x0
f010207a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102080:	e8 da ed ff ff       	call   f0100e5f <pgdir_walk>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102085:	89 f2                	mov    %esi,%edx
f0102087:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010208d:	c1 fa 03             	sar    $0x3,%edx
f0102090:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102093:	89 d0                	mov    %edx,%eax
f0102095:	c1 e8 0c             	shr    $0xc,%eax
f0102098:	83 c4 10             	add    $0x10,%esp
f010209b:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01020a1:	72 12                	jb     f01020b5 <mem_init+0x1002>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020a3:	52                   	push   %edx
f01020a4:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01020a9:	6a 59                	push   $0x59
f01020ab:	68 5b 3c 10 f0       	push   $0xf0103c5b
f01020b0:	e8 d6 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020b5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020be:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020c4:	f6 00 01             	testb  $0x1,(%eax)
f01020c7:	74 19                	je     f01020e2 <mem_init+0x102f>
f01020c9:	68 1c 3f 10 f0       	push   $0xf0103f1c
f01020ce:	68 75 3c 10 f0       	push   $0xf0103c75
f01020d3:	68 90 03 00 00       	push   $0x390
f01020d8:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01020dd:	e8 a9 df ff ff       	call   f010008b <_panic>
f01020e2:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020e5:	39 d0                	cmp    %edx,%eax
f01020e7:	75 db                	jne    f01020c4 <mem_init+0x1011>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020e9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020f4:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01020fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020fd:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102102:	83 ec 0c             	sub    $0xc,%esp
f0102105:	56                   	push   %esi
f0102106:	e8 d7 ec ff ff       	call   f0100de2 <page_free>
	page_free(pp1);
f010210b:	83 c4 04             	add    $0x4,%esp
f010210e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102111:	e8 cc ec ff ff       	call   f0100de2 <page_free>
	page_free(pp2);
f0102116:	89 1c 24             	mov    %ebx,(%esp)
f0102119:	e8 c4 ec ff ff       	call   f0100de2 <page_free>

	cprintf("check_page() succeeded!\n");
f010211e:	c7 04 24 33 3f 10 f0 	movl   $0xf0103f33,(%esp)
f0102125:	e8 4b 06 00 00       	call   f0102775 <cprintf>
	/* This macro takes a kernel virtual address -- an address that points above
 	 * KERNBASE, where the machine's maximum 256MB of physical memory is mapped --
	 * and returns the corresponding physical address.  It panics if you pass it a
	 * non-kernel virtual address.
	 */
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010212a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010212f:	83 c4 10             	add    $0x10,%esp
f0102132:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102137:	77 15                	ja     f010214e <mem_init+0x109b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102139:	50                   	push   %eax
f010213a:	68 64 40 10 f0       	push   $0xf0104064
f010213f:	68 bb 00 00 00       	push   $0xbb
f0102144:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102149:	e8 3d df ff ff       	call   f010008b <_panic>
f010214e:	83 ec 08             	sub    $0x8,%esp
f0102151:	6a 04                	push   $0x4
f0102153:	05 00 00 00 10       	add    $0x10000000,%eax
f0102158:	50                   	push   %eax
f0102159:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010215e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102163:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102168:	e8 85 ed ff ff       	call   f0100ef2 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010216d:	83 c4 10             	add    $0x10,%esp
f0102170:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102175:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010217a:	77 15                	ja     f0102191 <mem_init+0x10de>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010217c:	50                   	push   %eax
f010217d:	68 64 40 10 f0       	push   $0xf0104064
f0102182:	68 c9 00 00 00       	push   $0xc9
f0102187:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010218c:	e8 fa de ff ff       	call   f010008b <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102191:	83 ec 08             	sub    $0x8,%esp
f0102194:	6a 02                	push   $0x2
f0102196:	68 00 d0 10 00       	push   $0x10d000
f010219b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021a0:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021a5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021aa:	e8 43 ed ff ff       	call   f0100ef2 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f01021af:	83 c4 08             	add    $0x8,%esp
f01021b2:	6a 02                	push   $0x2
f01021b4:	6a 00                	push   $0x0
f01021b6:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021bb:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021c0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021c5:	e8 28 ed ff ff       	call   f0100ef2 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021ca:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021d0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01021d5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021d8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021e4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e7:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021ed:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021f0:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021f3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021f8:	eb 55                	jmp    f010224f <mem_init+0x119c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021fa:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102200:	89 f0                	mov    %esi,%eax
f0102202:	e8 3e e7 ff ff       	call   f0100945 <check_va2pa>
f0102207:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010220e:	77 15                	ja     f0102225 <mem_init+0x1172>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102210:	57                   	push   %edi
f0102211:	68 64 40 10 f0       	push   $0xf0104064
f0102216:	68 d5 02 00 00       	push   $0x2d5
f010221b:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102220:	e8 66 de ff ff       	call   f010008b <_panic>
f0102225:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010222c:	39 c2                	cmp    %eax,%edx
f010222e:	74 19                	je     f0102249 <mem_init+0x1196>
f0102230:	68 94 45 10 f0       	push   $0xf0104594
f0102235:	68 75 3c 10 f0       	push   $0xf0103c75
f010223a:	68 d5 02 00 00       	push   $0x2d5
f010223f:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102244:	e8 42 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102249:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010224f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102252:	77 a6                	ja     f01021fa <mem_init+0x1147>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102254:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102257:	c1 e7 0c             	shl    $0xc,%edi
f010225a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010225f:	eb 30                	jmp    f0102291 <mem_init+0x11de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102261:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102267:	89 f0                	mov    %esi,%eax
f0102269:	e8 d7 e6 ff ff       	call   f0100945 <check_va2pa>
f010226e:	39 c3                	cmp    %eax,%ebx
f0102270:	74 19                	je     f010228b <mem_init+0x11d8>
f0102272:	68 c8 45 10 f0       	push   $0xf01045c8
f0102277:	68 75 3c 10 f0       	push   $0xf0103c75
f010227c:	68 d9 02 00 00       	push   $0x2d9
f0102281:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102286:	e8 00 de ff ff       	call   f010008b <_panic>
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010228b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102291:	39 fb                	cmp    %edi,%ebx
f0102293:	72 cc                	jb     f0102261 <mem_init+0x11ae>
f0102295:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010229a:	89 da                	mov    %ebx,%edx
f010229c:	89 f0                	mov    %esi,%eax
f010229e:	e8 a2 e6 ff ff       	call   f0100945 <check_va2pa>
f01022a3:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022a9:	39 c2                	cmp    %eax,%edx
f01022ab:	74 19                	je     f01022c6 <mem_init+0x1213>
f01022ad:	68 f0 45 10 f0       	push   $0xf01045f0
f01022b2:	68 75 3c 10 f0       	push   $0xf0103c75
f01022b7:	68 dd 02 00 00       	push   $0x2dd
f01022bc:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01022c1:	e8 c5 dd ff ff       	call   f010008b <_panic>
f01022c6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022cc:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022d2:	75 c6                	jne    f010229a <mem_init+0x11e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022d4:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022d9:	89 f0                	mov    %esi,%eax
f01022db:	e8 65 e6 ff ff       	call   f0100945 <check_va2pa>
f01022e0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022e3:	74 51                	je     f0102336 <mem_init+0x1283>
f01022e5:	68 38 46 10 f0       	push   $0xf0104638
f01022ea:	68 75 3c 10 f0       	push   $0xf0103c75
f01022ef:	68 de 02 00 00       	push   $0x2de
f01022f4:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01022f9:	e8 8d dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022fe:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102303:	72 36                	jb     f010233b <mem_init+0x1288>
f0102305:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010230a:	76 07                	jbe    f0102313 <mem_init+0x1260>
f010230c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102311:	75 28                	jne    f010233b <mem_init+0x1288>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102313:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102317:	0f 85 83 00 00 00    	jne    f01023a0 <mem_init+0x12ed>
f010231d:	68 4c 3f 10 f0       	push   $0xf0103f4c
f0102322:	68 75 3c 10 f0       	push   $0xf0103c75
f0102327:	68 e6 02 00 00       	push   $0x2e6
f010232c:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102331:	e8 55 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102336:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010233b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102340:	76 3f                	jbe    f0102381 <mem_init+0x12ce>
				assert(pgdir[i] & PTE_P);
f0102342:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102345:	f6 c2 01             	test   $0x1,%dl
f0102348:	75 19                	jne    f0102363 <mem_init+0x12b0>
f010234a:	68 4c 3f 10 f0       	push   $0xf0103f4c
f010234f:	68 75 3c 10 f0       	push   $0xf0103c75
f0102354:	68 ea 02 00 00       	push   $0x2ea
f0102359:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010235e:	e8 28 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102363:	f6 c2 02             	test   $0x2,%dl
f0102366:	75 38                	jne    f01023a0 <mem_init+0x12ed>
f0102368:	68 5d 3f 10 f0       	push   $0xf0103f5d
f010236d:	68 75 3c 10 f0       	push   $0xf0103c75
f0102372:	68 eb 02 00 00       	push   $0x2eb
f0102377:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010237c:	e8 0a dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102381:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102385:	74 19                	je     f01023a0 <mem_init+0x12ed>
f0102387:	68 6e 3f 10 f0       	push   $0xf0103f6e
f010238c:	68 75 3c 10 f0       	push   $0xf0103c75
f0102391:	68 ed 02 00 00       	push   $0x2ed
f0102396:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010239b:	e8 eb dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023a0:	83 c0 01             	add    $0x1,%eax
f01023a3:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023a8:	0f 86 50 ff ff ff    	jbe    f01022fe <mem_init+0x124b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023ae:	83 ec 0c             	sub    $0xc,%esp
f01023b1:	68 68 46 10 f0       	push   $0xf0104668
f01023b6:	e8 ba 03 00 00       	call   f0102775 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023bb:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023c0:	83 c4 10             	add    $0x10,%esp
f01023c3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023c8:	77 15                	ja     f01023df <mem_init+0x132c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023ca:	50                   	push   %eax
f01023cb:	68 64 40 10 f0       	push   $0xf0104064
f01023d0:	68 e0 00 00 00       	push   $0xe0
f01023d5:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01023da:	e8 ac dc ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01023df:	05 00 00 00 10       	add    $0x10000000,%eax
f01023e4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01023ec:	e8 b8 e5 ff ff       	call   f01009a9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01023f1:	0f 20 c0             	mov    %cr0,%eax
f01023f4:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01023f7:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023fc:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023ff:	83 ec 0c             	sub    $0xc,%esp
f0102402:	6a 00                	push   $0x0
f0102404:	e8 69 e9 ff ff       	call   f0100d72 <page_alloc>
f0102409:	89 c3                	mov    %eax,%ebx
f010240b:	83 c4 10             	add    $0x10,%esp
f010240e:	85 c0                	test   %eax,%eax
f0102410:	75 19                	jne    f010242b <mem_init+0x1378>
f0102412:	68 5f 3d 10 f0       	push   $0xf0103d5f
f0102417:	68 75 3c 10 f0       	push   $0xf0103c75
f010241c:	68 ab 03 00 00       	push   $0x3ab
f0102421:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102426:	e8 60 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010242b:	83 ec 0c             	sub    $0xc,%esp
f010242e:	6a 00                	push   $0x0
f0102430:	e8 3d e9 ff ff       	call   f0100d72 <page_alloc>
f0102435:	89 c7                	mov    %eax,%edi
f0102437:	83 c4 10             	add    $0x10,%esp
f010243a:	85 c0                	test   %eax,%eax
f010243c:	75 19                	jne    f0102457 <mem_init+0x13a4>
f010243e:	68 75 3d 10 f0       	push   $0xf0103d75
f0102443:	68 75 3c 10 f0       	push   $0xf0103c75
f0102448:	68 ac 03 00 00       	push   $0x3ac
f010244d:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102452:	e8 34 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102457:	83 ec 0c             	sub    $0xc,%esp
f010245a:	6a 00                	push   $0x0
f010245c:	e8 11 e9 ff ff       	call   f0100d72 <page_alloc>
f0102461:	89 c6                	mov    %eax,%esi
f0102463:	83 c4 10             	add    $0x10,%esp
f0102466:	85 c0                	test   %eax,%eax
f0102468:	75 19                	jne    f0102483 <mem_init+0x13d0>
f010246a:	68 8b 3d 10 f0       	push   $0xf0103d8b
f010246f:	68 75 3c 10 f0       	push   $0xf0103c75
f0102474:	68 ad 03 00 00       	push   $0x3ad
f0102479:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010247e:	e8 08 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102483:	83 ec 0c             	sub    $0xc,%esp
f0102486:	53                   	push   %ebx
f0102487:	e8 56 e9 ff ff       	call   f0100de2 <page_free>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010248c:	89 f8                	mov    %edi,%eax
f010248e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102494:	c1 f8 03             	sar    $0x3,%eax
f0102497:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010249a:	89 c2                	mov    %eax,%edx
f010249c:	c1 ea 0c             	shr    $0xc,%edx
f010249f:	83 c4 10             	add    $0x10,%esp
f01024a2:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024a8:	72 12                	jb     f01024bc <mem_init+0x1409>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024aa:	50                   	push   %eax
f01024ab:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01024b0:	6a 59                	push   $0x59
f01024b2:	68 5b 3c 10 f0       	push   $0xf0103c5b
f01024b7:	e8 cf db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024bc:	83 ec 04             	sub    $0x4,%esp
f01024bf:	68 00 10 00 00       	push   $0x1000
f01024c4:	6a 01                	push   $0x1
f01024c6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024cb:	50                   	push   %eax
f01024cc:	e8 ef 0d 00 00       	call   f01032c0 <memset>
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024d1:	89 f0                	mov    %esi,%eax
f01024d3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024d9:	c1 f8 03             	sar    $0x3,%eax
f01024dc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024df:	89 c2                	mov    %eax,%edx
f01024e1:	c1 ea 0c             	shr    $0xc,%edx
f01024e4:	83 c4 10             	add    $0x10,%esp
f01024e7:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024ed:	72 12                	jb     f0102501 <mem_init+0x144e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024ef:	50                   	push   %eax
f01024f0:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01024f5:	6a 59                	push   $0x59
f01024f7:	68 5b 3c 10 f0       	push   $0xf0103c5b
f01024fc:	e8 8a db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102501:	83 ec 04             	sub    $0x4,%esp
f0102504:	68 00 10 00 00       	push   $0x1000
f0102509:	6a 02                	push   $0x2
f010250b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102510:	50                   	push   %eax
f0102511:	e8 aa 0d 00 00       	call   f01032c0 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102516:	6a 02                	push   $0x2
f0102518:	68 00 10 00 00       	push   $0x1000
f010251d:	57                   	push   %edi
f010251e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102524:	e8 12 eb ff ff       	call   f010103b <page_insert>
	assert(pp1->pp_ref == 1);
f0102529:	83 c4 20             	add    $0x20,%esp
f010252c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102531:	74 19                	je     f010254c <mem_init+0x1499>
f0102533:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0102538:	68 75 3c 10 f0       	push   $0xf0103c75
f010253d:	68 b2 03 00 00       	push   $0x3b2
f0102542:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102547:	e8 3f db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010254c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102553:	01 01 01 
f0102556:	74 19                	je     f0102571 <mem_init+0x14be>
f0102558:	68 88 46 10 f0       	push   $0xf0104688
f010255d:	68 75 3c 10 f0       	push   $0xf0103c75
f0102562:	68 b3 03 00 00       	push   $0x3b3
f0102567:	68 4f 3c 10 f0       	push   $0xf0103c4f
f010256c:	e8 1a db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102571:	6a 02                	push   $0x2
f0102573:	68 00 10 00 00       	push   $0x1000
f0102578:	56                   	push   %esi
f0102579:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010257f:	e8 b7 ea ff ff       	call   f010103b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102584:	83 c4 10             	add    $0x10,%esp
f0102587:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010258e:	02 02 02 
f0102591:	74 19                	je     f01025ac <mem_init+0x14f9>
f0102593:	68 ac 46 10 f0       	push   $0xf01046ac
f0102598:	68 75 3c 10 f0       	push   $0xf0103c75
f010259d:	68 b5 03 00 00       	push   $0x3b5
f01025a2:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01025a7:	e8 df da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025ac:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025b1:	74 19                	je     f01025cc <mem_init+0x1519>
f01025b3:	68 7e 3e 10 f0       	push   $0xf0103e7e
f01025b8:	68 75 3c 10 f0       	push   $0xf0103c75
f01025bd:	68 b6 03 00 00       	push   $0x3b6
f01025c2:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01025c7:	e8 bf da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025cc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025d1:	74 19                	je     f01025ec <mem_init+0x1539>
f01025d3:	68 f3 3e 10 f0       	push   $0xf0103ef3
f01025d8:	68 75 3c 10 f0       	push   $0xf0103c75
f01025dd:	68 b7 03 00 00       	push   $0x3b7
f01025e2:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01025e7:	e8 9f da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025ec:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025f3:	03 03 03 
//return the starting physical address corresponding to an element of pages[]
//if pages[N]==pp, then page2pa(pp)==N*PGSIZE
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025f6:	89 f0                	mov    %esi,%eax
f01025f8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01025fe:	c1 f8 03             	sar    $0x3,%eax
f0102601:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102604:	89 c2                	mov    %eax,%edx
f0102606:	c1 ea 0c             	shr    $0xc,%edx
f0102609:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010260f:	72 12                	jb     f0102623 <mem_init+0x1570>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102611:	50                   	push   %eax
f0102612:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0102617:	6a 59                	push   $0x59
f0102619:	68 5b 3c 10 f0       	push   $0xf0103c5b
f010261e:	e8 68 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102623:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010262a:	03 03 03 
f010262d:	74 19                	je     f0102648 <mem_init+0x1595>
f010262f:	68 d0 46 10 f0       	push   $0xf01046d0
f0102634:	68 75 3c 10 f0       	push   $0xf0103c75
f0102639:	68 b9 03 00 00       	push   $0x3b9
f010263e:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102643:	e8 43 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102648:	83 ec 08             	sub    $0x8,%esp
f010264b:	68 00 10 00 00       	push   $0x1000
f0102650:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102656:	e8 9d e9 ff ff       	call   f0100ff8 <page_remove>
	assert(pp2->pp_ref == 0);
f010265b:	83 c4 10             	add    $0x10,%esp
f010265e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102663:	74 19                	je     f010267e <mem_init+0x15cb>
f0102665:	68 e2 3e 10 f0       	push   $0xf0103ee2
f010266a:	68 75 3c 10 f0       	push   $0xf0103c75
f010266f:	68 bb 03 00 00       	push   $0x3bb
f0102674:	68 4f 3c 10 f0       	push   $0xf0103c4f
f0102679:	e8 0d da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010267e:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102684:	8b 11                	mov    (%ecx),%edx
f0102686:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010268c:	89 d8                	mov    %ebx,%eax
f010268e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102694:	c1 f8 03             	sar    $0x3,%eax
f0102697:	c1 e0 0c             	shl    $0xc,%eax
f010269a:	39 c2                	cmp    %eax,%edx
f010269c:	74 19                	je     f01026b7 <mem_init+0x1604>
f010269e:	68 4c 42 10 f0       	push   $0xf010424c
f01026a3:	68 75 3c 10 f0       	push   $0xf0103c75
f01026a8:	68 be 03 00 00       	push   $0x3be
f01026ad:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01026b2:	e8 d4 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026b7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026bd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026c2:	74 19                	je     f01026dd <mem_init+0x162a>
f01026c4:	68 6d 3e 10 f0       	push   $0xf0103e6d
f01026c9:	68 75 3c 10 f0       	push   $0xf0103c75
f01026ce:	68 c0 03 00 00       	push   $0x3c0
f01026d3:	68 4f 3c 10 f0       	push   $0xf0103c4f
f01026d8:	e8 ae d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026dd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026e3:	83 ec 0c             	sub    $0xc,%esp
f01026e6:	53                   	push   %ebx
f01026e7:	e8 f6 e6 ff ff       	call   f0100de2 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026ec:	c7 04 24 fc 46 10 f0 	movl   $0xf01046fc,(%esp)
f01026f3:	e8 7d 00 00 00       	call   f0102775 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026f8:	83 c4 10             	add    $0x10,%esp
f01026fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026fe:	5b                   	pop    %ebx
f01026ff:	5e                   	pop    %esi
f0102700:	5f                   	pop    %edi
f0102701:	5d                   	pop    %ebp
f0102702:	c3                   	ret    

f0102703 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102703:	55                   	push   %ebp
f0102704:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102706:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102709:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010270c:	5d                   	pop    %ebp
f010270d:	c3                   	ret    

f010270e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010270e:	55                   	push   %ebp
f010270f:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102711:	ba 70 00 00 00       	mov    $0x70,%edx
f0102716:	8b 45 08             	mov    0x8(%ebp),%eax
f0102719:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010271a:	ba 71 00 00 00       	mov    $0x71,%edx
f010271f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102720:	0f b6 c0             	movzbl %al,%eax
}
f0102723:	5d                   	pop    %ebp
f0102724:	c3                   	ret    

f0102725 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102725:	55                   	push   %ebp
f0102726:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102728:	ba 70 00 00 00       	mov    $0x70,%edx
f010272d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102730:	ee                   	out    %al,(%dx)
f0102731:	ba 71 00 00 00       	mov    $0x71,%edx
f0102736:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102739:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010273a:	5d                   	pop    %ebp
f010273b:	c3                   	ret    

f010273c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010273c:	55                   	push   %ebp
f010273d:	89 e5                	mov    %esp,%ebp
f010273f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102742:	ff 75 08             	pushl  0x8(%ebp)
f0102745:	e8 a8 de ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f010274a:	83 c4 10             	add    $0x10,%esp
f010274d:	c9                   	leave  
f010274e:	c3                   	ret    

f010274f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010274f:	55                   	push   %ebp
f0102750:	89 e5                	mov    %esp,%ebp
f0102752:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102755:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010275c:	ff 75 0c             	pushl  0xc(%ebp)
f010275f:	ff 75 08             	pushl  0x8(%ebp)
f0102762:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102765:	50                   	push   %eax
f0102766:	68 3c 27 10 f0       	push   $0xf010273c
f010276b:	e8 37 04 00 00       	call   f0102ba7 <vprintfmt>
	return cnt;
}
f0102770:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102773:	c9                   	leave  
f0102774:	c3                   	ret    

f0102775 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102775:	55                   	push   %ebp
f0102776:	89 e5                	mov    %esp,%ebp
f0102778:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010277b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010277e:	50                   	push   %eax
f010277f:	ff 75 08             	pushl  0x8(%ebp)
f0102782:	e8 c8 ff ff ff       	call   f010274f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102787:	c9                   	leave  
f0102788:	c3                   	ret    

f0102789 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102789:	55                   	push   %ebp
f010278a:	89 e5                	mov    %esp,%ebp
f010278c:	57                   	push   %edi
f010278d:	56                   	push   %esi
f010278e:	53                   	push   %ebx
f010278f:	83 ec 14             	sub    $0x14,%esp
f0102792:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102795:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102798:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010279b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010279e:	8b 1a                	mov    (%edx),%ebx
f01027a0:	8b 01                	mov    (%ecx),%eax
f01027a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027a5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027ac:	eb 7f                	jmp    f010282d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027b1:	01 d8                	add    %ebx,%eax
f01027b3:	89 c6                	mov    %eax,%esi
f01027b5:	c1 ee 1f             	shr    $0x1f,%esi
f01027b8:	01 c6                	add    %eax,%esi
f01027ba:	d1 fe                	sar    %esi
f01027bc:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027bf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027c2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027c5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027c7:	eb 03                	jmp    f01027cc <stab_binsearch+0x43>
			m--;
f01027c9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027cc:	39 c3                	cmp    %eax,%ebx
f01027ce:	7f 0d                	jg     f01027dd <stab_binsearch+0x54>
f01027d0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027d4:	83 ea 0c             	sub    $0xc,%edx
f01027d7:	39 f9                	cmp    %edi,%ecx
f01027d9:	75 ee                	jne    f01027c9 <stab_binsearch+0x40>
f01027db:	eb 05                	jmp    f01027e2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027dd:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027e0:	eb 4b                	jmp    f010282d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027e2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027e5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027e8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027ec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027ef:	76 11                	jbe    f0102802 <stab_binsearch+0x79>
			*region_left = m;
f01027f1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027f4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027f6:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027f9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102800:	eb 2b                	jmp    f010282d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102802:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102805:	73 14                	jae    f010281b <stab_binsearch+0x92>
			*region_right = m - 1;
f0102807:	83 e8 01             	sub    $0x1,%eax
f010280a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010280d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102810:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102812:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102819:	eb 12                	jmp    f010282d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010281b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010281e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102820:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102824:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102826:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010282d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102830:	0f 8e 78 ff ff ff    	jle    f01027ae <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102836:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010283a:	75 0f                	jne    f010284b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010283c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010283f:	8b 00                	mov    (%eax),%eax
f0102841:	83 e8 01             	sub    $0x1,%eax
f0102844:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102847:	89 06                	mov    %eax,(%esi)
f0102849:	eb 2c                	jmp    f0102877 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010284b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010284e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102850:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102853:	8b 0e                	mov    (%esi),%ecx
f0102855:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102858:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010285b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010285e:	eb 03                	jmp    f0102863 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102860:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102863:	39 c8                	cmp    %ecx,%eax
f0102865:	7e 0b                	jle    f0102872 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102867:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010286b:	83 ea 0c             	sub    $0xc,%edx
f010286e:	39 df                	cmp    %ebx,%edi
f0102870:	75 ee                	jne    f0102860 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102872:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102875:	89 06                	mov    %eax,(%esi)
	}
}
f0102877:	83 c4 14             	add    $0x14,%esp
f010287a:	5b                   	pop    %ebx
f010287b:	5e                   	pop    %esi
f010287c:	5f                   	pop    %edi
f010287d:	5d                   	pop    %ebp
f010287e:	c3                   	ret    

f010287f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010287f:	55                   	push   %ebp
f0102880:	89 e5                	mov    %esp,%ebp
f0102882:	57                   	push   %edi
f0102883:	56                   	push   %esi
f0102884:	53                   	push   %ebx
f0102885:	83 ec 3c             	sub    $0x3c,%esp
f0102888:	8b 75 08             	mov    0x8(%ebp),%esi
f010288b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010288e:	c7 03 28 47 10 f0    	movl   $0xf0104728,(%ebx)
	info->eip_line = 0;
f0102894:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010289b:	c7 43 08 28 47 10 f0 	movl   $0xf0104728,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01028a2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01028a9:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028ac:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028b3:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028b9:	76 11                	jbe    f01028cc <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028bb:	b8 6e c0 10 f0       	mov    $0xf010c06e,%eax
f01028c0:	3d c9 a2 10 f0       	cmp    $0xf010a2c9,%eax
f01028c5:	77 19                	ja     f01028e0 <debuginfo_eip+0x61>
f01028c7:	e9 c9 01 00 00       	jmp    f0102a95 <debuginfo_eip+0x216>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028cc:	83 ec 04             	sub    $0x4,%esp
f01028cf:	68 32 47 10 f0       	push   $0xf0104732
f01028d4:	6a 7f                	push   $0x7f
f01028d6:	68 3f 47 10 f0       	push   $0xf010473f
f01028db:	e8 ab d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028e0:	80 3d 6d c0 10 f0 00 	cmpb   $0x0,0xf010c06d
f01028e7:	0f 85 af 01 00 00    	jne    f0102a9c <debuginfo_eip+0x21d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028ed:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028f4:	b8 c8 a2 10 f0       	mov    $0xf010a2c8,%eax
f01028f9:	2d 70 49 10 f0       	sub    $0xf0104970,%eax
f01028fe:	c1 f8 02             	sar    $0x2,%eax
f0102901:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102907:	83 e8 01             	sub    $0x1,%eax
f010290a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010290d:	83 ec 08             	sub    $0x8,%esp
f0102910:	56                   	push   %esi
f0102911:	6a 64                	push   $0x64
f0102913:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102916:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102919:	b8 70 49 10 f0       	mov    $0xf0104970,%eax
f010291e:	e8 66 fe ff ff       	call   f0102789 <stab_binsearch>
	if (lfile == 0)
f0102923:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102926:	83 c4 10             	add    $0x10,%esp
f0102929:	85 c0                	test   %eax,%eax
f010292b:	0f 84 72 01 00 00    	je     f0102aa3 <debuginfo_eip+0x224>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102931:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102934:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102937:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010293a:	83 ec 08             	sub    $0x8,%esp
f010293d:	56                   	push   %esi
f010293e:	6a 24                	push   $0x24
f0102940:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102943:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102946:	b8 70 49 10 f0       	mov    $0xf0104970,%eax
f010294b:	e8 39 fe ff ff       	call   f0102789 <stab_binsearch>

	if (lfun <= rfun) {
f0102950:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102953:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102956:	83 c4 10             	add    $0x10,%esp
f0102959:	39 d0                	cmp    %edx,%eax
f010295b:	7f 40                	jg     f010299d <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010295d:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102960:	c1 e1 02             	shl    $0x2,%ecx
f0102963:	8d b9 70 49 10 f0    	lea    -0xfefb690(%ecx),%edi
f0102969:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010296c:	8b b9 70 49 10 f0    	mov    -0xfefb690(%ecx),%edi
f0102972:	b9 6e c0 10 f0       	mov    $0xf010c06e,%ecx
f0102977:	81 e9 c9 a2 10 f0    	sub    $0xf010a2c9,%ecx
f010297d:	39 cf                	cmp    %ecx,%edi
f010297f:	73 09                	jae    f010298a <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102981:	81 c7 c9 a2 10 f0    	add    $0xf010a2c9,%edi
f0102987:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010298a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010298d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102990:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102993:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102995:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102998:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010299b:	eb 0f                	jmp    f01029ac <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010299d:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01029a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01029a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029a9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029ac:	83 ec 08             	sub    $0x8,%esp
f01029af:	6a 3a                	push   $0x3a
f01029b1:	ff 73 08             	pushl  0x8(%ebx)
f01029b4:	e8 eb 08 00 00       	call   f01032a4 <strfind>
f01029b9:	2b 43 08             	sub    0x8(%ebx),%eax
f01029bc:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;
f01029bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029c2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01029c5:	8b 04 85 70 49 10 f0 	mov    -0xfefb690(,%eax,4),%eax
f01029cc:	05 c9 a2 10 f0       	add    $0xf010a2c9,%eax
f01029d1:	89 03                	mov    %eax,(%ebx)

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029d3:	83 c4 08             	add    $0x8,%esp
f01029d6:	56                   	push   %esi
f01029d7:	6a 44                	push   $0x44
f01029d9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029dc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029df:	b8 70 49 10 f0       	mov    $0xf0104970,%eax
f01029e4:	e8 a0 fd ff ff       	call   f0102789 <stab_binsearch>
	if (lline > rline) {
f01029e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029ec:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01029ef:	83 c4 10             	add    $0x10,%esp
f01029f2:	39 d0                	cmp    %edx,%eax
f01029f4:	0f 8f b0 00 00 00    	jg     f0102aaa <debuginfo_eip+0x22b>
	    return -1;
	} else {
	    info->eip_line = stabs[rline].n_desc;
f01029fa:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029fd:	0f b7 14 95 76 49 10 	movzwl -0xfefb68a(,%edx,4),%edx
f0102a04:	f0 
f0102a05:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a0b:	89 c2                	mov    %eax,%edx
f0102a0d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102a10:	8d 04 85 70 49 10 f0 	lea    -0xfefb690(,%eax,4),%eax
f0102a17:	eb 06                	jmp    f0102a1f <debuginfo_eip+0x1a0>
f0102a19:	83 ea 01             	sub    $0x1,%edx
f0102a1c:	83 e8 0c             	sub    $0xc,%eax
f0102a1f:	39 d7                	cmp    %edx,%edi
f0102a21:	7f 34                	jg     f0102a57 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0102a23:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a27:	80 f9 84             	cmp    $0x84,%cl
f0102a2a:	74 0b                	je     f0102a37 <debuginfo_eip+0x1b8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a2c:	80 f9 64             	cmp    $0x64,%cl
f0102a2f:	75 e8                	jne    f0102a19 <debuginfo_eip+0x19a>
f0102a31:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a35:	74 e2                	je     f0102a19 <debuginfo_eip+0x19a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a37:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a3a:	8b 14 85 70 49 10 f0 	mov    -0xfefb690(,%eax,4),%edx
f0102a41:	b8 6e c0 10 f0       	mov    $0xf010c06e,%eax
f0102a46:	2d c9 a2 10 f0       	sub    $0xf010a2c9,%eax
f0102a4b:	39 c2                	cmp    %eax,%edx
f0102a4d:	73 08                	jae    f0102a57 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a4f:	81 c2 c9 a2 10 f0    	add    $0xf010a2c9,%edx
f0102a55:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a57:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a5a:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a5d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a62:	39 f2                	cmp    %esi,%edx
f0102a64:	7d 50                	jge    f0102ab6 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f0102a66:	83 c2 01             	add    $0x1,%edx
f0102a69:	89 d0                	mov    %edx,%eax
f0102a6b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a6e:	8d 14 95 70 49 10 f0 	lea    -0xfefb690(,%edx,4),%edx
f0102a75:	eb 04                	jmp    f0102a7b <debuginfo_eip+0x1fc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a77:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a7b:	39 c6                	cmp    %eax,%esi
f0102a7d:	7e 32                	jle    f0102ab1 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a7f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a83:	83 c0 01             	add    $0x1,%eax
f0102a86:	83 c2 0c             	add    $0xc,%edx
f0102a89:	80 f9 a0             	cmp    $0xa0,%cl
f0102a8c:	74 e9                	je     f0102a77 <debuginfo_eip+0x1f8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a93:	eb 21                	jmp    f0102ab6 <debuginfo_eip+0x237>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a9a:	eb 1a                	jmp    f0102ab6 <debuginfo_eip+0x237>
f0102a9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa1:	eb 13                	jmp    f0102ab6 <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102aa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa8:	eb 0c                	jmp    f0102ab6 <debuginfo_eip+0x237>
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline) {
	    return -1;
f0102aaa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aaf:	eb 05                	jmp    f0102ab6 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ab1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ab6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ab9:	5b                   	pop    %ebx
f0102aba:	5e                   	pop    %esi
f0102abb:	5f                   	pop    %edi
f0102abc:	5d                   	pop    %ebp
f0102abd:	c3                   	ret    

f0102abe <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102abe:	55                   	push   %ebp
f0102abf:	89 e5                	mov    %esp,%ebp
f0102ac1:	57                   	push   %edi
f0102ac2:	56                   	push   %esi
f0102ac3:	53                   	push   %ebx
f0102ac4:	83 ec 1c             	sub    $0x1c,%esp
f0102ac7:	89 c7                	mov    %eax,%edi
f0102ac9:	89 d6                	mov    %edx,%esi
f0102acb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ace:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ad1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ad4:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102ad7:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102ada:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102adf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ae2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ae5:	39 d3                	cmp    %edx,%ebx
f0102ae7:	72 05                	jb     f0102aee <printnum+0x30>
f0102ae9:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102aec:	77 45                	ja     f0102b33 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102aee:	83 ec 0c             	sub    $0xc,%esp
f0102af1:	ff 75 18             	pushl  0x18(%ebp)
f0102af4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102af7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102afa:	53                   	push   %ebx
f0102afb:	ff 75 10             	pushl  0x10(%ebp)
f0102afe:	83 ec 08             	sub    $0x8,%esp
f0102b01:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b04:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b07:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b0a:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b0d:	e8 be 09 00 00       	call   f01034d0 <__udivdi3>
f0102b12:	83 c4 18             	add    $0x18,%esp
f0102b15:	52                   	push   %edx
f0102b16:	50                   	push   %eax
f0102b17:	89 f2                	mov    %esi,%edx
f0102b19:	89 f8                	mov    %edi,%eax
f0102b1b:	e8 9e ff ff ff       	call   f0102abe <printnum>
f0102b20:	83 c4 20             	add    $0x20,%esp
f0102b23:	eb 18                	jmp    f0102b3d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b25:	83 ec 08             	sub    $0x8,%esp
f0102b28:	56                   	push   %esi
f0102b29:	ff 75 18             	pushl  0x18(%ebp)
f0102b2c:	ff d7                	call   *%edi
f0102b2e:	83 c4 10             	add    $0x10,%esp
f0102b31:	eb 03                	jmp    f0102b36 <printnum+0x78>
f0102b33:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b36:	83 eb 01             	sub    $0x1,%ebx
f0102b39:	85 db                	test   %ebx,%ebx
f0102b3b:	7f e8                	jg     f0102b25 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b3d:	83 ec 08             	sub    $0x8,%esp
f0102b40:	56                   	push   %esi
f0102b41:	83 ec 04             	sub    $0x4,%esp
f0102b44:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b47:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b4a:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b4d:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b50:	e8 ab 0a 00 00       	call   f0103600 <__umoddi3>
f0102b55:	83 c4 14             	add    $0x14,%esp
f0102b58:	0f be 80 4d 47 10 f0 	movsbl -0xfefb8b3(%eax),%eax
f0102b5f:	50                   	push   %eax
f0102b60:	ff d7                	call   *%edi
}
f0102b62:	83 c4 10             	add    $0x10,%esp
f0102b65:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b68:	5b                   	pop    %ebx
f0102b69:	5e                   	pop    %esi
f0102b6a:	5f                   	pop    %edi
f0102b6b:	5d                   	pop    %ebp
f0102b6c:	c3                   	ret    

f0102b6d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b6d:	55                   	push   %ebp
f0102b6e:	89 e5                	mov    %esp,%ebp
f0102b70:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b73:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b77:	8b 10                	mov    (%eax),%edx
f0102b79:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b7c:	73 0a                	jae    f0102b88 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b7e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b81:	89 08                	mov    %ecx,(%eax)
f0102b83:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b86:	88 02                	mov    %al,(%edx)
}
f0102b88:	5d                   	pop    %ebp
f0102b89:	c3                   	ret    

f0102b8a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b8a:	55                   	push   %ebp
f0102b8b:	89 e5                	mov    %esp,%ebp
f0102b8d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b90:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b93:	50                   	push   %eax
f0102b94:	ff 75 10             	pushl  0x10(%ebp)
f0102b97:	ff 75 0c             	pushl  0xc(%ebp)
f0102b9a:	ff 75 08             	pushl  0x8(%ebp)
f0102b9d:	e8 05 00 00 00       	call   f0102ba7 <vprintfmt>
	va_end(ap);
}
f0102ba2:	83 c4 10             	add    $0x10,%esp
f0102ba5:	c9                   	leave  
f0102ba6:	c3                   	ret    

f0102ba7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102ba7:	55                   	push   %ebp
f0102ba8:	89 e5                	mov    %esp,%ebp
f0102baa:	57                   	push   %edi
f0102bab:	56                   	push   %esi
f0102bac:	53                   	push   %ebx
f0102bad:	83 ec 2c             	sub    $0x2c,%esp
f0102bb0:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bb3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bb6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bb9:	eb 12                	jmp    f0102bcd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bbb:	85 c0                	test   %eax,%eax
f0102bbd:	0f 84 36 04 00 00    	je     f0102ff9 <vprintfmt+0x452>
				return;
			putch(ch, putdat);
f0102bc3:	83 ec 08             	sub    $0x8,%esp
f0102bc6:	53                   	push   %ebx
f0102bc7:	50                   	push   %eax
f0102bc8:	ff d6                	call   *%esi
f0102bca:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bcd:	83 c7 01             	add    $0x1,%edi
f0102bd0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102bd4:	83 f8 25             	cmp    $0x25,%eax
f0102bd7:	75 e2                	jne    f0102bbb <vprintfmt+0x14>
f0102bd9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102bdd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102be4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102beb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bf2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bf7:	eb 07                	jmp    f0102c00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bfc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c00:	8d 47 01             	lea    0x1(%edi),%eax
f0102c03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c06:	0f b6 07             	movzbl (%edi),%eax
f0102c09:	0f b6 d0             	movzbl %al,%edx
f0102c0c:	83 e8 23             	sub    $0x23,%eax
f0102c0f:	3c 55                	cmp    $0x55,%al
f0102c11:	0f 87 c7 03 00 00    	ja     f0102fde <vprintfmt+0x437>
f0102c17:	0f b6 c0             	movzbl %al,%eax
f0102c1a:	ff 24 85 e0 47 10 f0 	jmp    *-0xfefb820(,%eax,4)
f0102c21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c24:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c28:	eb d6                	jmp    f0102c00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c32:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c35:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c38:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102c3c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102c3f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102c42:	83 f9 09             	cmp    $0x9,%ecx
f0102c45:	77 3f                	ja     f0102c86 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c47:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c4a:	eb e9                	jmp    f0102c35 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c4f:	8b 00                	mov    (%eax),%eax
f0102c51:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c54:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c57:	8d 40 04             	lea    0x4(%eax),%eax
f0102c5a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c60:	eb 2a                	jmp    f0102c8c <vprintfmt+0xe5>
f0102c62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c65:	85 c0                	test   %eax,%eax
f0102c67:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c6c:	0f 49 d0             	cmovns %eax,%edx
f0102c6f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c75:	eb 89                	jmp    f0102c00 <vprintfmt+0x59>
f0102c77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c7a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c81:	e9 7a ff ff ff       	jmp    f0102c00 <vprintfmt+0x59>
f0102c86:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c89:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c8c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c90:	0f 89 6a ff ff ff    	jns    f0102c00 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c96:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c99:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c9c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ca3:	e9 58 ff ff ff       	jmp    f0102c00 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102ca8:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102cae:	e9 4d ff ff ff       	jmp    f0102c00 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb6:	8d 78 04             	lea    0x4(%eax),%edi
f0102cb9:	83 ec 08             	sub    $0x8,%esp
f0102cbc:	53                   	push   %ebx
f0102cbd:	ff 30                	pushl  (%eax)
f0102cbf:	ff d6                	call   *%esi
			break;
f0102cc1:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102cc4:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102cca:	e9 fe fe ff ff       	jmp    f0102bcd <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ccf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd2:	8d 78 04             	lea    0x4(%eax),%edi
f0102cd5:	8b 00                	mov    (%eax),%eax
f0102cd7:	99                   	cltd   
f0102cd8:	31 d0                	xor    %edx,%eax
f0102cda:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102cdc:	83 f8 07             	cmp    $0x7,%eax
f0102cdf:	7f 0b                	jg     f0102cec <vprintfmt+0x145>
f0102ce1:	8b 14 85 40 49 10 f0 	mov    -0xfefb6c0(,%eax,4),%edx
f0102ce8:	85 d2                	test   %edx,%edx
f0102cea:	75 1b                	jne    f0102d07 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102cec:	50                   	push   %eax
f0102ced:	68 65 47 10 f0       	push   $0xf0104765
f0102cf2:	53                   	push   %ebx
f0102cf3:	56                   	push   %esi
f0102cf4:	e8 91 fe ff ff       	call   f0102b8a <printfmt>
f0102cf9:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cfc:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d02:	e9 c6 fe ff ff       	jmp    f0102bcd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d07:	52                   	push   %edx
f0102d08:	68 87 3c 10 f0       	push   $0xf0103c87
f0102d0d:	53                   	push   %ebx
f0102d0e:	56                   	push   %esi
f0102d0f:	e8 76 fe ff ff       	call   f0102b8a <printfmt>
f0102d14:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d17:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d1d:	e9 ab fe ff ff       	jmp    f0102bcd <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d22:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d25:	83 c0 04             	add    $0x4,%eax
f0102d28:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102d2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d2e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d30:	85 ff                	test   %edi,%edi
f0102d32:	b8 5e 47 10 f0       	mov    $0xf010475e,%eax
f0102d37:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d3a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d3e:	0f 8e 94 00 00 00    	jle    f0102dd8 <vprintfmt+0x231>
f0102d44:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d48:	0f 84 98 00 00 00    	je     f0102de6 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d4e:	83 ec 08             	sub    $0x8,%esp
f0102d51:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d54:	57                   	push   %edi
f0102d55:	e8 00 04 00 00       	call   f010315a <strnlen>
f0102d5a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d5d:	29 c1                	sub    %eax,%ecx
f0102d5f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d62:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d65:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d69:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d6c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d6f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d71:	eb 0f                	jmp    f0102d82 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d73:	83 ec 08             	sub    $0x8,%esp
f0102d76:	53                   	push   %ebx
f0102d77:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d7a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d7c:	83 ef 01             	sub    $0x1,%edi
f0102d7f:	83 c4 10             	add    $0x10,%esp
f0102d82:	85 ff                	test   %edi,%edi
f0102d84:	7f ed                	jg     f0102d73 <vprintfmt+0x1cc>
f0102d86:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d89:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d8c:	85 c9                	test   %ecx,%ecx
f0102d8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d93:	0f 49 c1             	cmovns %ecx,%eax
f0102d96:	29 c1                	sub    %eax,%ecx
f0102d98:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d9b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d9e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102da1:	89 cb                	mov    %ecx,%ebx
f0102da3:	eb 4d                	jmp    f0102df2 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102da5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102da9:	74 1b                	je     f0102dc6 <vprintfmt+0x21f>
f0102dab:	0f be c0             	movsbl %al,%eax
f0102dae:	83 e8 20             	sub    $0x20,%eax
f0102db1:	83 f8 5e             	cmp    $0x5e,%eax
f0102db4:	76 10                	jbe    f0102dc6 <vprintfmt+0x21f>
					putch('?', putdat);
f0102db6:	83 ec 08             	sub    $0x8,%esp
f0102db9:	ff 75 0c             	pushl  0xc(%ebp)
f0102dbc:	6a 3f                	push   $0x3f
f0102dbe:	ff 55 08             	call   *0x8(%ebp)
f0102dc1:	83 c4 10             	add    $0x10,%esp
f0102dc4:	eb 0d                	jmp    f0102dd3 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102dc6:	83 ec 08             	sub    $0x8,%esp
f0102dc9:	ff 75 0c             	pushl  0xc(%ebp)
f0102dcc:	52                   	push   %edx
f0102dcd:	ff 55 08             	call   *0x8(%ebp)
f0102dd0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102dd3:	83 eb 01             	sub    $0x1,%ebx
f0102dd6:	eb 1a                	jmp    f0102df2 <vprintfmt+0x24b>
f0102dd8:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ddb:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dde:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102de1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102de4:	eb 0c                	jmp    f0102df2 <vprintfmt+0x24b>
f0102de6:	89 75 08             	mov    %esi,0x8(%ebp)
f0102de9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dec:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102def:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102df2:	83 c7 01             	add    $0x1,%edi
f0102df5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102df9:	0f be d0             	movsbl %al,%edx
f0102dfc:	85 d2                	test   %edx,%edx
f0102dfe:	74 23                	je     f0102e23 <vprintfmt+0x27c>
f0102e00:	85 f6                	test   %esi,%esi
f0102e02:	78 a1                	js     f0102da5 <vprintfmt+0x1fe>
f0102e04:	83 ee 01             	sub    $0x1,%esi
f0102e07:	79 9c                	jns    f0102da5 <vprintfmt+0x1fe>
f0102e09:	89 df                	mov    %ebx,%edi
f0102e0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e0e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e11:	eb 18                	jmp    f0102e2b <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e13:	83 ec 08             	sub    $0x8,%esp
f0102e16:	53                   	push   %ebx
f0102e17:	6a 20                	push   $0x20
f0102e19:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e1b:	83 ef 01             	sub    $0x1,%edi
f0102e1e:	83 c4 10             	add    $0x10,%esp
f0102e21:	eb 08                	jmp    f0102e2b <vprintfmt+0x284>
f0102e23:	89 df                	mov    %ebx,%edi
f0102e25:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e28:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e2b:	85 ff                	test   %edi,%edi
f0102e2d:	7f e4                	jg     f0102e13 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e2f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102e32:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e38:	e9 90 fd ff ff       	jmp    f0102bcd <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e3d:	83 f9 01             	cmp    $0x1,%ecx
f0102e40:	7e 19                	jle    f0102e5b <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102e42:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e45:	8b 50 04             	mov    0x4(%eax),%edx
f0102e48:	8b 00                	mov    (%eax),%eax
f0102e4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e4d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e50:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e53:	8d 40 08             	lea    0x8(%eax),%eax
f0102e56:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e59:	eb 38                	jmp    f0102e93 <vprintfmt+0x2ec>
	else if (lflag)
f0102e5b:	85 c9                	test   %ecx,%ecx
f0102e5d:	74 1b                	je     f0102e7a <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e62:	8b 00                	mov    (%eax),%eax
f0102e64:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e67:	89 c1                	mov    %eax,%ecx
f0102e69:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e6c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e72:	8d 40 04             	lea    0x4(%eax),%eax
f0102e75:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e78:	eb 19                	jmp    f0102e93 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e7d:	8b 00                	mov    (%eax),%eax
f0102e7f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e82:	89 c1                	mov    %eax,%ecx
f0102e84:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e87:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e8d:	8d 40 04             	lea    0x4(%eax),%eax
f0102e90:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e93:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e96:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e99:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e9e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102ea2:	0f 89 02 01 00 00    	jns    f0102faa <vprintfmt+0x403>
				putch('-', putdat);
f0102ea8:	83 ec 08             	sub    $0x8,%esp
f0102eab:	53                   	push   %ebx
f0102eac:	6a 2d                	push   $0x2d
f0102eae:	ff d6                	call   *%esi
				num = -(long long) num;
f0102eb0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102eb3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102eb6:	f7 da                	neg    %edx
f0102eb8:	83 d1 00             	adc    $0x0,%ecx
f0102ebb:	f7 d9                	neg    %ecx
f0102ebd:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102ec0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ec5:	e9 e0 00 00 00       	jmp    f0102faa <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102eca:	83 f9 01             	cmp    $0x1,%ecx
f0102ecd:	7e 18                	jle    f0102ee7 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102ecf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ed2:	8b 10                	mov    (%eax),%edx
f0102ed4:	8b 48 04             	mov    0x4(%eax),%ecx
f0102ed7:	8d 40 08             	lea    0x8(%eax),%eax
f0102eda:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102edd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ee2:	e9 c3 00 00 00       	jmp    f0102faa <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102ee7:	85 c9                	test   %ecx,%ecx
f0102ee9:	74 1a                	je     f0102f05 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102eeb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eee:	8b 10                	mov    (%eax),%edx
f0102ef0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ef5:	8d 40 04             	lea    0x4(%eax),%eax
f0102ef8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102efb:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f00:	e9 a5 00 00 00       	jmp    f0102faa <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f05:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f08:	8b 10                	mov    (%eax),%edx
f0102f0a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f0f:	8d 40 04             	lea    0x4(%eax),%eax
f0102f12:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f15:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f1a:	e9 8b 00 00 00       	jmp    f0102faa <vprintfmt+0x403>
		case 'o':
			// Replace this with your code.
			// putch('0', putdat);
			// putch('X', putdat);
			// putch('X', putdat);
			num = (unsigned long long)
f0102f1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f22:	8b 10                	mov    (%eax),%edx
f0102f24:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0102f29:	8d 40 04             	lea    0x4(%eax),%eax
f0102f2c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102f2f:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102f34:	eb 74                	jmp    f0102faa <vprintfmt+0x403>
			// break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102f36:	83 ec 08             	sub    $0x8,%esp
f0102f39:	53                   	push   %ebx
f0102f3a:	6a 30                	push   $0x30
f0102f3c:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f3e:	83 c4 08             	add    $0x8,%esp
f0102f41:	53                   	push   %ebx
f0102f42:	6a 78                	push   $0x78
f0102f44:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102f46:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f49:	8b 10                	mov    (%eax),%edx
f0102f4b:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f50:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f53:	8d 40 04             	lea    0x4(%eax),%eax
f0102f56:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102f59:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102f5e:	eb 4a                	jmp    f0102faa <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f60:	83 f9 01             	cmp    $0x1,%ecx
f0102f63:	7e 15                	jle    f0102f7a <vprintfmt+0x3d3>
		return va_arg(*ap, unsigned long long);
f0102f65:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f68:	8b 10                	mov    (%eax),%edx
f0102f6a:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f6d:	8d 40 08             	lea    0x8(%eax),%eax
f0102f70:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f73:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f78:	eb 30                	jmp    f0102faa <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f7a:	85 c9                	test   %ecx,%ecx
f0102f7c:	74 17                	je     f0102f95 <vprintfmt+0x3ee>
		return va_arg(*ap, unsigned long);
f0102f7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f81:	8b 10                	mov    (%eax),%edx
f0102f83:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f88:	8d 40 04             	lea    0x4(%eax),%eax
f0102f8b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f8e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f93:	eb 15                	jmp    f0102faa <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f95:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f98:	8b 10                	mov    (%eax),%edx
f0102f9a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f9f:	8d 40 04             	lea    0x4(%eax),%eax
f0102fa2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102fa5:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102faa:	83 ec 0c             	sub    $0xc,%esp
f0102fad:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102fb1:	57                   	push   %edi
f0102fb2:	ff 75 e0             	pushl  -0x20(%ebp)
f0102fb5:	50                   	push   %eax
f0102fb6:	51                   	push   %ecx
f0102fb7:	52                   	push   %edx
f0102fb8:	89 da                	mov    %ebx,%edx
f0102fba:	89 f0                	mov    %esi,%eax
f0102fbc:	e8 fd fa ff ff       	call   f0102abe <printnum>
			break;
f0102fc1:	83 c4 20             	add    $0x20,%esp
f0102fc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fc7:	e9 01 fc ff ff       	jmp    f0102bcd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102fcc:	83 ec 08             	sub    $0x8,%esp
f0102fcf:	53                   	push   %ebx
f0102fd0:	52                   	push   %edx
f0102fd1:	ff d6                	call   *%esi
			break;
f0102fd3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fd9:	e9 ef fb ff ff       	jmp    f0102bcd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fde:	83 ec 08             	sub    $0x8,%esp
f0102fe1:	53                   	push   %ebx
f0102fe2:	6a 25                	push   $0x25
f0102fe4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102fe6:	83 c4 10             	add    $0x10,%esp
f0102fe9:	eb 03                	jmp    f0102fee <vprintfmt+0x447>
f0102feb:	83 ef 01             	sub    $0x1,%edi
f0102fee:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ff2:	75 f7                	jne    f0102feb <vprintfmt+0x444>
f0102ff4:	e9 d4 fb ff ff       	jmp    f0102bcd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ff9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ffc:	5b                   	pop    %ebx
f0102ffd:	5e                   	pop    %esi
f0102ffe:	5f                   	pop    %edi
f0102fff:	5d                   	pop    %ebp
f0103000:	c3                   	ret    

f0103001 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103001:	55                   	push   %ebp
f0103002:	89 e5                	mov    %esp,%ebp
f0103004:	83 ec 18             	sub    $0x18,%esp
f0103007:	8b 45 08             	mov    0x8(%ebp),%eax
f010300a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010300d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103010:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103014:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103017:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010301e:	85 c0                	test   %eax,%eax
f0103020:	74 26                	je     f0103048 <vsnprintf+0x47>
f0103022:	85 d2                	test   %edx,%edx
f0103024:	7e 22                	jle    f0103048 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103026:	ff 75 14             	pushl  0x14(%ebp)
f0103029:	ff 75 10             	pushl  0x10(%ebp)
f010302c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010302f:	50                   	push   %eax
f0103030:	68 6d 2b 10 f0       	push   $0xf0102b6d
f0103035:	e8 6d fb ff ff       	call   f0102ba7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010303a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010303d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103040:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103043:	83 c4 10             	add    $0x10,%esp
f0103046:	eb 05                	jmp    f010304d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103048:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010304d:	c9                   	leave  
f010304e:	c3                   	ret    

f010304f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010304f:	55                   	push   %ebp
f0103050:	89 e5                	mov    %esp,%ebp
f0103052:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103055:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103058:	50                   	push   %eax
f0103059:	ff 75 10             	pushl  0x10(%ebp)
f010305c:	ff 75 0c             	pushl  0xc(%ebp)
f010305f:	ff 75 08             	pushl  0x8(%ebp)
f0103062:	e8 9a ff ff ff       	call   f0103001 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103067:	c9                   	leave  
f0103068:	c3                   	ret    

f0103069 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103069:	55                   	push   %ebp
f010306a:	89 e5                	mov    %esp,%ebp
f010306c:	57                   	push   %edi
f010306d:	56                   	push   %esi
f010306e:	53                   	push   %ebx
f010306f:	83 ec 0c             	sub    $0xc,%esp
f0103072:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103075:	85 c0                	test   %eax,%eax
f0103077:	74 11                	je     f010308a <readline+0x21>
		cprintf("%s", prompt);
f0103079:	83 ec 08             	sub    $0x8,%esp
f010307c:	50                   	push   %eax
f010307d:	68 87 3c 10 f0       	push   $0xf0103c87
f0103082:	e8 ee f6 ff ff       	call   f0102775 <cprintf>
f0103087:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010308a:	83 ec 0c             	sub    $0xc,%esp
f010308d:	6a 00                	push   $0x0
f010308f:	e8 7f d5 ff ff       	call   f0100613 <iscons>
f0103094:	89 c7                	mov    %eax,%edi
f0103096:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103099:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010309e:	e8 5f d5 ff ff       	call   f0100602 <getchar>
f01030a3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01030a5:	85 c0                	test   %eax,%eax
f01030a7:	79 18                	jns    f01030c1 <readline+0x58>
			cprintf("read error: %e\n", c);
f01030a9:	83 ec 08             	sub    $0x8,%esp
f01030ac:	50                   	push   %eax
f01030ad:	68 60 49 10 f0       	push   $0xf0104960
f01030b2:	e8 be f6 ff ff       	call   f0102775 <cprintf>
			return NULL;
f01030b7:	83 c4 10             	add    $0x10,%esp
f01030ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01030bf:	eb 79                	jmp    f010313a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01030c1:	83 f8 08             	cmp    $0x8,%eax
f01030c4:	0f 94 c2             	sete   %dl
f01030c7:	83 f8 7f             	cmp    $0x7f,%eax
f01030ca:	0f 94 c0             	sete   %al
f01030cd:	08 c2                	or     %al,%dl
f01030cf:	74 1a                	je     f01030eb <readline+0x82>
f01030d1:	85 f6                	test   %esi,%esi
f01030d3:	7e 16                	jle    f01030eb <readline+0x82>
			if (echoing)
f01030d5:	85 ff                	test   %edi,%edi
f01030d7:	74 0d                	je     f01030e6 <readline+0x7d>
				cputchar('\b');
f01030d9:	83 ec 0c             	sub    $0xc,%esp
f01030dc:	6a 08                	push   $0x8
f01030de:	e8 0f d5 ff ff       	call   f01005f2 <cputchar>
f01030e3:	83 c4 10             	add    $0x10,%esp
			i--;
f01030e6:	83 ee 01             	sub    $0x1,%esi
f01030e9:	eb b3                	jmp    f010309e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030eb:	83 fb 1f             	cmp    $0x1f,%ebx
f01030ee:	7e 23                	jle    f0103113 <readline+0xaa>
f01030f0:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030f6:	7f 1b                	jg     f0103113 <readline+0xaa>
			if (echoing)
f01030f8:	85 ff                	test   %edi,%edi
f01030fa:	74 0c                	je     f0103108 <readline+0x9f>
				cputchar(c);
f01030fc:	83 ec 0c             	sub    $0xc,%esp
f01030ff:	53                   	push   %ebx
f0103100:	e8 ed d4 ff ff       	call   f01005f2 <cputchar>
f0103105:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103108:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f010310e:	8d 76 01             	lea    0x1(%esi),%esi
f0103111:	eb 8b                	jmp    f010309e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103113:	83 fb 0a             	cmp    $0xa,%ebx
f0103116:	74 05                	je     f010311d <readline+0xb4>
f0103118:	83 fb 0d             	cmp    $0xd,%ebx
f010311b:	75 81                	jne    f010309e <readline+0x35>
			if (echoing)
f010311d:	85 ff                	test   %edi,%edi
f010311f:	74 0d                	je     f010312e <readline+0xc5>
				cputchar('\n');
f0103121:	83 ec 0c             	sub    $0xc,%esp
f0103124:	6a 0a                	push   $0xa
f0103126:	e8 c7 d4 ff ff       	call   f01005f2 <cputchar>
f010312b:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010312e:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f0103135:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f010313a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010313d:	5b                   	pop    %ebx
f010313e:	5e                   	pop    %esi
f010313f:	5f                   	pop    %edi
f0103140:	5d                   	pop    %ebp
f0103141:	c3                   	ret    

f0103142 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103142:	55                   	push   %ebp
f0103143:	89 e5                	mov    %esp,%ebp
f0103145:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103148:	b8 00 00 00 00       	mov    $0x0,%eax
f010314d:	eb 03                	jmp    f0103152 <strlen+0x10>
		n++;
f010314f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103152:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103156:	75 f7                	jne    f010314f <strlen+0xd>
		n++;
	return n;
}
f0103158:	5d                   	pop    %ebp
f0103159:	c3                   	ret    

f010315a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010315a:	55                   	push   %ebp
f010315b:	89 e5                	mov    %esp,%ebp
f010315d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103160:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103163:	ba 00 00 00 00       	mov    $0x0,%edx
f0103168:	eb 03                	jmp    f010316d <strnlen+0x13>
		n++;
f010316a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010316d:	39 c2                	cmp    %eax,%edx
f010316f:	74 08                	je     f0103179 <strnlen+0x1f>
f0103171:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103175:	75 f3                	jne    f010316a <strnlen+0x10>
f0103177:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103179:	5d                   	pop    %ebp
f010317a:	c3                   	ret    

f010317b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010317b:	55                   	push   %ebp
f010317c:	89 e5                	mov    %esp,%ebp
f010317e:	53                   	push   %ebx
f010317f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103182:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103185:	89 c2                	mov    %eax,%edx
f0103187:	83 c2 01             	add    $0x1,%edx
f010318a:	83 c1 01             	add    $0x1,%ecx
f010318d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103191:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103194:	84 db                	test   %bl,%bl
f0103196:	75 ef                	jne    f0103187 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103198:	5b                   	pop    %ebx
f0103199:	5d                   	pop    %ebp
f010319a:	c3                   	ret    

f010319b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010319b:	55                   	push   %ebp
f010319c:	89 e5                	mov    %esp,%ebp
f010319e:	53                   	push   %ebx
f010319f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01031a2:	53                   	push   %ebx
f01031a3:	e8 9a ff ff ff       	call   f0103142 <strlen>
f01031a8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01031ab:	ff 75 0c             	pushl  0xc(%ebp)
f01031ae:	01 d8                	add    %ebx,%eax
f01031b0:	50                   	push   %eax
f01031b1:	e8 c5 ff ff ff       	call   f010317b <strcpy>
	return dst;
}
f01031b6:	89 d8                	mov    %ebx,%eax
f01031b8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031bb:	c9                   	leave  
f01031bc:	c3                   	ret    

f01031bd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01031bd:	55                   	push   %ebp
f01031be:	89 e5                	mov    %esp,%ebp
f01031c0:	56                   	push   %esi
f01031c1:	53                   	push   %ebx
f01031c2:	8b 75 08             	mov    0x8(%ebp),%esi
f01031c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031c8:	89 f3                	mov    %esi,%ebx
f01031ca:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031cd:	89 f2                	mov    %esi,%edx
f01031cf:	eb 0f                	jmp    f01031e0 <strncpy+0x23>
		*dst++ = *src;
f01031d1:	83 c2 01             	add    $0x1,%edx
f01031d4:	0f b6 01             	movzbl (%ecx),%eax
f01031d7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031da:	80 39 01             	cmpb   $0x1,(%ecx)
f01031dd:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031e0:	39 da                	cmp    %ebx,%edx
f01031e2:	75 ed                	jne    f01031d1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031e4:	89 f0                	mov    %esi,%eax
f01031e6:	5b                   	pop    %ebx
f01031e7:	5e                   	pop    %esi
f01031e8:	5d                   	pop    %ebp
f01031e9:	c3                   	ret    

f01031ea <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031ea:	55                   	push   %ebp
f01031eb:	89 e5                	mov    %esp,%ebp
f01031ed:	56                   	push   %esi
f01031ee:	53                   	push   %ebx
f01031ef:	8b 75 08             	mov    0x8(%ebp),%esi
f01031f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031f5:	8b 55 10             	mov    0x10(%ebp),%edx
f01031f8:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031fa:	85 d2                	test   %edx,%edx
f01031fc:	74 21                	je     f010321f <strlcpy+0x35>
f01031fe:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103202:	89 f2                	mov    %esi,%edx
f0103204:	eb 09                	jmp    f010320f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103206:	83 c2 01             	add    $0x1,%edx
f0103209:	83 c1 01             	add    $0x1,%ecx
f010320c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010320f:	39 c2                	cmp    %eax,%edx
f0103211:	74 09                	je     f010321c <strlcpy+0x32>
f0103213:	0f b6 19             	movzbl (%ecx),%ebx
f0103216:	84 db                	test   %bl,%bl
f0103218:	75 ec                	jne    f0103206 <strlcpy+0x1c>
f010321a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010321c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010321f:	29 f0                	sub    %esi,%eax
}
f0103221:	5b                   	pop    %ebx
f0103222:	5e                   	pop    %esi
f0103223:	5d                   	pop    %ebp
f0103224:	c3                   	ret    

f0103225 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103225:	55                   	push   %ebp
f0103226:	89 e5                	mov    %esp,%ebp
f0103228:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010322b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010322e:	eb 06                	jmp    f0103236 <strcmp+0x11>
		p++, q++;
f0103230:	83 c1 01             	add    $0x1,%ecx
f0103233:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103236:	0f b6 01             	movzbl (%ecx),%eax
f0103239:	84 c0                	test   %al,%al
f010323b:	74 04                	je     f0103241 <strcmp+0x1c>
f010323d:	3a 02                	cmp    (%edx),%al
f010323f:	74 ef                	je     f0103230 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103241:	0f b6 c0             	movzbl %al,%eax
f0103244:	0f b6 12             	movzbl (%edx),%edx
f0103247:	29 d0                	sub    %edx,%eax
}
f0103249:	5d                   	pop    %ebp
f010324a:	c3                   	ret    

f010324b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010324b:	55                   	push   %ebp
f010324c:	89 e5                	mov    %esp,%ebp
f010324e:	53                   	push   %ebx
f010324f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103252:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103255:	89 c3                	mov    %eax,%ebx
f0103257:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010325a:	eb 06                	jmp    f0103262 <strncmp+0x17>
		n--, p++, q++;
f010325c:	83 c0 01             	add    $0x1,%eax
f010325f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103262:	39 d8                	cmp    %ebx,%eax
f0103264:	74 15                	je     f010327b <strncmp+0x30>
f0103266:	0f b6 08             	movzbl (%eax),%ecx
f0103269:	84 c9                	test   %cl,%cl
f010326b:	74 04                	je     f0103271 <strncmp+0x26>
f010326d:	3a 0a                	cmp    (%edx),%cl
f010326f:	74 eb                	je     f010325c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103271:	0f b6 00             	movzbl (%eax),%eax
f0103274:	0f b6 12             	movzbl (%edx),%edx
f0103277:	29 d0                	sub    %edx,%eax
f0103279:	eb 05                	jmp    f0103280 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010327b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103280:	5b                   	pop    %ebx
f0103281:	5d                   	pop    %ebp
f0103282:	c3                   	ret    

f0103283 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103283:	55                   	push   %ebp
f0103284:	89 e5                	mov    %esp,%ebp
f0103286:	8b 45 08             	mov    0x8(%ebp),%eax
f0103289:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010328d:	eb 07                	jmp    f0103296 <strchr+0x13>
		if (*s == c)
f010328f:	38 ca                	cmp    %cl,%dl
f0103291:	74 0f                	je     f01032a2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103293:	83 c0 01             	add    $0x1,%eax
f0103296:	0f b6 10             	movzbl (%eax),%edx
f0103299:	84 d2                	test   %dl,%dl
f010329b:	75 f2                	jne    f010328f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010329d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032a2:	5d                   	pop    %ebp
f01032a3:	c3                   	ret    

f01032a4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01032a4:	55                   	push   %ebp
f01032a5:	89 e5                	mov    %esp,%ebp
f01032a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01032aa:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01032ae:	eb 03                	jmp    f01032b3 <strfind+0xf>
f01032b0:	83 c0 01             	add    $0x1,%eax
f01032b3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01032b6:	38 ca                	cmp    %cl,%dl
f01032b8:	74 04                	je     f01032be <strfind+0x1a>
f01032ba:	84 d2                	test   %dl,%dl
f01032bc:	75 f2                	jne    f01032b0 <strfind+0xc>
			break;
	return (char *) s;
}
f01032be:	5d                   	pop    %ebp
f01032bf:	c3                   	ret    

f01032c0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	57                   	push   %edi
f01032c4:	56                   	push   %esi
f01032c5:	53                   	push   %ebx
f01032c6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032c9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01032cc:	85 c9                	test   %ecx,%ecx
f01032ce:	74 36                	je     f0103306 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01032d0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01032d6:	75 28                	jne    f0103300 <memset+0x40>
f01032d8:	f6 c1 03             	test   $0x3,%cl
f01032db:	75 23                	jne    f0103300 <memset+0x40>
		c &= 0xFF;
f01032dd:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032e1:	89 d3                	mov    %edx,%ebx
f01032e3:	c1 e3 08             	shl    $0x8,%ebx
f01032e6:	89 d6                	mov    %edx,%esi
f01032e8:	c1 e6 18             	shl    $0x18,%esi
f01032eb:	89 d0                	mov    %edx,%eax
f01032ed:	c1 e0 10             	shl    $0x10,%eax
f01032f0:	09 f0                	or     %esi,%eax
f01032f2:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032f4:	89 d8                	mov    %ebx,%eax
f01032f6:	09 d0                	or     %edx,%eax
f01032f8:	c1 e9 02             	shr    $0x2,%ecx
f01032fb:	fc                   	cld    
f01032fc:	f3 ab                	rep stos %eax,%es:(%edi)
f01032fe:	eb 06                	jmp    f0103306 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103300:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103303:	fc                   	cld    
f0103304:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103306:	89 f8                	mov    %edi,%eax
f0103308:	5b                   	pop    %ebx
f0103309:	5e                   	pop    %esi
f010330a:	5f                   	pop    %edi
f010330b:	5d                   	pop    %ebp
f010330c:	c3                   	ret    

f010330d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010330d:	55                   	push   %ebp
f010330e:	89 e5                	mov    %esp,%ebp
f0103310:	57                   	push   %edi
f0103311:	56                   	push   %esi
f0103312:	8b 45 08             	mov    0x8(%ebp),%eax
f0103315:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103318:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010331b:	39 c6                	cmp    %eax,%esi
f010331d:	73 35                	jae    f0103354 <memmove+0x47>
f010331f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103322:	39 d0                	cmp    %edx,%eax
f0103324:	73 2e                	jae    f0103354 <memmove+0x47>
		s += n;
		d += n;
f0103326:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103329:	89 d6                	mov    %edx,%esi
f010332b:	09 fe                	or     %edi,%esi
f010332d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103333:	75 13                	jne    f0103348 <memmove+0x3b>
f0103335:	f6 c1 03             	test   $0x3,%cl
f0103338:	75 0e                	jne    f0103348 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010333a:	83 ef 04             	sub    $0x4,%edi
f010333d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103340:	c1 e9 02             	shr    $0x2,%ecx
f0103343:	fd                   	std    
f0103344:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103346:	eb 09                	jmp    f0103351 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103348:	83 ef 01             	sub    $0x1,%edi
f010334b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010334e:	fd                   	std    
f010334f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103351:	fc                   	cld    
f0103352:	eb 1d                	jmp    f0103371 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103354:	89 f2                	mov    %esi,%edx
f0103356:	09 c2                	or     %eax,%edx
f0103358:	f6 c2 03             	test   $0x3,%dl
f010335b:	75 0f                	jne    f010336c <memmove+0x5f>
f010335d:	f6 c1 03             	test   $0x3,%cl
f0103360:	75 0a                	jne    f010336c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103362:	c1 e9 02             	shr    $0x2,%ecx
f0103365:	89 c7                	mov    %eax,%edi
f0103367:	fc                   	cld    
f0103368:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010336a:	eb 05                	jmp    f0103371 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010336c:	89 c7                	mov    %eax,%edi
f010336e:	fc                   	cld    
f010336f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103371:	5e                   	pop    %esi
f0103372:	5f                   	pop    %edi
f0103373:	5d                   	pop    %ebp
f0103374:	c3                   	ret    

f0103375 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103375:	55                   	push   %ebp
f0103376:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103378:	ff 75 10             	pushl  0x10(%ebp)
f010337b:	ff 75 0c             	pushl  0xc(%ebp)
f010337e:	ff 75 08             	pushl  0x8(%ebp)
f0103381:	e8 87 ff ff ff       	call   f010330d <memmove>
}
f0103386:	c9                   	leave  
f0103387:	c3                   	ret    

f0103388 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103388:	55                   	push   %ebp
f0103389:	89 e5                	mov    %esp,%ebp
f010338b:	56                   	push   %esi
f010338c:	53                   	push   %ebx
f010338d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103390:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103393:	89 c6                	mov    %eax,%esi
f0103395:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103398:	eb 1a                	jmp    f01033b4 <memcmp+0x2c>
		if (*s1 != *s2)
f010339a:	0f b6 08             	movzbl (%eax),%ecx
f010339d:	0f b6 1a             	movzbl (%edx),%ebx
f01033a0:	38 d9                	cmp    %bl,%cl
f01033a2:	74 0a                	je     f01033ae <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01033a4:	0f b6 c1             	movzbl %cl,%eax
f01033a7:	0f b6 db             	movzbl %bl,%ebx
f01033aa:	29 d8                	sub    %ebx,%eax
f01033ac:	eb 0f                	jmp    f01033bd <memcmp+0x35>
		s1++, s2++;
f01033ae:	83 c0 01             	add    $0x1,%eax
f01033b1:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01033b4:	39 f0                	cmp    %esi,%eax
f01033b6:	75 e2                	jne    f010339a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01033b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033bd:	5b                   	pop    %ebx
f01033be:	5e                   	pop    %esi
f01033bf:	5d                   	pop    %ebp
f01033c0:	c3                   	ret    

f01033c1 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01033c1:	55                   	push   %ebp
f01033c2:	89 e5                	mov    %esp,%ebp
f01033c4:	53                   	push   %ebx
f01033c5:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01033c8:	89 c1                	mov    %eax,%ecx
f01033ca:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01033cd:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033d1:	eb 0a                	jmp    f01033dd <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033d3:	0f b6 10             	movzbl (%eax),%edx
f01033d6:	39 da                	cmp    %ebx,%edx
f01033d8:	74 07                	je     f01033e1 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033da:	83 c0 01             	add    $0x1,%eax
f01033dd:	39 c8                	cmp    %ecx,%eax
f01033df:	72 f2                	jb     f01033d3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033e1:	5b                   	pop    %ebx
f01033e2:	5d                   	pop    %ebp
f01033e3:	c3                   	ret    

f01033e4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033e4:	55                   	push   %ebp
f01033e5:	89 e5                	mov    %esp,%ebp
f01033e7:	57                   	push   %edi
f01033e8:	56                   	push   %esi
f01033e9:	53                   	push   %ebx
f01033ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033ed:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033f0:	eb 03                	jmp    f01033f5 <strtol+0x11>
		s++;
f01033f2:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033f5:	0f b6 01             	movzbl (%ecx),%eax
f01033f8:	3c 20                	cmp    $0x20,%al
f01033fa:	74 f6                	je     f01033f2 <strtol+0xe>
f01033fc:	3c 09                	cmp    $0x9,%al
f01033fe:	74 f2                	je     f01033f2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103400:	3c 2b                	cmp    $0x2b,%al
f0103402:	75 0a                	jne    f010340e <strtol+0x2a>
		s++;
f0103404:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103407:	bf 00 00 00 00       	mov    $0x0,%edi
f010340c:	eb 11                	jmp    f010341f <strtol+0x3b>
f010340e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103413:	3c 2d                	cmp    $0x2d,%al
f0103415:	75 08                	jne    f010341f <strtol+0x3b>
		s++, neg = 1;
f0103417:	83 c1 01             	add    $0x1,%ecx
f010341a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010341f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103425:	75 15                	jne    f010343c <strtol+0x58>
f0103427:	80 39 30             	cmpb   $0x30,(%ecx)
f010342a:	75 10                	jne    f010343c <strtol+0x58>
f010342c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103430:	75 7c                	jne    f01034ae <strtol+0xca>
		s += 2, base = 16;
f0103432:	83 c1 02             	add    $0x2,%ecx
f0103435:	bb 10 00 00 00       	mov    $0x10,%ebx
f010343a:	eb 16                	jmp    f0103452 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010343c:	85 db                	test   %ebx,%ebx
f010343e:	75 12                	jne    f0103452 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103440:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103445:	80 39 30             	cmpb   $0x30,(%ecx)
f0103448:	75 08                	jne    f0103452 <strtol+0x6e>
		s++, base = 8;
f010344a:	83 c1 01             	add    $0x1,%ecx
f010344d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103452:	b8 00 00 00 00       	mov    $0x0,%eax
f0103457:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010345a:	0f b6 11             	movzbl (%ecx),%edx
f010345d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103460:	89 f3                	mov    %esi,%ebx
f0103462:	80 fb 09             	cmp    $0x9,%bl
f0103465:	77 08                	ja     f010346f <strtol+0x8b>
			dig = *s - '0';
f0103467:	0f be d2             	movsbl %dl,%edx
f010346a:	83 ea 30             	sub    $0x30,%edx
f010346d:	eb 22                	jmp    f0103491 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010346f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103472:	89 f3                	mov    %esi,%ebx
f0103474:	80 fb 19             	cmp    $0x19,%bl
f0103477:	77 08                	ja     f0103481 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103479:	0f be d2             	movsbl %dl,%edx
f010347c:	83 ea 57             	sub    $0x57,%edx
f010347f:	eb 10                	jmp    f0103491 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103481:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103484:	89 f3                	mov    %esi,%ebx
f0103486:	80 fb 19             	cmp    $0x19,%bl
f0103489:	77 16                	ja     f01034a1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010348b:	0f be d2             	movsbl %dl,%edx
f010348e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103491:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103494:	7d 0b                	jge    f01034a1 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103496:	83 c1 01             	add    $0x1,%ecx
f0103499:	0f af 45 10          	imul   0x10(%ebp),%eax
f010349d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010349f:	eb b9                	jmp    f010345a <strtol+0x76>

	if (endptr)
f01034a1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01034a5:	74 0d                	je     f01034b4 <strtol+0xd0>
		*endptr = (char *) s;
f01034a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034aa:	89 0e                	mov    %ecx,(%esi)
f01034ac:	eb 06                	jmp    f01034b4 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034ae:	85 db                	test   %ebx,%ebx
f01034b0:	74 98                	je     f010344a <strtol+0x66>
f01034b2:	eb 9e                	jmp    f0103452 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01034b4:	89 c2                	mov    %eax,%edx
f01034b6:	f7 da                	neg    %edx
f01034b8:	85 ff                	test   %edi,%edi
f01034ba:	0f 45 c2             	cmovne %edx,%eax
}
f01034bd:	5b                   	pop    %ebx
f01034be:	5e                   	pop    %esi
f01034bf:	5f                   	pop    %edi
f01034c0:	5d                   	pop    %ebp
f01034c1:	c3                   	ret    
f01034c2:	66 90                	xchg   %ax,%ax
f01034c4:	66 90                	xchg   %ax,%ax
f01034c6:	66 90                	xchg   %ax,%ax
f01034c8:	66 90                	xchg   %ax,%ax
f01034ca:	66 90                	xchg   %ax,%ax
f01034cc:	66 90                	xchg   %ax,%ax
f01034ce:	66 90                	xchg   %ax,%ax

f01034d0 <__udivdi3>:
f01034d0:	55                   	push   %ebp
f01034d1:	57                   	push   %edi
f01034d2:	56                   	push   %esi
f01034d3:	53                   	push   %ebx
f01034d4:	83 ec 1c             	sub    $0x1c,%esp
f01034d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034e7:	85 f6                	test   %esi,%esi
f01034e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034ed:	89 ca                	mov    %ecx,%edx
f01034ef:	89 f8                	mov    %edi,%eax
f01034f1:	75 3d                	jne    f0103530 <__udivdi3+0x60>
f01034f3:	39 cf                	cmp    %ecx,%edi
f01034f5:	0f 87 c5 00 00 00    	ja     f01035c0 <__udivdi3+0xf0>
f01034fb:	85 ff                	test   %edi,%edi
f01034fd:	89 fd                	mov    %edi,%ebp
f01034ff:	75 0b                	jne    f010350c <__udivdi3+0x3c>
f0103501:	b8 01 00 00 00       	mov    $0x1,%eax
f0103506:	31 d2                	xor    %edx,%edx
f0103508:	f7 f7                	div    %edi
f010350a:	89 c5                	mov    %eax,%ebp
f010350c:	89 c8                	mov    %ecx,%eax
f010350e:	31 d2                	xor    %edx,%edx
f0103510:	f7 f5                	div    %ebp
f0103512:	89 c1                	mov    %eax,%ecx
f0103514:	89 d8                	mov    %ebx,%eax
f0103516:	89 cf                	mov    %ecx,%edi
f0103518:	f7 f5                	div    %ebp
f010351a:	89 c3                	mov    %eax,%ebx
f010351c:	89 d8                	mov    %ebx,%eax
f010351e:	89 fa                	mov    %edi,%edx
f0103520:	83 c4 1c             	add    $0x1c,%esp
f0103523:	5b                   	pop    %ebx
f0103524:	5e                   	pop    %esi
f0103525:	5f                   	pop    %edi
f0103526:	5d                   	pop    %ebp
f0103527:	c3                   	ret    
f0103528:	90                   	nop
f0103529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103530:	39 ce                	cmp    %ecx,%esi
f0103532:	77 74                	ja     f01035a8 <__udivdi3+0xd8>
f0103534:	0f bd fe             	bsr    %esi,%edi
f0103537:	83 f7 1f             	xor    $0x1f,%edi
f010353a:	0f 84 98 00 00 00    	je     f01035d8 <__udivdi3+0x108>
f0103540:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103545:	89 f9                	mov    %edi,%ecx
f0103547:	89 c5                	mov    %eax,%ebp
f0103549:	29 fb                	sub    %edi,%ebx
f010354b:	d3 e6                	shl    %cl,%esi
f010354d:	89 d9                	mov    %ebx,%ecx
f010354f:	d3 ed                	shr    %cl,%ebp
f0103551:	89 f9                	mov    %edi,%ecx
f0103553:	d3 e0                	shl    %cl,%eax
f0103555:	09 ee                	or     %ebp,%esi
f0103557:	89 d9                	mov    %ebx,%ecx
f0103559:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010355d:	89 d5                	mov    %edx,%ebp
f010355f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103563:	d3 ed                	shr    %cl,%ebp
f0103565:	89 f9                	mov    %edi,%ecx
f0103567:	d3 e2                	shl    %cl,%edx
f0103569:	89 d9                	mov    %ebx,%ecx
f010356b:	d3 e8                	shr    %cl,%eax
f010356d:	09 c2                	or     %eax,%edx
f010356f:	89 d0                	mov    %edx,%eax
f0103571:	89 ea                	mov    %ebp,%edx
f0103573:	f7 f6                	div    %esi
f0103575:	89 d5                	mov    %edx,%ebp
f0103577:	89 c3                	mov    %eax,%ebx
f0103579:	f7 64 24 0c          	mull   0xc(%esp)
f010357d:	39 d5                	cmp    %edx,%ebp
f010357f:	72 10                	jb     f0103591 <__udivdi3+0xc1>
f0103581:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103585:	89 f9                	mov    %edi,%ecx
f0103587:	d3 e6                	shl    %cl,%esi
f0103589:	39 c6                	cmp    %eax,%esi
f010358b:	73 07                	jae    f0103594 <__udivdi3+0xc4>
f010358d:	39 d5                	cmp    %edx,%ebp
f010358f:	75 03                	jne    f0103594 <__udivdi3+0xc4>
f0103591:	83 eb 01             	sub    $0x1,%ebx
f0103594:	31 ff                	xor    %edi,%edi
f0103596:	89 d8                	mov    %ebx,%eax
f0103598:	89 fa                	mov    %edi,%edx
f010359a:	83 c4 1c             	add    $0x1c,%esp
f010359d:	5b                   	pop    %ebx
f010359e:	5e                   	pop    %esi
f010359f:	5f                   	pop    %edi
f01035a0:	5d                   	pop    %ebp
f01035a1:	c3                   	ret    
f01035a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035a8:	31 ff                	xor    %edi,%edi
f01035aa:	31 db                	xor    %ebx,%ebx
f01035ac:	89 d8                	mov    %ebx,%eax
f01035ae:	89 fa                	mov    %edi,%edx
f01035b0:	83 c4 1c             	add    $0x1c,%esp
f01035b3:	5b                   	pop    %ebx
f01035b4:	5e                   	pop    %esi
f01035b5:	5f                   	pop    %edi
f01035b6:	5d                   	pop    %ebp
f01035b7:	c3                   	ret    
f01035b8:	90                   	nop
f01035b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	89 d8                	mov    %ebx,%eax
f01035c2:	f7 f7                	div    %edi
f01035c4:	31 ff                	xor    %edi,%edi
f01035c6:	89 c3                	mov    %eax,%ebx
f01035c8:	89 d8                	mov    %ebx,%eax
f01035ca:	89 fa                	mov    %edi,%edx
f01035cc:	83 c4 1c             	add    $0x1c,%esp
f01035cf:	5b                   	pop    %ebx
f01035d0:	5e                   	pop    %esi
f01035d1:	5f                   	pop    %edi
f01035d2:	5d                   	pop    %ebp
f01035d3:	c3                   	ret    
f01035d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035d8:	39 ce                	cmp    %ecx,%esi
f01035da:	72 0c                	jb     f01035e8 <__udivdi3+0x118>
f01035dc:	31 db                	xor    %ebx,%ebx
f01035de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035e2:	0f 87 34 ff ff ff    	ja     f010351c <__udivdi3+0x4c>
f01035e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035ed:	e9 2a ff ff ff       	jmp    f010351c <__udivdi3+0x4c>
f01035f2:	66 90                	xchg   %ax,%ax
f01035f4:	66 90                	xchg   %ax,%ax
f01035f6:	66 90                	xchg   %ax,%ax
f01035f8:	66 90                	xchg   %ax,%ax
f01035fa:	66 90                	xchg   %ax,%ax
f01035fc:	66 90                	xchg   %ax,%ax
f01035fe:	66 90                	xchg   %ax,%ax

f0103600 <__umoddi3>:
f0103600:	55                   	push   %ebp
f0103601:	57                   	push   %edi
f0103602:	56                   	push   %esi
f0103603:	53                   	push   %ebx
f0103604:	83 ec 1c             	sub    $0x1c,%esp
f0103607:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010360b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010360f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103613:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103617:	85 d2                	test   %edx,%edx
f0103619:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010361d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103621:	89 f3                	mov    %esi,%ebx
f0103623:	89 3c 24             	mov    %edi,(%esp)
f0103626:	89 74 24 04          	mov    %esi,0x4(%esp)
f010362a:	75 1c                	jne    f0103648 <__umoddi3+0x48>
f010362c:	39 f7                	cmp    %esi,%edi
f010362e:	76 50                	jbe    f0103680 <__umoddi3+0x80>
f0103630:	89 c8                	mov    %ecx,%eax
f0103632:	89 f2                	mov    %esi,%edx
f0103634:	f7 f7                	div    %edi
f0103636:	89 d0                	mov    %edx,%eax
f0103638:	31 d2                	xor    %edx,%edx
f010363a:	83 c4 1c             	add    $0x1c,%esp
f010363d:	5b                   	pop    %ebx
f010363e:	5e                   	pop    %esi
f010363f:	5f                   	pop    %edi
f0103640:	5d                   	pop    %ebp
f0103641:	c3                   	ret    
f0103642:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103648:	39 f2                	cmp    %esi,%edx
f010364a:	89 d0                	mov    %edx,%eax
f010364c:	77 52                	ja     f01036a0 <__umoddi3+0xa0>
f010364e:	0f bd ea             	bsr    %edx,%ebp
f0103651:	83 f5 1f             	xor    $0x1f,%ebp
f0103654:	75 5a                	jne    f01036b0 <__umoddi3+0xb0>
f0103656:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010365a:	0f 82 e0 00 00 00    	jb     f0103740 <__umoddi3+0x140>
f0103660:	39 0c 24             	cmp    %ecx,(%esp)
f0103663:	0f 86 d7 00 00 00    	jbe    f0103740 <__umoddi3+0x140>
f0103669:	8b 44 24 08          	mov    0x8(%esp),%eax
f010366d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103671:	83 c4 1c             	add    $0x1c,%esp
f0103674:	5b                   	pop    %ebx
f0103675:	5e                   	pop    %esi
f0103676:	5f                   	pop    %edi
f0103677:	5d                   	pop    %ebp
f0103678:	c3                   	ret    
f0103679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103680:	85 ff                	test   %edi,%edi
f0103682:	89 fd                	mov    %edi,%ebp
f0103684:	75 0b                	jne    f0103691 <__umoddi3+0x91>
f0103686:	b8 01 00 00 00       	mov    $0x1,%eax
f010368b:	31 d2                	xor    %edx,%edx
f010368d:	f7 f7                	div    %edi
f010368f:	89 c5                	mov    %eax,%ebp
f0103691:	89 f0                	mov    %esi,%eax
f0103693:	31 d2                	xor    %edx,%edx
f0103695:	f7 f5                	div    %ebp
f0103697:	89 c8                	mov    %ecx,%eax
f0103699:	f7 f5                	div    %ebp
f010369b:	89 d0                	mov    %edx,%eax
f010369d:	eb 99                	jmp    f0103638 <__umoddi3+0x38>
f010369f:	90                   	nop
f01036a0:	89 c8                	mov    %ecx,%eax
f01036a2:	89 f2                	mov    %esi,%edx
f01036a4:	83 c4 1c             	add    $0x1c,%esp
f01036a7:	5b                   	pop    %ebx
f01036a8:	5e                   	pop    %esi
f01036a9:	5f                   	pop    %edi
f01036aa:	5d                   	pop    %ebp
f01036ab:	c3                   	ret    
f01036ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036b0:	8b 34 24             	mov    (%esp),%esi
f01036b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01036b8:	89 e9                	mov    %ebp,%ecx
f01036ba:	29 ef                	sub    %ebp,%edi
f01036bc:	d3 e0                	shl    %cl,%eax
f01036be:	89 f9                	mov    %edi,%ecx
f01036c0:	89 f2                	mov    %esi,%edx
f01036c2:	d3 ea                	shr    %cl,%edx
f01036c4:	89 e9                	mov    %ebp,%ecx
f01036c6:	09 c2                	or     %eax,%edx
f01036c8:	89 d8                	mov    %ebx,%eax
f01036ca:	89 14 24             	mov    %edx,(%esp)
f01036cd:	89 f2                	mov    %esi,%edx
f01036cf:	d3 e2                	shl    %cl,%edx
f01036d1:	89 f9                	mov    %edi,%ecx
f01036d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036db:	d3 e8                	shr    %cl,%eax
f01036dd:	89 e9                	mov    %ebp,%ecx
f01036df:	89 c6                	mov    %eax,%esi
f01036e1:	d3 e3                	shl    %cl,%ebx
f01036e3:	89 f9                	mov    %edi,%ecx
f01036e5:	89 d0                	mov    %edx,%eax
f01036e7:	d3 e8                	shr    %cl,%eax
f01036e9:	89 e9                	mov    %ebp,%ecx
f01036eb:	09 d8                	or     %ebx,%eax
f01036ed:	89 d3                	mov    %edx,%ebx
f01036ef:	89 f2                	mov    %esi,%edx
f01036f1:	f7 34 24             	divl   (%esp)
f01036f4:	89 d6                	mov    %edx,%esi
f01036f6:	d3 e3                	shl    %cl,%ebx
f01036f8:	f7 64 24 04          	mull   0x4(%esp)
f01036fc:	39 d6                	cmp    %edx,%esi
f01036fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103702:	89 d1                	mov    %edx,%ecx
f0103704:	89 c3                	mov    %eax,%ebx
f0103706:	72 08                	jb     f0103710 <__umoddi3+0x110>
f0103708:	75 11                	jne    f010371b <__umoddi3+0x11b>
f010370a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010370e:	73 0b                	jae    f010371b <__umoddi3+0x11b>
f0103710:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103714:	1b 14 24             	sbb    (%esp),%edx
f0103717:	89 d1                	mov    %edx,%ecx
f0103719:	89 c3                	mov    %eax,%ebx
f010371b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010371f:	29 da                	sub    %ebx,%edx
f0103721:	19 ce                	sbb    %ecx,%esi
f0103723:	89 f9                	mov    %edi,%ecx
f0103725:	89 f0                	mov    %esi,%eax
f0103727:	d3 e0                	shl    %cl,%eax
f0103729:	89 e9                	mov    %ebp,%ecx
f010372b:	d3 ea                	shr    %cl,%edx
f010372d:	89 e9                	mov    %ebp,%ecx
f010372f:	d3 ee                	shr    %cl,%esi
f0103731:	09 d0                	or     %edx,%eax
f0103733:	89 f2                	mov    %esi,%edx
f0103735:	83 c4 1c             	add    $0x1c,%esp
f0103738:	5b                   	pop    %ebx
f0103739:	5e                   	pop    %esi
f010373a:	5f                   	pop    %edi
f010373b:	5d                   	pop    %ebp
f010373c:	c3                   	ret    
f010373d:	8d 76 00             	lea    0x0(%esi),%esi
f0103740:	29 f9                	sub    %edi,%ecx
f0103742:	19 d6                	sbb    %edx,%esi
f0103744:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103748:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010374c:	e9 18 ff ff ff       	jmp    f0103669 <__umoddi3+0x69>
