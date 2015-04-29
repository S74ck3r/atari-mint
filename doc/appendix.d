Appendix D: filesys.h

/*
 * Symbolic constants and structures for file system operations.
 *
 * NOTE: This file only works if sizeof(int) == 2!
 * UNLESS: you have an ANSI compiler and use prototypes
 *
 * Copyright 1991,1992 Eric R. Smith.
 * Copyright 1993,1994 Atari Corporation.
 */

#ifndef _filesys_h
#define _filesys_h

#ifndef P_
# ifdef __STDC__
#  define P_(x) x
# else
#  define P_(x) ()
# endif
#endif

#include "portab.h"	/* define WORD to be a 16 bit integer */

#define NAME_MAX 32
#define PATH_MAX 128

struct filesys;		/* forward declaration */
struct devdrv;		/* ditto */

typedef struct f_cookie {
	struct filesys *fs;	/* filesystem that knows about this cookie */
	unsigned short	dev;		/* device info (e.g. Rwabs device number) */
	unsigned short	aux;		/* extra data that the file system may want */
	long	index;		/* this+dev uniquely identifies a file */
} fcookie;

/* structure for opendir/readdir/closedir */
typedef struct dirstruct {
	fcookie fc;		/* cookie for this directory */
	unsigned short	index;		/* index of the current entry */
	unsigned short	flags;		/* flags (e.g. tos or not) */
#define TOS_SEARCH	0x01
	char	fsstuff[60];	/* anything else the file system wants */
				/* NOTE: this must be at least 45 bytes */
} DIR;

/* structure for getxattr */
typedef struct xattr {
	unsigned short	mode;
/* file types */
#define S_IFMT	0170000		/* mask to select file type */
#define S_IFCHR	0020000		/* BIOS special file */
#define S_IFDIR	0040000		/* directory file */
#define S_IFREG 0100000		/* regular file */
#define S_IFIFO 0120000		/* FIFO */
#define S_IMEM	0140000		/* memory region or process */
#define S_IFLNK	0160000		/* symbolic link */

/* special bits: setuid, setgid, sticky bit */
#define S_ISUID	04000
#define S_ISGID 02000
#define S_ISVTX	01000

/* file access modes for user, group, and other*/
#define S_IRUSR	0400
#define S_IWUSR 0200
#define S_IXUSR 0100
#define S_IRGRP 0040
#define S_IWGRP	0020
#define S_IXGRP	0010
#define S_IROTH	0004
#define S_IWOTH	0002
#define S_IXOTH	0001
#define DEFAULT_DIRMODE (0777)
#define DEFAULT_MODE	(0666)
	long	index;
	unsigned short	dev;
	unsigned short	reserved1;
	unsigned short	nlink;
	unsigned short	uid;
	unsigned short	gid;
	long	size;
	long	blksize, nblocks;
	short	mtime, mdate;
	short	atime, adate;
	short	ctime, cdate;
	short	attr;
	short	reserved2;
	long	reserved3[2];
} XATTR;

typedef struct fileptr {
	short	links;	    /* number of copies of this descriptor */
	unsigned short	flags;	    /* file open mode and other file flags */
	long	pos;	    /* position in file */
	long	devinfo;    /* device driver specific info */
	fcookie	fc;	    /* file system cookie for this file */
	struct devdrv *dev; /* device driver that knows how to deal with this */
	struct fileptr *next; /* link to next fileptr for this file */
} FILEPTR;

/* lock structure */
struct flock {
	short l_type;			/* type of lock */
#define F_RDLCK		O_RDONLY
#define F_WRLCK		O_WRONLY
#define F_UNLCK		3
	short l_whence;			/* SEEK_SET, SEEK_CUR, SEEK_END */
	long l_start;			/* start of locked region */
	long l_len;			/* length of locked region */
	short l_pid;			/* pid of locking process
						(F_GETLK only) */
};

/* LOCK structure used by the kernel internally */

typedef struct ilock {
	struct flock l;
	struct ilock *next;
	long  reserved[4];
} LOCK;

typedef struct devdrv {
	long (*open)	P_((FILEPTR *f));
	long (*write)	P_((FILEPTR *f, char *buf, long bytes));
	long (*read)	P_((FILEPTR *f, char *buf, long bytes));
	long (*lseek)	P_((FILEPTR *f, long where, WORD whence));
	long (*ioctl)	P_((FILEPTR *f, WORD mode, void *buf));
	long (*datime)	P_((FILEPTR *f, WORD *timeptr, WORD rwflag));
	long (*close)	P_((FILEPTR *f, WORD pid));
	long (*select)	P_((FILEPTR *f, long proc, WORD mode));
	void (*unselect) P_((FILEPTR *f, long proc, WORD mode));
	long	reserved[3];	/* reserved for future use */
} DEVDRV;

typedef struct filesys {
	struct	filesys	*next;	/* link to next file system on chain */
	long	fsflags;
#define FS_KNOPARSE	0x01	/* kernel shouldn't do parsing */
#define FS_CASESENSITIVE	0x02	/* file names are case sensitive */
#define FS_NOXBIT	0x04	/* if a file can be read, it can be executed */
#define	FS_LONGPATH	0x08	/* file system understands "size" argument to
				   "getname" */

	long	(*root) P_((WORD drv, fcookie *fc));
	long	(*lookup) P_((fcookie *dir, char *name, fcookie *fc));
	long	(*creat) P_((fcookie *dir, char *name, unsigned WORD mode,
				WORD attrib, fcookie *fc));
	DEVDRV *(*getdev) P_((fcookie *fc, long *devspecial));
	long	(*getxattr) P_((fcookie *fc, XATTR *xattr));
	long	(*chattr) P_((fcookie *fc, WORD attr));
	long	(*chown) P_((fcookie *fc, WORD uid, WORD gid));
	long	(*chmode) P_((fcookie *fc, unsigned WORD mode));
	long	(*mkdir) P_((fcookie *dir, char *name, unsigned WORD mode));
	long	(*rmdir) P_((fcookie *dir, char *name));
	long	(*remove) P_((fcookie *dir, char *name));
	long	(*getname) P_((fcookie *relto, fcookie *dir, char *pathname,
				WORD size));
	long	(*rename) P_((fcookie *olddir, char *oldname,
			    fcookie *newdir, char *newname));
	long	(*opendir) P_((DIR *dirh, WORD tosflag));
	long	(*readdir) P_((DIR *dirh, char *nm, WORD nmlen, fcookie *fc));
	long	(*rewinddir) P_((DIR *dirh));
	long	(*closedir) P_((DIR *dirh));
	long	(*pathconf) P_((fcookie *dir, WORD which));
	long	(*dfree) P_((fcookie *dir, long *buf));
	long	(*writelabel) P_((fcookie *dir, char *name));
	long	(*readlabel) P_((fcookie *dir, char *name, WORD namelen));
	long	(*symlink) P_((fcookie *dir, char *name, char *to));
	long	(*readlink) P_((fcookie *dir, char *buf, WORD len));
	long	(*hardlink) P_((fcookie *fromdir, char *fromname,
				fcookie *todir, char *toname));
	long	(*fscntl) P_((fcookie *dir, char *name, WORD cmd, long arg));
	long	(*dskchng) P_((WORD drv));
	long	(*release) P_((fcookie *fc));
	long	(*dupcookie) P_((fcookie *dest, fcookie *src));

} FILESYS;

/*
 * this is the structure passed to loaded file systems to tell them
 * about the kernel
 */

typedef long (*_LongFunc)();

struct kerinfo {
	short	maj_version;	/* kernel version number */
	short	min_version;	/* minor kernel version number */
	unsigned short default_mode;	/* default file access mode */
	short	reserved1;	/* room for expansion */

/* OS functions */
	_LongFunc *bios_tab; 	/* pointer to the BIOS entry points */
	_LongFunc *dos_tab;	/* pointer to the GEMDOS entry points */

/* media change vector */
	void	(*drvchng) P_((short));

/* Debugging stuff */
	void	(*trace) P_((char *, ...));
	void	(*debug) P_((char *, ...));
	void	(*alert) P_((char *, ...));
	void	(*fatal) P_((char *, ...));

/* memory allocation functions */
	void *	(*kmalloc) P_((long));
	void	(*kfree) P_((void *));
	void *	(*umalloc) P_((long));
	void	(*ufree) P_((void *));

/* utility functions for string manipulation */
	short	(*strnicmp) P_((char *, char *, WORD));
	short	(*stricmp) P_((char *, char *));
	char *	(*strlwr) P_((char *));
	char *	(*strupr) P_((char *));
	short	(*sprintf) P_((char *, char *, ...));

/* utility functions for manipulating time */
	void	(*millis_time) P_((unsigned long, WORD *));
	long	(*unixtim) P_((unsigned WORD, unsigned WORD));
	long	(*dostim) P_((long));

/* utility functions for dealing with pauses */
	void	(*nap) P_((unsigned WORD));
	void	(*sleep) P_((WORD que, long cond));
	void	(*wake) P_((WORD que, long cond));
	void	(*wakeselect) P_((long param));

/* file system utility functions */
	short	(*denyshare) P_((FILEPTR *, FILEPTR *));
	LOCK *	(*denylock) P_((LOCK *, LOCK *));

/* timeout functions: available only in MiNT 1.06 and later */
	long	(*addtimeout) P_((long delta, void (*func)(void)));
	void	(*canceltimeout) P_((long));

/* extended timeout functions; MiNT 1.11 and later only */
	struct timeout * ARGS_ON_STACK (*addroottimeout) P_((long, void (*)(), short));
	void	ARGS_ON_STACK (*cancelroottimeout) P_((struct timeout *));

/* miscellaneous other things: MiNT 1.12 and later only */
	long	ARGS_ON_STACK (*ikill) P_((int, int));
	void	ARGS_ON_STACK (*iwake) P_((int que, long cond, short pid));

/* reserved for future use */
	long	res2[3];
};

/* flags for open() modes */
#define O_RWMODE  	0x03	/* isolates file read/write mode */
#	define O_RDONLY	0x00
#	define O_WRONLY	0x01
#	define O_RDWR	0x02
#	define O_EXEC	0x03	/* execute file; used by kernel only */

#define O_APPEND	0x08	/* all writes go to end of file */

#define O_SHMODE	0x70	/* isolates file sharing mode */
#	define O_COMPAT	0x00	/* compatibility mode */
#	define O_DENYRW	0x10	/* deny both read and write access */
#	define O_DENYW	0x20	/* deny write access to others */
#	define O_DENYR	0x30	/* deny read access to others */
#	define O_DENYNONE 0x40	/* don't deny any access to others */

#define O_NOINHERIT	0x80	/* children don't get this file descriptor */

#define O_NDELAY	0x100	/* don't block for i/o on this file */
#define O_CREAT		0x200	/* create file if it doesn't exist */
#define O_TRUNC		0x400	/* truncate file to 0 bytes if it does exist */
#define O_EXCL		0x800	/* fail open if file exists */

#define O_USER		0x0fff	/* isolates user-settable flag bits */

#define O_GLOBAL	0x1000	/* for Fopen: opens a global file handle */

/* kernel mode bits -- the user can't set these! */
#define O_TTY		0x2000	/* FILEPTR refers to a terminal */
#define O_HEAD		0x4000	/* FILEPTR is the master side of a fifo */
#define O_LOCK		0x8000	/* FILEPTR has had locking Fcntl's performed */


/* GEMDOS file attributes */

/* macros to be applied to FILEPTRS to determine their type */
#define is_terminal(f) (f->flags & O_TTY)

/* lseek() origins */
#define	SEEK_SET	0		/* from beginning of file */
#define	SEEK_CUR	1		/* from current location */
#define	SEEK_END	2		/* from end of file */

/* The requests for Dpathconf() */
#define DP_IOPEN	0	/* internal limit on # of open files */
#define DP_MAXLINKS	1	/* max number of hard links to a file */
#define DP_PATHMAX	2	/* max path name length */
#define DP_NAMEMAX	3	/* max length of an individual file name */
#define DP_ATOMIC	4	/* # of bytes that can be written atomically */
#define DP_TRUNC	5	/* file name truncation behavior */
#	define	DP_NOTRUNC	0	/* long filenames give an error */
#	define	DP_AUTOTRUNC	1	/* long filenames truncated */
#	define	DP_DOSTRUNC	2	/* DOS truncation rules in effect */
#define DP_CASE		6	/* file name case conversion behavior */
#	define	DP_CASESENS	0	/* case sensitive */
#	define	DP_CASECONV	1	/* case always converted */
#	define	DP_CASEINSENS	2	/* case insensitive, preserved */
#define DP_MODEATTR		7
#	define	DP_ATTRBITS	0x000000ffL	/* mask for valid TOS attribs */
#	define	DP_MODEBITS	0x000fff00L	/* mask for valid Unix file modes */
#	define	DP_FILETYPS	0xfff00000L	/* mask for valid file types */
#	define	DP_FT_DIR	0x00100000L	/* directories (always if . is there) */
#	define	DP_FT_CHR	0x00200000L	/* character special files */
#	define	DP_FT_BLK	0x00400000L	/* block special files, currently unused */
#	define	DP_FT_REG	0x00800000L	/* regular files */
#	define	DP_FT_LNK	0x01000000L	/* symbolic links */
#	define	DP_FT_SOCK	0x02000000L	/* sockets, currently unused */
#	define	DP_FT_FIFO	0x04000000L	/* pipes */
#	define	DP_FT_MEM	0x08000000L	/* shared memory or proc files */
#define DP_XATTRFIELDS	8
#	define	DP_INDEX	0x0001
#	define	DP_DEV		0x0002
#	define	DP_RDEV		0x0004
#	define	DP_NLINK	0x0008
#	define	DP_UID		0x0010
#	define	DP_GID		0x0020
#	define	DP_BLKSIZE	0x0040
#	define	DP_SIZE		0x0080
#	define	DP_NBLOCKS	0x0100
#	define	DP_ATIME	0x0200
#	define	DP_CTIME	0x0400
#	define	DP_MTIME	0x0800
#define DP_MAXREQ	8	/* highest legal request */

/* Dpathconf and Sysconf return this when a value is not limited
   (or is limited only by available memory) */

#define UNLIMITED	0x7fffffffL

/* various character constants and defines for TTY's */
#define MiNTEOF 0x0000ff1a	/* 1a == ^Z */

/* defines for tty_read */
#define RAW	0
#define COOKED	0x1
#define NOECHO	0
#define ECHO	0x2
#define ESCSEQ	0x04		/* cursor keys, etc. get escape sequences */

/* constants for various Fcntl commands */
/* constants for Fcntl calls */
#define F_DUPFD		0		/* handled by kernel */
#define F_GETFD		1		/* handled by kernel */
#define F_SETFD		2		/* handled by kernel */
#	define FD_CLOEXEC	1	/* close on exec flag */

#define F_GETFL		3		/* handled by kernel */
#define F_SETFL		4		/* handled by kernel */
#define F_GETLK		5
#define F_SETLK		6
#define F_SETLKW	7

#define FSTAT		(('F'<< 8) | 0)	/* handled by kernel */
#define FIONREAD	(('F'<< 8) | 1)
#define FIONWRITE	(('F'<< 8) | 2)
#define TIOCGETP	(('T'<< 8) | 0)
#define TIOCSETP	(('T'<< 8) | 1)
#define TIOCSETN	TIOCSETP
#define TIOCGETC	(('T'<< 8) | 2)
#define TIOCSETC	(('T'<< 8) | 3)
#define TIOCGLTC	(('T'<< 8) | 4)
#define TIOCSLTC	(('T'<< 8) | 5)
#define TIOCGPGRP	(('T'<< 8) | 6)
#define TIOCSPGRP	(('T'<< 8) | 7)
#define TIOCFLUSH	(('T'<< 8) | 8)
#define TIOCSTOP	(('T'<< 8) | 9)
#define TIOCSTART	(('T'<< 8) | 10)
#define TIOCGWINSZ	(('T'<< 8) | 11)
#define TIOCSWINSZ	(('T'<< 8) | 12)
#define TIOCGXKEY	(('T'<< 8) | 13)
#define TIOCSXKEY	(('T'<< 8) | 14)
#define TIOCIBAUD	(('T'<< 8) | 18)
#define TIOCOBAUD	(('T'<< 8) | 19)
#define TIOCCBRK	(('T'<< 8) | 20)
#define TIOCSBRK	(('T'<< 8) | 21)
#define TIOCGFLAGS	(('T'<< 8) | 22)
#define TIOCSFLAGS	(('T'<< 8) | 23)
#define TIOCOUTQ	(('T'<< 8) | 24)
#define TIOCSETP	(('T'<< 8) | 25)
#define TIOCHPCL	(('T'<< 8) | 26)
#define TIOCCAR		(('T'<< 8) | 27)
#define TIOCNCAR	(('T'<< 8) | 28)
#define TIOCWONLINE	(('T'<< 8) | 29)
#define TIOCSFLAGSB	(('T'<< 8) | 30)
#define TIOCGSTATE	(('T'<< 8) | 31)
#define TIOCSSTATEB	(('T'<< 8) | 32)
#define TIOCGVMIN	(('T'<< 8) | 33)
#define TIOCSVMIN	(('T'<< 8) | 34)

#define TCURSOFF	(('c'<< 8) | 0)
#define TCURSON		(('c'<< 8) | 1)
#define TCURSBLINK	(('c'<< 8) | 2)
#define TCURSSTEADY	(('c'<< 8) | 3)
#define TCURSSRATE	(('c'<< 8) | 4)
#define TCURSGRATE	(('c'<< 8) | 5)

#define PPROCADDR	(('P'<< 8) | 1)
#define PBASEADDR	(('P'<< 8) | 2)
#define PCTXTSIZE	(('P'<< 8) | 3)
#define PSETFLAGS	(('P'<< 8) | 4)
#define PGETFLAGS	(('P'<< 8) | 5)
#define PTRACESFLAGS	(('P'<< 8) | 6)
#define PTRACEGFLAGS	(('P'<< 8) | 7)
#	define	P_ENABLE	(1 << 0)	/* enable tracing */

#define PTRACEGO	(('P'<< 8) | 8)
#define PTRACEFLOW	(('P'<< 8) | 9)
#define PTRACESTEP	(('P'<< 8) | 10)
#define PTRACE11	(('P'<< 8) | 11)	/* unused, reserved */
#define PLOADINFO	(('P'<< 8) | 12)
#define	PFSTAT		(('P'<< 8) | 13)

struct ploadinfo {
	/* passed */
	short fnamelen;
	/* returned */
	char *cmdlin, *fname;
};

#define SHMGETBLK	(('M'<< 8) | 0)
#define SHMSETBLK	(('M'<< 8) | 1)


/* terminal control constants (tty.sg_flags) */
#define T_CRMOD		0x0001
#define T_CBREAK	0x0002
#define T_ECHO		0x0004
#define T_RAW		0x0010
#define T_TOS		0x0080
#define T_TOSTOP	0x0100
#define T_XKEY		0x0200		/* Fread returns escape sequences for
					   cursor keys, etc. */
#define T_ECHOCTL	0x0400		/* echo ctl chars as ^x */

#define T_TANDEM	0x1000
#define T_RTSCTS	0x2000
#define T_EVENP		0x4000		/* EVENP and ODDP are mutually exclusive */
#define T_ODDP		0x8000

#define TF_FLAGS	0xF000

/* some flags for TIOC[GS]FLAGS */
#define TF_CAR		0x800		/* nonlocal mode, require carrier */
#define TF_NLOCAL	TF_CAR

#define TF_BRKINT	0x80		/* allow breaks interrupt (like ^C) */

#define TF_STOPBITS	0x0003
#define TF_1STOP	0x0001
#define TF_15STOP	0x0002
#define	TF_2STOP	0x0003

#define TF_CHARBITS	0x000C
#define TF_8BIT		0
#define TF_7BIT		0x4
#define TF_6BIT		0x8
#define TF_5BIT		0xC

/* the following are terminal status flags (tty.state) */
/* (the low byte of tty.state indicates a part of an escape sequence still
 * hasn't been read by Fread, and is an index into that escape sequence)
 */
#define TS_ESC		0x00ff
#define TS_HOLD		0x1000		/* hold (e.g. ^S/^Q) */
#define TS_COOKED	0x8000		/* interpret control chars */

/* structures for terminals */
struct tchars {
	char t_intrc;
	char t_quitc;
	char t_startc;
	char t_stopc;
	char t_eofc;
	char t_brkc;
};

struct ltchars {
	char t_suspc;
	char t_dsuspc;
	char t_rprntc;
	char t_flushc;
	char t_werasc;
	char t_lnextc;
};

struct sgttyb {
	char sg_ispeed;
	char sg_ospeed;
	char sg_erase;
	char sg_kill;
	unsigned short sg_flags;
};

struct winsize {
	short	ws_row;
	short	ws_col;
	short	ws_xpixel;
	short	ws_ypixel;
};

struct xkey {
	short	xk_num;
	char	xk_def[8];
};

struct tty {
	short		pgrp;		/* process group of terminal */
	short		state;		/* terminal status, e.g. stopped */
	short		use_cnt;	/* number of times terminal is open */
	short		res1;		/* reserved for future expansion */
	struct sgttyb 	sg;
	struct tchars 	tc;
	struct ltchars 	ltc;
	struct winsize	wsiz;
	long		rsel;		/* selecting process for read */
	long		wsel;		/* selecting process for write */
	char		*xkey;		/* extended keyboard table */
	long		hup_ospeed;	/* saved ospeed while hanging up */
	unsigned short	vmin, vtime;	/* min chars, timeout for RAW reads */
	long		resrvd[1];	/* for future expansion */
};

/* defines and declarations for Dcntl operations */

#define DEV_INSTALL	0xde02
#define DEV_NEWBIOS	0xde01
#define DEV_NEWTTY	0xde00

struct dev_descr {
	DEVDRV	*driver;
	short	dinfo;
	short	flags;
	struct tty *tty;
	long	devdrvsiz;		/* size of DEVDRV struct */
	long	reserved[4];
};

#define FS_INSTALL    0xf001  /* let the kernel know about the file system */
#define FS_MOUNT      0xf002  /* make a new directory for a file system */
#define FS_UNMOUNT    0xf003  /* remove a directory for a file system */
#define FS_UNINSTALL  0xf004  /* remove a file system from the list */


struct fs_descr
{
	FILESYS *file_system;
	short dev_no;    /* this is filled in by MiNT if arg == FS_MOUNT*/
	long flags;
	long reserved[4];
};


/* defines for TOS attribute bytes */
#ifndef FA_RDONLY
#define	       FA_RDONLY	       0x01
#define	       FA_HIDDEN	       0x02
#define	       FA_SYSTEM	       0x04
#define	       FA_LABEL		       0x08
#define	       FA_DIR		       0x10
#define	       FA_CHANGED	       0x20
#endif

#endif /* _filesys_h */
