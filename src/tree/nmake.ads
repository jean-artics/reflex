------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                                N M A K E                                 --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--          Copyright (C) 1992-2007, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT; see file COPYING3.  If not, go to --
-- http://www.gnu.org/licenses for a complete copy of the license.          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Namet;  use Namet;
with Nlists; use Nlists;
with Types;  use Types;
with Uintp;  use Uintp;
with Urealp; use Urealp;

package Nmake is

--  This package contains a set of routines used to construct tree nodes
--  using a functional style. There is one routine for each node type defined
--  in Sinfo with the general interface:

--    function Make_xxx (Sloc : Source_Ptr,
--                       Field_Name_1 : Field_Name_1_Type [:= default]
--                       Field_Name_2 : Field_Name_2_Type [:= default]
--                       ...)
--    return Node_Id

--  Only syntactic fields are included (i.e. fields marked as "-Sem" or "-Lib"
--  in the Sinfo spec are excluded). In addition, the following four syntactic
--  fields are excluded:

--    Prev_Ids
--    More_Ids
--    Comes_From_Source
--    Paren_Count

--  since they are very rarely set in expanded code. If they need to be set,
--  to other than the default values (False, False, False, zero), then the
--  appropriate Set_xxx procedures must be used on the returned value.

--  Default values are provided only for flag fields (where the default is
--  False), and for optional fields. An optional field is one where the
--  comment line describing the field contains the string "(set to xxx if".
--  For such fields, a default value of xxx is provided."

--  Warning: since calls to Make_xxx routines are normal function calls, the
--  arguments can be evaluated in any order. This means that at most one such
--  argument can have side effects (e.g. be a call to a parse routine).

   function Make_Unused_At_Start (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Unused_At_Start);

   function Make_Unused_At_End (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Unused_At_End);

   function Make_Identifier (Sloc : Source_Ptr;
      Chars                        : Name_Id)
      return Node_Id;
   pragma Inline (Make_Identifier);

   function Make_Integer_Literal (Sloc : Source_Ptr;
      Intval                       : Uint)
      return Node_Id;
   pragma Inline (Make_Integer_Literal);

   function Make_Real_Literal (Sloc : Source_Ptr;
      Realval                      : Ureal)
      return Node_Id;
   pragma Inline (Make_Real_Literal);

   function Make_Character_Literal (Sloc : Source_Ptr;
      Chars                        : Name_Id;
      Char_Literal_Value           : Char_Code)
      return Node_Id;
   pragma Inline (Make_Character_Literal);

   function Make_String_Literal (Sloc : Source_Ptr;
      Strval                       : String_Id)
      return Node_Id;
   pragma Inline (Make_String_Literal);

   function Make_Pragma (Sloc : Source_Ptr;
      Chars                        : Name_Id;
      Pragma_Argument_Associations : List_Id := No_List;
      Debug_Statement              : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Pragma);

   function Make_Pragma_Argument_Association (Sloc : Source_Ptr;
      Chars                        : Name_Id := No_Name;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Pragma_Argument_Association);

   function Make_Defining_Identifier (Sloc : Source_Ptr;
      Chars                        : Name_Id)
      return Node_Id;
   pragma Inline (Make_Defining_Identifier);

   function Make_Full_Type_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Type_Definition              : Node_Id)
      return Node_Id;
   pragma Inline (Make_Full_Type_Declaration);

   function Make_Subtype_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Subtype_Indication           : Node_Id)
      return Node_Id;
   pragma Inline (Make_Subtype_Declaration);

   function Make_Subtype_Indication (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id;
      Constraint                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Subtype_Indication);

   function Make_Object_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Aliased_Present              : Boolean := False;
      Constant_Present             : Boolean := False;
      Object_Definition            : Node_Id;
      Expression                   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Object_Declaration);

   function Make_Number_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Number_Declaration);

   function Make_Derived_Type_Definition (Sloc : Source_Ptr;
      Abstract_Present             : Boolean := False;
      Subtype_Indication           : Node_Id;
      Record_Extension_Part        : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Derived_Type_Definition);

   function Make_Range_Constraint (Sloc : Source_Ptr;
      Range_Expression             : Node_Id)
      return Node_Id;
   pragma Inline (Make_Range_Constraint);

   function Make_Range (Sloc : Source_Ptr;
      Low_Bound                    : Node_Id;
      High_Bound                   : Node_Id;
      Includes_Infinities          : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Range);

   function Make_Aspect_Specification (Sloc : Source_Ptr;
      Identifier                   : Node_Id;
      Expression                   : Node_Id := Empty;
      Class_Present                : Boolean := False;
      Split_PPC                    : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Aspect_Specification);

   function Make_Enumeration_Type_Definition (Sloc : Source_Ptr;
      Literals                     : List_Id;
      End_Label                    : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Enumeration_Type_Definition);

   function Make_Defining_Character_Literal (Sloc : Source_Ptr;
      Chars                        : Name_Id)
      return Node_Id;
   pragma Inline (Make_Defining_Character_Literal);

   function Make_Signed_Integer_Type_Definition (Sloc : Source_Ptr;
      Low_Bound                    : Node_Id;
      High_Bound                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Signed_Integer_Type_Definition);

   function Make_Modular_Type_Definition (Sloc : Source_Ptr;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Modular_Type_Definition);

   function Make_Floating_Point_Definition (Sloc : Source_Ptr;
      Digits_Expression            : Node_Id;
      Real_Range_Specification     : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Floating_Point_Definition);

   function Make_Real_Range_Specification (Sloc : Source_Ptr;
      Low_Bound                    : Node_Id;
      High_Bound                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Real_Range_Specification);

   function Make_Digits_Constraint (Sloc : Source_Ptr;
      Digits_Expression            : Node_Id;
      Range_Constraint             : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Digits_Constraint);

   function Make_Unconstrained_Array_Definition (Sloc : Source_Ptr;
      Subtype_Marks                : List_Id;
      Component_Definition         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Unconstrained_Array_Definition);

   function Make_Constrained_Array_Definition (Sloc : Source_Ptr;
      Discrete_Subtype_Definitions : List_Id;
      Component_Definition         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Constrained_Array_Definition);

   function Make_Component_Definition (Sloc : Source_Ptr;
      Aliased_Present              : Boolean := False;
      Subtype_Indication           : Node_Id;
      Access_Definition            : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Component_Definition);

   function Make_Index_Or_Discriminant_Constraint (Sloc : Source_Ptr;
      Constraints                  : List_Id)
      return Node_Id;
   pragma Inline (Make_Index_Or_Discriminant_Constraint);

   function Make_Discriminant_Association (Sloc : Source_Ptr;
      Selector_Names               : List_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Discriminant_Association);

   function Make_Record_Definition (Sloc : Source_Ptr;
      End_Label                    : Node_Id := Empty;
      Abstract_Present             : Boolean := False;
      Tagged_Present               : Boolean := False;
      Component_List               : Node_Id;
      Null_Present                 : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Record_Definition);

   function Make_Component_List (Sloc : Source_Ptr;
      Component_Items              : List_Id;
      Null_Present                 : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Component_List);

   function Make_Component_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Component_Definition         : Node_Id;
      Expression                   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Component_Declaration);

   function Make_Others_Choice (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Others_Choice);

   function Make_Access_To_Object_Definition (Sloc : Source_Ptr;
      All_Present                  : Boolean := False;
      Subtype_Indication           : Node_Id;
      Constant_Present             : Boolean := False;
      Access_To_Subprogram_Definition : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Access_To_Object_Definition);

   function Make_Access_Function_Definition (Sloc : Source_Ptr;
      Parameter_Specifications     : List_Id := No_List;
      Subtype_Mark                 : Node_Id)
      return Node_Id;
   pragma Inline (Make_Access_Function_Definition);

   function Make_Access_Procedure_Definition (Sloc : Source_Ptr;
      Parameter_Specifications     : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Access_Procedure_Definition);

   function Make_Access_Definition (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id)
      return Node_Id;
   pragma Inline (Make_Access_Definition);

   function Make_Incomplete_Type_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id)
      return Node_Id;
   pragma Inline (Make_Incomplete_Type_Declaration);

   function Make_Explicit_Dereference (Sloc : Source_Ptr;
      Prefix                       : Node_Id)
      return Node_Id;
   pragma Inline (Make_Explicit_Dereference);

   function Make_Indexed_Component (Sloc : Source_Ptr;
      Prefix                       : Node_Id;
      Expressions                  : List_Id)
      return Node_Id;
   pragma Inline (Make_Indexed_Component);

   function Make_Slice (Sloc : Source_Ptr;
      Prefix                       : Node_Id;
      Discrete_Range               : Node_Id)
      return Node_Id;
   pragma Inline (Make_Slice);

   function Make_Selected_Component (Sloc : Source_Ptr;
      Prefix                       : Node_Id;
      Selector_Name                : Node_Id)
      return Node_Id;
   pragma Inline (Make_Selected_Component);

   function Make_Attribute_Reference (Sloc : Source_Ptr;
      Prefix                       : Node_Id;
      Attribute_Name               : Name_Id;
      Expressions                  : List_Id := No_List;
      Must_Be_Byte_Aligned         : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Attribute_Reference);

   function Make_Aggregate (Sloc : Source_Ptr;
      Expressions                  : List_Id := No_List;
      Component_Associations       : List_Id := No_List;
      Null_Record_Present          : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Aggregate);

   function Make_Component_Association (Sloc : Source_Ptr;
      Choices                      : List_Id;
      Expression                   : Node_Id;
      Box_Present                  : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Component_Association);

   function Make_Extension_Aggregate (Sloc : Source_Ptr;
      Ancestor_Part                : Node_Id;
      Expressions                  : List_Id := No_List;
      Component_Associations       : List_Id := No_List;
      Null_Record_Present          : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Extension_Aggregate);

   function Make_Null (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Null);

   function Make_And_Then (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_And_Then);

   function Make_Or_Else (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Or_Else);

   function Make_In (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_In);

   function Make_Not_In (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Not_In);

   function Make_Op_And (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_And);

   function Make_Op_Or (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Or);

   function Make_Op_Xor (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Xor);

   function Make_Op_Eq (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Eq);

   function Make_Op_Ne (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Ne);

   function Make_Op_Lt (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Lt);

   function Make_Op_Le (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Le);

   function Make_Op_Gt (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Gt);

   function Make_Op_Ge (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Ge);

   function Make_Op_Add (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Add);

   function Make_Op_Subtract (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Subtract);

   function Make_Op_Concat (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Concat);

   function Make_Op_Multiply (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Multiply);

   function Make_Op_Divide (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Divide);

   function Make_Op_Mod (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Mod);

   function Make_Op_Rem (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Rem);

   function Make_Op_Expon (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Expon);

   function Make_Op_Plus (Sloc : Source_Ptr;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Plus);

   function Make_Op_Minus (Sloc : Source_Ptr;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Minus);

   function Make_Op_Abs (Sloc : Source_Ptr;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Abs);

   function Make_Op_Not (Sloc : Source_Ptr;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Not);

   function Make_Type_Conversion (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Type_Conversion);

   function Make_Qualified_Expression (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Qualified_Expression);

   function Make_Allocator (Sloc : Source_Ptr;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Allocator);

   function Make_Null_Statement (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Null_Statement);

   function Make_Label (Sloc : Source_Ptr;
      Identifier                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Label);

   function Make_Assignment_Statement (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Assignment_Statement);

   function Make_If_Statement (Sloc : Source_Ptr;
      Condition                    : Node_Id;
      Then_Statements              : List_Id;
      Elsif_Parts                  : List_Id := No_List;
      Else_Statements              : List_Id := No_List;
      End_Span                     : Uint := No_Uint)
      return Node_Id;
   pragma Inline (Make_If_Statement);

   function Make_Elsif_Part (Sloc : Source_Ptr;
      Condition                    : Node_Id;
      Then_Statements              : List_Id)
      return Node_Id;
   pragma Inline (Make_Elsif_Part);

   function Make_Case_Statement (Sloc : Source_Ptr;
      Expression                   : Node_Id;
      Alternatives                 : List_Id;
      End_Span                     : Uint := No_Uint)
      return Node_Id;
   pragma Inline (Make_Case_Statement);

   function Make_Case_Statement_Alternative (Sloc : Source_Ptr;
      Discrete_Choices             : List_Id;
      Statements                   : List_Id)
      return Node_Id;
   pragma Inline (Make_Case_Statement_Alternative);

   function Make_Loop_Statement (Sloc : Source_Ptr;
      Identifier                   : Node_Id := Empty;
      Iteration_Scheme             : Node_Id := Empty;
      Statements                   : List_Id;
      End_Label                    : Node_Id;
      Has_Created_Identifier       : Boolean := False;
      Is_Null_Loop                 : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Loop_Statement);

   function Make_Iteration_Scheme (Sloc : Source_Ptr;
      Condition                    : Node_Id := Empty;
      Loop_Parameter_Specification : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Iteration_Scheme);

   function Make_Loop_Parameter_Specification (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Reverse_Present              : Boolean := False;
      Discrete_Subtype_Definition  : Node_Id)
      return Node_Id;
   pragma Inline (Make_Loop_Parameter_Specification);

   function Make_Block_Statement (Sloc : Source_Ptr;
      Identifier                   : Node_Id := Empty;
      Declarations                 : List_Id := No_List;
      Handled_Statement_Sequence   : Node_Id;
      Has_Created_Identifier       : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Block_Statement);

   function Make_Exit_Statement (Sloc : Source_Ptr;
      Name                         : Node_Id := Empty;
      Condition                    : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Exit_Statement);

   function Make_Goto_Statement (Sloc : Source_Ptr;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Goto_Statement);

   function Make_Subprogram_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id)
      return Node_Id;
   pragma Inline (Make_Subprogram_Declaration);

   function Make_Abstract_Subprogram_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id)
      return Node_Id;
   pragma Inline (Make_Abstract_Subprogram_Declaration);

   function Make_Function_Specification (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Parameter_Specifications     : List_Id := No_List;
      Subtype_Mark                 : Node_Id)
      return Node_Id;
   pragma Inline (Make_Function_Specification);

   function Make_Procedure_Specification (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Parameter_Specifications     : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Procedure_Specification);

   function Make_Designator (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Identifier                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Designator);

   function Make_Defining_Program_Unit_Name (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Defining_Identifier          : Node_Id)
      return Node_Id;
   pragma Inline (Make_Defining_Program_Unit_Name);

   function Make_Parameter_Specification (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      In_Present                   : Boolean := False;
      Out_Present                  : Boolean := False;
      Parameter_Type               : Node_Id;
      Expression                   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Parameter_Specification);

   function Make_Subprogram_Body (Sloc : Source_Ptr;
      Specification                : Node_Id;
      Declarations                 : List_Id;
      Handled_Statement_Sequence   : Node_Id;
      Bad_Is_Detected              : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Subprogram_Body);

   function Make_Procedure_Call_Statement (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Parameter_Associations       : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Procedure_Call_Statement);

   function Make_Function_Call (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Parameter_Associations       : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Function_Call);

   function Make_Parameter_Association (Sloc : Source_Ptr;
      Selector_Name                : Node_Id;
      Explicit_Actual_Parameter    : Node_Id)
      return Node_Id;
   pragma Inline (Make_Parameter_Association);

   function Make_Return_Statement (Sloc : Source_Ptr;
      Expression                   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Return_Statement);

   function Make_Package_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id)
      return Node_Id;
   pragma Inline (Make_Package_Declaration);

   function Make_Package_Specification (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Visible_Declarations         : List_Id;
      Private_Declarations         : List_Id := No_List;
      End_Label                    : Node_Id)
      return Node_Id;
   pragma Inline (Make_Package_Specification);

   function Make_Package_Body (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Declarations                 : List_Id;
      Handled_Statement_Sequence   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Package_Body);

   function Make_Private_Type_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Abstract_Present             : Boolean := False;
      Tagged_Present               : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Private_Type_Declaration);

   function Make_Private_Extension_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Abstract_Present             : Boolean := False;
      Subtype_Indication           : Node_Id)
      return Node_Id;
   pragma Inline (Make_Private_Extension_Declaration);

   function Make_Use_Package_Clause (Sloc : Source_Ptr;
      Names                        : List_Id)
      return Node_Id;
   pragma Inline (Make_Use_Package_Clause);

   function Make_Use_Type_Clause (Sloc : Source_Ptr;
      Subtype_Marks                : List_Id)
      return Node_Id;
   pragma Inline (Make_Use_Type_Clause);

   function Make_Object_Renaming_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Subtype_Mark                 : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Object_Renaming_Declaration);

   function Make_Package_Renaming_Declaration (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Package_Renaming_Declaration);

   function Make_Subprogram_Renaming_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Subprogram_Renaming_Declaration);

   function Make_Generic_Package_Renaming_Declaration (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Package_Renaming_Declaration);

   function Make_Generic_Procedure_Renaming_Declaration (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Procedure_Renaming_Declaration);

   function Make_Generic_Function_Renaming_Declaration (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Function_Renaming_Declaration);

   function Make_Compilation_Unit (Sloc : Source_Ptr;
      Context_Items                : List_Id;
      Private_Present              : Boolean := False;
      Unit                         : Node_Id;
      Aux_Decls_Node               : Node_Id)
      return Node_Id;
   pragma Inline (Make_Compilation_Unit);

   function Make_Compilation_Unit_Aux (Sloc : Source_Ptr;
      Declarations                 : List_Id := No_List;
      Actions                      : List_Id := No_List;
      Pragmas_After                : List_Id := No_List;
      Config_Pragmas               : List_Id := Empty_List)
      return Node_Id;
   pragma Inline (Make_Compilation_Unit_Aux);

   function Make_With_Clause (Sloc : Source_Ptr;
      Name                         : Node_Id;
      First_Name                   : Boolean := True;
      Last_Name                    : Boolean := True)
      return Node_Id;
   pragma Inline (Make_With_Clause);

   function Make_With_Type_Clause (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Tagged_Present               : Boolean := False)
      return Node_Id;
   pragma Inline (Make_With_Type_Clause);

   function Make_Handled_Sequence_Of_Statements (Sloc : Source_Ptr;
      Statements                   : List_Id;
      End_Label                    : Node_Id := Empty;
      At_End_Proc                  : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Handled_Sequence_Of_Statements);

   function Make_Generic_Subprogram_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id;
      Generic_Formal_Declarations  : List_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Subprogram_Declaration);

   function Make_Generic_Package_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id;
      Generic_Formal_Declarations  : List_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Package_Declaration);

   function Make_Package_Instantiation (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id;
      Generic_Associations         : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Package_Instantiation);

   function Make_Procedure_Instantiation (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id;
      Generic_Associations         : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Procedure_Instantiation);

   function Make_Function_Instantiation (Sloc : Source_Ptr;
      Defining_Unit_Name           : Node_Id;
      Name                         : Node_Id;
      Generic_Associations         : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Function_Instantiation);

   function Make_Generic_Association (Sloc : Source_Ptr;
      Selector_Name                : Node_Id := Empty;
      Explicit_Generic_Actual_Parameter : Node_Id)
      return Node_Id;
   pragma Inline (Make_Generic_Association);

   function Make_Formal_Object_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      In_Present                   : Boolean := False;
      Out_Present                  : Boolean := False;
      Subtype_Mark                 : Node_Id;
      Expression                   : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Formal_Object_Declaration);

   function Make_Formal_Type_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Formal_Type_Definition       : Node_Id)
      return Node_Id;
   pragma Inline (Make_Formal_Type_Declaration);

   function Make_Formal_Private_Type_Definition (Sloc : Source_Ptr;
      Abstract_Present             : Boolean := False;
      Tagged_Present               : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Formal_Private_Type_Definition);

   function Make_Formal_Derived_Type_Definition (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id;
      Private_Present              : Boolean := False;
      Abstract_Present             : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Formal_Derived_Type_Definition);

   function Make_Formal_Discrete_Type_Definition (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Formal_Discrete_Type_Definition);

   function Make_Formal_Signed_Integer_Type_Definition (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Formal_Signed_Integer_Type_Definition);

   function Make_Formal_Modular_Type_Definition (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Formal_Modular_Type_Definition);

   function Make_Formal_Floating_Point_Definition (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Formal_Floating_Point_Definition);

   function Make_Formal_Subprogram_Declaration (Sloc : Source_Ptr;
      Specification                : Node_Id;
      Default_Name                 : Node_Id := Empty;
      Box_Present                  : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Formal_Subprogram_Declaration);

   function Make_Formal_Package_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Name                         : Node_Id;
      Generic_Associations         : List_Id := No_List;
      Box_Present                  : Boolean := False)
      return Node_Id;
   pragma Inline (Make_Formal_Package_Declaration);

   function Make_Attribute_Definition_Clause (Sloc : Source_Ptr;
      Name                         : Node_Id;
      Chars                        : Name_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Attribute_Definition_Clause);

   function Make_Enumeration_Representation_Clause (Sloc : Source_Ptr;
      Identifier                   : Node_Id;
      Array_Aggregate              : Node_Id)
      return Node_Id;
   pragma Inline (Make_Enumeration_Representation_Clause);

   function Make_Record_Representation_Clause (Sloc : Source_Ptr;
      Identifier                   : Node_Id;
      Mod_Clause                   : Node_Id := Empty;
      Component_Clauses            : List_Id)
      return Node_Id;
   pragma Inline (Make_Record_Representation_Clause);

   function Make_Component_Clause (Sloc : Source_Ptr;
      Component_Name               : Node_Id;
      Position                     : Node_Id;
      First_Bit                    : Node_Id;
      Last_Bit                     : Node_Id)
      return Node_Id;
   pragma Inline (Make_Component_Clause);

   function Make_Code_Statement (Sloc : Source_Ptr;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Code_Statement);

   function Make_Op_Rotate_Left (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Rotate_Left);

   function Make_Op_Rotate_Right (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Rotate_Right);

   function Make_Op_Shift_Left (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Shift_Left);

   function Make_Op_Shift_Right_Arithmetic (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Shift_Right_Arithmetic);

   function Make_Op_Shift_Right (Sloc : Source_Ptr;
      Left_Opnd                    : Node_Id;
      Right_Opnd                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Op_Shift_Right);

   function Make_At_Clause (Sloc : Source_Ptr;
      Identifier                   : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_At_Clause);

   function Make_Mod_Clause (Sloc : Source_Ptr;
      Expression                   : Node_Id;
      Pragmas_Before               : List_Id)
      return Node_Id;
   pragma Inline (Make_Mod_Clause);

   function Make_Reactive_State (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id;
      Corresponding_Node           : Node_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_State);

   function Make_Reactive_Wait_Statement (Sloc : Source_Ptr;
      State_Identifier             : Node_Id;
      Condition                    : Node_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_Wait_Statement);

   function Make_Reactive_Pause_Statement (Sloc : Source_Ptr;
      State_Identifier             : Node_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_Pause_Statement);

   function Make_Reactive_Fork_Statement (Sloc : Source_Ptr;
      Condition                    : Node_Id;
      Alternatives                 : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Reactive_Fork_Statement);

   function Make_Reactive_Fork_Alternative (Sloc : Source_Ptr;
      Statements                   : List_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_Fork_Alternative);

   function Make_Reactive_Select_Statement (Sloc : Source_Ptr;
      State_Identifier             : Node_Id;
      Alternatives                 : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Reactive_Select_Statement);

   function Make_Reactive_Select_Alternative (Sloc : Source_Ptr;
      Condition                    : Node_Id;
      Statements                   : List_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_Select_Alternative);

   function Make_Reactive_Abort_Statement (Sloc : Source_Ptr;
      Condition                    : Node_Id;
      Statements                   : List_Id;
      Abort_Handler                : Node_Id := Empty)
      return Node_Id;
   pragma Inline (Make_Reactive_Abort_Statement);

   function Make_Reactive_Abort_Handler (Sloc : Source_Ptr;
      Statements                   : List_Id)
      return Node_Id;
   pragma Inline (Make_Reactive_Abort_Handler);

   function Make_Conditional_Expression (Sloc : Source_Ptr;
      Expressions                  : List_Id)
      return Node_Id;
   pragma Inline (Make_Conditional_Expression);

   function Make_Expanded_Name (Sloc : Source_Ptr;
      Chars                        : Name_Id;
      Prefix                       : Node_Id;
      Selector_Name                : Node_Id)
      return Node_Id;
   pragma Inline (Make_Expanded_Name);

   function Make_Free_Statement (Sloc : Source_Ptr;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Free_Statement);

   function Make_Freeze_Entity (Sloc : Source_Ptr;
      Actions                      : List_Id := No_List)
      return Node_Id;
   pragma Inline (Make_Freeze_Entity);

   function Make_Implicit_Label_Declaration (Sloc : Source_Ptr;
      Defining_Identifier          : Node_Id)
      return Node_Id;
   pragma Inline (Make_Implicit_Label_Declaration);

   function Make_Reference (Sloc : Source_Ptr;
      Prefix                       : Node_Id)
      return Node_Id;
   pragma Inline (Make_Reference);

   function Make_Subprogram_Info (Sloc : Source_Ptr;
      Identifier                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Subprogram_Info);

   function Make_Unchecked_Expression (Sloc : Source_Ptr;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Unchecked_Expression);

   function Make_Unchecked_Type_Conversion (Sloc : Source_Ptr;
      Subtype_Mark                 : Node_Id;
      Expression                   : Node_Id)
      return Node_Id;
   pragma Inline (Make_Unchecked_Type_Conversion);

   function Make_Validate_Unchecked_Conversion (Sloc : Source_Ptr)
      return Node_Id;
   pragma Inline (Make_Validate_Unchecked_Conversion);

end Nmake;
