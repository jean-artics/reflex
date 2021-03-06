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

with GNAT.Strings; use GNAT.Strings;

with Atree;    use Atree;
--with Checks;
with CStand;
with Debug;    use Debug;
with Elists;
--with Exp_Ch11;
--with Exp_Dbug;
with Fmap;
with Fname.UF;
with Hostparm; use Hostparm;
with Inline;   use Inline;
with Lib;      use Lib;
with Lib.Load; use Lib.Load;
--with Live;     use Live;
with Namet;    use Namet;
with Nlists;   use Nlists;
with Opt;      use Opt;
with Osint;
with Output;   use Output;
with Par;
--with Prepcomp;
with Rtsfind;
with Sprint;
with Scn;      use Scn;
with Sem;      use Sem;
with Sem_Ch8;  use Sem_Ch8;
-- with Sem_Elab; use Sem_Elab;
with Sem_Prag; use Sem_Prag;
with Sem_Warn; use Sem_Warn;
with Sinfo;    use Sinfo;
with Sinput;   use Sinput;
with Sinput.L; use Sinput.L;
with Tbuild;   use Tbuild;
with Types;    use Types;

procedure Frontend is
      Config_Pragmas : List_Id;
      --  Gather configuration pragmas

begin
   --  Carry out package initializations. These are initializations which
   --  might logically be performed at elaboration time, were it not for
   --  the fact that we may be doing things more than once in the big loop
   --  over files. Like elaboration, the order in which these calls are
   --  made is in some cases important. For example, Lib cannot be
   --  initialized until Namet, since it uses names table entries.

   Rtsfind.Initialize;
   Atree.Initialize;
   Nlists.Initialize;
   Elists.Initialize;
   Lib.Load.Initialize;
   Sem_Ch8.Initialize;
   Fname.UF.Initialize;
   --Exp_Ch11.Initialize;
   --Checks.Initialize;

   --  Create package Standard

   CStand.Create_Standard;

   --  Check possible symbol definitions specified by -gnateD switches

   --Prepcomp.Process_Command_Line_Symbol_Definitions;

   --  If -gnatep= was specified, parse the preprocessing data file

   --  Now that the preprocessing situation is established, we are able to
   --  load the main source (this is no longer done by Lib.Load.Initalize).

   Lib.Load.Load_Main_Source;

   --  Read and process configuration pragma files if present

   declare
      Save_Style_Check : constant Boolean := Opt.Style_Check;
      --  Save style check mode so it can be restored later

      Source_Config_File : Source_File_Index;
      --  Source reference for -gnatec configuration file

      Prag : Node_Id;

   begin
      --  We always analyze config files with style checks off, since
      --  we don't want a miscellaneous gnat.adc that is around to
      --  discombobulate intended -gnatg or -gnaty compilations.

      Opt.Style_Check := False;
      Style_Check := False;

      --  Capture current suppress options, which may get modified

      Scope_Suppress := Opt.Suppress_Options;

      --  First deal with gnat.adc file

      if Opt.Config_File then
         Name_Buffer (1 .. 10) := "reflex.rxc";
         Name_Len := 10;
         Source_reflex_adc := Load_Config_File (Name_Enter);

         if Source_reflex_adc /= No_Source_File then
            Initialize_Scanner (No_Unit, Source_reflex_adc);
            Config_Pragmas := Par (Configuration_Pragmas => True);

         else
            Config_Pragmas := Empty_List;
         end if;

      else
         Config_Pragmas := Empty_List;
      end if;

      --  Now deal with specified config pragmas files if there are any

      if Opt.Config_File_Names /= null then
         for Index in Opt.Config_File_Names'Range loop
            Name_Len := Config_File_Names (Index)'Length;
            Name_Buffer (1 .. Name_Len) := Config_File_Names (Index).all;
            Source_Config_File := Load_Config_File (Name_Enter);

            if Source_Config_File = No_Source_File then
               Osint.Fail
                 ("cannot find configuration pragmas file ",
                  Config_File_Names (Index).all);
            end if;

            Initialize_Scanner (No_Unit, Source_Config_File);
            Append_List_To
              (Config_Pragmas, Par (Configuration_Pragmas => True));
         end loop;
      end if;

      --  Now analyze all pragmas except those whose analysis must be
      --  deferred till after the main unit is analyzed.

      if Config_Pragmas /= Error_List
        and then Operating_Mode /= Check_Syntax
      then
         Prag := First (Config_Pragmas);
         while Present (Prag) loop
--            if not Delay_Config_Pragma_Analyze (Prag) then
               Analyze_Pragma (Prag);
--            end if;

            Next (Prag);
         end loop;
      end if;

      --  Restore style check, but if config file turned on checks, leave on!

      Opt.Style_Check := Save_Style_Check or Style_Check;

      --  Capture any modifications to suppress options from config pragmas

      Opt.Suppress_Options := Scope_Suppress;
   end;

   --  If there was a -gnatem switch, initialize the mappings of unit names to
   --  file names and of file names to path names from the mapping file.

   if Mapping_File_Name /= null then
      Fmap.Initialize (Mapping_File_Name.all);
   end if;

   --  We have now processed the command line switches, and the gnat.adc
   --  file, so this is the point at which we want to capture the values
   --  of the configuration switches (see Opt for further details).

   Opt.Register_Opt_Config_Switches;

   --  Initialize the scanner. Note that we do this after the call to
   --  Create_Standard, which uses the scanner in its processing of
   --  floating-point bounds.

   Initialize_Scanner (Main_Unit, Source_Index (Main_Unit));

   --  Output header if in verbose mode or full list mode

   if Verbose_Mode or Full_List then
      Write_Eol;

      if Operating_Mode = Generate_Code then
         Write_Str ("Compiling: ");
      else
         Write_Str ("Checking: ");
      end if;

      Write_Name (Full_File_Name (Current_Source_File));

      if not Debug_Flag_7 then
         Write_Str (" (source file time stamp: ");
         Write_Time_Stamp (Current_Source_File);
         Write_Char (')');
      end if;

      Write_Eol;
   end if;

   --  Here we call the parser to parse the compilation unit (or units in
   --  the check syntax mode, but in that case we won't go on to the
   --  semantics in any case).

   Discard_List (Par (Configuration_Pragmas => False));

   --  The main unit is now loaded, and subunits of it can be loaded,
   --  without reporting spurious loading circularities.

   Set_Loading (Main_Unit, False);

   --  Now that the main unit is installed, we can complete the analysis
   --  of the pragmas in gnat.adc and the configuration file, that require
   --  a context for their semantic processing.

   if Config_Pragmas /= Error_List
     and then Operating_Mode /= Check_Syntax
   then
      --  Pragmas that require some semantic activity, such as
      --  Interrupt_State, cannot be processed until the main unit
      --  is installed, because they require a compilation unit on
      --  which to attach with_clauses, etc. So analyze them now.

      declare
         Prag : Node_Id;

      begin
         Prag := First (Config_Pragmas);
         while Present (Prag) loop
--            if Delay_Config_Pragma_Analyze (Prag) then
               Analyze_Pragma (Prag);
--            end if;

            Next (Prag);
         end loop;
      end;
   end if;

   --  Now on to the semantics. Skip if in syntax only mode

   if Operating_Mode /= Check_Syntax then

      --  Install the configuration pragmas in the tree

      Set_Config_Pragmas (Aux_Decls_Node (Cunit (Main_Unit)), Config_Pragmas);

      --  Following steps are skipped if we had a fatal error during parsing

      if not Fatal_Error (Main_Unit) then

         --  Analyze (and possibly expand) main unit

         Scope_Suppress := Suppress_Options;
         Semantics (Cunit (Main_Unit));

         --  Cleanup processing after completing main analysis

         if Operating_Mode = Generate_Code then
            Instantiate_Bodies;
         end if;

         if Operating_Mode = Generate_Code then
            if Inline_Processing_Required then
               Analyze_Inlined_Bodies;
            end if;

            --  Remove entities from program that do not have any
            --  execution time references.

--              if Debug_Flag_UU then
--                 Collect_Garbage_Entities;
--              end if;

            --Check_Elab_Calls;

            --  Build unit exception table. We leave this up to the end to
            --  make sure that all the necessary information is at hand.

            ---Exp_Ch11.Generate_Unit_Exception_Table;
         end if;

         --  List library units if requested

--           if List_Units then
--              Lib.List;
--           end if;

         --  Output any messages for unreferenced entities

         Output_Unreferenced_Messages;
         Sem_Warn.Check_Unused_Withs;
      end if;
   end if;

   --  Qualify all entity names in inner packages, package bodies, etc.,
   --  except when compiling for the JVM back end, which depends on
   --  having unqualified names in certain cases and handles the
   --  generation of qualified names when needed.

   -- JMA ??? Exp_Dbug.Qualify_All_Entity_Names;

   --  If a mapping file has been specified by a -gnatem switch, update
   --  it if there has been some sourcs that were not in the mappings.

   if Mapping_File_Name /= null then
      Fmap.Update_Mapping_File (Mapping_File_Name.all);
   end if;

   return;
end Frontend;
