------------------------------------------------------------------------------
--                                                                          --
--                         REFLEX COMPILER COMPONENTS                       --
--                                                                          --
--          Copyright (C) 1992-2020, Free Software Foundation, Inc.         --
--                                                                          --
-- Reflex is free software; you can redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware Foundation; either version 3, or (at your option) any later version --
-- Reflex is distributed in the hope that it will be useful, but WITH-      --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License distributed with Reflex; see file COPYING3. If not, go to --
-- http://www.gnu.org/licenses for a complete copy of the license.          --
--                                                                          --
-- Reflex is a fork from the GNAT compiler. GNAT was originally developed   --
-- by the GNAT team at  New York University. Extensive  contributions to    --
-- GNAT were provided by Ada Core Technologies Inc. Reflex is developed  by --
-- the Artics team at Grenoble.                                             --
--                                                                          --
------------------------------------------------------------------------------

package body Debug is

   ---------------------------------
   -- Summary of Debug Flag Usage --
   ---------------------------------

   --  Debug flags for compiler (GNAT1)

   --  da   Generate messages tracking semantic analyzer progress
   --  db   Show encoding of type names for debug output
   --  dc   List names of units as they are compiled
   --  dd   Dynamic allocation of tables messages generated
   --  de   List the entity table
   --  df   Full tree/source print (includes withed units)
   --  dg   Print source from tree (generated code only)
   --  dh   Generate listing showing loading of name table hash chains
   --  di   Generate messages for visibility linking/delinking
   --  dj   Suppress "junk null check" for access parameter values
   --  dk   Generate GNATBUG message on abort, even if previous errors
   --  dl   Generate unit load trace messages
   --  dm   Allow VMS features even if not OpenVMS version
   --  dn   Generate messages for node/list allocation
   --  do   Print source from tree (original code only)
   --  dp   Generate messages for parser scope stack push/pops
   --  dq   No auto-alignment of small records
   --  dr   Generate parser resynchronization messages
   --  ds   Print source from tree (including original and generated stuff)
   --  dt   Print full tree
   --  du   Uncheck categorization pragmas
   --  dv   Output trace of overload resolution
   --  dw   Print trace of semantic scope stack
   --  dx   Force expansion on, even if no code being generated
   --  dy   Print tree of package Standard
   --  dz   Print source of package Standard

   --  dA   All entities included in representation information output
   --  dB   Output debug encoding of type names and variants
   --  dC   Output debugging information on check suppression
   --  dD   Delete elaboration checks in inner level routines
   --  dE   Apply elaboration checks to predefined units
   --  dF   Front end data layout enabled.
   --  dG   Generate all warnings including those normally suppressed
   --  dH   Hold (kill) call to gigi
   --  dI   Inhibit internal name numbering in gnatG listing
   --  dJ   Output debugging trace info for JGNAT (Java VM version of GNAT)
   --  dK   Kill all error messages
   --  dL   Output trace information on elaboration checking
   --  dM   Asssume all variables are modified (no current values)
   --  dN   No file name information in exception messages
   --  dO   Output immediate error messages
   --  dP   Do not check for controlled objects in preelaborable packages
   --  dQ
   --  dR   Bypass check for correct version of s-rpc
   --  dS   Never convert numbers to machine numbers in Sem_Eval
   --  dT   Convert to machine numbers only for constant declarations
   --  dU   Enable garbage collection of unreachable entities
   --  dV   Enable viewing of all symbols in debugger
   --  dW   Disable warnings on calls for IN OUT parameters
   --  dX   Enable Frontend ZCX even when it is not supported
   --  dY   Enable configurable run-time mode
   --  dZ

   --  d.a
   --  d.b
   --  d.c
   --  d.d
   --  d.e
   --  d.f
   --  d.g
   --  d.h
   --  d.i
   --  d.j
   --  d.k
   --  d.l
   --  d.m
   --  d.n
   --  d.o
   --  d.p
   --  d.q
   --  d.r
   --  d.s
   --  d.t
   --  d.u
   --  d.v
   --  d.w
   --  d.x  No exception handlers
   --  d.y
   --  d.z



   --  d1   Error msgs have node numbers where possible
   --  d2   Eliminate error flags in verbose form error messages
   --  d3   Dump bad node in Comperr on an abort
   --  d4   Inhibit automatic krunch of predefined library unit files
   --  d5   Debug output for tree read/write
   --  d6   Default access unconstrained to thin pointers
   --  d7   Do not output version & file time stamp in -gnatv or -gnatl mode
   --  d8   Force opposite endianness in packed stuff
   --  d9

   --  Debug flags for binder (GNATBIND)

   --  da
   --  db
   --  dc  List units as they are chosen
   --  dd
   --  de  Elaboration dependencies including system units
   --  df
   --  dg
   --  dh
   --  di
   --  dj
   --  dk
   --  dl
   --  dm
   --  dn  List details of manipulation of Num_Pred values
   --  do
   --  dp
   --  dq
   --  dr
   --  ds
   --  dt
   --  du  List units as they are acquired
   --  dv
   --  dw
   --  dx  Force binder to read xref information from ali files
   --  dy
   --  dz

   --  d1
   --  d2
   --  d3
   --  d4
   --  d5
   --  d6
   --  d7
   --  d8
   --  d9

   --  Debug flags used in package Make and its clients (e.g. GNATMAKE)

   --  da
   --  db
   --  dc
   --  dd
   --  de
   --  df
   --  dg
   --  dh
   --  di
   --  dj
   --  dk
   --  dl
   --  dm
   --  dn  Do not delete temp files created by gnatmake
   --  do
   --  dp  Prints the contents of the Q used by Make.Compile_Sources
   --  dq  Prints source files as they are enqueued and dequeued
   --  dr
   --  ds
   --  dt  Display time stamps when there is a mismatch
   --  du  List units as their ali files are acquired
   --  dv
   --  dw  Prints the list of units withed by the unit currently explored
   --  dx
   --  dy
   --  dz

   --  d1
   --  d2
   --  d3
   --  d4
   --  d5
   --  d6
   --  d7
   --  d8
   --  d9

   --------------------------------------------
   -- Documentation for Compiler Debug Flags --
   --------------------------------------------

   --  da   Generate messages tracking semantic analyzer progress. A message
   --       is output showing each node as it gets analyzed, expanded,
   --       resolved, or evaluated. This option is useful for finding out
   --       exactly where a bomb during semantic analysis is occurring.

   --  db   In Exp_Dbug, certain type names are encoded to include debugging
   --       information. This debug switch causes lines to be output showing
   --       the encodings used.

   --  dc   List names of units as they are compiled. One line of output will
   --       be generated at the start of compiling each unit (package or
   --       subprogram).

   --  dd   Dynamic allocation of tables messages generated. Each time a
   --       table is reallocated, a line is output indicating the expansion.

   --  de   List the entity table

   --  df   Full tree/source print (includes withed units). Normally the tree
   --       output (dt) or recreated source output (dg,do,ds) includes only
   --       the main unit. If df is set, then the output in either case
   --       includes all compiled units (see also dg,do,ds,dt). Note that to
   --       be effective, this swich must be used in combination with one or
   --       more of dt, dg, do or ds.

   --  dg   Print the source recreated from the generated tree. In the case
   --       where the tree has been rewritten this output includes only the
   --       generated code, not the original code (see also df,do,ds,dz).
   --       This flag differs from -gnatG in that the output also includes
   --       non-source generated null statements, and freeze nodes, which
   --       are normally omitted in -gnatG mode.

   --  dh   Generates a table at the end of a compilation showing how the hash
   --       table chains built by the Namet package are loaded. This is useful
   --       in ensuring that the hashing algorithm (in Namet.Hash) is working
   --       effectively with typical sets of program identifiers.

   --  di   Generate messages for visibility linking/delinking

   --  dj   Suppress "junk null check" for access parameters. This flag permits
   --       Ada programs to pass null parameters to access parameters, and to
   --       explicitly check such access values against the null literal.
   --       Neither of these is valid Ada, but both were allowed in versions of
   --       GNAT before 3.10, so this switch can ease the transition process.

   --  dk   Immediate kill on abort. Normally on an abort (i.e. a call to
   --       Comperr.Compiler_Abort), the GNATBUG message is not given if
   --       there is a previous error. This debug switch bypasses this test
   --       and gives the message unconditionally (useful for debugging).

   --  dl   Generate unit load trace messages. A line of traceback output is
   --       generated each time a request is made to the library manager to
   --       load a new unit.

   --  dm   Some features are permitted only in OpenVMS ports of GNAT (e.g.
   --       the specification of passing by descriptor). Normally any use
   --       of these features will be flagged as an error, but this debug
   --       flag allows acceptance of these features in non OpenVMS ports.
   --       Of course they may not have any useful effect, and in particular
   --       attempting to generate code with this flag set may blow up.
   --       The flag also forces the use of 64-bits for Long_Integer.

   --  dn   Generate messages for node/list allocation. Each time a node or
   --       list header is allocated, a line of output is generated. Certain
   --       other basic tree operations also cause a line of output to be
   --       generated. This option is useful in seeing where the parser is
   --       blowing up.;

   --  do   Print the source recreated from the generated tree. In the case
   --       where the tree has been rewritten, this output includes only the
   --       original code, not the generated code (see also df,dg,ds,dz).

   --  dp   Generate messages for parser scope stack push/pops. A line of
   --       output by the parser each time the parser scope stack is either
   --       pushed or popped. Useful in debugging situations where the
   --       parser scope stack ends up incorrectly synchronized

   --  dq   In layout version 1.38, 2002/01/12, a circuit was implemented
   --       to give decent default alignment to short records that had no
   --       specific alignment set. This debug option restores the previous
   --       behavior of giving such records poor alignments, typically 1.
   --       This may be useful in dealing with transition.

   --  dr   Generate parser resynchronization messages. Normally the parser
   --       resynchronizes quietly. With this debug option, two messages
   --       are generated, one when the parser starts a resynchronization
   --       skip, and another when it resumes parsing. Useful in debugging
   --       inadequate error recovery situations.

   --  ds   Print the source recreated from the generated tree. In the case
   --       where the tree has been rewritten this output includes both the
   --       generated code and the original code with the generated code
   --       being enlosed in curly brackets (see also df,do,ds,dz)

   --  dt   Print full tree. The generated tree is output (see also df,dy)

   --  du   Uncheck categorization pragmas. This debug switch causes the
   --       categorization pragmas (Pure, Preelaborate etc) to be ignored
   --       so that normal checks are not made (this is particularly useful
   --       for adding temporary debugging code to units that have pragmas
   --       that are inconsistent with the debugging code added.

   --  dv   Output trace of overload resolution. Outputs messages for
   --       overload attempts that involve cascaded errors, or where
   --       an interepretation is incompatible with the context.

   --  dw   Write semantic scope stack messages. Each time a scope is created
   --       or removed, a message is output (see the Sem_Ch8.New_Scope and
   --       Sem_Ch8.Pop_Scope subprograms).

   --  dx   Force expansion on, even if no code being generated. Normally the
   --       expander is inhibited if no code is generated. This switch forces
   --       expansion to proceed normally even if the backend is not being
   --       called. This is particularly useful for debugging purposes when
   --       using the front-end only version of the compiler (which normally
   --       would never do any expansion).

   --  dy   Print tree of package Standard. Normally the tree print out does
   --       not include package Standard, even if the -df switch is set. This
   --       switch forces output of the internal tree built for Standard.

   --  dz   Print source of package Standard. Normally the source print out
   --       does not include package Standard, even if the -df switch is set.
   --       This switch forces output of the source recreated from the internal
   --       tree built for Standard. Note that this differs from -gnatS in
   --       that it prints from the actual tree using the normal Sprint
   --       circuitry for printing trees.

   --  dA   Forces output of representation information, including full
   --       information for all internal type and object entities, as well
   --       as all user defined type and object entities including private
   --       and incomplete types.

   --  dB   Output debug encodings for types and variants. See Exp_Dbug for
   --       exact form of the generated output.

   --  dC   Output trace information showing the decisions made during
   --       check suppression activity in unit Checks.

   --  dD   Delete new elaboration checks. This flag causes GNAT to return
   --       to the 3.13a elaboration semantics, and to suppress the fixing
   --       of two bugs. The first is in the context of inner routines in
   --       dynamic elaboration mode, when the subprogram we are in was
   --       called at elaboration time by a unit that was also compiled with
   --       dynamic elaboration checks. In this case, if A calls B calls C,
   --       and all are in different units, we need an elaboration check at
   --       each call. These nested checks were only put in recently (see
   --       version 1.80 of Sem_Elab) and we provide this debug flag to
   --       revert to the previous behavior in case of regressions. The
   --       other behavior reverted by this flag is the treatment of the
   --       Elaborate_Body pragma in static elaboration mode. This used to
   --       be treated as not needing elaboration checking, but in fact in
   --       general Elaborate_All is still required because of nested calls.

   --  dE   Apply compile time elaboration checking for with relations between
   --       predefined units. Normally no checks are made (it seems that at
   --       least on the SGI, such checks run into trouble).

   --  dF   Front end data layout enabled. Normally front end data layout
   --       is only enabled if the target parameter Backend_Layout is False.
   --       This debugging switch enables it unconditionally.

   --  dG   Generate all warnings. Normally Errout suppresses warnings on
   --       units that are not part of the main extended source, and also
   --       suppresses warnings on instantiations in the main extended
   --       source that duplicate warnings already posted on the template.
   --       This switch stops both kinds of deletion and causes Errout to
   --       post all warnings sent to it.

   --  dH   Inhibit call to gigi. This is useful for testing front end data
   --       layout, and may be useful in other debugging situations where
   --       you do not want gigi to intefere with the testing.

   --  dI   Inhibit internal name numbering in gnatDG listing. For internal
   --       names of the form <uppercase-letters><digits><suffix>, the output
   --       will be modified to <uppercase-letters>...<suffix>. This is used
   --       in the fixed bugs run to minimize system and version dependency
   --       in filed -gnatDG output.

   --  dJ   Generate debugging trace output for the JGNAT back end. This
   --       consists of symbolic Java Byte Code sequences for all generated
   --       classes plus additional information to indicate local variables
   --       and methods.

   --  dK   Kill all error messages. This debug flag suppresses the output
   --       of all error messages. It is used in regression tests where the
   --       error messages are target dependent and irrelevant.

   --  dL   Output trace information on elaboration checking. This debug
   --       switch causes output to be generated showing each call or
   --       instantiation as it is checked, and the progress of the recursive
   --       trace through calls at elaboration time.

   --  dM   Assume all variables have been modified, and ignore current value
   --       indications. This debug flag disconnects the tracking of constant
   --       values (see Exp_Ch2.Expand_Current_Value).

   --  dN   Do not generate file name information in exception messages.

   --  dO   Output immediate error messages. This causes error messages to
   --       be output as soon as they are generated (disconnecting several
   --       circuits for improvement of messages, deletion of duplicate
   --       messages etc). Useful to diagnose compiler bombs caused by
   --       erroneous handling of error situations

   --  dP   Do not check for controlled objects in preelaborable packages.
   --       RM 10.2.1(9) forbids the use of library level controlled objects
   --       in preelaborable packages, but this restriction is a huge pain,
   --       especially in the predefined library units.

   --  dR   Bypass the check for a proper version of s-rpc being present
   --       to use the -gnatz? switch. This allows debugging of the use
   --       of stubs generation without needing to have GLADE (or some
   --       other PCS  installed).

   --  dS   Omit conversion of fpt numbers to exact machine numbers in
   --       non-static evaluation contexts (see Check_Non_Static_Context).
   --       This is intended for testing out timing problems with this
   --       conversion circuit.

   --  dT   Similar to dS, but omits the conversions only in the case where
   --       the parent is not a constant declaration.

   --  dU   Enable garbage collection of unreachable entities. This enables
   --       both the reachability analysis and changing the Is_Public and
   --       Is_Eliminated flags.

   --  dV   Enable viewing of all symbols in debugger. Causes debug information
   --       to be generated for all symbols, including internal symbols. This
   --       is enabled by default for -gnatD, but this switch allows this to
   --       be enabled without generating modified source files. Note that the
   --       use of -gnatdV ensures in the dwarf/elf case that all symbols that
   --       are present in the elf tables are also in the dwarf tables (which
   --       seems to be required by some tools). Another effect of dV is to
   --       generate full qualified names, including internal names generated
   --       for blocks and loops.

   --  dW   Disable warnings when a possibly uninitialized scalar value is
   --       passed to an IN OUT parameter of a procedure. This usage is a
   --       quite improper bounded error [erroneous in Ada 83] situation,
   --       and would normally generate a warning. However, to ease the
   --       task of transitioning incorrect legacy code, we provide this
   --       undocumented feature for suppressing these warnings.

   --  dX   Enable frontend ZCX even when it is not supported. Equivalent to
   --       -gnatZ but without verifying that System.Front_End_ZCX_Support
   --       is set. This causes the front end to generate suitable tables
   --       for ZCX handling even when the runtime cannot handle ZCX. This
   --       is used for testing the front end for correct ZCX operation, and
   --       in particular is useful for multi-target testing.

   --  dY   Enable configurable run-time mode, just as though the System file
   --       had Configurable_Run_Time_Mode set to True. This is useful in
   --       testing high integrity mode.

   --  d.x  No exception handlers in generated code. This causes exception
   --       handles to be eliminated from the generated code. They are still
   --       fully compiled and analyzed, they just get eliminated from the
   --       code generation step.


   --  d1   Error messages have node numbers where possible. Normally error
   --       messages have only source locations. This option is useful when
   --       debugging errors caused by expanded code, where the source location
   --       does not give enough information.

   --  d2   Suppress output of the error position flags for verbose form error
   --       messages. The messages are still interspersed in the listing, but
   --       without any error flags or extra blank lines. Also causes an extra
   --       <<< to be output at the right margin. This is intended to be the
   --       easiest format for checking conformance of ACATS B tests. This
   --       flag also suppresses the additional messages explaining why a
   --       non-static expression is non-static (see Sem_Eval.Why_Not_Static).
   --       This avoids having to worry about these messages in ACATS testing.

   --  d3   Causes Comperr to dump the contents of the node for which an abort
   --       was detected (normally only the Node_Id of the node is output).

   --  d4   Inhibits automatic krunching of predefined library unit file names.
   --       Normally, as described in the spec of package Krunch, such files
   --       are automatically krunched to 8 characters, with special treatment
   --       of the prefixes Ada, System, and Interfaces. Setting this debug
   --       switch disables this special treatment.

   --  d5   Causes the tree read/write circuit to output detailed information
   --       tracking the data that is read and written element by element.

   --  d6   Normally access-to-unconstrained-array types are represented
   --       using fat (double) pointers. Using this debug flag causes them
   --       to default to thin. This can be used to test the performance
   --       implications of using thin pointers, and also to test that the
   --       compiler functions correctly with this choice.

   --  d7   Normally a -gnatl or -gnatv listing includes the time stamp
   --       of the source file. This debug flag suppresses this output,
   --       and also suppresses the message with the version number.
   --       This is useful in certain regression tests.

   --  d8   This forces the packed stuff to generate code assuming the
   --       opposite endianness from the actual correct value. Useful in
   --       testing out code generation from the packed routines.

   ------------------------------------------
   -- Documentation for Binder Debug Flags --
   ------------------------------------------

   --  dc  List units as they are chosen. As units are selected for addition to
   --      the elaboration order, a line of output is generated showing which
   --      unit has been selected.

   --  de  Similar to the effect of -e (output complete list of elaboration
   --      dependencies) except that internal units are included in the
   --      listing.

   --  dn  List details of manipulation of Num_Pred values during execution of
   --      the algorithm used to determine a correct order of elaboration. This
   --      is useful in diagnosing any problems in its behavior.

   --  du  List unit name and file name for each unit as it is read in

   --  dx  Force the binder to read (and then ignore) the xref information
   --      in ali files (used to check that read circuit is working OK).

   ------------------------------------------------------------
   -- Documentation for the Debug Flags used in package Make --
   ------------------------------------------------------------

   --  Please note that such flags apply to all of Make clients,
   --  such as gnatmake.

   --  dn  Do not delete temporary files creates by Make at the end
   --      of execution, such as temporary config pragma files, mapping
   --      files or project path files.

   --  dp  Prints the Q used by routine Make.Compile_Sources every time
   --      we go around the main compile loop of Make.Compile_Sources

   --  dq  Prints source files as they are enqueued and dequeued in the Q
   --      used by routine Make.Compile_Sources. Useful to figure out the
   --      order in which sources are recompiled.

   --  dt  When a time stamp mismatch has been found for an ALI file,
   --      display the source file name, the time stamp expected and
   --      the time stamp found.

   --  du  List unit name and file name for each unit as it is read in

   --  dw  Prints the list of units withed by the unit currently explored
   --      during the main loop of Make.Compile_Sources.

   ----------------------
   -- Get_Debug_Flag_K --
   ----------------------

   function Get_Debug_Flag_K return Boolean is
   begin
      return Debug_Flag_K;
   end Get_Debug_Flag_K;

   --------------------
   -- Set_Debug_Flag --
   --------------------

   procedure Set_Debug_Flag (C : Character; Val : Boolean := True) is
      subtype Dig  is Character range '1' .. '9';
      subtype LLet is Character range 'a' .. 'z';
      subtype ULet is Character range 'A' .. 'Z';

   begin
      if C in Dig then
         case Dig (C) is
            when '1' => Debug_Flag_1 := Val;
            when '2' => Debug_Flag_2 := Val;
            when '3' => Debug_Flag_3 := Val;
            when '4' => Debug_Flag_4 := Val;
            when '5' => Debug_Flag_5 := Val;
            when '6' => Debug_Flag_6 := Val;
            when '7' => Debug_Flag_7 := Val;
            when '8' => Debug_Flag_8 := Val;
            when '9' => Debug_Flag_9 := Val;
         end case;

      elsif C in ULet then
         case ULet (C) is
            when 'A' => Debug_Flag_AA := Val;
            when 'B' => Debug_Flag_BB := Val;
            when 'C' => Debug_Flag_CC := Val;
            when 'D' => Debug_Flag_DD := Val;
            when 'E' => Debug_Flag_EE := Val;
            when 'F' => Debug_Flag_FF := Val;
            when 'G' => Debug_Flag_GG := Val;
            when 'H' => Debug_Flag_HH := Val;
            when 'I' => Debug_Flag_II := Val;
            when 'J' => Debug_Flag_JJ := Val;
            when 'K' => Debug_Flag_KK := Val;
            when 'L' => Debug_Flag_LL := Val;
            when 'M' => Debug_Flag_MM := Val;
            when 'N' => Debug_Flag_NN := Val;
            when 'O' => Debug_Flag_OO := Val;
            when 'P' => Debug_Flag_PP := Val;
            when 'Q' => Debug_Flag_QQ := Val;
            when 'R' => Debug_Flag_RR := Val;
            when 'S' => Debug_Flag_SS := Val;
            when 'T' => Debug_Flag_TT := Val;
            when 'U' => Debug_Flag_UU := Val;
            when 'V' => Debug_Flag_VV := Val;
            when 'W' => Debug_Flag_WW := Val;
            when 'X' => Debug_Flag_XX := Val;
            when 'Y' => Debug_Flag_YY := Val;
            when 'Z' => Debug_Flag_ZZ := Val;
         end case;

      else
         case LLet (C) is
            when 'a' => Debug_Flag_A := Val;
            when 'b' => Debug_Flag_B := Val;
            when 'c' => Debug_Flag_C := Val;
            when 'd' => Debug_Flag_D := Val;
            when 'e' => Debug_Flag_E := Val;
            when 'f' => Debug_Flag_F := Val;
            when 'g' => Debug_Flag_G := Val;
            when 'h' => Debug_Flag_H := Val;
            when 'i' => Debug_Flag_I := Val;
            when 'j' => Debug_Flag_J := Val;
            when 'k' => Debug_Flag_K := Val;
            when 'l' => Debug_Flag_L := Val;
            when 'm' => Debug_Flag_M := Val;
            when 'n' => Debug_Flag_N := Val;
            when 'o' => Debug_Flag_O := Val;
            when 'p' => Debug_Flag_P := Val;
            when 'q' => Debug_Flag_Q := Val;
            when 'r' => Debug_Flag_R := Val;
            when 's' => Debug_Flag_S := Val;
            when 't' => Debug_Flag_T := Val;
            when 'u' => Debug_Flag_U := Val;
            when 'v' => Debug_Flag_V := Val;
            when 'w' => Debug_Flag_W := Val;
            when 'x' => Debug_Flag_X := Val;
            when 'y' => Debug_Flag_Y := Val;
            when 'z' => Debug_Flag_Z := Val;
         end case;
      end if;
   end Set_Debug_Flag;

   ---------------------------
   -- Set_Dotted_Debug_Flag --
   ---------------------------

   procedure Set_Dotted_Debug_Flag (C : Character; Val : Boolean := True) is
      subtype Dig  is Character range '1' .. '9';
      subtype LLet is Character range 'a' .. 'z';
      subtype ULet is Character range 'A' .. 'Z';

   begin
      if C in Dig then
         case Dig (C) is
            when '1' => Debug_Flag_Dot_1 := Val;
            when '2' => Debug_Flag_Dot_2 := Val;
            when '3' => Debug_Flag_Dot_3 := Val;
            when '4' => Debug_Flag_Dot_4 := Val;
            when '5' => Debug_Flag_Dot_5 := Val;
            when '6' => Debug_Flag_Dot_6 := Val;
            when '7' => Debug_Flag_Dot_7 := Val;
            when '8' => Debug_Flag_Dot_8 := Val;
            when '9' => Debug_Flag_Dot_9 := Val;
         end case;

      elsif C in ULet then
         case ULet (C) is
            when 'A' => Debug_Flag_Dot_AA := Val;
            when 'B' => Debug_Flag_Dot_BB := Val;
            when 'C' => Debug_Flag_Dot_CC := Val;
            when 'D' => Debug_Flag_Dot_DD := Val;
            when 'E' => Debug_Flag_Dot_EE := Val;
            when 'F' => Debug_Flag_Dot_FF := Val;
            when 'G' => Debug_Flag_Dot_GG := Val;
            when 'H' => Debug_Flag_Dot_HH := Val;
            when 'I' => Debug_Flag_Dot_II := Val;
            when 'J' => Debug_Flag_Dot_JJ := Val;
            when 'K' => Debug_Flag_Dot_KK := Val;
            when 'L' => Debug_Flag_Dot_LL := Val;
            when 'M' => Debug_Flag_Dot_MM := Val;
            when 'N' => Debug_Flag_Dot_NN := Val;
            when 'O' => Debug_Flag_Dot_OO := Val;
            when 'P' => Debug_Flag_Dot_PP := Val;
            when 'Q' => Debug_Flag_Dot_QQ := Val;
            when 'R' => Debug_Flag_Dot_RR := Val;
            when 'S' => Debug_Flag_Dot_SS := Val;
            when 'T' => Debug_Flag_Dot_TT := Val;
            when 'U' => Debug_Flag_Dot_UU := Val;
            when 'V' => Debug_Flag_Dot_VV := Val;
            when 'W' => Debug_Flag_Dot_WW := Val;
            when 'X' => Debug_Flag_Dot_XX := Val;
            when 'Y' => Debug_Flag_Dot_YY := Val;
            when 'Z' => Debug_Flag_Dot_ZZ := Val;
         end case;

      else
         case LLet (C) is
            when 'a' => Debug_Flag_Dot_A := Val;
            when 'b' => Debug_Flag_Dot_B := Val;
            when 'c' => Debug_Flag_Dot_C := Val;
            when 'd' => Debug_Flag_Dot_D := Val;
            when 'e' => Debug_Flag_Dot_E := Val;
            when 'f' => Debug_Flag_Dot_F := Val;
            when 'g' => Debug_Flag_Dot_G := Val;
            when 'h' => Debug_Flag_Dot_H := Val;
            when 'i' => Debug_Flag_Dot_I := Val;
            when 'j' => Debug_Flag_Dot_J := Val;
            when 'k' => Debug_Flag_Dot_K := Val;
            when 'l' => Debug_Flag_Dot_L := Val;
            when 'm' => Debug_Flag_Dot_M := Val;
            when 'n' => Debug_Flag_Dot_N := Val;
            when 'o' => Debug_Flag_Dot_O := Val;
            when 'p' => Debug_Flag_Dot_P := Val;
            when 'q' => Debug_Flag_Dot_Q := Val;
            when 'r' => Debug_Flag_Dot_R := Val;
            when 's' => Debug_Flag_Dot_S := Val;
            when 't' => Debug_Flag_Dot_T := Val;
            when 'u' => Debug_Flag_Dot_U := Val;
            when 'v' => Debug_Flag_Dot_V := Val;
            when 'w' => Debug_Flag_Dot_W := Val;
            when 'x' => Debug_Flag_Dot_X := Val;
            when 'y' => Debug_Flag_Dot_Y := Val;
            when 'z' => Debug_Flag_Dot_Z := Val;
         end case;
      end if;
   end Set_Dotted_Debug_Flag;

end Debug;
