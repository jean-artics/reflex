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

with Atree;    use Atree;
with Debug;    use Debug;
with Debug_A;  use Debug_A;
with Einfo;    use Einfo;
with Errout;   use Errout;
with Fname;    use Fname;
with Lib;      use Lib;
with Lib.Load; use Lib.Load;
with Nlists;   use Nlists;
with Opt;      use Opt;
with Sem_Attr; use Sem_Attr;
with Sem_Ch2;  use Sem_Ch2;
with Sem_Ch3;  use Sem_Ch3;
with Sem_Ch4;  use Sem_Ch4;
with Sem_Ch5;  use Sem_Ch5;
with Sem_Ch6;  use Sem_Ch6;
with Sem_Ch7;  use Sem_Ch7;
with Sem_Ch8;  use Sem_Ch8;
with Sem_Ch10; use Sem_Ch10;
with Sem_Ch11; use Sem_Ch11;
with Sem_Ch12; use Sem_Ch12;
with Sem_Ch13; use Sem_Ch13;
with Sem_Prag; use Sem_Prag;
with Sem_Util; use Sem_Util;
with Sinfo;    use Sinfo;
with Stand;    use Stand;
with Uintp;    use Uintp;

pragma Warnings (Off, Sem_Util);
--  Suppress warnings of unused with for Sem_Util (used only in asserts)

package body Sem is

   Outer_Generic_Scope : Entity_Id := Empty;
   --  Global reference to the outer scope that is generic. In a non
   --  generic context, it is empty. At the moment, it is only used
   --  for avoiding freezing of external references in generics.

   -------------
   -- Analyze --
   -------------

   procedure Analyze (N : Node_Id) is
   begin
      Debug_A_Entry ("analyzing  ", N);

      --  Immediate return if already analyzed

      if Analyzed (N) then
         Debug_A_Exit ("analyzing  ", N, "  (done, analyzed already)");
         return;
      end if;

      --  Otherwise processing depends on the node kind

      case Nkind (N) is

         when N_Abstract_Subprogram_Declaration =>
            Analyze_Abstract_Subprogram_Declaration (N);

         when N_Aggregate =>
            Analyze_Aggregate (N);

         when N_Allocator =>
            null; -- Analyze_Allocator (N);

         when N_And_Then =>
            Analyze_Short_Circuit (N);

         when N_Aspect_Specification =>
            null;

         when N_Assignment_Statement =>
            Analyze_Assignment (N);

         when N_At_Clause =>
            Analyze_At_Clause (N);

         when N_Attribute_Reference =>
            Analyze_Attribute (N);

         when N_Attribute_Definition_Clause   =>
            Analyze_Attribute_Definition_Clause (N);

         when N_Block_Statement =>
            Analyze_Block_Statement (N);

         when N_Case_Statement =>
            Analyze_Case_Statement (N);

         when N_Character_Literal =>
            Analyze_Character_Literal (N);

         when N_Code_Statement =>
            Analyze_Code_Statement (N);

         when N_Compilation_Unit =>
            Analyze_Compilation_Unit (N);

         when N_Component_Declaration =>
            Analyze_Component_Declaration (N);

         when N_Conditional_Expression =>
            Analyze_Conditional_Expression (N);

         when N_Enumeration_Representation_Clause =>
            Analyze_Enumeration_Representation_Clause (N);

--           when N_Exception_Declaration =>
--              Analyze_Exception_Declaration (N);
--
--           when N_Exception_Renaming_Declaration =>
--              Analyze_Exception_Renaming (N);

         when N_Exit_Statement =>
            Analyze_Exit_Statement (N);

         when N_Expanded_Name =>
            Analyze_Expanded_Name (N);

         when N_Explicit_Dereference =>
            Analyze_Explicit_Dereference (N);

         when N_Extension_Aggregate =>
            Analyze_Aggregate (N);

         when N_Formal_Object_Declaration =>
            Analyze_Formal_Object_Declaration (N);

         when N_Formal_Package_Declaration =>
            Analyze_Formal_Package (N);

         when N_Formal_Subprogram_Declaration =>
            Analyze_Formal_Subprogram (N);

         when N_Formal_Type_Declaration =>
            Analyze_Formal_Type_Declaration (N);

         when N_Free_Statement =>
            Analyze_Free_Statement (N);

         when N_Freeze_Entity =>
            null;  -- no semantic processing required

         when N_Full_Type_Declaration =>
            Analyze_Type_Declaration (N);

         when N_Function_Call =>
            Analyze_Function_Call (N);

         when N_Function_Instantiation =>
            Analyze_Function_Instantiation (N);

         when N_Generic_Function_Renaming_Declaration =>
            Analyze_Generic_Function_Renaming (N);

         when N_Generic_Package_Declaration =>
            Analyze_Generic_Package_Declaration (N);

         when N_Generic_Package_Renaming_Declaration =>
            Analyze_Generic_Package_Renaming (N);

         when N_Generic_Procedure_Renaming_Declaration =>
            Analyze_Generic_Procedure_Renaming (N);

         when N_Generic_Subprogram_Declaration =>
            Analyze_Generic_Subprogram_Declaration (N);

         when N_Goto_Statement =>
            Analyze_Goto_Statement (N);

         when N_Handled_Sequence_Of_Statements =>
            Analyze_Handled_Statements (N);

         when N_Identifier =>
            Analyze_Identifier (N);

         when N_If_Statement =>
            Analyze_If_Statement (N);

         when N_Implicit_Label_Declaration =>
            Analyze_Implicit_Label_Declaration (N);

         when N_In =>
            Analyze_Membership_Op (N);

         when N_Incomplete_Type_Declaration =>
            Analyze_Incomplete_Type_Decl (N);

         when N_Indexed_Component =>
            Analyze_Indexed_Component_Form (N);

         when N_Integer_Literal =>
            Analyze_Integer_Literal (N);

--           when N_Itype_Reference =>
--              null; -- Analyze_Itype_Reference (N);

         when N_Label =>
            Analyze_Label (N);

         when N_Loop_Statement =>
            Analyze_Loop_Statement (N);

         when N_Not_In =>
            Analyze_Membership_Op (N);

         when N_Null =>
            Analyze_Null (N);

         when N_Null_Statement =>
            Analyze_Null_Statement (N);

         when N_Number_Declaration =>
            Analyze_Number_Declaration (N);

         when N_Object_Declaration =>
            Analyze_Object_Declaration (N);

         when N_Object_Renaming_Declaration  =>
            Analyze_Object_Renaming (N);

--           when N_Operator_Symbol =>
--              null; -- Analyze_Operator_Symbol (N);

         when N_Op_Abs =>
            Analyze_Unary_Op (N);

         when N_Op_Add =>
            Analyze_Arithmetic_Op (N);

         when N_Op_And =>
            Analyze_Logical_Op (N);

         when N_Op_Concat =>
            Analyze_Concatenation (N);

         when N_Op_Divide =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Eq =>
            Analyze_Equality_Op (N);

         when N_Op_Expon =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Ge =>
            Analyze_Comparison_Op (N);

         when N_Op_Gt =>
            Analyze_Comparison_Op (N);

         when N_Op_Le =>
            Analyze_Comparison_Op (N);

         when N_Op_Lt =>
            Analyze_Comparison_Op (N);

         when N_Op_Minus =>
            Analyze_Unary_Op (N);

         when N_Op_Mod =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Multiply =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Ne =>
            Analyze_Equality_Op (N);

         when N_Op_Not =>
            Analyze_Negation (N);

         when N_Op_Or =>
            Analyze_Logical_Op (N);

         when N_Op_Plus =>
            Analyze_Unary_Op (N);

         when N_Op_Rem =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Rotate_Left =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Rotate_Right =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Shift_Left =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Shift_Right =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Shift_Right_Arithmetic =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Subtract =>
            Analyze_Arithmetic_Op (N);

         when N_Op_Xor =>
            Analyze_Logical_Op (N);

         when N_Or_Else =>
            Analyze_Short_Circuit (N);

         when N_Others_Choice =>
            Analyze_Others_Choice (N);

         when N_Package_Body =>
            Analyze_Package_Body (N);

         when N_Package_Declaration =>
            Analyze_Package_Declaration (N);

         when N_Package_Instantiation =>
            Analyze_Package_Instantiation (N);

         when N_Package_Renaming_Declaration =>
            Analyze_Package_Renaming (N);

         when N_Package_Specification =>
            Analyze_Package_Specification (N);

         when N_Parameter_Association =>
            Analyze_Parameter_Association (N);

         when N_Pragma =>
            Analyze_Pragma (N);

         when N_Private_Extension_Declaration =>
            Analyze_Private_Extension_Declaration (N);

         when N_Private_Type_Declaration =>
            Analyze_Private_Type_Declaration (N);

         when N_Procedure_Call_Statement =>
            Analyze_Procedure_Call (N);

         when N_Procedure_Instantiation =>
            Analyze_Procedure_Instantiation (N);

         when N_Qualified_Expression =>
            Analyze_Qualified_Expression (N);

         when N_Range =>
            Analyze_Range (N);

         when N_Range_Constraint =>
            Analyze_Range (Range_Expression (N));
	    
	 when N_Reactive_Type =>
	    null;
	 when N_Reactive_State =>
	    null;
	 when N_Reactive_Wait_Statement =>
	    Analyze_Reactive_Wait_Statement (N);

	 when N_Reactive_Pause_Statement =>
	    Analyze_Reactive_Pause_Statement (N);
	    
	 when N_Reactive_Fork_Statement =>
	    Analyze_Reactive_Fork_Statement (N);

	 when N_Reactive_Fork_Alternative =>
	    raise Program_Error;
	    
	 when N_Reactive_Select_Statement =>
	    Analyze_Reactive_Select_Statement (N);

	 when N_Reactive_Select_Alternative =>
	    raise Program_Error;

	 when N_Reactive_Abort_Statement =>
	    null;
	 when N_Reactive_Abort_Handler =>
	    null;
	    
         when N_Real_Literal =>
            Analyze_Real_Literal (N);

         when N_Record_Representation_Clause =>
            Analyze_Record_Representation_Clause (N);

         when N_Reference =>
            Analyze_Reference (N);

         when N_Return_Statement =>
            Analyze_Return_Statement (N);

         when N_Selected_Component =>
            Find_Selected_Component (N);
            --  ??? why not Analyze_Selected_Component, needs comments

         when N_Slice =>
            Analyze_Slice (N);

         when N_String_Literal =>
            Analyze_String_Literal (N);

         when N_Subprogram_Body =>
            Analyze_Subprogram_Body (N);

         when N_Subprogram_Declaration =>
            Analyze_Subprogram_Declaration (N);

         when N_Subprogram_Info =>
            Analyze_Subprogram_Info (N);

         when N_Subprogram_Renaming_Declaration =>
            Analyze_Subprogram_Renaming (N);

         when N_Subtype_Declaration =>
            Analyze_Subtype_Declaration (N);

         when N_Subtype_Indication =>
            Analyze_Subtype_Indication (N);

         when N_Type_Conversion =>
            Analyze_Type_Conversion (N);

         when N_Unchecked_Expression =>
            Analyze_Unchecked_Expression (N);

         when N_Unchecked_Type_Conversion =>
            Analyze_Unchecked_Type_Conversion (N);

         when N_Use_Package_Clause =>
            Analyze_Use_Package (N);

         when N_Use_Type_Clause =>
            null; -- Analyze_Use_Type (N);

         when N_Validate_Unchecked_Conversion =>
            null;

         when N_With_Clause =>
            Analyze_With_Clause (N);

         when N_With_Type_Clause =>
            null; -- Analyze_With_Type_Clause (N);

         --  A call to analyze the Empty node is an error, but most likely
         --  it is an error caused by an attempt to analyze a malformed
         --  piece of tree caused by some other error, so if there have
         --  been any other errors, we just ignore it, otherwise it is
         --  a real internal error which we complain about.

         when N_Empty =>
            pragma Assert (Serious_Errors_Detected /= 0);
            null;

         --  A call to analyze the error node is simply ignored, to avoid
         --  causing cascaded errors (happens of course only in error cases)

         when N_Error =>
            null;

         --  For the remaining node types, we generate compiler abort, because
         --  these nodes are always analyzed within the Sem_Chn routines and
         --  there should never be a case of making a call to the main Analyze
         --  routine for these node kinds. For example, an N_Access_Definition
         --  node appears only in the context of a type declaration, and is
         --  processed by the analyze routine for type declarations.

         when
           N_Access_Definition                      |
           N_Access_Function_Definition             |
           N_Access_Procedure_Definition            |
           N_Access_To_Object_Definition            |
           N_Case_Statement_Alternative             |
           N_Compilation_Unit_Aux                   |
           N_Component_Association                  |
           N_Component_Clause                       |
           N_Component_Definition                   |
           N_Component_List                         |
           N_Constrained_Array_Definition           |
           N_Defining_Character_Literal             |
           N_Defining_Identifier                    |
           --N_Defining_Operator_Symbol               |
           N_Defining_Program_Unit_Name             |
           N_Derived_Type_Definition                |
           N_Designator                             |
           N_Digits_Constraint                      |
           N_Discriminant_Association               |
           N_Elsif_Part                             |
           N_Enumeration_Type_Definition            |
--           N_Exception_Handler                      |
           N_Floating_Point_Definition              |
           N_Formal_Derived_Type_Definition         |
           N_Formal_Discrete_Type_Definition        |
           N_Formal_Floating_Point_Definition       |
           N_Formal_Modular_Type_Definition         |
           N_Formal_Private_Type_Definition         |
           N_Formal_Signed_Integer_Type_Definition  |
           N_Function_Specification                 |
           N_Generic_Association                    |
           N_Index_Or_Discriminant_Constraint       |
           N_Iteration_Scheme                       |
           N_Loop_Parameter_Specification           |
           N_Mod_Clause                             |
           N_Modular_Type_Definition                |
           N_Parameter_Specification                |
           N_Pragma_Argument_Association            |
           N_Procedure_Specification                |
           N_Real_Range_Specification               |
           N_Record_Definition                      |
           N_Signed_Integer_Type_Definition         |
           N_Unconstrained_Array_Definition         |
           N_Unused_At_Start                        |
           N_Unused_At_End                          =>

            raise Program_Error;
      end case;

      Debug_A_Exit ("analyzing  ", N, "  (done)");

      --  Now that we have analyzed the node, we call the expander to
      --  perform possible expansion. This is done only for nodes that
      --  are not subexpressions, because in the case of subexpressions,
      --  we don't have the type yet, and the expander will need to know
      --  the type before it can do its job. For subexpression nodes, the
      --  call to the expander happens in the Sem_Res.Resolve.

      --  The Analyzed flag is also set at this point for non-subexpression
      --  nodes (in the case of subexpression nodes, we can't set the flag
      --  yet, since resolution and expansion have not yet been completed)

--        if Nkind (N) not in N_Subexpr then
--           Expand (N);
--        end if;
   end Analyze;

   --  Version with check(s) suppressed

   procedure Analyze (N : Node_Id; Suppress : Check_Id) is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Analyze (N);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Analyze (N);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Analyze;

   ------------------
   -- Analyze_List --
   ------------------

   procedure Analyze_List (L : List_Id) is
      Node : Node_Id;

   begin
      Node := First (L);
      while Present (Node) loop
         Analyze (Node);
         Next (Node);
      end loop;
   end Analyze_List;

   --  Version with check(s) suppressed

   procedure Analyze_List (L : List_Id; Suppress : Check_Id) is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Analyze_List (L);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Analyze_List (L);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Analyze_List;

   --------------------------
   -- Copy_Suppress_Status --
   --------------------------

   procedure Copy_Suppress_Status
     (C    : Check_Id;
      From : Entity_Id;
      To   : Entity_Id)
   is
   begin
      if not Checks_May_Be_Suppressed (From) then
         return;
      end if;

      --  First search the local entity suppress table, we search this in
      --  reverse order so that we get the innermost entry that applies to
      --  this case if there are nested entries. Note that for the purpose
      --  of this procedure we are ONLY looking for entries corresponding
      --  to a two-argument Suppress, where the second argument matches From.

      for J in
        reverse Local_Entity_Suppress.First .. Local_Entity_Suppress.Last
      loop
         declare
            R : Entity_Check_Suppress_Record
                  renames Local_Entity_Suppress.Table (J);

         begin
            if R.Entity = From
              and then (R.Check = All_Checks or else R.Check = C)
            then
               if R.Suppress then
                  Set_Checks_May_Be_Suppressed (To, True);
                  Local_Entity_Suppress.Append
                    ((Entity   => To,
                      Check    => C,
                      Suppress => True));
                  return;
               end if;
            end if;
         end;
      end loop;

      --  Now search the global entity suppress table for a matching entry
      --  We also search this in reverse order so that if there are multiple
      --  pragmas for the same entity, the last one applies.

      for J in
        reverse Global_Entity_Suppress.First .. Global_Entity_Suppress.Last
      loop
         declare
            R : Entity_Check_Suppress_Record
                 renames Global_Entity_Suppress.Table (J);

         begin
            if R.Entity = From
              and then (R.Check = All_Checks or else R.Check = C)
            then
               if R.Suppress then
                  Set_Checks_May_Be_Suppressed (To, True);
                  Local_Entity_Suppress.Append
                    ((Entity   => To,
                      Check    => C,
                      Suppress => True));
               end if;
            end if;
         end;
      end loop;
   end Copy_Suppress_Status;

   -------------------------
   -- Enter_Generic_Scope --
   -------------------------

   procedure Enter_Generic_Scope (S : Entity_Id) is
   begin
      if No (Outer_Generic_Scope) then
         Outer_Generic_Scope := S;
      end if;
   end Enter_Generic_Scope;

   ------------------------
   -- Exit_Generic_Scope --
   ------------------------

   procedure Exit_Generic_Scope  (S : Entity_Id) is
   begin
      if S = Outer_Generic_Scope then
         Outer_Generic_Scope := Empty;
      end if;
   end Exit_Generic_Scope;

   -----------------------
   -- Explicit_Suppress --
   -----------------------

   function Explicit_Suppress (E : Entity_Id; C : Check_Id) return Boolean is
   begin
      if not Checks_May_Be_Suppressed (E) then
         return False;

      else
         for J in
           reverse Global_Entity_Suppress.First .. Global_Entity_Suppress.Last
         loop
            declare
               R : Entity_Check_Suppress_Record
                     renames Global_Entity_Suppress.Table (J);

            begin
               if R.Entity = E
                 and then (R.Check = All_Checks or else R.Check = C)
               then
                  return R.Suppress;
               end if;
            end;
         end loop;

         return False;
      end if;
   end Explicit_Suppress;

   -----------------------------
   -- External_Ref_In_Generic --
   -----------------------------

   function External_Ref_In_Generic (E : Entity_Id) return Boolean is
      Scop : Entity_Id;

   begin
      --  Entity is global if defined outside of current outer_generic_scope:
      --  Either the entity has a smaller depth that the outer generic, or it
      --  is in a different compilation unit, or it is defined within a unit
      --  in the same compilation, that is not within the outer_generic.

      if No (Outer_Generic_Scope) then
         return False;

      elsif Scope_Depth (Scope (E)) < Scope_Depth (Outer_Generic_Scope)
        or else not In_Same_Source_Unit (E, Outer_Generic_Scope)
      then
         return True;

      else
         Scop := Scope (E);

         while Present (Scop) loop
            if Scop = Outer_Generic_Scope then
               return False;
            elsif Scope_Depth (Scop) < Scope_Depth (Outer_Generic_Scope) then
               return True;
            else
               Scop := Scope (Scop);
            end if;
         end loop;

         return True;
      end if;
   end External_Ref_In_Generic;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Local_Entity_Suppress.Init;
      Global_Entity_Suppress.Init;
      Scope_Stack.Init;
      Unloaded_Subunits := False;
   end Initialize;

   ------------------------------
   -- Insert_After_And_Analyze --
   ------------------------------

   procedure Insert_After_And_Analyze (N : Node_Id; M : Node_Id) is
      Node : Node_Id;

   begin
      if Present (M) then

         --  If we are not at the end of the list, then the easiest
         --  coding is simply to insert before our successor

         if Present (Next (N)) then
            Insert_Before_And_Analyze (Next (N), M);

         --  Case of inserting at the end of the list

         else
            --  Capture the Node_Id of the node to be inserted. This Node_Id
            --  will still be the same after the insert operation.

            Node := M;
            Insert_After (N, M);

            --  Now just analyze from the inserted node to the end of
            --  the new list (note that this properly handles the case
            --  where any of the analyze calls result in the insertion of
            --  nodes after the analyzed node, expecting analysis).

            while Present (Node) loop
               Analyze (Node);
               Mark_Rewrite_Insertion (Node);
               Next (Node);
            end loop;
         end if;
      end if;
   end Insert_After_And_Analyze;

   --  Version with check(s) suppressed

   procedure Insert_After_And_Analyze
     (N        : Node_Id;
      M        : Node_Id;
      Suppress : Check_Id)
   is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Insert_After_And_Analyze (N, M);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Insert_After_And_Analyze (N, M);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Insert_After_And_Analyze;

   -------------------------------
   -- Insert_Before_And_Analyze --
   -------------------------------

   procedure Insert_Before_And_Analyze (N : Node_Id; M : Node_Id) is
      Node : Node_Id;

   begin
      if Present (M) then

         --  Capture the Node_Id of the first list node to be inserted.
         --  This will still be the first node after the insert operation,
         --  since Insert_List_After does not modify the Node_Id values.

         Node := M;
         Insert_Before (N, M);

         --  The insertion does not change the Id's of any of the nodes in
         --  the list, and they are still linked, so we can simply loop from
         --  the original first node until we meet the node before which the
         --  insertion is occurring. Note that this properly handles the case
         --  where any of the analyzed nodes insert nodes after themselves,
         --  expecting them to get analyzed.

         while Node /= N loop
            Analyze (Node);
            Mark_Rewrite_Insertion (Node);
            Next (Node);
         end loop;
      end if;
   end Insert_Before_And_Analyze;

   --  Version with check(s) suppressed

   procedure Insert_Before_And_Analyze
     (N        : Node_Id;
      M        : Node_Id;
      Suppress : Check_Id)
   is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Insert_Before_And_Analyze (N, M);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Insert_Before_And_Analyze (N, M);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Insert_Before_And_Analyze;

   -----------------------------------
   -- Insert_List_After_And_Analyze --
   -----------------------------------

   procedure Insert_List_After_And_Analyze (N : Node_Id; L : List_Id) is
      After : constant Node_Id := Next (N);
      Node  : Node_Id;

   begin
      if Is_Non_Empty_List (L) then

         --  Capture the Node_Id of the first list node to be inserted.
         --  This will still be the first node after the insert operation,
         --  since Insert_List_After does not modify the Node_Id values.

         Node := First (L);
         Insert_List_After (N, L);

         --  Now just analyze from the original first node until we get to
         --  the successor of the original insertion point (which may be
         --  Empty if the insertion point was at the end of the list). Note
         --  that this properly handles the case where any of the analyze
         --  calls result in the insertion of nodes after the analyzed
         --  node (possibly calling this routine recursively).

         while Node /= After loop
            Analyze (Node);
            Mark_Rewrite_Insertion (Node);
            Next (Node);
         end loop;
      end if;
   end Insert_List_After_And_Analyze;

   --  Version with check(s) suppressed

   procedure Insert_List_After_And_Analyze
     (N : Node_Id; L : List_Id; Suppress : Check_Id)
   is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Insert_List_After_And_Analyze (N, L);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Insert_List_After_And_Analyze (N, L);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Insert_List_After_And_Analyze;

   ------------------------------------
   -- Insert_List_Before_And_Analyze --
   ------------------------------------

   procedure Insert_List_Before_And_Analyze (N : Node_Id; L : List_Id) is
      Node : Node_Id;

   begin
      if Is_Non_Empty_List (L) then

         --  Capture the Node_Id of the first list node to be inserted.
         --  This will still be the first node after the insert operation,
         --  since Insert_List_After does not modify the Node_Id values.

         Node := First (L);
         Insert_List_Before (N, L);

         --  The insertion does not change the Id's of any of the nodes in
         --  the list, and they are still linked, so we can simply loop from
         --  the original first node until we meet the node before which the
         --  insertion is occurring. Note that this properly handles the case
         --  where any of the analyzed nodes insert nodes after themselves,
         --  expecting them to get analyzed.

         while Node /= N loop
            Analyze (Node);
            Mark_Rewrite_Insertion (Node);
            Next (Node);
         end loop;
      end if;
   end Insert_List_Before_And_Analyze;

   --  Version with check(s) suppressed

   procedure Insert_List_Before_And_Analyze
     (N : Node_Id; L : List_Id; Suppress : Check_Id)
   is
   begin
      if Suppress = All_Checks then
         declare
            Svg : constant Suppress_Array := Scope_Suppress;

         begin
            Scope_Suppress := (others => True);
            Insert_List_Before_And_Analyze (N, L);
            Scope_Suppress := Svg;
         end;

      else
         declare
            Svg : constant Boolean := Scope_Suppress (Suppress);

         begin
            Scope_Suppress (Suppress) := True;
            Insert_List_Before_And_Analyze (N, L);
            Scope_Suppress (Suppress) := Svg;
         end;
      end if;
   end Insert_List_Before_And_Analyze;

   -------------------------
   -- Is_Check_Suppressed --
   -------------------------

   function Is_Check_Suppressed (E : Entity_Id; C : Check_Id) return Boolean is
   begin
      --  First search the local entity suppress table, we search this in
      --  reverse order so that we get the innermost entry that applies to
      --  this case if there are nested entries.

      for J in
        reverse Local_Entity_Suppress.First .. Local_Entity_Suppress.Last
      loop
         declare
            R : Entity_Check_Suppress_Record
                  renames Local_Entity_Suppress.Table (J);

         begin
            if (R.Entity = Empty or else R.Entity = E)
              and then (R.Check = All_Checks or else R.Check = C)
            then
               return R.Suppress;
            end if;
         end;
      end loop;

      --  Now search the global entity suppress table for a matching entry
      --  We also search this in reverse order so that if there are multiple
      --  pragmas for the same entity, the last one applies (not clear what
      --  or whether the RM specifies this handling, but it seems reasonable).

      for J in
        reverse Global_Entity_Suppress.First .. Global_Entity_Suppress.Last
      loop
         declare
            R : Entity_Check_Suppress_Record
                  renames Global_Entity_Suppress.Table (J);

         begin
            if R.Entity = E
              and then (R.Check = All_Checks or else R.Check = C)
            then
               return R.Suppress;
            end if;
         end;
      end loop;

      --  If we did not find a matching entry, then use the normal scope
      --  suppress value after all (actually this will be the global setting
      --  since it clearly was not overridden at any point)

      return Scope_Suppress (C);
   end Is_Check_Suppressed;

   ----------
   -- Lock --
   ----------

   procedure Lock is
   begin
      Local_Entity_Suppress.Locked := True;
      Global_Entity_Suppress.Locked := True;
      Scope_Stack.Locked := True;
      Local_Entity_Suppress.Release;
      Global_Entity_Suppress.Release;
      Scope_Stack.Release;
   end Lock;

   ---------------
   -- Semantics --
   ---------------

   procedure Semantics (Comp_Unit : Node_Id) is

      --  The following locations save the corresponding global flags and
      --  variables so that they can be restored on completion. This is
      --  needed so that calls to Rtsfind start with the proper default
      --  values for these variables, and also that such calls do not
      --  disturb the settings for units being analyzed at a higher level.

      S_Full_Analysis    : constant Boolean          := Full_Analysis;
      S_In_Default_Expr  : constant Boolean          := In_Default_Expression;
      S_Inside_A_Generic : constant Boolean          := Inside_A_Generic;
      S_New_Nodes_OK     : constant Int              := New_Nodes_OK;
      S_Outer_Gen_Scope  : constant Entity_Id        := Outer_Generic_Scope;
      S_Sem_Unit         : constant Unit_Number_Type := Current_Sem_Unit;

      Generic_Main       : constant Boolean :=
                             Nkind (Unit (Cunit (Main_Unit)))
                               in N_Generic_Declaration;

      --  If the main unit is generic, every compiled unit, including its
      --  context, is compiled with expansion disabled.

      Save_Config_Switches : Config_Switches_Type;
      --  Variable used to save values of config switches while we analyze
      --  the new unit, to be restored on exit for proper recursive behavior.

      procedure Do_Analyze;
      --  Procedure to analyze the compilation unit. This is called more
      --  than once when the high level optimizer is activated.

      ----------------
      -- Do_Analyze --
      ----------------

      procedure Do_Analyze is
      begin
         Save_Scope_Stack;
         New_Scope (Standard_Standard);
         Scope_Suppress := Suppress_Options;
         Scope_Stack.Table
           (Scope_Stack.Last).Component_Alignment_Default := Calign_Default;
         Scope_Stack.Table
           (Scope_Stack.Last).Is_Active_Stack_Base := True;
         Outer_Generic_Scope := Empty;

         --  Now analyze the top level compilation unit node

         Analyze (Comp_Unit);

         --  Check for scope mismatch on exit from compilation

         pragma Assert (Current_Scope = Standard_Standard
                          or else Comp_Unit = Cunit (Main_Unit));

         --  Then pop entry for Standard, and pop implicit types

         Pop_Scope;
         Restore_Scope_Stack;
      end Do_Analyze;

   --  Start of processing for Semantics

   begin
      Compiler_State        := Analyzing;
      Current_Sem_Unit      := Get_Cunit_Unit_Number (Comp_Unit);

--        if Generic_Main then
--           Expander_Mode_Save_And_Set (False);
--        else
--           Expander_Mode_Save_And_Set
--             (Operating_Mode = Generate_Code or Debug_Flag_X);
--        end if;

      Full_Analysis         := True;
      Inside_A_Generic      := False;
      In_Default_Expression := False;

      Set_Comes_From_Source_Default (False);
      Save_Opt_Config_Switches (Save_Config_Switches);
      Set_Opt_Config_Switches
        (Is_Internal_File_Name (Unit_File_Name (Current_Sem_Unit)));

      --  Only do analysis of unit that has not already been analyzed

      if not Analyzed (Comp_Unit) then
         Initialize_Version (Current_Sem_Unit);
         Do_Analyze;
      end if;

      --  Save indication of dynamic elaboration checks for ALI file

      Set_Dynamic_Elab (Current_Sem_Unit, Dynamic_Elaboration_Checks);

      --  Restore settings of saved switches to entry values

      Current_Sem_Unit       := S_Sem_Unit;
      Full_Analysis          := S_Full_Analysis;
      In_Default_Expression  := S_In_Default_Expr;
      Inside_A_Generic       := S_Inside_A_Generic;
      New_Nodes_OK           := S_New_Nodes_OK;
      Outer_Generic_Scope    := S_Outer_Gen_Scope;

      Restore_Opt_Config_Switches (Save_Config_Switches);

   end Semantics;
end Sem;
