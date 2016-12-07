/* Copyright (c) 2013-2014 Red Hat, Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use, modify,
   copy, or redistribute it subject to the terms and conditions of the BSD
   License.   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY expressed or implied, including the implied warranties
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy of this license
   is available at http://www.opensource.org/licenses. Any Red Hat trademarks that
   are incorporated in the source code or documentation are not subject to the BSD
   License and may only be used or replicated with the express permission of
   Red Hat, Inc.  */

/* Default linker script, for normal MSP430 executables.  */

OUTPUT_ARCH(msp430)
ENTRY(_start)

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

PROVIDE (WDTCTL = 0x015C);

INCLUDE intr_vectors.ld

MEMORY
{
  RAM (w) : ORIGIN = 0x500, LENGTH = 0xeb00
}

SECTIONS
{
  .rodata :
  {
    . = ALIGN(2);
    *(.plt)
    . = ALIGN(2);
    *(.lower.rodata.* .lower.rodata)
    . = ALIGN(2);
    *(.rodata .rodata.* .gnu.linkonce.r.* .const .const:*)
    . = ALIGN(2);
    *(.either.rodata.* .either.rodata)
    . = ALIGN(2);
    *(.rodata1)
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

    /* gcc uses crtbegin.o to find the start of the constructors, so
       we make sure it is first.  Because this is a wildcard, it
       doesn't matter if the user does not actually link against
       crtbegin.o; the linker won't look for a file to match a
       wildcard.  The wildcard also means that it doesn't matter which
       directory crtbegin.o is in.  */
    KEEP (*crtbegin*.o(.ctors))

    /* We don't want to include the .ctor section from from the
       crtend.o file until after the sorted ctors.  The .ctor section
       from the crtend file contains the end of ctors marker and it
       must be last */
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))

    KEEP (*crtbegin*.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } > RAM

  .text :
  {
    . = ALIGN(2);
    PROVIDE (_start = .);
    KEEP (*(SORT(.crt_*)))
    *(.lowtext)
    *(.lower.text.* .lower.text)
    *(.text .stub .text.* .gnu.linkonce.t.* .text:*)
    *(.either.text.* .either.text)
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
  } > RAM

  .data :
  {
    . = ALIGN(2);
    PROVIDE (__datastart = .);

    *(.lower.data.* .lower.data)
    KEEP (*(.jcr))
    *(.data.rel.ro.local) *(.data.rel.ro*)
    *(.dynamic)

    *(.data .data.* .gnu.linkonce.d.*)

    *(.either.data.* .either.data)

    KEEP (*(.gnu.linkonce.d.*personality*))
    SORT(CONSTRUCTORS)
    *(.data1)
    *(.got.plt) *(.got)

    /* We want the small data sections together, so single-instruction offsets
       can access them all, and initialized data all before uninitialized, so
       we can shorten the on-disk segment size.  */
    . = ALIGN(2);
    *(.sdata .sdata.* .gnu.linkonce.s.* D_2 D_1)

    . = ALIGN(2);
    _edata = .;
    PROVIDE (edata = .);
    PROVIDE (__dataend = .);
  } > RAM

  /* Note that crt0 assumes this is a multiple of two; all the
     start/stop symbols are also assumed word-aligned.  */
  PROVIDE(__romdatastart = LOADADDR(.data));
  PROVIDE (__romdatacopysize = SIZEOF(.data));

  .bss :
  {
    . = ALIGN(2);
    PROVIDE (__bssstart = .);
    *(.lower.bss.* .lower.bss)
    *(.dynbss)
    *(.sbss .sbss.*)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(.either.bss.* .either.bss)
    . = ALIGN(2);
    *(COMMON)
    . = ALIGN(2);
    PROVIDE (__bssend = .);
  } > RAM
  PROVIDE (__bsssize = SIZEOF(.bss));

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

  /* This section is intended to contain data that *is* initialised during load
     but *not* on application reset.  Normally the section would be stored in
     FLASH RAM, but this is not available here.  We just have to hope that the
     programmer knows what they are doing.  */
  .persistent :
  {
    . = ALIGN(2);
    PROVIDE (__persistent_start = .);
    *(.persistent)
    . = ALIGN(2);
    PROVIDE (__persistent_end = .);
  } > RAM
 
  _end = .;
  PROVIDE (end = .);

  /* We create this section so that "end" will always be in the
     FRAM region (matching .stack below), even if the .bss
     section is empty.  */
  .heap (NOLOAD) :
  {
    . = ALIGN(2);
    _end = .;
    PROVIDE (end = .);
    /* This word is here so that the section is not empty, and thus
       not discarded by the linker.  The actual value does not matter
       and is ignored.  */
    LONG(0);
  } > RAM

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

  /* Make sure that .upper sections are not used without -mlarge support.  */
  .upper :
  {
    *(.upper.rodata.* .upper.rodata)
    *(.upper.data.* .upper.data)
    *(.upper.bss.* .upper.bss)
    *(.upper.text.* .upper.text)  
    ASSERT (SIZEOF(.upper) == 0, "This MCU does not support high memory");
  }

  .resetvec :
  {
    *(.resetvec)
  } > VECT31

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
