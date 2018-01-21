### Exercise1.

> In the file kern/pmap.c, you must implement code for the following functions (probably in the order given).</br>
- `boot_alloc()` </br>
- `mem_init() (only up to the call to check_page_free_list(1))`,放在最后</br> 
- `page_init()`</br>
- `page_alloc()`</br>
- `page_free()`</br>

### Answer
- `boot_alloc(uint32_t n)`  //返回一个虚拟地址，指向n byte空闲空间
```
  .......
  result = nextfree;      //nextfree --> virtual address of next byte of free memory
	nextfree = ROUNDUP(nextfree+n,PGSIZE);     //for aligned
	if((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)){
		panic("Out of memory\n");
	}
	return result;
```
- page_init()           //对全部物理页初始化
```
......
  size_t i;
	page_free_list = NULL;
	for(i=0; i<npages; i++){
		if(i == 0){         //the 0th
			pages[i].pp_ref = 1;
		} else if(i < npages_basemem){
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		} else if(IOPHYSMEM / PGSIZE <= i && i < EXTPHYSMEM / PGSIZE){
			pages[i].pp_ref = 1;
		} else if(EXTPHYSMEM / PGSIZE <= i && i < PADDR(boot_alloc(0))/PGSIZE){  // ???
			pages[i].pp_ref++;
			pages[i].pp_link = NULL;
		} else {
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}

```
- page_alloc()   //分配一页物理内存
```
struct PageInfo *
page_alloc(int alloc_flags)
{
	struct PageInfo *pg;
	if(page_free_list == NULL){
		return NULL;
	}
	pg = page_free_list;
	page_free_list = pg->pp_link;      // 55,56,57这三行是单链表的相关操作
	pg->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(pg), 0, PGSIZE);  //将pg对应的内核虚拟地址(kva),大小为PGSIZE,初始化为0
	}
	return pg;        //返回pg
}

```
- page_free()
```
void
page_free(struct PageInfo *pp)
{
	//Fill this function in
	//Hint : You may want to panic if pp->pp_ref is 
	//nonzero of pp->pp_link is not NULL
	assert(pp->pp_ref == 0);    //释放一个page, pp_ref = 0, 否则，终止程序执行
	assert(pp->pp_link == NULL);
	
	pp->pp_link = page_free_list;
	page_free_list = pp;	
}
```

### Exercise 2
[关于虚拟地址，线性地址，物理地址之间的关系](https://www.zhihu.com/question/29918252)

### Exercise 3
> Q:Assuming that the following JOS kernel code is correct, what type should variable x have, uintptr_t or physaddr_t?
```
  mystery_t x;
	char* value = return_a_pointer();
	*value = 10;
	x = (mystery_t) value;
```
### Answer:
```
uintptr_r, *value = 10, 这是明显的虚拟地址的操作。
```
### Exercise 4
> In the file kern/pmap.c, you must implement code for the following functions.
- pgdir_walk()
- boot_map_region()
- page_lookup()
- page_remove()
- page_insert()

+ pgdir_walk()    //returns a pointer to the page table entry(PTE) for linear address 'va'
```
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{

	uint32_t dic_off = PDX(va);     // the first 10bit
	uint32_t tab_off = PTX(va);     // the medium 10bit
	pte_t* page_base = NULL;
	struct PageInfo* new_page = NULL;
	pte_t* dic_entry_ptr = pgdir + dic_off;
	if(!(*dic_entry_ptr & PTE_P)){    //if the corresponding page dictory entry not exist
		if(create){
			new_page = page_alloc(1);
			if(new_page == NULL){         //if failed
				return NULL;
			}
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		} else return NULL;
	}
	/* (inc/mmu.h)#define PTE_ADDR(pte) ((physadd_t) (pte) & ~0xFF) -> Address in page table or page directory entry
	 * (kern/pmap.h)#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa) -> take a physical address, return the 
	 * corresponding kernel virtual address.
	 */
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[tab_off];
}

```
+ boot_map_region() // Map [va, va+size) of virtual address space to physical [pa, pa+size)
```
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
  int i;
  for(i=0; i < size/PGSIZE; i++, va += PGSIZE, pa += PGSIZE){
    pte_t* pte = pgdir_walk(pgdir, (void *)va, 1);
    if(!pte){
      panic("boot_map_region, out of memory\n");
    }
    *pte = pa | perm | PTE_P;     //set flags
  }
  cprintf("Virtual Address %x mapped to Physical memory %x\n", va, pa);
}
```

+ page_lookup() // Return the page mapped at virtual address 'va'.
```
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
  pte_t *pte = pgdir_walk(pgdir, va, 0);
  if(!pte || !(*pte | PTE_P)){
    return NULL;
  }
  if(pte_store){
    *pte_store = pte;
  }
  return pa2page(PADDR(*pte));    // pa2page-->Physical address to virtual address
}
```
+ page_insert() //
```
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
  pte_t * pte = pgdir_walk(pgdir, va, 1);     //有，返回，没有，创建。
  if(pte == NULL){
    panic("out of memory");
  }
  pp->pp_ref ++;
  if((*pte) | PTE_P){                         //清除映射
    tlb_invalidate(pgidr, va);
    page_remove(pgdir, va);
 }
 *pte = (page2pa(pp) | perm | PTE_P);         //设置Page Table Entry中的条目权限，属性。
 pgdir[PDX(va)] |= perm;
 return 0;
}
```
+ page_remove()
```
void
page_remove(pde_t *pgdir, void *va)
{
  pte_t * pte = NULL;
  struct PageInfo* pg = page_lookup(pgdir, va, &pte);   //fist search
  if(pte || !(*pte) & PTE_P){       //No, return 
    return;
  }
  page_decref(pg);                  //exist, decrease ref
  *pte = 0;                         // Page Table Entry value set 0
  tlb_invalidate(pgidr, va);        // tlb entry invalidate
}
```
### Exercise 5
> Fill in the missing code in mem_init() after the call to check_page().

```
void
mem_init(void){

}
```
