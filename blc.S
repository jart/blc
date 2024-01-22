/*-*- mode:unix-assembly; indent-tabs-mode:t; tab-width:8; coding:utf-8     -*-│
│vi: set et ft=asm ts=8 tw=8 fenc=utf-8                                     :vi│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2022 Justine Alexandra Roberts Tunney                              │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/

//	@fileoverview Binary Lambda Calculus Virtual Machine
//	              In a 521 byte Linux x64 ELF executable
//
//	@see	https://tromp.github.io/cl/Binary_lambda_calculus.html
//	@see	https://www.ioccc.org/2012/tromp/hint.html

#define TRACE   0               // enable ./trace.sh support
#define STACK	31		// how many bits of stack memory
#define TERMS	5000000		// number of words of bss
#define sz	(1<<lg)		// byte size of word

#define IOOPS	0		// code for read, write0, write1, flush
#define ASSOC	1		// code for variable name lookup
#define APPLY	2		// code for applications
#define LAMBD	3		// code for abstractions

#define NEXT	0
#define REFS	1
#define ENVP	2
#define TERM	3

#if STACK < 32
#define lg	2
#define I(x)	x##l
#define V(x)	x##d
#define R(x)	%e##x
#else
#define lg	3
#define I(x)	x##q
#define V(x)	x
#define R(x)	%r##x
#endif

#define mop
#define mem	%rbx
#define memd	%ebx
#define envp	%rbp
#define envpd	%ebp
#define contp	%r9
#define contpd	%r9d
#define frep	%r8
#define frepd	%r8d
#define frepb	%r8b
#define bits	%r13
#define bitsb	%r13b
#define bitsd	%r13d
#define idx	%r15
#define idxb	%r15b
#define idxd	%r15d

#define GetBitAddr *getbit-_(mem)

	.macro	pushpop constexpr:req register:req
	.byte	0x6a,\constexpr
	pop	%r\register
	.endm

	.macro	stlog ordinal:req
#if TRACE
	push	%rax
	push	%rcx
	push	%r11
	mov	$\ordinal,%eax
	syscall
	pop	%r11
	pop	%rcx
	pop	%rax
	nop
	nop
	nop
#endif
	.endm

	.macro	getpid
	stlog	0x27
	.endm
	.macro	getuid
	stlog	0x66
	.endm
	.macro	getgid
	stlog	0x68
	.endm
	.macro	getppid
	stlog	0x6e
	.endm
	.macro	geteuid
	stlog	0x6b
	.endm
	.macro	getegid
	stlog	0x6c
	.endm

	.bss
	.align	8
kBytes:	.zero	4*256
getbit:	.zero	8
ci:	.zero	sz
co:	.zero	sz
_:	.zero	sz*TERMS
	.previous

ehdr:	.ascii	"\177ELF"

////////////////////////////////////////////////////////////////////////////////
//	TWELVE BYTE OVERLAP		#
//	.byte	2			# EI_CLASS is ELFCLASS64
//	.byte	1			# EI_DATA is ELFDATA2LSB
//	.byte	1			# EI_VERSION is 1
//	.byte	3			# EI_OSABI is ELFOSABI_LINUX
//	.quad	0			#
kRom1:	.byte	LAMBD			#  0       (λ ((0 (λ (λ ?))) ⋯))
	.byte	  APPLY			#  1       8
	.byte	  8			#──2──┐    wut
	.byte	    APPLY		#  3  │    (0 (λ (λ ?)))
	.byte	    2			#──4────┐  (read (λ (λ ?)))
	.byte	      ASSOC		#  5  │ │  0
	.byte	      0			#  6  │ │  read
	.byte	    LAMBD		#──7────┘  (λ (λ ?))
	.byte	      LAMBD		#  8  │    (λ ?)
	.byte	        ASSOC		#  9  ┴    ?
kRom2:	.byte	0			# elf padding
	.byte	0			# elf padding
////////////////////////////////////////////////////////////////////////////////

ehdr2:	.word	2			# e_type is ET_EXEC           [precious]
	.word	62			# e_machine is EM_X86_64      [precious]

////////////////////////////////////////////////////////////////////////////////
//	.long	1			# e_version is 1                  [mark]
GetBit:	push	%rax
	push	%rdi
	jmp	Bit
////////////////////////////////////////////////////////////////////////////////

ehdr3:	.quad	_start			# e_entry                     [precious]
	.quad	phdrs - ehdr		# e_phoff is 56               [precious]

////////////////////////////////////////////////////////////////////////////////
//	FOURTEEN BYTE OVERLAP		#
//	.quad	0xc681c031		# e_shoff  [should be 0]
//	.long	0xfce2abac		# e_flags  [should be 0]
//	.word	0xc3			# e_ehsize [should be 64]
Copy:	xor	%eax,%eax		#
	add	$kRom1,%esi		#
0:	lodsb				#
	I(stos)				#
	loop	0b			#
	ret				#
	.byte	0			#
////////////////////////////////////////////////////////////////////////////////

	.word	56			# e_phentsize

////////////////////////////////////////////////////////////////////////////////
//	EIGHT BYTE OVERLAP		#
//	.word	1			# e_phnum              [correct overlap]
//	.word	0			# e_shentsize          [correct overlap]
//	.word	1|2|4			# e_shnum              [p_flags clobber]
//	.word	0			# e_shstrndx           [correct overlap]
phdrs:	.long	1			# p_type is PT_LOAD
	.long	1|2|4			# p_flags is PF_X|PF_W|PF_R
////////////////////////////////////////////////////////////////////////////////

	.quad	0			# p_offset
	.quad	ehdr			# p_vaddr

////////////////////////////////////////////////////////////////////////////////
//	EIGHT BYTE OVERLAP		#
//	.quad	ehdr			# p_paddr
Gc2:	mov	R(cx),V(frep)		#
	mov	ENVP*sz(%rcx),R(cx)	#
	jmp	Gc			#
////////////////////////////////////////////////////////////////////////////////

phdrs2:	.quad	filesz			# p_filesz         [insurmountable gulf]
	.quad	memsz			# p_memsz          [insurmountable gulf]
//	.quad	4096			# p_align

Gc:	I(dec)	REFS*sz(%rcx)		# unref memory (order matters)
	jnz	.Lret			# 1. free parents via recursion
	push	%rcx			# 2. free self
	mov	NEXT*sz(%rcx),R(cx)	# 3. free siblings via iteration
	call	Gc
	pop	%rcx
	mov	V(frep),NEXT*sz(%rcx)
	jmp	Gc2

kRom3:	.byte	APPLY			#  0         (λ 0 λ 0 (λ 0 wr0 wr1) put) (main get) [called once]
	.byte	.Lloop-1f		#──1─┐       xxx: this gets clobbered
1:	.byte	  LAMBD			#  2 │       λ 0 λ 0 (λ 0 wr0 wr1) put
	.byte	    APPLY		#  3 │       0 λ 0 (λ 0 wr0 wr1) put
	.byte	    2			#──4───┐     put λ 0 (λ 0 wr0 wr1) put
	.byte	      ASSOC		#  5 │ │     0
	.byte	      0			#  6 │ │     put [never evaluated]
	.byte	  LAMBD			#──7───┘     λ 0 (λ 0 wr0 wr1) put
	.byte	    APPLY		#  8 │       0 (λ 0 wr0 wr1) put
.L0w01:	.byte	    LAMBD		#──9───┐     λ 0 λ 0 wr0 wr1
	.byte	      APPLY		# 10 │ │     0 λ 0 wr0 wr1
	.byte	      2			#─11─────┐   put λ 0 wr0 wr1
	.byte	        ASSOC		# 12 │ │ │   0
	.byte	        0		#─13───┘ │   put
.Lw01:	.byte	  LAMBD			# 14─────┘   λ 0 wr0 wr1
	.byte	    APPLY		# 15 │       0 wr0 wr1
	.byte	    4			#─16───┐     wut
	.byte	      APPLY		# 17 │ │     0 wr0
	.byte	      1			#─18─────┐   1
	.byte	        ASSOC		# 19 │ │ │   0
.Lwr:	.byte	      IOOPS		#─20─────┘   wr0
	.byte	  IOOPS			#─21───┘     wr1
.Lloop:	.byte	APPLY			#─22─┘       main get
.Lmain:

Bit:	lea	ci-_(mem),%esi
	dec	bitsb
	jns	1f
	xor	%edi,%edi		# stdin
	xor	%eax,%eax		# __NR_read
	syscall
	lea	-2(%rdx,%rax,8),bitsd	# r12d = (rax << 3) - 1
1:	mov	(%rsi),%eax
	bt	bitsd,%eax
	pop	%rdi
	pop	%rax
.Lret:	ret

Parse:	push	%rdi			# save 1
0:	xor	%eax,%eax
	call	GetBitAddr
	jc	2f
	call	GetBitAddr
	jc	1f
	mov	$LAMBD,%al		# 00 is abstraction
	I(stos)
	jmp	0b
1:	mov	$APPLY,%al		# 01 is application
	I(stos)
	push	%rdi			# save 2
	I(scas)
	call	Parse
	pop	%rsi			# rest 2
	mov	R(ax),(%rsi)
	jmp	0b
2:	mov	$ASSOC,%al		# 1⋯ is variable
	I(stos)				# 0-based de Bruijn indices
	or	$-1,R(ax)
3:	call	GetBitAddr
	I(inc)	R(ax)
	jc	3b
	I(stos)
	pop	%rsi			# rest 1
	mov	%edi,%eax
	sub	%esi,%eax
	sar	$lg,%eax
	ret

Assoc:	getuid
	push	envp
1:	dec	R(cx)
	js	2f
	mov	NEXT*sz(envp),V(envp)
	jmp	1b
2:	mov	TERM*sz(envp),V(idx)
	mov	ENVP*sz(envp),V(envp)
	I(inc)	REFS*sz(envp)
	pop	%rcx
	call	Gc
	jmp	Eval

_start:	mov	$_,memd

//	Allocate Stack
//	We need a big one.
#if STACK < 32
	inc	%edi
	ror	$32-STACK,%edi		# bottom of stack
	sub	%edi,%esi		# size
#else
	mov	$0x7f0000000000-(1<<STACK),%rdi
	mov	$(1<<STACK),%rsi
#endif
	mov	$9,%al			# __NR_mmap
	mov	$3,%dl			# PROT_READ|PROT_WRITE
	mov	$0x132,%r10w		# MAP_PRIVATE|MAP_ANONYMOUS|MAP_GROWSDOWN|MAP_FIXED
	syscall
	lea	(%rdi,%rsi),%rsp

//	Setup Static Memory
	shr	%edx			# dx=1 for read and write
	mov	memd,%edi
	mov	memd,envpd		# xxx: prevent segfault
	movl	$GetBit,getbit-_(mem)

	pushpop	kRom3-kRom1,si
	pushpop	.Lmain-kRom3+1,cx
	call	Copy

//	Load ROM
	push	%rdi
	call	Parse
	pop	%rsi
	mov	%eax,-sz(%rsi)		# sets main() apply length
	xor	bitsd,bitsd
//	jmp	Eval

Eval:	mov	(mem,idx,sz),%eax	# should be ∈ {0,1,2,3}
	inc	idxd
	mov	(mem,idx,sz),R(cx)
	cmp	$APPLY,%al
	ja	Lambd
	je	Apply
	test	%al,%al
	jnz	Assoc
//	jmp	Ioops

Ioops:	getppid
	dec	idxd
	cmp	$.Lmain-kRom3,idxd
	ja	Read
//	jmp	Write

Write:	lea	co-_(mem),%esi		# idxd ∈ {13, 20, 21}
	and	%edx,idxd		# idxd &= 1
	test	$1,%cl			# cx&1 ∈ {1, 0, 0}
	jnz	Put
	shlb	(%rsi)
	or	idxb,(%rsi)		# idx ∈ {0, 1}
	mov	$.L0w01-kRom3,idxb	# λ 0 λ 0 wr0 wr1
0:	jmp	Eval

Put:	push	%rdi			# idx = 1
	mov	%edx,%edi		# stdout
	mov	%edx,%eax		# __NR_write
	syscall
	shl	idxd			# idx = 2
	pop	%rdi
	jmp	0b

Lambd:	getpid
	test	V(contp),V(contp)
	jz	Exit
	xchg	V(envp),NEXT*8(contp)
	xchg	V(envp),V(contp)
	jmp	Eval

Apply:	getgid
	test	V(frep),V(frep)
	jnz	1f
#if STACK > 31
	xor	%eax,%eax
	push	%rax			# calloc() on stack lool
	push	%rax
	push	%rax
	push	%rax
#else
	push	$0
	push	$0
#endif
	mov	%rsp,frep		# allocate heap on stack lool
1:	inc	idxd
	xchg	V(contp),NEXT*sz(frep)	# get closure from free list
	xchg	V(contp),V(frep)
	I(inc)	REFS*sz(contp)		# save machine state
	I(inc)	REFS*sz(envp)
	mov	V(envp),ENVP*sz(contp)
2:	add	V(idx),R(cx)
	mov	R(cx),TERM*sz(contp)
77:	jmp	Eval

Exit:	mov	sz(mem,idx,sz),%edi
	pushpop	60,ax			# __NR_exit
	syscall

Read:	call	GetBitAddr
	test	bitsb,bitsb
	lea	1(bitsd),bitsd
	jle	Expand
	xor	%esi,%esi		# Copy(0,6)
	pushpop	7,cx
	call	Copy
	movb	$4+8*(7+4)+4,-5*sz(%rdi)
//	jmp	Expand

Expand:	push	%rsi			# save 1
0:	test	bitsb,bitsb
	jz	1f
	xor	%eax,%eax
	call	GetBitAddr		# Copy[0,9] w/ GetBit()
	setnc	%al
	push	$0			# save 2
	push	$10			# save 3
	jmp	2f
1:	xor	%eax,%eax		# Copy[7,9] w/ 0
	push	$7			# save 2
	push	$3			# save 3
2:	pop	%rcx			# rest 3
	pop	%rsi			# rest 2
	push	%rax			# save 4
	call	Copy
	pop	%rax			# rest 4
	I(stos)
	pop	%rax			# rest 1
	test	%al,%al
	jz	77b
	push	bits
	jmp	0b

	.globl	ehdr
	.globl	_start
	.type	kRom1,@object
	.type	kRom2,@object
	.type	kRom3,@object
	.type	ehdr,@object
	.type	ehdr2,@object
	.type	ehdr3,@object
	.type	phdrs,@object
	.type	phdrs2,@object
	.weak	filesz
	.weak	memsz
