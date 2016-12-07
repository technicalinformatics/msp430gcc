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

/* Example linker script, for MSP430 MCUs that have RAM and FLASH memory.
   For devices that have other memory configurations see the files:
   ram+flash+flash2.ld, ram+fram.ld or ram+fram+fram2.ld.  */

OUTPUT_ARCH(msp430)
ENTRY(_start)

/* Load the interrupt vector definitions.  */

INCLUDE intr_vectors.ld

/* Memory Regions.
   Note - These regions are just examples.  Real MSP430 MCUs will have
   different sizes of RAM and FLASH.  Device specific linker scripts are
   provided by TI, so this file is intended to be used as a guide for
   creating new scripts.  */
MEMORY
{
  RAM   (rw)     : ORIGIN = 0x00500, LENGTH = 0x01b00
  FLASH (rx)     : ORIGIN = 0x02000, LENGTH = 0x0df00
  /* The regions from intr_vectors.ld go here.  */
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
  .resetvec :
  {
    *(.resetvec)
  } > VECT31

  .data :
  {
    . = ALIGN(2);
    PROVIDE (__datastart = .);
    *(.lower.data.* .lower.data)

    . = ALIGN(2);
    *(.sdata .sdata.* .gnu.linkonce.s.* D_2 D_1)

    . = ALIGN(2);
    KEEP (*(.jcr))
    *(.data.rel.ro.local) *(.data.rel.ro*)
    *(.dynamic)

    . = ALIGN(2);
    *(.data .data.* .gnu.linkonce.d.*)

    . = ALIGN(2);
    *(.either.data.* .either.data)

    . = ALIGN(2);
    *(.upper.data.* .upper.data)

    KEEP (*(.gnu.linkonce.d.*personality*))
    SORT(CONSTRUCTORS)

    *(.data1)
    *(.got.plt .got)

    . = ALIGN(2);
    _edata = .;
    PROVIDE (edata = .);
    PROVIDE (__dataend = .);

  /* Note - we assume that this type of device does not support applications
     that need to survive a device reset.  Thus there is no need to keep a
     copy of the initial data values (the .cinit section in TI speak).  */
  } > RAM

  __romdatastart = LOADADDR(.data);
  __romdatacopysize = SIZEOF(.data);

  /* This section contains data that *is* initialised during load
     but *not* on application reset.  Normally such a section would be
     in FRAM, but this device does not have that, so we stick the data
     in RAM.  Hopefully the programmer is aware of this.  */
  .persistent :
  {
    . = ALIGN(2);
    PROVIDE (__persistent_start = .);
    *(.persistent)
    . = ALIGN(2);
    PROVIDE (__persistent_end = .);
    /* Alternatively you could delete the five lines above and instead
       uncomment the line below.  This will generate a link time error
       message if any persistent data is found in the application.  */
    /* ASSERT (SIZEOF(.persistent) == 0, "This MCU does not support persistent data"); */
  } > RAM
 
  .bss :
  {
    . = ALIGN(2);
    PROVIDE (__bssstart = .);
    *(.lower.bss.* .lower.bss)
    *(.dynbss)
    *(.sbss .sbss.*)
    *(.bss .bss.* .gnu.linkonce.b.*)
    . = ALIGN(2);
    *(.either.bss.* .either.bss)
    . = ALIGN(2);
    *(.upper.bss.* .upper.bss)
    . = ALIGN(2);
    *(COMMON)
    . = ALIGN(2);
    PROVIDE (__bssend = .);
  } > RAM
  PROVIDE (__bsssize = SIZEOF(.bss));

  /* This section contains data that is not initialised during load.  */
  .noinit (NOLOAD) :
  {
    . = ALIGN(2);
    PROVIDE (__noinit_start = .);
    *(.noinit)
    . = ALIGN(2);
    PROVIDE (__noinit_end = .);
  } > RAM

  /* We create this section so that "end" will always be the last
     allocated section in the RAM region even if the .bss and
     .noinit sections are empty.  */
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
  } > RAM

  /* WARNING: Do not place anything in RAM here.
     The heap section must be the last section in RAM and the stack
     section must be placed at the very end of the RAM region.  */
     
  /* Note - memory allocation starts from _end, defined above and grows
     upwards.  Stack allocation start at __stack, defined below and grows
     downwards.  If the top of the heap ever meets the stack pointer, you
     have run out of memory.  */

  .stack (ORIGIN (RAM) + LENGTH (RAM)) :
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

  .rodata :
  {
    . = ALIGN(2);
    *(.plt)

    . = ALIGN(2);
    *(.lower.rodata.* .lower.rodata)

    . = ALIGN(2);
    *(.either.rodata.*) *(.either.rodata)

    . = ALIGN(2);
    *(.rodata .rodata.* .gnu.linkonce.r.* .const .const:* .rodata1)

    . = ALIGN(2);
    *(.upper.rodata.*) *(.upper.rodata)
       
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
  } > FLASH

  .text :
  {
    PROVIDE (_start = .);

    . = ALIGN(2);
    KEEP (*(SORT(.crt_*)))

    . = ALIGN(2);
    KEEP (*(.lowtext))

    . = ALIGN(2);
    *(.lower.text.* .lower.text)

    . = ALIGN(2);
    *(.text .stub .text.* .gnu.linkonce.t.* .text:*)

    . = ALIGN(2);
    *(.either.text.* .either.text)
    
    . = ALIGN(2);
    *(.upper.text.* .upper.text)
    
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
  } > FLASH

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
