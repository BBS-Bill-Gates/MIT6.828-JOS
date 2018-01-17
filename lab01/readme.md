# lab01
### Question
> Question1:	At what point does the processor start executing 32-bit code?
>  What exactly causes the switch from 16- to 32-bit mode?
```
  lgdt    gdtdesc
  movl    %cr0, %eax    ; eax
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0
```
