/* Copyright (c) 2013-2015 Red Hat, Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions of
   the BSD License.   This program is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY expressed or implied, including the
   implied warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   A copy of this license is available at http://www.opensource.org/licenses.

   Any Red Hat trademarks that are incorporated in the source code or
   documentation are not subject to the BSD License and may only be used or
   replicated with the express permission of Red Hat, Inc.  */

/* Example linker script, for MSP430 MCUs that have RAM and both low and high
   FRAM memory.  For devices that have other memory configurations see the
   files: ram+flash.ld, ram+flash+flash2.ld or ram+fram.ld.  */

OUTPUT_ARCH(msp430)
ENTRY(_start)

/* Load the interrupt vector definitions.  */

INCLUDE intr_vectors.ld

/* Memory Regions.
   Note - These regions are just examples.  Real MSP430 MCUs will have
   different varieties and sizes of RAM and FLASH.  Device specific linker
   scripts are provided by TI, so this file is intended to be used as a
   guide for creating new scripts.  */
MEMORY
{
  RAM (rw)     : ORIGIN = 0x00500, LENGTH = 0x01b00
  FRAM (rwx)   : ORIGIN = 0x02000, LENGTH = 0x0df00
  /* The regions from intr_vectors.ld go here.  */
  FRAM2 (rwx)  : ORIGIN = 0x10000, LENGTH = 0xF0000
}

/* Hardware addresses.
   The values here are just examples.  Real hardware can place these
   registers at different locations.

   If these values are going to be the same for lots of different
   linker scripts you could just place them in a separate file
   and INCLUDE them here instead.

   To access these values from a C program, declare them as extern
   volatile values.  For example:

       extern volatile unsigned int WDTCTL;

       WDTCTL = WDTPW | WDTHOLD;  */

/* USCI B1 */
PROVIDE (UCB1CTLW0          = 0x0620);
PROVIDE (UCB1CTLW0_L        = 0x0620);
PROVIDE (UCB1CTLW0_H        = 0x0621);
PROVIDE (UCB1BRW            = 0x0626);
PROVIDE (UCB1BRW_L          = 0x0626);
PROVIDE (UCB1BRW_H          = 0x0627);
PROVIDE (UCB1STAT           = 0x062A);
PROVIDE (UCB1RXBUF          = 0x062C);
PROVIDE (UCB1TXBUF          = 0x062E);
PROVIDE (UCB1I2COA          = 0x0630);
PROVIDE (UCB1I2COA_L        = 0x0630);
PROVIDE (UCB1I2COA_H        = 0x0631);
PROVIDE (UCB1I2CSA          = 0x0632);
PROVIDE (UCB1I2CSA_L        = 0x0632);
PROVIDE (UCB1I2CSA_H        = 0x0633);
PROVIDE (UCB1ICTL           = 0x063C);
PROVIDE (UCB1ICTL_L         = 0x063C);
PROVIDE (UCB1ICTL_H         = 0x063D);
PROVIDE (UCB1IV             = 0x063E);

/* WATCHDOG TIMER A */
PROVIDE (WDTCTL             = 0x015C);
PROVIDE (WDTCTL_L           = 0x015C);
PROVIDE (WDTCTL_H           = 0x015D);

/* Sections.
   This is where sections from input files are assigned to memory regions.

   Note - the sections below are arranged in order of increasing address,
   starting with the lowest addressed memory region.  They do not have to
   be arranged this way though...  */

SECTIONS
{
  .data :
  {
    . = ALIGN(2);
    PROVIDE (__datastart = .);
    *(.lower.data.* .lower.data)

    . = ALIGN(2);
    KEEP (*(.jcr))
    *(.data.rel.ro.local) *(.data.rel.ro*)
    *(.dynamic)
    
    KEEP (*(.gnu.linkonce.d.*personality*))
    SORT(CONSTRUCTORS)
    *(.data1)
    *(.got.plt) *(.got)

    /* We want the small data sections together, so single-instruction offsets
       can access them all, and initialized data all before uninitialized, so
       we can shorten the on-disk segment size.  */
    . = ALIGN(2);
    *(.sdata .sdata.* .gnu.linkonce.s.* D_2 D_1)

    /* Note - unlike .text we *do* place incoming data sections here, in
       low memory, rather than in .upper.data in high memory.  This is
       because the code to initialise .upper.data will only be included in
       the C startup sequence if the assembler detects the presence of
       .upper.data or .either.data sections.  When the assembler detects
       the presence of a .data section it arranges for a different, low
       memory specific, sequence to be included in the startup code.  */
    . = ALIGN(2);
    *(.data .data.* .gnu.linkonce.d.*)

    /* See note in .rodata section about why we do not have this line here:

      *(.either.data.* .either.data)
    */

    . = ALIGN(2);
    _edata = .;
    PROVIDE (edata = .);
    PROVIDE (__dataend = .);

    /* Note the line below means that the .data section will be loaded
       into the FRAM2 memory region, but it is expected to be exectuted
       from the RAM region.  It is the responsibility of the C startup
       code to copy the data from FRAM2 to RAM.  (Which is why __romdatastart
       and __romdatacopysize are defined below).  This also means that
       this application can survive a device reset and start executing
       again.  The downside is that the .data section takes up two lots
       of memory, one in RAM and one in FRAM2.  */
  } > RAM AT> FRAM2
    
  /* Note that crt0 assumes that __romdatacopysize is a multiple of two.
     All the start/stop symbols are also assumed to be word-aligned.  */
  __romdatastart = LOADADDR(.data);
  __romdatacopysize = SIZEOF(.data);

  /* This section contains data that is not initialised during load
     *or* application reset.  */
  .noinit (NOLOAD) :
  {
    . = ALIGN(2);
    PROVIDE (__noinit_start = .);
    *(.noinit)
    . = ALIGN(2);
    PROVIDE (__noinit_end = .);
  } > RAM

  .text :
  {
    PROVIDE (_start = .);

    . = ALIGN(2);
    KEEP (*(SORT(.crt_*)))

    . = ALIGN(2);
    KEEP (*(.lowtext))

    . = ALIGN(2);
    *(.lower.text.* .lower.text)

    /* See note in .rodata section about why we do not have this line here:

      *(.either.text.* .either.text)
    */
    
    KEEP (*(.text.*personality*))
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.interp .hash .dynsym .dynstr .gnu.version*)
    PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);
    . = ALIGN(2);
    KEEP (*(.init))
    KEEP (*(.fini))
    KEEP (*(.tm_clone_table))
  } > FRAM

  .rodata :
  {
    . = ALIGN(2);
    *(.plt)

    . = ALIGN(2);
    *(.lower.rodata.* .lower.rodata)

    /* Note: By default we do not have this line:

         *(.either.rodata.*) *(.either.rodata)

       defined here, or anywhere else in this script.  This is deliberate.
       The algorithm in the linker that automatically places rodata into
       either the .rodata or the .upper.rodata sections relies upon the
       fact that the .either.rodata section is not defined.  If the
       .upper.rodata is not going to be defined then the line above should
       be restored to this section.

       The same reason applies to the absence of definitions for the
       .either.text, .either.data and .either.bss sections as well.  */
       
    . = ALIGN(2);
    *(.eh_frame_hdr)
    KEEP (*(.eh_frame))
    KEEP (*(.gcc_except_table)) *(.gcc_except_table.*)
    PROVIDE (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE (__preinit_array_end = .);
    PROVIDE (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    PROVIDE (__init_array_end = .);
    PROVIDE (__fini_array_start = .);
    KEEP (*(.fini_array))
    KEEP (*(SORT(.fini_array.*)))
    PROVIDE (__fini_array_end = .);
    LONG(0); /* Sentinel.  */

    /* gcc uses crtbegin.o to find the start of the constructors, so we make
       sure it is first.  Because this is a wildcard, it doesn't matter if
       the user does not actually link against crtbegin.o; the linker won't
       look for a file to match a wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o is in.  */
    KEEP (*crtbegin*.o(.ctors))

    /* We don't want to include the .ctor section from from the crtend.o file
       until after the sorted ctors.  The .ctor section from the crtend file
       contains the end of ctors marker and it must be last.  */
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))

    KEEP (*crtbegin*.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } > FRAM

  .bss :
  {
    . = ALIGN(2);
    PROVIDE (__bssstart = .);
    *(.lower.bss.* .lower.bss)
    /* See note in .rodata section about why we do not have this line here:

      *(.either.bss.* .either.bss)
    */
    *(.dynbss)
    *(.sbss .sbss.*)

    /* Note - unlike .text we *do* place incoming zero data here, in
       low memory, rather than in .upper.bss in high memory.  This is
       because the code to initialise .upper.bss will only be included in
       the C startup sequence if the assembler detects the presence of
       .upper.bss or .either.bss sections.  When the assembler detects
       the presence of .bss data it arranges for a different, low memory
       specific, startup sequence to be used.  */
    . = ALIGN(2);
    *(.bss .bss.* .gnu.linkonce.b.*)

    . = ALIGN(2);
    *(COMMON)

    . = ALIGN(2);
    PROVIDE (__bssend = .);
  } > FRAM

  PROVIDE (__bsssize = SIZEOF(.bss));
  
  /* We create this section so that "end" will always be in the
     FRAM region (matching .stack below), even if the .bss
     section is empty.  */
  .heap (NOLOAD) :
  {
    . = ALIGN(2);
    *(.heap)
    _end = .;
    PROVIDE (end = .);
    /* This word is here so that the section is not empty, and thus
       not discarded by the linker.  The actual value does not matter
       and is ignored.  */
    LONG(0);
  } > FRAM

  /* WARNING: Do not place anything in FRAM here.
     The heap section must be the last section in FRAM and the stack
     section must be placed at the very end of the FRAM region.  */
     
  /* Note: We place the stack in FRAM because there is more room in
     FRAM than in RAM.  If the region for the stack is changed,
     then be sure to change the definition of .heap_start above as well.  */
  .stack (ORIGIN (FRAM) + LENGTH (FRAM)) :
  {
    PROVIDE (__stack = .);
    *(.stack)
    /* Linker section checking ignores empty sections like this so we
       have to have our own test here.  The value 0x100 is just a guess.
       FIXME: There ought to be a way for the user to provide a stack
       requirement value, rather than using 0x100.  In fact ideally
       gcc's stack usage option ought to be able to be used in some way.  */
    ASSERT ((__stack > (_end + 0x100)), "Error: Too much data - no room left for the stack");
  }

  .resetvec :
  {
    *(.resetvec)
  } > VECT31

  .upper.text :
  {
    /* Note: We place ordinary incoming code here, rather than in
       the .text section, because there is a lot more room in the FRAM2
       memory region.  Space in the FRAM region used by the .text
       section is at a premium.  */
    . = ALIGN(2);
    *(.text .stub .text.* .gnu.linkonce.t.* .text:*)

    . = ALIGN(2);
    *(.upper.text.* .upper.text)
  } > FRAM2

  .upper.rodata :
  {
    /* Note: We place ordinary incoming read-only here, rather than in
       the .rodata section, because there is a lot more room in the FRAM2
       memory region.  Space in the FRAM region used by the .rodata section
       is at a premium.  */
    . = ALIGN(2);
    *(.rodata .rodata.* .gnu.linkonce.r.* .const .const:* .rodata1)

    . = ALIGN(2);
    *(.upper.rodata.* .upper.rodata)
  } > FRAM2

  .upper.data :
  {
    . = ALIGN(2);
    __high_datastart = .;

    *(.upper.data.* .upper.data)

    __high_dataend = .;
  } > FRAM2

  __rom_highdatacopysize = SIZEOF(.upper.data);

  /* This section contains a copy of the .upper.data section.
     It is used to initialise the .upper.data section after a device
     reset.  Note - unlike the .data section we do *not* place the
     copy of the .upper.data section in a different memory region.
     This is because space in the only other available region - FRAM
     - is at a premium.

     This poses a problem for the linker however since it does not know
     how to duplicate a section *within the same memory region*.  (It
     copes just fine when two memory regions are involved).  So instead
     some trickery in the C startup code is used.  The first time that
     the startup code runs it sees the 0 status word in the .cinit section
     and it knows that it has to copy data from .upper.data to .cinit.
     It then sets the status word to 1.  The second and subsequent times
     that the startup code is run (after device resets), it sees the
     1 value in the status word and knows that it has to copy data from
     the .cinit section to the .upper.data section.  */
  .cinit :
  {
    . = ALIGN(2);
    __upper_data_init = .;
    /* Status word.  */
    SHORT(0);

    /* Space for the copy of .upper.data.  */
    . = . + SIZEOF(.upper.data);
  } > FRAM2

  __rom_highdatastart = LOADADDR(.cinit) + 2;

  /* This section contains data that *is* initialised during load
     but *not* on application reset.  */
  .persistent :
  {
    . = ALIGN(2);
    PROVIDE (__persistent_start = .);
    *(.persistent)
    . = ALIGN(2);
    PROVIDE (__persistent_end = .);
  } > FRAM2
 
  .upper.bss :
  {
    . = ALIGN(2);
    __high_bssstart = .;
    *(.upper.bss.* .upper.bss)
    . = ALIGN(2);

    __high_bssend = .;
  } > FRAM2
  __high_bsssize = SIZEOF(.upper.bss);

  /* The rest are all not normally part of the runtime image.  */

  .MP430.attributes 0 :
  {
    KEEP (*(.MSP430.attributes))
    KEEP (*(.gnu.attributes))
    KEEP (*(__TI_build_attributes))
  }

  INCLUDE debug.ld

  /DISCARD/ : { *(.note.GNU-stack) }
}
