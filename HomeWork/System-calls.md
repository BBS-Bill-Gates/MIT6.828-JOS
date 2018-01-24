## Homework: xv6 system calls

### Part One: System call tracing
```
Hint: modify the syscall() function in syscall.c.
```
> 通过观察看到, `syscall.c`中的`syscall`函数
```
void
syscall(void)
{
  int num;
  struct proc *curproc = myproc();

  num = curproc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
}
```
> `myproc`的作用从当前CPU structure中读取一个`proc`结构体, 这个结构体中包含了系统调用所需的一切信息,如: 系统调用号, 相应的参数.

根据相应的汇编知识可知, 系统调用发生时,系统调用号存放在寄存器`eax`中, 于是我们可以根据系统调用号来取得对应的系统调用名称,只不过需要建立一个映射:syscall_number-->syscall_name. 我们可以用数组来实现.

```
static char* syscall_names[]={
    [SYS_fork]    "fork",
    [SYS_exit]    "exit",
    [SYS_wait]    "wait",
    [SYS_pipe]    "pipe",
    [SYS_read]    "read",
    [SYS_kill]    "kill",
    [SYS_exec]    "exec",
    [SYS_fstat]   "fstat",
    [SYS_chdir]   "chdir",
    [SYS_dup]     "dup",
    [SYS_getpid]  "getpid",
    [SYS_sbrk]    "sbrk",
    [SYS_sleep]   "sleep",
    [SYS_uptime]  "uptime",
    [SYS_open]    "open",
    [SYS_write]   "write",
    [SYS_mknod]   "mknod",
    [SYS_unlink]  "unlink",
    [SYS_link]    "link",
    [SYS_mkdir]   "mkdir",
    [SYS_close]   "close",
}
```
可能看着非常的奇怪, 怎么会有这种数组的初始化方式呢,是不是错了呢?
> 答案是没有错误,[具体详解,参看此链接](http://gcc.gnu.org/onlinedocs/gcc-4.1.2/gcc/Designated-Inits.html)

#### 返回值问题如何解决?
> 熟悉GDB调试的同学应该都知道,函数返回的时候,返回值是存放哪里? `eax`中,于是有`curproc->tf->eax = syscalls[num]()`,当然你也可以使用其他的变量存放返回值,这里不在多说.
```
整体代码:
static char *syscall_names[] = {
[SYS_fork]    "fork",
[SYS_exit]    "exit",
[SYS_wait]    "wait",
[SYS_pipe]    "pipe",
[SYS_read]    "read",
[SYS_kill]    "kill",
[SYS_exec]    "exec",
[SYS_fstat]   "fstat",
[SYS_chdir]   "chdir",
[SYS_dup]     "dup",
[SYS_getpid]  "getpid",
[SYS_sbrk]    "sbrk",
[SYS_sleep]   "sleep",
[SYS_uptime]  "uptime",
[SYS_open]    "open",
[SYS_write]   "write",
[SYS_mknod]   "mknod",
[SYS_unlink]  "unlink",
[SYS_link]    "link",
[SYS_mkdir]   "mkdir",
[SYS_close]   "close",
};

void
syscall(void)
{
  int num;
  //myproc in proc.c
  //URL: https://www.cs.utexas.edu/~bismith/test/syscalls/syscalls.html
  struct proc *curproc = myproc();

  num = curproc->tf->eax;		//current syscall number
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num]();	//return value
    cprintf("%s -> %d", syscall_names[num], curproc->tf->eax);
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
```
## Part Two: Date system call
任务: 添加一个系统调用,显示当前时间
```
/*
 *date.c 调用你写的syscall
 */
#include "types.h"
#include "user.h"
#include "date.h"

int
main(int argc, char *argv[])
{
  struct rtcdate r;

  if (date(&r)) {
    printf(2, "date failed\n");
    exit();
  }

  // your code to print the time in any format you like...

  exit();
}
```
### Hint
- cmostime(defined in lapic.c), to read the real time clock.
-  date.h contains the definition of the struct rtcdate struct
- cmostime的参数是一个rtctime的结构体指针
- Makefile中的UPROGS位置处,添加上_date
- 你可以以uptime为例子

### First: 声明
```
/*
 *syscall.h
 */
 #define SYS_date 22

 /*
  *syscall.c
  */
  ......
  extern int sys_date(void);
  ......
  static int (*syscalls[])(void) = {
    ......
    [SYS_date]    sys_date,
  }
/*
 * user.h
 */
char* sbrk(int);
int sleep(int);
int uptime(void);
int date(struct rtcdate*);

/*
 *usys.S最后一行添加如下代码
 */
 SYSCALL(date)
```
### Second: syscall code
```
/*
 * sysproc.c 添加
 */
 int sys_date(struct rtcdate* r){
   if(argptr(0, (void*) &r, sizeof(struct rtcdate))){
     return -1;
   }
   cmostime(r);
   return 0; 
 }
```
### Third: date.c
```
#include "types.h"
#include "user.h"
#include "date.h"

int
main(int argc, char *argv[])
{
  struct rtcdate r;

  if (date(&r)) {
    printf(2, "date failed\n");
    exit();
  }

  // your code to print the time in any format you like...
  printf(1,"%d-%d-%d %d:%d:%d\n", r.month, r.day, r.year, r.hour, r.minute, r.second);
  exit();
}
```
### Fourth: Makefile
```
/*
 *Makefile
 */
  _usertests\
	_wc\
	_zombie\
  _date

```
### 编译, 运行:
```
make
make qemu-nox
```
### 注解: date.c中的`printf`和我们平常的`printf`不是很一样, 1-->正常输出, 2-->error输出