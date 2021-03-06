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


--  This package contains the declaration of the string used by the Tree_Print
--  package. It must be updated whenever the arrangements of the field names
--  in package Sinfo is changed. The utility program XTREEPRS is used to
--  do this update correctly using the template treeprs.adt as input.

with Sinfo; use Sinfo;

package Treeprs is

   --------------------------------
   -- String Data for Node Print --
   --------------------------------

   --  String data for print out. The Pchars array is a long string with the
   --  the entry for each node type consisting of a single blank, followed by
   --  a series of entries, one for each Op or Flag field used for the node.
   --  Each entry has a single character which identifies the field, followed
   --  by the synonym name. The starting location for a given node type is
   --  found from the corresponding entry in the Pchars_Pos_Array.

   --  The following characters identify the field. These are characters
   --  which  could never occur in a field name, so they also mark the
   --  end of the previous name.

   subtype Fchar is Character range '#' .. '9';

   F_Field1     : constant Fchar := '#'; -- Character'Val (16#23#)
   F_Field2     : constant Fchar := '$'; -- Character'Val (16#24#)
   F_Field3     : constant Fchar := '%'; -- Character'Val (16#25#)
   F_Field4     : constant Fchar := '&'; -- Character'Val (16#26#)
   F_Field5     : constant Fchar := '''; -- Character'Val (16#27#)
   F_Flag1      : constant Fchar := '('; -- Character'Val (16#28#)
   F_Flag2      : constant Fchar := ')'; -- Character'Val (16#29#)
   F_Flag3      : constant Fchar := '*'; -- Character'Val (16#2A#)
   F_Flag4      : constant Fchar := '+'; -- Character'Val (16#2B#)
   F_Flag5      : constant Fchar := ','; -- Character'Val (16#2C#)
   F_Flag6      : constant Fchar := '-'; -- Character'Val (16#2D#)
   F_Flag7      : constant Fchar := '.'; -- Character'Val (16#2E#)
   F_Flag8      : constant Fchar := '/'; -- Character'Val (16#2F#)
   F_Flag9      : constant Fchar := '0'; -- Character'Val (16#30#)
   F_Flag10     : constant Fchar := '1'; -- Character'Val (16#31#)
   F_Flag11     : constant Fchar := '2'; -- Character'Val (16#32#)
   F_Flag12     : constant Fchar := '3'; -- Character'Val (16#33#)
   F_Flag13     : constant Fchar := '4'; -- Character'Val (16#34#)
   F_Flag14     : constant Fchar := '5'; -- Character'Val (16#35#)
   F_Flag15     : constant Fchar := '6'; -- Character'Val (16#36#)
   F_Flag16     : constant Fchar := '7'; -- Character'Val (16#37#)
   F_Flag17     : constant Fchar := '8'; -- Character'Val (16#38#)
   F_Flag18     : constant Fchar := '9'; -- Character'Val (16#39#)

   --  Note this table does not include entity field and flags whose access
   --  functions are in Einfo (these are handled by the Print_Entity_Info
   --  procedure in Treepr, which uses the routines in Einfo to get the
   --  proper symbolic information). In addition, the following fields are
   --  handled by Treepr, and do not appear in the Pchars array:

   --    Analyzed
   --    Cannot_Be_Constant
   --    Chars
   --    Comes_From_Source
   --    Error_Posted
   --    Etype
   --    Is_Controlling_Actual
   --    Is_Overloaded
   --    Is_Static_Expression
   --    Left_Opnd
   --    Must_Check_Expr
   --    Must_Not_Freeze
   --    No_Overflow_Expr
   --    Paren_Count
   --    Raises_Constraint_Error
   --    Right_Opnd

   Pchars : constant String :=
      --  Unused_At_Start
      "" &
      --  At_Clause
      "#Identifier%Expression" &
      --  Component_Clause
      "#Component_Name$Position%First_Bit&Last_Bit" &
      --  Enumeration_Representation_Clause
      "#Identifier%Array_Aggregate&Next_Rep_Item" &
      --  Mod_Clause
      "%Expression&Pragmas_Before" &
      --  Record_Representation_Clause
      "#Identifier$Mod_Clause%Component_Clauses&Next_Rep_Item" &
      --  Attribute_Definition_Clause
      "$Name%Expression&Next_Rep_Item+From_At_Mod2Check_Address_Alignment" &
      --  Empty
      "" &
      --  Pragma
      "$Pragma_Argument_Associations%Debug_Statement&Next_Rep_Item" &
      --  Pragma_Argument_Association
      "%Expression" &
      --  Error
      "" &
      --  Defining_Character_Literal
      "$Next_Entity%Scope" &
      --  Defining_Identifier
      "$Next_Entity%Scope" &
      --  Defining_Operator_Symbol
      "$Next_Entity%Scope" &
      --  Expanded_Name
      "%Prefix$Selector_Name&Entity&Associated_Node4Redundant_Use2Has_Privat" &
         "e_View" &
      --  Identifier
      "&Entity&Associated_Node$Original_Discriminant4Redundant_Use2Has_Priva" &
         "te_View" &
      --  Operator_Symbol
      "%Strval&Entity&Associated_Node2Has_Private_View" &
      --  Character_Literal
      "$Char_Literal_Value&Entity&Associated_Node2Has_Private_View" &
      --  Op_Add
      "" &
      --  Op_Concat
      "4Is_Component_Left_Opnd5Is_Component_Right_Opnd" &
      --  Op_Expon
      "4Is_Power_Of_2_For_Shift" &
      --  Op_Subtract
      "" &
      --  Op_Divide
      "5Treat_Fixed_As_Integer4Do_Division_Check9Rounded_Result" &
      --  Op_Mod
      "5Treat_Fixed_As_Integer4Do_Division_Check" &
      --  Op_Multiply
      "5Treat_Fixed_As_Integer9Rounded_Result" &
      --  Op_Rem
      "5Treat_Fixed_As_Integer4Do_Division_Check" &
      --  Op_And
      "+Do_Length_Check" &
      --  Op_Eq
      "" &
      --  Op_Ge
      "" &
      --  Op_Gt
      "" &
      --  Op_Le
      "" &
      --  Op_Lt
      "" &
      --  Op_Ne
      "" &
      --  Op_Or
      "+Do_Length_Check" &
      --  Op_Xor
      "+Do_Length_Check" &
      --  Op_Rotate_Left
      "+Shift_Count_OK" &
      --  Op_Rotate_Right
      "+Shift_Count_OK" &
      --  Op_Shift_Left
      "+Shift_Count_OK" &
      --  Op_Shift_Right
      "+Shift_Count_OK" &
      --  Op_Shift_Right_Arithmetic
      "+Shift_Count_OK" &
      --  Op_Abs
      "" &
      --  Op_Minus
      "" &
      --  Op_Not
      "" &
      --  Op_Plus
      "" &
      --  Attribute_Reference
      "%Prefix$Attribute_Name#Expressions&Entity&Associated_Node8Do_Overflow" &
         "_Check4Redundant_Use+OK_For_Stream5Must_Be_Byte_Aligned" &
      --  And_Then
      "#Actions" &
      --  Conditional_Expression
      "#Expressions$Then_Actions%Else_Actions" &
      --  Explicit_Dereference
      "%Prefix" &
      --  Function_Call
      "$Name%Parameter_Associations&First_Named_Actual#Controlling_Argument4" &
         "Do_Tag_Check5No_Elaboration_Check8Parameter_List_Truncated9ABE_Is_" &
         "Certain" &
      --  In
      "" &
      --  Indexed_Component
      "%Prefix#Expressions" &
      --  Integer_Literal
      "$Original_Entity%Intval4Print_In_Hex" &
      --  Not_In
      "" &
      --  Null
      "" &
      --  Or_Else
      "#Actions" &
      --  Procedure_Call_Statement
      "$Name%Parameter_Associations&First_Named_Actual#Controlling_Argument4" &
         "Do_Tag_Check5No_Elaboration_Check8Parameter_List_Truncated9ABE_Is_" &
         "Certain" &
      --  Qualified_Expression
      "&Subtype_Mark%Expression" &
      --  Raise_Constraint_Error
      "#Condition%Reason" &
      --  Raise_Program_Error
      "#Condition%Reason" &
      --  Raise_Storage_Error
      "#Condition%Reason" &
      --  Aggregate
      "#Expressions$Component_Associations8Null_Record_Present%Aggregate_Bou" &
         "nds&Associated_Node+Static_Processing_OK9Compile_Time_Known_Aggreg" &
         "ate2Expansion_Delayed" &
      --  Allocator
      "%Expression#Storage_Pool&Procedure_To_Call4No_Initialization8Do_Stora" &
         "ge_Check" &
      --  Extension_Aggregate
      "%Ancestor_Part&Associated_Node#Expressions$Component_Associations8Nul" &
         "l_Record_Present2Expansion_Delayed" &
      --  Range
      "#Low_Bound$High_Bound2Includes_Infinities" &
      --  Real_Literal
      "$Original_Entity%Realval&Corresponding_Integer_Value2Is_Machine_Numbe" &
         "r" &
      --  Reference
      "%Prefix" &
      --  Selected_Component
      "%Prefix$Selector_Name&Associated_Node4Do_Discriminant_Check2Is_In_Dis" &
         "criminant_Check" &
      --  Slice
      "%Prefix&Discrete_Range" &
      --  String_Literal
      "%Strval2Has_Wide_Character" &
      --  Subprogram_Info
      "#Identifier" &
      --  Type_Conversion
      "&Subtype_Mark%Expression4Do_Tag_Check+Do_Length_Check8Do_Overflow_Che" &
         "ck2Float_Truncate9Rounded_Result5Conversion_OK" &
      --  Unchecked_Expression
      "%Expression" &
      --  Unchecked_Type_Conversion
      "&Subtype_Mark%Expression2Kill_Range_Check8No_Truncation" &
      --  Subtype_Indication
      "&Subtype_Mark%Constraint/Must_Not_Freeze" &
      --  Component_Declaration
      "#Defining_Identifier&Component_Definition%Expression,More_Ids-Prev_Id" &
         "s" &
      --  Entry_Declaration
      "#Defining_Identifier&Discrete_Subtype_Definition%Parameter_Specificat" &
         "ions'Corresponding_Body" &
      --  Formal_Object_Declaration
      "#Defining_Identifier6In_Present8Out_Present&Subtype_Mark%Expression,M" &
         "ore_Ids-Prev_Ids" &
      --  Formal_Type_Declaration
      "#Defining_Identifier%Formal_Type_Definition&Discriminant_Specificatio" &
         "ns4Unknown_Discriminants_Present" &
      --  Full_Type_Declaration
      "#Defining_Identifier&Discriminant_Specifications%Type_Definition2Disc" &
         "r_Check_Funcs_Built" &
      --  Incomplete_Type_Declaration
      "#Defining_Identifier&Discriminant_Specifications4Unknown_Discriminant" &
         "s_Present" &
      --  Loop_Parameter_Specification
      "#Defining_Identifier6Reverse_Present&Discrete_Subtype_Definition" &
      --  Object_Declaration
      "#Defining_Identifier+Aliased_Present8Constant_Present&Object_Definiti" &
         "on%Expression$Handler_List_Entry'Corresponding_Generic_Association" &
         ",More_Ids-Prev_Ids4No_Initialization6Assignment_OK2Exception_Junk5" &
         "Delay_Finalize_Attach7Is_Subprogram_Descriptor" &
      --  Protected_Type_Declaration
      "#Defining_Identifier&Discriminant_Specifications%Protected_Definition" &
         "'Corresponding_Body" &
      --  Private_Extension_Declaration
      "#Defining_Identifier&Discriminant_Specifications4Unknown_Discriminant" &
         "s_Present+Abstract_Present'Subtype_Indication" &
      --  Private_Type_Declaration
      "#Defining_Identifier&Discriminant_Specifications4Unknown_Discriminant" &
         "s_Present+Abstract_Present6Tagged_Present8Limited_Present" &
      --  Subtype_Declaration
      "#Defining_Identifier'Subtype_Indication&Generic_Parent_Type2Exception" &
         "_Junk" &
      --  Function_Specification
      "#Defining_Unit_Name$Elaboration_Boolean%Parameter_Specifications&Subt" &
         "ype_Mark'Generic_Parent" &
      --  Procedure_Specification
      "#Defining_Unit_Name$Elaboration_Boolean%Parameter_Specifications'Gene" &
         "ric_Parent" &
      --  Entry_Index_Specification
      "#Defining_Identifier&Discrete_Subtype_Definition" &
      --  Freeze_Entity
      "&Entity$Access_Types_To_Process%TSS_Elist#Actions'First_Subtype_Link" &
      --  Access_Function_Definition
      "6Protected_Present%Parameter_Specifications&Subtype_Mark" &
      --  Access_Procedure_Definition
      "6Protected_Present%Parameter_Specifications" &
      --  Task_Type_Declaration
      "#Defining_Identifier$Task_Body_Procedure&Discriminant_Specifications%" &
         "Task_Definition'Corresponding_Body" &
      --  Package_Body_Stub
      "#Defining_Identifier&Library_Unit'Corresponding_Body" &
      --  Protected_Body_Stub
      "#Defining_Identifier&Library_Unit'Corresponding_Body" &
      --  Subprogram_Body_Stub
      "#Specification&Library_Unit'Corresponding_Body" &
      --  Task_Body_Stub
      "#Defining_Identifier&Library_Unit'Corresponding_Body" &
      --  Function_Instantiation
      "#Defining_Unit_Name$Name%Generic_Associations&Parent_Spec'Instance_Sp" &
         "ec9ABE_Is_Certain" &
      --  Package_Instantiation
      "#Defining_Unit_Name$Name%Generic_Associations&Parent_Spec'Instance_Sp" &
         "ec9ABE_Is_Certain" &
      --  Procedure_Instantiation
      "#Defining_Unit_Name$Name&Parent_Spec%Generic_Associations'Instance_Sp" &
         "ec9ABE_Is_Certain" &
      --  Package_Body
      "#Defining_Unit_Name$Declarations&Handled_Statement_Sequence'Correspon" &
         "ding_Spec4Was_Originally_Stub" &
      --  Subprogram_Body
      "#Specification$Declarations&Handled_Statement_Sequence%Activation_Cha" &
         "in_Entity'Corresponding_Spec+Acts_As_Spec6Bad_Is_Detected8Do_Stora" &
         "ge_Check-Has_Priority_Pragma.Is_Protected_Subprogram_Body,Is_Task_" &
         "Master4Was_Originally_Stub" &
      --  Protected_Body
      "#Defining_Identifier$Declarations&End_Label'Corresponding_Spec4Was_Or" &
         "iginally_Stub" &
      --  Task_Body
      "#Defining_Identifier$Declarations&Handled_Statement_Sequence,Is_Task_" &
         "Master%Activation_Chain_Entity'Corresponding_Spec4Was_Originally_S" &
         "tub" &
      --  Implicit_Label_Declaration
      "#Defining_Identifier$Label_Construct" &
      --  Package_Declaration
      "#Specification'Corresponding_Body&Parent_Spec%Activation_Chain_Entity" &
      --  Single_Task_Declaration
      "#Defining_Identifier%Task_Definition" &
      --  Subprogram_Declaration
      "#Specification%Body_To_Inline'Corresponding_Body&Parent_Spec" &
      --  Use_Package_Clause
      "$Names%Next_Use_Clause&Hidden_By_Use_Clause" &
      --  Generic_Package_Declaration
      "#Specification'Corresponding_Body$Generic_Formal_Declarations&Parent_" &
         "Spec%Activation_Chain_Entity" &
      --  Generic_Subprogram_Declaration
      "#Specification'Corresponding_Body$Generic_Formal_Declarations&Parent_" &
         "Spec" &
      --  Constrained_Array_Definition
      "$Discrete_Subtype_Definitions&Component_Definition" &
      --  Unconstrained_Array_Definition
      "$Subtype_Marks&Component_Definition" &
      --  Exception_Renaming_Declaration
      "#Defining_Identifier$Name" &
      --  Object_Renaming_Declaration
      "#Defining_Identifier&Subtype_Mark$Name'Corresponding_Generic_Associat" &
         "ion" &
      --  Package_Renaming_Declaration
      "#Defining_Unit_Name$Name&Parent_Spec" &
      --  Subprogram_Renaming_Declaration
      "#Specification$Name&Parent_Spec'Corresponding_Spec" &
      --  Generic_Function_Renaming_Declaration
      "#Defining_Unit_Name$Name&Parent_Spec" &
      --  Generic_Package_Renaming_Declaration
      "#Defining_Unit_Name$Name&Parent_Spec" &
      --  Generic_Procedure_Renaming_Declaration
      "#Defining_Unit_Name$Name&Parent_Spec" &
      --  Abort_Statement
      "$Names" &
      --  Accept_Statement
      "#Entry_Direct_Name'Entry_Index%Parameter_Specifications&Handled_State" &
         "ment_Sequence$Declarations" &
      --  Assignment_Statement
      "$Name%Expression4Do_Tag_Check+Do_Length_Check,Forwards_OK-Backwards_O" &
         "K.No_Ctrl_Actions" &
      --  Asynchronous_Select
      "#Triggering_Alternative$Abortable_Part" &
      --  Block_Statement
      "#Identifier$Declarations&Handled_Statement_Sequence,Is_Task_Master%Ac" &
         "tivation_Chain_Entity6Has_Created_Identifier-Is_Task_Allocation_Bl" &
         "ock.Is_Asynchronous_Call_Block" &
      --  Case_Statement
      "%Expression&Alternatives'End_Span" &
      --  Code_Statement
      "%Expression" &
      --  Conditional_Entry_Call
      "#Entry_Call_Alternative&Else_Statements" &
      --  Delay_Relative_Statement
      "%Expression" &
      --  Delay_Until_Statement
      "%Expression" &
      --  Entry_Call_Statement
      "$Name%Parameter_Associations&First_Named_Actual" &
      --  Free_Statement
      "%Expression#Storage_Pool&Procedure_To_Call" &
      --  Goto_Statement
      "$Name2Exception_Junk" &
      --  Loop_Statement
      "#Identifier$Iteration_Scheme%Statements&End_Label6Has_Created_Identif" &
         "ier7Is_Null_Loop" &
      --  Null_Statement
      "" &
      --  Raise_Statement
      "$Name" &
      --  Requeue_Statement
      "$Name6Abort_Present" &
      --  Return_Statement
      "%Expression#Storage_Pool&Procedure_To_Call4Do_Tag_Check$Return_Type,B" &
         "y_Ref" &
      --  Selective_Accept
      "#Select_Alternatives&Else_Statements" &
      --  Timed_Entry_Call
      "#Entry_Call_Alternative&Delay_Alternative" &
      --  Exit_Statement
      "$Name#Condition" &
      --  If_Statement
      "#Condition$Then_Statements%Elsif_Parts&Else_Statements'End_Span" &
      --  Accept_Alternative
      "$Accept_Statement#Condition%Statements&Pragmas_Before'Accept_Handler_" &
         "Records" &
      --  Delay_Alternative
      "$Delay_Statement#Condition%Statements&Pragmas_Before" &
      --  Elsif_Part
      "#Condition$Then_Statements%Condition_Actions" &
      --  Entry_Body_Formal_Part
      "&Entry_Index_Specification%Parameter_Specifications#Condition" &
      --  Iteration_Scheme
      "#Condition%Condition_Actions&Loop_Parameter_Specification" &
      --  Terminate_Alternative
      "#Condition&Pragmas_Before'Pragmas_After" &
      --  Abortable_Part
      "%Statements" &
      --  Abstract_Subprogram_Declaration
      "#Specification" &
      --  Access_Definition
      "&Subtype_Mark" &
      --  Access_To_Object_Definition
      "6All_Present'Subtype_Indication8Constant_Present" &
      --  Case_Statement_Alternative
      "&Discrete_Choices%Statements" &
      --  Compilation_Unit
      "&Library_Unit#Context_Items6Private_Present$Unit'Aux_Decls_Node8Has_N" &
         "o_Elaboration_Code4Body_Required+Acts_As_Spec%First_Inlined_Subpro" &
         "gram" &
      --  Compilation_Unit_Aux
      "$Declarations#Actions'Pragmas_After&Config_Pragmas" &
      --  Component_Association
      "#Choices$Loop_Actions%Expression6Box_Present" &
      --  Component_Definition
      "+Aliased_Present'Subtype_Indication" &
      --  Component_List
      "%Component_Items&Variant_Part4Null_Present" &
      --  Derived_Type_Definition
      "+Abstract_Present'Subtype_Indication%Record_Extension_Part" &
      --  Decimal_Fixed_Point_Definition
      "%Delta_Expression$Digits_Expression&Real_Range_Specification" &
      --  Defining_Program_Unit_Name
      "$Name#Defining_Identifier" &
      --  Delta_Constraint
      "%Delta_Expression&Range_Constraint" &
      --  Designator
      "$Name#Identifier" &
      --  Digits_Constraint
      "$Digits_Expression&Range_Constraint" &
      --  Discriminant_Association
      "#Selector_Names%Expression" &
      --  Discriminant_Specification
      "#Defining_Identifier'Discriminant_Type%Expression,More_Ids-Prev_Ids" &
      --  Enumeration_Type_Definition
      "#Literals&End_Label" &
      --  Entry_Body
      "#Defining_Identifier'Entry_Body_Formal_Part$Declarations&Handled_Stat" &
         "ement_Sequence%Activation_Chain_Entity" &
      --  Entry_Call_Alternative
      "#Entry_Call_Statement%Statements&Pragmas_Before" &
      --  Exception_Declaration
      "#Defining_Identifier%Expression,More_Ids-Prev_Ids" &
      --  Exception_Handler
      "$Choice_Parameter&Exception_Choices%Statements,Zero_Cost_Handling" &
      --  Floating_Point_Definition
      "$Digits_Expression&Real_Range_Specification" &
      --  Formal_Decimal_Fixed_Point_Definition
      "" &
      --  Formal_Derived_Type_Definition
      "&Subtype_Mark6Private_Present+Abstract_Present" &
      --  Formal_Discrete_Type_Definition
      "" &
      --  Formal_Floating_Point_Definition
      "" &
      --  Formal_Modular_Type_Definition
      "" &
      --  Formal_Ordinary_Fixed_Point_Definition
      "" &
      --  Formal_Package_Declaration
      "#Defining_Identifier$Name%Generic_Associations6Box_Present'Instance_S" &
         "pec9ABE_Is_Certain" &
      --  Formal_Private_Type_Definition
      "+Abstract_Present6Tagged_Present8Limited_Present" &
      --  Formal_Signed_Integer_Type_Definition
      "" &
      --  Formal_Subprogram_Declaration
      "#Specification$Default_Name6Box_Present" &
      --  Generic_Association
      "$Selector_Name#Explicit_Generic_Actual_Parameter" &
      --  Handled_Sequence_Of_Statements
      "%Statements&End_Label'Exception_Handlers#At_End_Proc$First_Real_State" &
         "ment,Zero_Cost_Handling" &
      --  Index_Or_Discriminant_Constraint
      "#Constraints" &
      --  Itype_Reference
      "#Itype" &
      --  Label
      "#Identifier2Exception_Junk" &
      --  Modular_Type_Definition
      "%Expression" &
      --  Number_Declaration
      "#Defining_Identifier%Expression,More_Ids-Prev_Ids" &
      --  Ordinary_Fixed_Point_Definition
      "%Delta_Expression&Real_Range_Specification" &
      --  Others_Choice
      "#Others_Discrete_Choices2All_Others" &
      --  Package_Specification
      "#Defining_Unit_Name$Visible_Declarations%Private_Declarations&End_Lab" &
         "el'Generic_Parent9Limited_View_Installed" &
      --  Parameter_Association
      "$Selector_Name%Explicit_Actual_Parameter&Next_Named_Actual" &
      --  Parameter_Specification
      "#Defining_Identifier6In_Present8Out_Present$Parameter_Type%Expression" &
         "4Do_Accessibility_Check,More_Ids-Prev_Ids'Default_Expression" &
      --  Protected_Definition
      "$Visible_Declarations%Private_Declarations&End_Label-Has_Priority_Pra" &
         "gma" &
      --  Range_Constraint
      "&Range_Expression" &
      --  Real_Range_Specification
      "#Low_Bound$High_Bound" &
      --  Record_Definition
      "&End_Label+Abstract_Present6Tagged_Present8Limited_Present#Component_" &
         "List4Null_Present" &
      --  Signed_Integer_Type_Definition
      "#Low_Bound$High_Bound" &
      --  Single_Protected_Declaration
      "#Defining_Identifier%Protected_Definition" &
      --  Subunit
      "$Name#Proper_Body%Corresponding_Stub" &
      --  Task_Definition
      "$Visible_Declarations%Private_Declarations&End_Label-Has_Priority_Pra" &
         "gma,Has_Storage_Size_Pragma.Has_Task_Info_Pragma/Has_Task_Name_Pra" &
         "gma" &
      --  Triggering_Alternative
      "#Triggering_Statement%Statements&Pragmas_Before" &
      --  Use_Type_Clause
      "$Subtype_Marks%Next_Use_Clause&Hidden_By_Use_Clause" &
      --  Validate_Unchecked_Conversion
      "#Source_Type$Target_Type" &
      --  Variant
      "&Discrete_Choices#Component_List$Enclosing_Variant%Present_Expr'Dchec" &
         "k_Function" &
      --  Variant_Part
      "$Name#Variants" &
      --  With_Clause
      "$Name&Library_Unit'Corresponding_Spec,First_Name-Last_Name4Context_In" &
         "stalled+Elaborate_Present6Elaborate_All_Present7Implicit_With8Limi" &
         "ted_Present9Limited_View_Installed.Unreferenced_In_Spec/No_Entitie" &
         "s_Ref_In_Spec" &
      --  With_Type_Clause
      "$Name6Tagged_Present" &
      --  Unused_At_End
      "";

   type Pchar_Pos_Array is array (Node_Kind) of Positive;
   Pchar_Pos : constant Pchar_Pos_Array := Pchar_Pos_Array'(
      N_Unused_At_Start                        => 1,
      N_At_Clause                              => 1,
      N_Component_Clause                       => 23,
      N_Enumeration_Representation_Clause      => 66,
      N_Mod_Clause                             => 107,
      N_Record_Representation_Clause           => 133,
      N_Attribute_Definition_Clause            => 187,
      N_Empty                                  => 253,
      N_Pragma                                 => 253,
      N_Pragma_Argument_Association            => 312,
      N_Error                                  => 323,
      N_Defining_Character_Literal             => 323,
      N_Defining_Identifier                    => 341,
      --N_Defining_Operator_Symbol               => 359,
      N_Expanded_Name                          => 377,
      N_Identifier                             => 452,
      --N_Operator_Symbol                        => 528,
      N_Character_Literal                      => 575,
      N_Op_Add                                 => 634,
      N_Op_Concat                              => 634,
      N_Op_Expon                               => 681,
      N_Op_Subtract                            => 705,
      N_Op_Divide                              => 705,
      N_Op_Mod                                 => 761,
      N_Op_Multiply                            => 802,
      N_Op_Rem                                 => 840,
      N_Op_And                                 => 881,
      N_Op_Eq                                  => 897,
      N_Op_Ge                                  => 897,
      N_Op_Gt                                  => 897,
      N_Op_Le                                  => 897,
      N_Op_Lt                                  => 897,
      N_Op_Ne                                  => 897,
      N_Op_Or                                  => 897,
      N_Op_Xor                                 => 913,
      N_Op_Rotate_Left                         => 929,
      N_Op_Rotate_Right                        => 944,
      N_Op_Shift_Left                          => 959,
      N_Op_Shift_Right                         => 974,
      N_Op_Shift_Right_Arithmetic              => 989,
      N_Op_Abs                                 => 1004,
      N_Op_Minus                               => 1004,
      N_Op_Not                                 => 1004,
      N_Op_Plus                                => 1004,
      N_Attribute_Reference                    => 1004,
      N_And_Then                               => 1128,
      N_Conditional_Expression                 => 1136,
      N_Explicit_Dereference                   => 1174,
      N_Function_Call                          => 1181,
      N_In                                     => 1323,
      N_Indexed_Component                      => 1323,
      N_Integer_Literal                        => 1342,
      N_Not_In                                 => 1378,
      N_Null                                   => 1378,
      N_Or_Else                                => 1378,
      N_Procedure_Call_Statement               => 1386,
      N_Qualified_Expression                   => 1528,
      N_Aggregate                              => 1603,
      N_Allocator                              => 1759,
      N_Extension_Aggregate                    => 1836,
      N_Range                                  => 1939,
      N_Real_Literal                           => 1980,
      N_Reference                              => 2050,
      N_Selected_Component                     => 2057,
      N_Slice                                  => 2141,
      N_String_Literal                         => 2163,
      N_Subprogram_Info                        => 2189,
      N_Type_Conversion                        => 2200,
      N_Unchecked_Expression                   => 2315,
      N_Unchecked_Type_Conversion              => 2326,
      N_Subtype_Indication                     => 2381,
      N_Component_Declaration                  => 2421,
      N_Formal_Object_Declaration              => 2583,
      N_Formal_Type_Declaration                => 2668,
      N_Full_Type_Declaration                  => 2769,
      N_Incomplete_Type_Declaration            => 2857,
      N_Loop_Parameter_Specification           => 2935,
      N_Object_Declaration                     => 2999,
      N_Private_Extension_Declaration          => 3334,
      N_Private_Type_Declaration               => 3448,
      N_Subtype_Declaration                    => 3574,
      N_Function_Specification                 => 3648,
      N_Procedure_Specification                => 3740,
      N_Freeze_Entity                          => 3867,
      N_Access_Function_Definition             => 3935,
      N_Access_Procedure_Definition            => 3991,
      N_Function_Instantiation                 => 4339,
      N_Package_Instantiation                  => 4425,
      N_Procedure_Instantiation                => 4511,
      N_Package_Body                           => 4597,
      N_Subprogram_Body                        => 4695,
      N_Implicit_Label_Declaration             => 5142,
      N_Package_Declaration                    => 5178,
      N_Subprogram_Declaration                 => 5283,
      N_Use_Package_Clause                     => 5343,
      N_Generic_Package_Declaration            => 5386,
      N_Generic_Subprogram_Declaration         => 5483,
      N_Constrained_Array_Definition           => 5556,
      N_Unconstrained_Array_Definition         => 5606,
      N_Object_Renaming_Declaration            => 5666,
      N_Package_Renaming_Declaration           => 5738,
      N_Subprogram_Renaming_Declaration        => 5774,
      N_Generic_Function_Renaming_Declaration  => 5824,
      N_Generic_Package_Renaming_Declaration   => 5860,
      N_Generic_Procedure_Renaming_Declaration => 5896,
      N_Assignment_Statement                   => 6033,
      N_Block_Statement                        => 6157,
      N_Case_Statement                         => 6322,
      N_Code_Statement                         => 6355,
      N_Free_Statement                         => 6474,
      N_Goto_Statement                         => 6516,
      N_Loop_Statement                         => 6536,
      N_Null_Statement                         => 6621,
      N_Return_Statement                       => 6645,
      N_Exit_Statement                         => 6796,
      N_If_Statement                           => 6811,
      N_Elsif_Part                             => 7002,
      N_Iteration_Scheme                       => 7107,
      N_Abstract_Subprogram_Declaration        => 7214,
      N_Access_Definition                      => 7228,
      N_Access_To_Object_Definition            => 7241,
      N_Aspect_Specification                   => 7243,
      N_Case_Statement_Alternative             => 7289,
      N_Compilation_Unit                       => 7317,
      N_Compilation_Unit_Aux                   => 7456,
      N_Component_Association                  => 7506,
      N_Component_Definition                   => 7550,
      N_Component_List                         => 7585,
      N_Derived_Type_Definition                => 7627,
      N_Defining_Program_Unit_Name             => 7745,
      N_Designator                             => 7804,
      N_Digits_Constraint                      => 7820,
      N_Discriminant_Association               => 7855,
      N_Enumeration_Type_Definition            => 7948,
      N_Floating_Point_Definition              => 8235,
      N_Formal_Derived_Type_Definition         => 8278,
      N_Formal_Discrete_Type_Definition        => 8324,
      N_Formal_Floating_Point_Definition       => 8324,
      N_Formal_Modular_Type_Definition         => 8324,
      N_Formal_Package_Declaration             => 8324,
      N_Formal_Private_Type_Definition         => 8411,
      N_Formal_Signed_Integer_Type_Definition  => 8459,
      N_Formal_Subprogram_Declaration          => 8459,
      N_Generic_Association                    => 8498,
      N_Handled_Sequence_Of_Statements         => 8546,
      N_Index_Or_Discriminant_Constraint       => 8638,
      N_Label                                  => 8656,
      N_Modular_Type_Definition                => 8682,
      N_Number_Declaration                     => 8693,
      N_Others_Choice                          => 8784,
      N_Package_Specification                  => 8819,
      N_Parameter_Association                  => 8928,
      N_Parameter_Specification                => 8986,
      N_Range_Constraint                       => 9187,
      N_Real_Range_Specification               => 9204,
      N_Record_Definition                      => 9225,
      N_Signed_Integer_Type_Definition         => 9311,
      N_Use_Type_Clause                        => 9594,
      N_Validate_Unchecked_Conversion          => 9645,
      N_With_Clause                            => 9762,
							    
      N_Reactive_Type                          => 9872,
      N_Reactive_State                         => 9873,
      N_Reactive_Wait_Statement                => 9874,
      N_Reactive_Pause_Statement               => 9876,
      N_Reactive_Fork_Statement                => 9878,
      N_Reactive_Fork_Alternative              => 9880,
      N_Reactive_Select_Statement              => 9882,
      N_Reactive_Select_Alternative            => 9884,
      N_Reactive_Abort_Statement               => 9886,
      N_Reactive_Abort_Handler                 => 9888,
							    
      N_With_Type_Clause                       => 9976,
      N_Unused_At_End                          => 9996);

end Treeprs;
