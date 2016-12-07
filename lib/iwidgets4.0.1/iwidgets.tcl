#
# iwidgets.tcl
# ----------------------------------------------------------------------
# Invoked automatically by [incr Tk] upon startup to initialize
# the [incr Widgets] package.
# ----------------------------------------------------------------------
#  AUTHOR: Mark L. Ulferts               EMAIL: mulferts@spd.dsccc.com
#
#  @(#) $Id: iwidgets.tcl.in,v 1.3 2001/08/07 19:56:47 smithc Exp $
# ----------------------------------------------------------------------
#                Copyright (c) 1995  Mark L. Ulferts
# ======================================================================
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require Tcl 8.0
package require Tk 8.0
package require Itcl 3.2
package require Itk 3.2

namespace eval ::iwidgets {
    namespace export *

    variable library [file dirname [info script]]
    variable version 4.0.1
}

set cvsSrcDir [file join $iwidgets::library .. .. .. src itcl iwidgets]
set gitSrcDir [file join $iwidgets::library .. .. .. gdb itcl iwidgets]
lappend auto_path $iwidgets::library \
		  [file join $iwidgets::library generic] \
		  [file join $iwidgets::library scripts] \
		  [file join $cvsSrcDir generic] \
		  [file join $cvsSrcDir scripts] \
		  [file join $gitSrcDir generic] \
		  [file join $gitSrcDir scripts]
package provide Iwidgets $iwidgets::version
