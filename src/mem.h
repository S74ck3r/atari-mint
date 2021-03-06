/*
Copyright 1990,1991,1992 Eric R. Smith.
Copyright 1992,1993,1994 Atari Corporation.
All rights reserved.
*/

#ifndef _mem_h
#define _mem_h

#include "file.h"

typedef struct memregion {
	long	loc;		/* base of memory region */
	ulong	len;		/* length of memory region */
	ushort	links;		/* number of users of region */
	ushort	mflags;		/* e.g. which map this came from */
	struct memregion *next; /* next region in memory map */
} MEMREGION;

/* flags for memory regions: these are used only in MEMREGION struct */
#define M_CORE		0x01	/* region came from core map */
#define M_ALT		0x02	/* region came from alt map */
#define M_SWAP		0x04	/* region came from swap map */
#define M_KER		0x08	/* region came from kernel map */
#define M_MAP		0x0f	/* and with this to pick out map */

#define M_SHTEXT	0x10	/* region is a shared text region */
#define M_SHTEXT_T	0x20	/* `sticky bit' for shared text regions */
#define M_FSAVED	0x40	/* region is saved memory of a forked process */
#define M_KEEP		0x0100	/* don't free on process termination */
#define M_SEEN		0x8000	/* for memused() to find links */

/* dummy type for virtual addresses */
typedef struct vaddr {
	char dummy;
} *virtaddr;

/* structure for shared text regions */

typedef struct shtextreg {
	FILEPTR *f;		/* what file did this come from? */
	MEMREGION *text;	/* pointer to shared text region */
	short mtime, mdate;	/* date & time for file */
	struct shtextreg *next;
} SHTEXT;

/*
 * Here's the deal with memory bits:
 *
 * Mxalloc(long size, int mode) takes these fields in 'mode': BITS 0-2 hold
 * values 0-3 for the old GEMDOS mode argument.  If bit 3 is on, then only
 * F_PROTMODE (bits 4-7) counts, and it encodes the desired protection mode
 * to change a block to. Else F_PROTMODE is the desired protection mode for
 * the new block you're allocating.  In either case, F_PROTMODE turns into
 * a PROT_* thusly: if it's zero, you get the F_PROTMODE value from curproc's
 * prgflags. Else you get (F_PROTMODE >> F_PROTSHIFT)-1.
 *
 * The 0x4000 bit is carried along into get_region (but not from there into
 * mark_region) and, if set, causes M_KEEP to be set in the region's
 * mflags.
 */

/* structure of exectuable program headers */
typedef struct fileheader {
	short	fmagic;
	long	ftext;
	long	fdata;
	long	fbss;
	long	fsym;
	long	reserved;
	long	flag;
	short	reloc;
} FILEHEAD;

#define GEMDOS_MAGIC 0x601a

/* flags for curproc->memflags */
/* also used for program headers PRGFLAGS */
#define F_FASTLOAD	0x01		/* don't zero heap */
#define F_ALTLOAD	0x02		/* OK to load in alternate ram */
#define F_ALTALLOC	0x04		/* OK to malloc from alt. ram */
#define F_RESERVED	0x08		/* reserved for future use */
#define F_MEMFLAGS	0xf0		/* reserved for future use */
#define F_SHTEXT	0x800		/* program's text may be shared */

#define F_MINALT	0xf0000000L	/* used to decide which type of RAM to load in */

/* Bit in Mxalloc's arg for "don't auto-free this memory" */
#define F_KEEP		0x4000

#define F_OS_SPECIAL	0x8000		/* mark as a special process */

/* flags for curproc->memflags (that is, PRGFLAGS) and also Mxalloc mode.  */
/* (Actually, when users call Mxalloc, they add 0x10 to what you see here) */
#define	F_PROTMODE	0xf0		/* protection mode bits */
#define F_PROT_P	0x00		/* no read or write */
#define F_PROT_G	0x10		/* any access OK */
#define F_PROT_S	0x20		/* any super access OK */
#define F_PROT_PR	0x30		/* any read OK, no write */
#define F_PROT_I	0x40		/* invalid page */

/* actual values found in page_mode_table and used as args to alloc_region */
#define PROT_P	0
#define PROT_G	1
#define PROT_S	2
#define PROT_PR	3
#define PROT_I	4
#define PROT_MAX_MODE 4
#define PROT_PROTMODE 0xf   /* these bits are the prot mode */
#define PROT_NOCHANGE -1

#define F_PROTSHIFT	4

typedef MEMREGION **MMAP;

#ifndef GENMAGIC
extern MMAP core, alt, ker, swap;
#endif

/* compilers differ on what "sizeof" returns */
#define SIZEOF		(long)sizeof

/* QUANTUM: the page size for the mmu: 8K.  This is hard-coded elsewhere. */
#define QUANTUM 0x2000L

/* MiNT leaves this much memory for TOS to use (8K)
 */
#define TOS_MEM		(QUANTUM)

/* MiNT tries to keep this much memory available for the kernel and other
 * programs when a program is launched (8K)
 */
#define KEEP_MEM	(QUANTUM)

/*
 * how much memory should be allocated to the kernel? (24K)
 */
#define KERNEL_MEM	(3*QUANTUM)

/* macro for rounding off region sizes to QUANTUM (page) boundaries */
/* there is code in mem.c that assumes it's OK to put the screen
 * in any region, so this should be at least 256 for STs (16 is OK for
 * STes, TTs, and Falcons). We actually set a variable in main.c
 * that holds the screen boundary stuff.
 */
extern int no_mem_prot;
extern int screen_boundary;

#define MASKBITS	(no_mem_prot ? screen_boundary : (QUANTUM-1))
#define ROUND(size) ((size + MASKBITS) & ~MASKBITS)

/* interesting memory constants */

#define EIGHT_K (0x400L*8L)
#define ONE_MEG 0x00100000L
#define LOG2_ONE_MEG 20
#define LOG2_16_MEG 24
#define LOG2_EIGHT_K 13
#define SIXTEEN_MEG (0x400L*0x400L*16L)

/* macro for turning a curproc->base_table pointer into a 16-byte boundary */
#define ROUND16(ld) ((long_desc *)(((ulong)(ld) + 15) & ~15))

/* TBL_SIZE is the size in entries of the A, B, and C level tables */
#define TBL_SIZE (16)
#define TBL_SIZE_BYTES (TBL_SIZE * sizeof(long_desc))

typedef struct {
	short limit;
	unsigned zeros:14;
	unsigned dt:2;
	struct long_desc *tbl_address;
} crp_reg;

/* format of long descriptors, both page descriptors and table descriptors */

typedef struct {
    unsigned limit;		/* set to $7fff to disable */
    unsigned unused1:6;
    unsigned unused2:1;
    unsigned s:1;		/* 1 grants supervisor access only */
    unsigned unused3:1;
    unsigned ci:1;		/* cache inhibit: used in page desc only */
    unsigned unused4:1;
    unsigned m:1;		/* modified: used in page desc only */
    unsigned u:1;		/* accessed */
    unsigned wp:1;		/* write-protected */
    unsigned dt:2;		/* type */
} page_type;

typedef struct long_desc {
    page_type page_type;
    struct long_desc *tbl_address;
} long_desc;

typedef struct {
    unsigned enable:1;
    unsigned zeros:5;
    unsigned sre:1;
    unsigned fcl:1;
    unsigned ps:4;
    unsigned is:4;
    unsigned tia:4;
    unsigned tib:4;
    unsigned tic:4;
    unsigned tid:4;
} tc_reg;

#endif /* _mem_h */
