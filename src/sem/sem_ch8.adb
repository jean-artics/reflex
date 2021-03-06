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
with Einfo;    use Einfo;
with Elists;   use Elists;
with Errout;   use Errout;
with Exp_Util; use Exp_Util;
with Fname;    use Fname;
with Freeze;   use Freeze;
with Lib;      use Lib;
with Lib.Load; use Lib.Load;
with Namet;    use Namet;
with Nlists;   use Nlists;
with Nmake;    use Nmake;
with Opt;      use Opt;
with Output;   use Output;
with Restrict; use Restrict;
with Rtsfind;  use Rtsfind;
with Sem;      use Sem;
with Sem_Cat;  use Sem_Cat;
with Sem_Ch3;  use Sem_Ch3;
with Sem_Ch4;  use Sem_Ch4;
with Sem_Ch6;  use Sem_Ch6;
with Sem_Ch12; use Sem_Ch12;
with Sem_Res;  use Sem_Res;
with Sem_Util; use Sem_Util;
with Sem_Type; use Sem_Type;
with Stand;    use Stand;
with Sinfo;    use Sinfo;
with Sinfo.CN; use Sinfo.CN;
with Snames;   use Snames;
with Table;
with Tbuild;   use Tbuild;
with Uintp;    use Uintp;

with GNAT.Spelling_Checker; use GNAT.Spelling_Checker;

package body Sem_Ch8 is

   ------------------------------------
   -- Visibility and Name Resolution --
   ------------------------------------

   --  This package handles name resolution and the collection of
   --  interpretations for overloaded names, prior to overload resolution.

   --  Name resolution is the process that establishes a mapping between source
   --  identifiers and the entities they denote at each point in the program.
   --  Each entity is represented by a defining occurrence. Each identifier
   --  that denotes an entity points to the corresponding defining occurrence.
   --  This is the entity of the applied occurrence. Each occurrence holds
   --  an index into the names table, where source identifiers are stored.

   --  Each entry in the names table for an identifier or designator uses the
   --  Info pointer to hold a link to the currently visible entity that has
   --  this name (see subprograms Get_Name_Entity_Id and Set_Name_Entity_Id
   --  in package Sem_Util). The visibility is initialized at the beginning of
   --  semantic processing to make entities in package Standard immediately
   --  visible. The visibility table is used in a more subtle way when
   --  compiling subunits (see below).

   --  Entities that have the same name (i.e. homonyms) are chained. In the
   --  case of overloaded entities, this chain holds all the possible meanings
   --  of a given identifier. The process of overload resolution uses type
   --  information to select from this chain the unique meaning of a given
   --  identifier.

   --  Entities are also chained in their scope, through the Next_Entity link.
   --  As a consequence, the name space is organized as a sparse matrix, where
   --  each row corresponds to a scope, and each column to a source identifier.
   --  Open scopes, that is to say scopes currently being compiled, have their
   --  corresponding rows of entities in order, innermost scope first.

   --  The scopes of packages that are mentioned in  context clauses appear in
   --  no particular order, interspersed among open scopes. This is because
   --  in the course of analyzing the context of a compilation, a package
   --  declaration is first an open scope, and subsequently an element of the
   --  context. If subunits or child units are present, a parent unit may
   --  appear under various guises at various times in the compilation.

   --  When the compilation of the innermost scope is complete, the entities
   --  defined therein are no longer visible. If the scope is not a package
   --  declaration, these entities are never visible subsequently, and can be
   --  removed from visibility chains. If the scope is a package declaration,
   --  its visible declarations may still be accessible. Therefore the entities
   --  defined in such a scope are left on the visibility chains, and only
   --  their visibility (immediately visibility or potential use-visibility)
   --  is affected.

   --  The ordering of homonyms on their chain does not necessarily follow
   --  the order of their corresponding scopes on the scope stack. For
   --  example, if package P and the enclosing scope both contain entities
   --  named E, then when compiling the package body the chain for E will
   --  hold the global entity first,  and the local one (corresponding to
   --  the current inner scope) next. As a result, name resolution routines
   --  do not assume any relative ordering of the homonym chains, either
   --  for scope nesting or to order of appearance of context clauses.

   --  When compiling a child unit, entities in the parent scope are always
   --  immediately visible. When compiling the body of a child unit, private
   --  entities in the parent must also be made immediately visible. There
   --  are separate routines to make the visible and private declarations
   --  visible at various times (see package Sem_Ch7).

   --              +--------+         +-----+
   --              | In use |-------->| EU1 |-------------------------->
   --              +--------+         +-----+
   --                                    |                      |
   --      +--------+                 +-----+                +-----+
   --      | Stand. |---------------->| ES1 |--------------->| ES2 |--->
   --      +--------+                 +-----+                +-----+
   --                                    |                      |
   --              +---------+           |                   +-----+
   --              | with'ed |------------------------------>| EW2 |--->
   --              +---------+           |                   +-----+
   --                                    |                      |
   --      +--------+                 +-----+                +-----+
   --      | Scope2 |---------------->| E12 |--------------->| E22 |--->
   --      +--------+                 +-----+                +-----+
   --                                    |                      |
   --      +--------+                 +-----+                +-----+
   --      | Scope1 |---------------->| E11 |--------------->| E12 |--->
   --      +--------+                 +-----+                +-----+
   --          ^                         |                      |
   --          |                         |                      |
   --          |   +---------+           |                      |
   --          |   | with'ed |----------------------------------------->
   --          |   +---------+           |                      |
   --          |                         |                      |
   --      Scope stack                   |                      |
   --      (innermost first)             |                      |
   --                                 +----------------------------+
   --      Names  table =>            | Id1 |     |    |     | Id2 |
   --                                 +----------------------------+

   --  Name resolution must deal with several syntactic forms: simple names,
   --  qualified names, indexed names, and various forms of calls.

   --  Each identifier points to an entry in the names table. The resolution
   --  of a simple name consists in traversing the homonym chain, starting
   --  from the names table. If an entry is immediately visible, it is the one
   --  designated by the identifier. If only potentially use-visible entities
   --  are on the chain, we must verify that they do not hide each other. If
   --  the entity we find is overloadable, we collect all other overloadable
   --  entities on the chain as long as they are not hidden.
   --
   --  To resolve expanded names, we must find the entity at the intersection
   --  of the entity chain for the scope (the prefix) and the homonym chain
   --  for the selector. In general, homonym chains will be much shorter than
   --  entity chains, so it is preferable to start from the names table as
   --  well. If the entity found is overloadable, we must collect all other
   --  interpretations that are defined in the scope denoted by the prefix.

   --  For records, protected types, and tasks, their local entities are
   --  removed from visibility chains on exit from the corresponding scope.
   --  From the outside, these entities are always accessed by selected
   --  notation, and the entity chain for the record type, protected type,
   --  etc. is traversed sequentially in  order to find the designated entity.

   --  The discriminants of a type and the operations of a protected type or
   --  task are unchained on  exit from the first view of the type, (such as
   --  a private or incomplete type declaration, or a protected type speci-
   --  fication) and re-chained when compiling the second view.

   --  In the case of operators,  we do not make operators on derived types
   --  explicit. As a result, the notation P."+" may denote either a user-
   --  defined function with name "+", or else an implicit declaration of the
   --  operator "+" in package P. The resolution of expanded names always
   --  tries to resolve an operator name as such an implicitly defined entity,
   --  in addition to looking for explicit declarations.

   --  All forms of names that denote entities (simple names, expanded names,
   --  character literals in some cases) have a Entity attribute, which
   --  identifies the entity denoted by the name.

   ---------------------
   -- The Scope Stack --
   ---------------------

   --  The Scope stack keeps track of the scopes currently been compiled.
   --  Every entity that contains declarations (including records) is placed
   --  on the scope stack while it is being processed, and removed at the end.
   --  Whenever a non-package scope is exited, the entities defined therein
   --  are removed from the visibility table, so that entities in outer scopes
   --  become visible (see previous description). On entry to Sem, the scope
   --  stack only contains the package Standard. As usual, subunits complicate
   --  this picture ever so slightly.

   --  The Rtsfind mechanism can force a call to Semantics while another
   --  compilation is in progress. The unit retrieved by Rtsfind must be
   --  compiled in  its own context, and has no access to the visibility of
   --  the unit currently being compiled. The procedures Save_Scope_Stack and
   --  Restore_Scope_Stack make entities in current open scopes invisible
   --  before compiling the retrieved unit, and restore the compilation
   --  environment afterwards.

   ------------------------
   -- Compiling subunits --
   ------------------------

   --  Subunits must be compiled in the environment of the corresponding
   --  stub, that is to say with the same visibility into the parent (and its
   --  context) that is available at the point of the stub declaration, but
   --  with the additional visibility provided by the context clause of the
   --  subunit itself. As a result, compilation of a subunit forces compilation
   --  of the parent (see description in lib-). At the point of the stub
   --  declaration, Analyze is called recursively to compile the proper body
   --  of the subunit, but without reinitializing the names table, nor the
   --  scope stack (i.e. standard is not pushed on the stack). In this fashion
   --  the context of the subunit is added to the context of the parent, and
   --  the subunit is compiled in the correct environment. Note that in the
   --  course of processing the context of a subunit, Standard will appear
   --  twice on the scope stack: once for the parent of the subunit, and
   --  once for the unit in the context clause being compiled. However, the
   --  two sets of entities are not linked by homonym chains, so that the
   --  compilation of any context unit happens in a fresh visibility
   --  environment.

   -------------------------------
   -- Processing of USE Clauses --
   -------------------------------

   --  Every defining occurrence has a flag indicating if it is potentially use
   --  visible. Resolution of simple names examines this flag. The processing
   --  of use clauses consists in setting this flag on all visible entities
   --  defined in the corresponding package. On exit from the scope of the use
   --  clause, the corresponding flag must be reset. However, a package may
   --  appear in several nested use clauses (pathological but legal, alas!)
   --  which forces us to use a slightly more involved scheme:

   --    a) The defining occurrence for a package holds a flag -In_Use- to
   --    indicate that it is currently in the scope of a use clause. If a
   --    redundant use clause is encountered, then the corresponding occurrence
   --    of the package name is flagged -Redundant_Use-.

   --    b) On exit from a scope, the use clauses in its declarative part are
   --    scanned. The visibility flag is reset in all entities declared in
   --    package named in a use clause, as long as the package is not flagged
   --    as being in a redundant use clause (in which case the outer use
   --    clause is still in effect, and the direct visibility of its entities
   --    must be retained).

   --  Note that entities are not removed from their homonym chains on exit
   --  from the package specification. A subsequent use clause does not need
   --  to rechain the visible entities, but only to establish their direct
   --  visibility.

   -----------------------------------
   -- Handling private declarations --
   -----------------------------------

   --  The principle that each entity has a single defining occurrence clashes
   --  with the presence of two separate definitions for private types: the
   --  first is the private type declaration, and second is the full type
   --  declaration. It is important that all references to the type point to
   --  the same defining occurrence, namely the first one. To enforce the two
   --  separate views of the entity, the corresponding information is swapped
   --  between the two declarations. Outside of the package, the defining
   --  occurrence only contains the private declaration information, while in
   --  the private part and the body of the package the defining occurrence
   --  contains the full declaration. To simplify the swap, the defining
   --  occurrence that currently holds the private declaration points to the
   --  full declaration. During semantic processing the defining occurrence
   --  also points to a list of private dependents, that is to say access
   --  types or composite types whose designated types or component types are
   --  subtypes or derived types of the private type in question. After the
   --  full declaration has been seen, the private dependents are updated to
   --  indicate that they have full definitions.

   ------------------------------------
   -- Handling of Undefined Messages --
   ------------------------------------

   --  In normal mode, only the first use of an undefined identifier generates
   --  a message. The table Urefs is used to record error messages that have
   --  been issued so that second and subsequent ones do not generate further
   --  messages. However, the second reference causes text to be added to the
   --  original undefined message noting "(more references follow)". The
   --  full error list option (-gnatf) forces messages to be generated for
   --  every reference and disconnects the use of this table.

   type Uref_Entry is record
      Node : Node_Id;
      --  Node for identifier for which original message was posted. The
      --  Chars field of this identifier is used to detect later references
      --  to the same identifier.

      Err : Error_Msg_Id;
      --  Records error message Id of original undefined message. Reset to
      --  No_Error_Msg after the second occurrence, where it is used to add
      --  text to the original message as described above.

      Nvis : Boolean;
      --  Set if the message is not visible rather than undefined

      Loc : Source_Ptr;
      --  Records location of error message. Used to make sure that we do
      --  not consider a, b : undefined as two separate instances, which
      --  would otherwise happen, since the parser converts this sequence
      --  to a : undefined; b : undefined.

   end record;

   package Urefs is new Table.Table (
     Table_Component_Type => Uref_Entry,
     Table_Index_Type     => Nat,
     Table_Low_Bound      => 1,
     Table_Initial        => 10,
     Table_Increment      => 100,
     Table_Name           => "Urefs");

   Candidate_Renaming : Entity_Id;
   --  Holds a candidate interpretation that appears in a subprogram renaming
   --  declaration and does not match the given specification, but matches at
   --  least on the first formal. Allows better error message when given
   --  specification omits defaulted parameters, a common error.

   -----------------------
   -- Local Subprograms --
   -----------------------

   procedure Analyze_Generic_Renaming
     (N : Node_Id;
      K : Entity_Kind);
   --  Common processing for all three kinds of generic renaming declarations.
   --  Enter new name and indicate that it renames the generic unit.

   procedure Analyze_Renamed_Character
     (N       : Node_Id;
      New_S   : Entity_Id;
      Is_Body : Boolean);
   --  Renamed entity is given by a character literal, which must belong
   --  to the return type of the new entity. Is_Body indicates whether the
   --  declaration is a renaming_as_body. If the original declaration has
   --  already been frozen (because of an intervening body, e.g.) the body of
   --  the function must be built now. The same applies to the following
   --  various renaming procedures.

   procedure Analyze_Renamed_Dereference
     (N       : Node_Id;
      New_S   : Entity_Id;
      Is_Body : Boolean);
   --  Renamed entity is given by an explicit dereference. Prefix must be a
   --  conformant access_to_subprogram type.

   function Applicable_Use (Pack_Name : Node_Id) return Boolean;
   --  Common code to Use_One_Package and Set_Use, to determine whether
   --  use clause must be processed. Pack_Name is an entity name that
   --  references the package in question.

   procedure Check_Frozen_Renaming (N : Node_Id; Subp : Entity_Id);
   --  A renaming_as_body may occur after the entity of the original decla-
   --  ration has been frozen. In that case, the body of the new entity must
   --  be built now, because the usual mechanism of building the renamed
   --  body at the point of freezing will not work. Subp is the subprogram
   --  for which N provides the Renaming_As_Body.

   procedure Check_In_Previous_With_Clause
     (N   : Node_Id;
      Nam : Node_Id);
   --  N is a use_package clause and Nam the package name, or N is a use_type
   --  clause and Nam is the prefix of the type name. In either case, verify
   --  that the package is visible at that point in the context: either  it
   --  appears in a previous with_clause, or because it is a fully qualified
   --  name and the root ancestor appears in a previous with_clause.

   procedure Check_Library_Unit_Renaming (N : Node_Id; Old_E : Entity_Id);
   --  Verify that the entity in a renaming declaration that is a library unit
   --  is itself a library unit and not a nested unit or subunit. Also check
   --  that if the renaming is a child unit of a generic parent, then the
   --  renamed unit must also be a child unit of that parent. Finally, verify
   --  that a renamed generic unit is not an implicit child declared within
   --  an instance of the parent.

   procedure Chain_Use_Clause (N : Node_Id);
   --  Chain use clause onto list of uses clauses headed by First_Use_Clause
   --  in the top scope table entry.

   function Has_Implicit_Character_Literal (N : Node_Id) return Boolean;
   --  Find a type derived from Character or Wide_Character in the prefix of N.
   --  Used to resolved qualified names whose selector is a character literal.

   procedure Find_Expanded_Name (N : Node_Id);
   --  Selected component is known to be expanded name. Verify legality
   --  of selector given the scope denoted by prefix.

   function Find_Renamed_Entity
     (N         : Node_Id;
      Nam       : Node_Id;
      New_S     : Entity_Id;
      Is_Actual : Boolean := False) return Entity_Id;
   --  Find the renamed entity that corresponds to the given parameter profile
   --  in a subprogram renaming declaration. The renamed entity may be an
   --  operator, a subprogram, an entry, or a protected operation. Is_Actual
   --  indicates that the renaming is the one generated for an actual subpro-
   --  gram in an instance, for which special visibility checks apply.

   function Has_Implicit_Operator (N : Node_Id) return Boolean;
   --  N is an expanded name whose selector is an operator name (eg P."+").
   --  A declarative part contains an implicit declaration of an operator
   --  if it has a declaration of a type to which one of the predefined
   --  operators apply. The existence of this routine is an artifact of
   --  our implementation: a more straightforward but more space-consuming
   --  choice would be to make all inherited operators explicit in the
   --  symbol table.

   procedure Inherit_Renamed_Profile (New_S : Entity_Id; Old_S : Entity_Id);
   --  A subprogram defined by a renaming declaration inherits the parameter
   --  profile of the renamed entity. The subtypes given in the subprogram
   --  specification are discarded and replaced with those of the renamed
   --  subprogram, which are then used to recheck the default values.

   function Is_Appropriate_For_Record (T : Entity_Id) return Boolean;
   --  Prefix is appropriate for record if it is of a record type, or
   --  an access to such.

   procedure Premature_Usage (N : Node_Id);
   --  Diagnose usage of an entity before it is visible.

   procedure Use_One_Package (P : Entity_Id; N : Node_Id);
   --  Make visible entities declared in package P potentially use-visible
   --  in the current context. Also used in the analysis of subunits, when
   --  re-installing use clauses of parent units. N is the use_clause that
   --  names P (and possibly other packages).

   procedure Write_Info;
   --  Write debugging information on entities declared in current scope

   procedure Write_Scopes;
   pragma Warnings (Off, Write_Scopes);
   --  Debugging information: dump all entities on scope stack

   --------------------------------
   -- Analyze_Exception_Renaming --
   --------------------------------

   --  The language only allows a single identifier, but the tree holds
   --  an identifier list. The parser has already issued an error message
   --  if there is more than one element in the list.

   procedure Analyze_Exception_Renaming (N : Node_Id) is
   begin
      null;
   end Analyze_Exception_Renaming;

   ---------------------------
   -- Analyze_Expanded_Name --
   ---------------------------

   procedure Analyze_Expanded_Name (N : Node_Id) is
   begin
      --  If the entity pointer is already set, this is an internal node, or
      --  a node that is analyzed more than once, after a tree modification.
      --  In such a case there is no resolution to perform, just set the type.
      --  For completeness, analyze prefix as well.

      if Present (Entity (N)) then
         if Is_Type (Entity (N)) then
            Set_Etype (N, Entity (N));
         else
            Set_Etype (N, Etype (Entity (N)));
         end if;

         Analyze (Prefix (N));
         return;
      else
         Find_Expanded_Name (N);
      end if;
   end Analyze_Expanded_Name;

   ----------------------------------------
   --  Analyze_Generic_Function_Renaming --
   ----------------------------------------

   procedure Analyze_Generic_Function_Renaming  (N : Node_Id) is
   begin
      Analyze_Generic_Renaming (N, E_Generic_Function);
   end Analyze_Generic_Function_Renaming;

   ---------------------------------------
   --  Analyze_Generic_Package_Renaming --
   ---------------------------------------

   procedure Analyze_Generic_Package_Renaming   (N : Node_Id) is
   begin
      --  Apply the Text_IO Kludge here, since we may be renaming
      --  one of the subpackages of Text_IO, then join common routine.

      Text_IO_Kludge (Name (N));

      Analyze_Generic_Renaming (N, E_Generic_Package);
   end Analyze_Generic_Package_Renaming;

   -----------------------------------------
   --  Analyze_Generic_Procedure_Renaming --
   -----------------------------------------

   procedure Analyze_Generic_Procedure_Renaming (N : Node_Id) is
   begin
      Analyze_Generic_Renaming (N, E_Generic_Procedure);
   end Analyze_Generic_Procedure_Renaming;

   ------------------------------
   -- Analyze_Generic_Renaming --
   ------------------------------

   procedure Analyze_Generic_Renaming
     (N : Node_Id;
      K : Entity_Kind)
   is
      New_P : constant Entity_Id := Defining_Entity (N);
      Old_P : Entity_Id;
      Inst  : Boolean   := False; -- prevent junk warning

   begin
      if Name (N) = Error then
         return;
      end if;

      if Current_Scope /= Standard_Standard then
         Set_Is_Pure (New_P, Is_Pure (Current_Scope));
      end if;

      if Nkind (Name (N)) = N_Selected_Component then
         Check_Generic_Child_Unit (Name (N), Inst);
      else
         Analyze (Name (N));
      end if;

      if not Is_Entity_Name (Name (N)) then
         Error_Msg_N ("expect entity name in renaming declaration", Name (N));
         Old_P := Any_Id;
      else
         Old_P := Entity (Name (N));
      end if;

      Enter_Name (New_P);
      Set_Ekind (New_P, K);

      if Etype (Old_P) = Any_Type then
         null;

      elsif Ekind (Old_P) /= K then
         Error_Msg_N ("invalid generic unit name", Name (N));

      else
         if Present (Renamed_Object (Old_P)) then
            Set_Renamed_Object (New_P,  Renamed_Object (Old_P));
         else
            Set_Renamed_Object (New_P, Old_P);
         end if;

         Set_Etype (New_P, Etype (Old_P));
         Set_Has_Completion (New_P);

         if In_Open_Scopes (Old_P) then
            Error_Msg_N ("within its scope, generic denotes its instance", N);
         end if;

         Check_Library_Unit_Renaming (N, Old_P);
      end if;

   end Analyze_Generic_Renaming;

   -----------------------------
   -- Analyze_Object_Renaming --
   -----------------------------

   procedure Analyze_Object_Renaming (N : Node_Id) is
      Id  : constant Entity_Id := Defining_Identifier (N);
      Dec : Node_Id;
      Nam : constant Node_Id   := Name (N);
      S   : constant Entity_Id := Subtype_Mark (N);
      T   : Entity_Id;
      T2  : Entity_Id;

   begin
      if Nam = Error then
         return;
      end if;

      Set_Is_Pure (Id, Is_Pure (Current_Scope));
      Enter_Name (Id);

      --  The renaming of a component that depends on a discriminant
      --  requires an actual subtype, because in subsequent use of the object
      --  Gigi will be unable to locate the actual bounds. This explicit step
      --  is required when the renaming is generated in removing side effects
      --  of an already-analyzed expression.

      if Nkind (Nam) = N_Selected_Component
        and then Analyzed (Nam)
      then
         T := Etype (Nam);
         Dec :=  Build_Actual_Subtype_Of_Component (Etype (Nam), Nam);

--           if Present (Dec) then
--              Insert_Action (N, Dec);
--              T := Defining_Identifier (Dec);
--              Set_Etype (Nam, T);
--           end if;

      else
         Find_Type (S);
         T := Entity (S);
         Analyze_And_Resolve (Nam, T);
      end if;

      --  An object renaming requires an exact match of the type;
      --  class-wide matching is not allowed.

      if Is_Class_Wide_Type (T)
        and then Base_Type (Etype (Nam)) /= Base_Type (T)
      then
         Wrong_Type (Nam, T);
      end if;

      T2 := Etype (Nam);
      Set_Ekind (Id, E_Variable);
      Init_Size_Align (Id);

      if T = Any_Type or else Etype (Nam) = Any_Type then
         return;

      --  Verify that the renamed entity is an object or a function call.
      --  It may have been rewritten in several ways.

      elsif Is_Object_Reference (Nam) then
         if Comes_From_Source (N)
           and then Is_Dependent_Component_Of_Mutable_Object (Nam)
         then
            Error_Msg_N
              ("illegal renaming of discriminant-dependent component", Nam);
         else
            null;
         end if;

      --  A static function call may have been folded into a literal

      elsif Nkind (Original_Node (Nam)) = N_Function_Call

            --  When expansion is disabled, attribute reference is not
            --  rewritten as function call. Otherwise it may be rewritten
            --  as a conversion, so check original node.

        or else (Nkind (Original_Node (Nam)) = N_Attribute_Reference
                  and then Is_Function_Attribute_Name
                    (Attribute_Name (Original_Node (Nam))))

            --  Weird but legal, equivalent to renaming a function call.

        or else (Is_Entity_Name (Nam)
                  and then Ekind (Entity (Nam)) = E_Enumeration_Literal)

        or else (Nkind (Nam) = N_Type_Conversion
                    and then Is_Tagged_Type (Entity (Subtype_Mark (Nam))))
      then
         null;

      else
         if Nkind (Nam) = N_Type_Conversion then
            Error_Msg_N
              ("renaming of conversion only allowed for tagged types", Nam);

         else
            Error_Msg_N ("expect object name in renaming", Nam);
         end if;

      end if;

      Set_Etype (Id, T2);

      if not Is_Variable (Nam) then
         Set_Ekind               (Id, E_Constant);
         Set_Never_Set_In_Source (Id, True);
         Set_Is_True_Constant    (Id, True);
      end if;

      Set_Renamed_Object (Id, Nam);
   end Analyze_Object_Renaming;

   ------------------------------
   -- Analyze_Package_Renaming --
   ------------------------------

   procedure Analyze_Package_Renaming (N : Node_Id) is
      New_P : constant Entity_Id := Defining_Entity (N);
      Old_P : Entity_Id;
      Spec  : Node_Id;

   begin
      if Name (N) = Error then
         return;
      end if;

      --  Apply Text_IO kludge here, since we may be renaming one of
      --  the children of Text_IO

      Text_IO_Kludge (Name (N));

      if Current_Scope /= Standard_Standard then
         Set_Is_Pure (New_P, Is_Pure (Current_Scope));
      end if;

      Enter_Name (New_P);
      Analyze (Name (N));
      if Is_Entity_Name (Name (N)) then
         Old_P := Entity (Name (N));
      else
         Old_P := Any_Id;
      end if;

      if Etype (Old_P) = Any_Type then
         Error_Msg_N
           ("expect package name in renaming", Name (N));

      elsif Ekind (Old_P) /= E_Package
        and then not (Ekind (Old_P) = E_Generic_Package
                       and then In_Open_Scopes (Old_P))
      then
         if Ekind (Old_P) = E_Generic_Package then
            Error_Msg_N
               ("generic package cannot be renamed as a package", Name (N));
         else
            Error_Msg_Sloc := Sloc (Old_P);
            Error_Msg_NE
             ("expect package name in renaming, found& declared#",
               Name (N), Old_P);
         end if;

         --  Set basic attributes to minimize cascaded errors.

         Set_Ekind (New_P, E_Package);
         Set_Etype (New_P, Standard_Void_Type);

      else
         --  Entities in the old package are accessible through the
         --  renaming entity. The simplest implementation is to have
         --  both packages share the entity list.

         Set_Ekind (New_P, E_Package);
         Set_Etype (New_P, Standard_Void_Type);

         if Present (Renamed_Object (Old_P)) then
            Set_Renamed_Object (New_P,  Renamed_Object (Old_P));
         else
            Set_Renamed_Object (New_P,  Old_P);
         end if;

         Set_Has_Completion (New_P);

         Set_First_Entity (New_P,  First_Entity (Old_P));
         Set_Last_Entity  (New_P,  Last_Entity  (Old_P));
         Set_First_Private_Entity (New_P, First_Private_Entity (Old_P));
         Check_Library_Unit_Renaming (N, Old_P);

         --  If this is the renaming declaration of a package instantiation
         --  within itself, it is the declaration that ends the list of actuals
         --  for the instantiation. At this point, the subtypes that rename
         --  the actuals are flagged as generic, to avoid spurious ambiguities
         --  if the actuals for two distinct formals happen to coincide. If
         --  the actual is a private type, the subtype has a private completion
         --  that is flagged in the same fashion.

         --  Resolution is identical to what is was in the original generic.
         --  On exit from the generic instance, these are turned into regular
         --  subtypes again, so they are compatible with types in their class.

         if not Is_Generic_Instance (Old_P) then
            return;
         else
            Spec := Specification (Unit_Declaration_Node (Old_P));
         end if;

         if Nkind (Spec) = N_Package_Specification
           and then Present (Generic_Parent (Spec))
           and then Old_P = Current_Scope
           and then Chars (New_P) = Chars (Generic_Parent (Spec))
         then
            declare
               E : Entity_Id := First_Entity (Old_P);
            begin
               while Present (E)
                 and then E /= New_P
               loop
                  if Is_Type (E)
                    and then Nkind (Parent (E)) = N_Subtype_Declaration
                  then
                     Set_Is_Generic_Actual_Type (E);

                     if Is_Private_Type (E)
                       and then Present (Full_View (E))
                     then
                        Set_Is_Generic_Actual_Type (Full_View (E));
                     end if;
                  end if;

                  Next_Entity (E);
               end loop;
            end;
         end if;
      end if;

   end Analyze_Package_Renaming;

   -------------------------------
   -- Analyze_Renamed_Character --
   -------------------------------

   procedure Analyze_Renamed_Character
     (N       : Node_Id;
      New_S   : Entity_Id;
      Is_Body : Boolean)
   is
      C : constant Node_Id := Name (N);

   begin
      if Ekind (New_S) = E_Function then
         Resolve (C, Etype (New_S));

         if Is_Body then
            Check_Frozen_Renaming (N, New_S);
         end if;

      else
         Error_Msg_N ("character literal can only be renamed as function", N);
      end if;
   end Analyze_Renamed_Character;

   ---------------------------------
   -- Analyze_Renamed_Dereference --
   ---------------------------------

   procedure Analyze_Renamed_Dereference
     (N       : Node_Id;
      New_S   : Entity_Id;
      Is_Body : Boolean)
   is
      Nam : constant Node_Id := Name (N);
      P   : constant Node_Id := Prefix (Nam);
      Typ : Entity_Id;
      Ind : Interp_Index;
      It  : Interp;

   begin
      if not Is_Overloaded (P) then
         if Ekind (Etype (Nam)) /= E_Subprogram_Type
           or else not Type_Conformant (Etype (Nam), New_S) then
            Error_Msg_N ("designated type does not match specification", P);
         else
            Resolve (P);
         end if;

         return;

      else
         Typ := Any_Type;
         Get_First_Interp (Nam, Ind, It);

         while Present (It.Nam) loop

            if Ekind (It.Nam) = E_Subprogram_Type
              and then Type_Conformant (It.Nam, New_S) then

               if Typ /= Any_Id then
                  Error_Msg_N ("ambiguous renaming", P);
                  return;
               else
                  Typ := It.Nam;
               end if;
            end if;

            Get_Next_Interp (Ind, It);
         end loop;

         if Typ = Any_Type then
            Error_Msg_N ("designated type does not match specification", P);
         else
            Resolve (N, Typ);

            if Is_Body then
               Check_Frozen_Renaming (N, New_S);
            end if;
         end if;
      end if;
   end Analyze_Renamed_Dereference;

   ---------------------------------
   -- Analyze_Subprogram_Renaming --
   ---------------------------------

   procedure Analyze_Subprogram_Renaming (N : Node_Id) is
      Spec        : constant Node_Id := Specification (N);
      Save_83     : constant Boolean := Ada_83;
      Nam         : constant Node_Id := Name (N);
      New_S       : Entity_Id;
      Old_S       : Entity_Id  := Empty;
      Rename_Spec : Entity_Id;
      Is_Actual   : Boolean    := False;
      Inst_Node   : Node_Id    := Empty;

      function Original_Subprogram (Subp : Entity_Id) return Entity_Id;
      --  Find renamed entity when the declaration is a renaming_as_body
      --  and the renamed entity may itself be a renaming_as_body. Used to
      --  enforce rule that a renaming_as_body is illegal if the declaration
      --  occurs before the subprogram it completes is frozen, and renaming
      --  indirectly renames the subprogram itself.(Defect Report 8652/0027).

      -------------------------
      -- Original_Subprogram --
      -------------------------

      function Original_Subprogram (Subp : Entity_Id) return Entity_Id is
         Orig_Decl : Node_Id;
         Orig_Subp : Entity_Id;

      begin
         --  First case: renamed entity is itself a renaming

         if Present (Alias (Subp)) then
            return Alias (Subp);

         elsif
           Nkind (Unit_Declaration_Node (Subp)) = N_Subprogram_Declaration
             and then Present
              (Corresponding_Body (Unit_Declaration_Node (Subp)))
         then
            --  Check if renamed entity is a renaming_as_body

            Orig_Decl :=
              Unit_Declaration_Node
                (Corresponding_Body (Unit_Declaration_Node (Subp)));

            if Nkind (Orig_Decl) = N_Subprogram_Renaming_Declaration then
               Orig_Subp := Entity (Name (Orig_Decl));

               if Orig_Subp = Rename_Spec then

                  --  Circularity detected.

                  return Orig_Subp;

               else
                  return (Original_Subprogram (Orig_Subp));
               end if;
            else
               return Subp;
            end if;
         else
            return Subp;
         end if;
      end Original_Subprogram;

   --  Start of processing for Analyze_Subprogram_Renaming

   begin
      --  We must test for the attribute renaming case before the Analyze
      --  Check whether this declaration corresponds to the instantiation
      --  of a formal subprogram. This is indicated by the presence of a
      --  Corresponding_Spec that is the instantiation declaration.

      --  If this is an instantiation, the corresponding actual is frozen
      --  and error messages can be made more precise. If this is a default
      --  subprogram, the entity is already established in the generic, and
      --  is not retrieved by visibility. If it is a default with a box, the
      --  candidate interpretations, if any, have been collected when building
      --  the renaming declaration. If overloaded, the proper interpretation
      --  is determined in Find_Renamed_Entity. If the entity is an operator,
      --  Find_Renamed_Entity applies additional visibility checks.

      if Present (Corresponding_Spec (N)) then
         Is_Actual := True;
         Inst_Node := Unit_Declaration_Node (Corresponding_Spec (N));

         if Is_Entity_Name (Nam)
           and then Present (Entity (Nam))
           and then not Comes_From_Source (Nam)
           and then not Is_Overloaded (Nam)
         then
            Old_S := Entity (Nam);
            New_S := Analyze_Subprogram_Specification (Spec);

            if Ekind (Entity (Nam)) = E_Operator
              and then Box_Present (Inst_Node)
            then
               Old_S := Find_Renamed_Entity (N, Name (N), New_S, Is_Actual);
            end if;

         else
            Analyze (Nam);
            New_S := Analyze_Subprogram_Specification (Spec);
         end if;

         Set_Corresponding_Spec (N, Empty);

      else
         --  Renamed entity must be analyzed first, to avoid being hidden by
         --  new name (which might be the same in a generic instance).

         Analyze (Nam);

         --  The renaming defines a new overloaded entity, which is analyzed
         --  like a subprogram declaration.

         New_S := Analyze_Subprogram_Specification (Spec);
      end if;

      if Current_Scope /= Standard_Standard then
         Set_Is_Pure (New_S, Is_Pure (Current_Scope));
      end if;

      Rename_Spec := Find_Corresponding_Spec (N);

      if Present (Rename_Spec) then

         --  Renaming_As_Body. Renaming declaration is the completion of
         --  the declaration of Rename_Spec. We will build an actual body
         --  for it at the freezing point.

         Set_Corresponding_Spec (N, Rename_Spec);
         Set_Corresponding_Body (Unit_Declaration_Node (Rename_Spec), New_S);

         --  The body is created when the entity is frozen. If the context
         --  is generic, freeze_all is not invoked, so we need to indicate
         --  that the entity has a completion.

         Set_Has_Completion (Rename_Spec, Inside_A_Generic);

         Set_Convention (New_S,  Convention (Rename_Spec));
         Check_Fully_Conformant (New_S, Rename_Spec);
         Set_Public_Status (New_S);

         --  Indicate that the entity in the declaration functions like
         --  the corresponding body, and is not a new entity.

         Set_Ekind (New_S, E_Subprogram_Body);
         New_S := Rename_Spec;

      else
         New_Overloaded_Entity (New_S);
         if Is_Entity_Name (Nam)
           and then Is_Intrinsic_Subprogram (Entity (Nam))
         then
            null;
         else
            Check_Delayed_Subprogram (New_S);
         end if;
      end if;

      --  There is no need for elaboration checks on the new entity, which
      --  may be called before the next freezing point where the body will
      --  appear. Elaboration checks refer to the real entity, not the one
      --  created by the renaming declaration.

      Set_Kill_Elaboration_Checks (New_S, True);

      if Etype (Nam) = Any_Type then
         Set_Has_Completion (New_S);
         return;

      elsif Nkind (Nam) = N_Explicit_Dereference then

         --  Renamed entity is designated by access_to_subprogram expression.
         --  Must build body to encapsulate call, as in the entry case.

         Analyze_Renamed_Dereference (N, New_S, Present (Rename_Spec));
         return;

      elsif Nkind (Nam) = N_Character_Literal then
         Analyze_Renamed_Character (N, New_S, Present (Rename_Spec));
         return;

      elsif not Is_Entity_Name (Nam)
--                and then Nkind (Nam) /= N_Operator_Symbol)
        or else not Is_Overloadable (Entity (Nam))
      then
         Error_Msg_N ("expect valid subprogram name in renaming", N);
         return;

      end if;

      --  Most common case: subprogram renames subprogram. No body is
      --  generated in this case, so we must indicate that the declaration
      --  is complete as is.

      if No (Rename_Spec) then
         Set_Has_Completion (New_S);
      end if;

      --  Find the renamed entity that matches the given specification.
      --  Disable Ada_83 because there is no requirement of full conformance
      --  between renamed entity and new entity, even though the same circuit
      --  is used.

      Ada_83 := False;

      if No (Old_S) then
         Old_S := Find_Renamed_Entity (N, Name (N), New_S, Is_Actual);
      end if;

      if Old_S /= Any_Id then

         --  For a renaming-as-body, require subtype conformance,
         --  but if the declaration being completed has not been
         --  frozen, then inherit the convention of the renamed
         --  subprogram prior to checking conformance (unless the
         --  renaming has an explicit convention established; the
         --  rule stated in the RM doesn't seem to address this ???).

         if Present (Rename_Spec) then
            if not Is_Frozen (Rename_Spec) then
               if not Has_Convention_Pragma (Rename_Spec) then
                  Set_Convention (New_S, Convention (Old_S));
               end if;

               if Ekind (Old_S) /= E_Operator then
                  Check_Mode_Conformant (New_S, Old_S, Spec);
               end if;

               if Original_Subprogram (Old_S) = Rename_Spec then
                  Error_Msg_N ("unfrozen subprogram cannot rename itself ", N);
               end if;
            else
               Check_Subtype_Conformant (New_S, Old_S, Spec);
            end if;

            Check_Frozen_Renaming (N, Rename_Spec);

         elsif Ekind (Old_S) /= E_Operator then
            Check_Mode_Conformant (New_S, Old_S);

            if Is_Actual
              and then Error_Posted (New_S)
            then
               Error_Msg_NE ("invalid actual subprogram: & #!", N, Old_S);
            end if;
         end if;

         if No (Rename_Spec) then

            --  The parameter profile of the new entity is that of the renamed
            --  entity: the subtypes given in the specification are irrelevant.

            Inherit_Renamed_Profile (New_S, Old_S);

            --  A call to the subprogram is transformed into a call to the
            --  renamed entity. This is transitive if the renamed entity is
            --  itself a renaming.

            if Present (Alias (Old_S)) then
               Set_Alias (New_S, Alias (Old_S));
            else
               Set_Alias (New_S, Old_S);
            end if;

            --  Note that we do not set Is_Instrinsic_Subprogram if we have
            --  a renaming as body, since the entity in this case is not an
            --  intrinsic (it calls an intrinsic, but we have a real body
            --  for this call, and it is in this body that the required
            --  intrinsic processing will take place).

            --  Also, if this is a renaming of inequality, the renamed
            --  operator is intrinsic, but what matters is the corresponding
            --  equality operator, which may be user-defined.

            Set_Is_Intrinsic_Subprogram
              (New_S,
                Is_Intrinsic_Subprogram (Old_S)
                  and then
                    (Chars (Old_S) /= Name_Op_Ne
                       or else Ekind (Old_S) = E_Operator
                       or else
                         Is_Intrinsic_Subprogram
                            (Corresponding_Equality (Old_S))));

            if Ekind (Alias (New_S)) = E_Operator then
               Set_Has_Delayed_Freeze (New_S, False);
            end if;

         end if;

         if not Is_Actual
           and then (Old_S = New_S
                      or else (Nkind (Nam) /= N_Expanded_Name
                        and then  Chars (Old_S) = Chars (New_S)))
         then
            Error_Msg_N ("subprogram cannot rename itself", N);
         end if;

         Set_Convention (New_S, Convention (Old_S));
         Set_Is_Abstract (New_S, Is_Abstract (Old_S));
         Check_Library_Unit_Renaming (N, Old_S);

         if Is_Actual then
            Freeze_Before (N, Old_S);
            Set_Has_Delayed_Freeze (New_S, False);
            Freeze_Before (N, New_S);

            if (Ekind (Old_S) = E_Procedure or else Ekind (Old_S) = E_Function)
              and then Is_Abstract (Old_S)
            then
               Error_Msg_N
                 ("abstract subprogram not allowed as generic actual", Nam);
            end if;
         end if;

      else
         --  A common error is to assume that implicit operators for types
         --  are defined in Standard, or in the scope of a subtype. In those
         --  cases where the renamed entity is given with an expanded name,
         --  it is worth mentioning that operators for the type are not
         --  declared in the scope given by the prefix.

--           if Nkind (Nam) = N_Expanded_Name
--             and then Nkind (Selector_Name (Nam)) = N_Operator_Symbol
--             and then Scope (Entity (Nam)) = Standard_Standard
--           then
--              declare
--                 T : constant Entity_Id :=
--                       Base_Type (Etype (First_Formal (New_S)));
--  
--              begin
--                 Error_Msg_Node_2 := Prefix (Nam);
--                 Error_Msg_NE
--                   ("operator for type& is not declared in&", Prefix (Nam), T);
--              end;
--  
--           else
            Error_Msg_NE
              ("no visible subprogram matches the specification for&",
                Spec, New_S);
         --end if;

         if Present (Candidate_Renaming) then
            declare
               F1 : Entity_Id;
               F2 : Entity_Id;

            begin
               F1 := First_Formal (Candidate_Renaming);
               F2 := First_Formal (New_S);

               while Present (F1) and then Present (F2) loop
                  Next_Formal (F1);
                  Next_Formal (F2);
               end loop;

               if Present (F1) and then Present (Default_Value (F1)) then
                  if Present (Next_Formal (F1)) then
                     Error_Msg_NE
                       ("\missing specification for &" &
                          " and other formals with defaults", Spec, F1);
                  else
                     Error_Msg_NE
                    ("\missing specification for &", Spec, F1);
                  end if;
               end if;
            end;
         end if;
      end if;

      Ada_83 := Save_83;
   end Analyze_Subprogram_Renaming;

   -------------------------
   -- Analyze_Use_Package --
   -------------------------

   --  Resolve the package names in the use clause, and make all the visible
   --  entities defined in the package potentially use-visible. If the package
   --  is already in use from a previous use clause, its visible entities are
   --  already use-visible. In that case, mark the occurrence as a redundant
   --  use. If the package is an open scope, i.e. if the use clause occurs
   --  within the package itself, ignore it.

   procedure Analyze_Use_Package (N : Node_Id) is
      Pack_Name : Node_Id;
      Pack      : Entity_Id;

   --  Start of processing for Analyze_Use_Package

   begin
      Set_Hidden_By_Use_Clause (N, No_Elist);

      --  Use clause is not allowed in a spec of a predefined package
      --  declaration except that packages whose file name starts a-n
      --  are OK (these are children of Ada.Numerics, and such packages
      --  are never loaded by Rtsfind).

      if Is_Predefined_File_Name (Unit_File_Name (Current_Sem_Unit))
        and then Name_Buffer (1 .. 3) /= "a-n"
        and then
          Nkind (Unit (Cunit (Current_Sem_Unit))) = N_Package_Declaration
      then
         Error_Msg_N ("use clause not allowed in predefined spec", N);
      end if;

      --  Chain clause to list of use clauses in current scope.

      if Nkind (Parent (N)) /= N_Compilation_Unit then
         Chain_Use_Clause (N);
      end if;

      --  Loop through package names to identify referenced packages

      Pack_Name := First (Names (N));

      while Present (Pack_Name) loop
         Analyze (Pack_Name);

         if Nkind (Parent (N)) = N_Compilation_Unit
           and then Nkind (Pack_Name) = N_Expanded_Name
         then
            declare
               Pref : Node_Id := Prefix (Pack_Name);

            begin
               while Nkind (Pref) = N_Expanded_Name loop
                  Pref := Prefix (Pref);
               end loop;

               if Entity (Pref) = Standard_Standard then
                  Error_Msg_N
                   ("predefined package Standard cannot appear"
                     & " in a context clause", Pref);
               end if;
            end;
         end if;

         Next (Pack_Name);
      end loop;

      --  Loop through package names to mark all entities as potentially
      --  use visible.

      Pack_Name := First (Names (N));

      while Present (Pack_Name) loop

         if Is_Entity_Name (Pack_Name) then
            Pack := Entity (Pack_Name);

            if Ekind (Pack) /= E_Package
              and then Etype (Pack) /= Any_Type
            then
               if Ekind (Pack) = E_Generic_Package then
                  Error_Msg_N
                   ("a generic package is not allowed in a use clause",
                      Pack_Name);
               else
                  Error_Msg_N ("& is not a usable package", Pack_Name);
               end if;

            else
               if Nkind (Parent (N)) = N_Compilation_Unit then
                  Check_In_Previous_With_Clause (N, Pack_Name);
               end if;

               if Applicable_Use (Pack_Name) then
                  Use_One_Package (Pack, N);
               end if;
            end if;
         end if;

         Next (Pack_Name);
      end loop;

   end Analyze_Use_Package;

   --------------------
   -- Applicable_Use --
   --------------------

   function Applicable_Use (Pack_Name : Node_Id) return Boolean is
      Pack : constant Entity_Id := Entity (Pack_Name);

   begin
      if In_Open_Scopes (Pack) then
         return False;

      elsif In_Use (Pack) then
         Set_Redundant_Use (Pack_Name, True);
         return False;

      elsif Present (Renamed_Object (Pack))
        and then In_Use (Renamed_Object (Pack))
      then
         Set_Redundant_Use (Pack_Name, True);
         return False;

      else
         return True;
      end if;
   end Applicable_Use;

   ----------------------
   -- Chain_Use_Clause --
   ----------------------

   procedure Chain_Use_Clause (N : Node_Id) is
   begin
      Set_Next_Use_Clause (N,
        Scope_Stack.Table (Scope_Stack.Last).First_Use_Clause);
      Scope_Stack.Table (Scope_Stack.Last).First_Use_Clause := N;
   end Chain_Use_Clause;

   ----------------------------
   --  Check_Frozen_Renaming --
   ----------------------------

   procedure Check_Frozen_Renaming (N : Node_Id; Subp : Entity_Id) is
      B_Node : Node_Id;
      Old_S  : Entity_Id;

   begin
      if Is_Frozen (Subp)
        and then not Has_Completion (Subp)
      then
         B_Node :=
           Build_Renamed_Body
             (Parent (Declaration_Node (Subp)), Defining_Entity (N));

         if Is_Entity_Name (Name (N)) then
            Old_S := Entity (Name (N));

--              if not Is_Frozen (Old_S)
--                and then Operating_Mode /= Check_Semantics
--              then
--                 Append_Freeze_Action (Old_S, B_Node);
--              else
               Insert_After (N, B_Node);
               Analyze (B_Node);
            --end if;

            if Is_Intrinsic_Subprogram (Old_S)
              and then not In_Instance
            then
               Error_Msg_N
                 ("subprogram used in renaming_as_body cannot be intrinsic",
                    Name (N));
            end if;

         else
            Insert_After (N, B_Node);
            Analyze (B_Node);
         end if;
      end if;
   end Check_Frozen_Renaming;

   -----------------------------------
   -- Check_In_Previous_With_Clause --
   -----------------------------------

   procedure Check_In_Previous_With_Clause
     (N   : Node_Id;
      Nam : Entity_Id)
   is
      Pack : constant Entity_Id := Entity (Original_Node (Nam));
      Item : Node_Id;
      Par  : Node_Id;

   begin
      Item := First (Context_Items (Parent (N)));

      while Present (Item)
        and then Item /= N
      loop
         if Nkind (Item) = N_With_Clause
           and then Entity (Name (Item)) = Pack
         then
            Par := Nam;

            --  Find root library unit in with_clause.

            while Nkind (Par) = N_Expanded_Name loop
               Par := Prefix (Par);
            end loop;

            if Is_Child_Unit (Entity (Original_Node (Par))) then
               Error_Msg_NE
                 ("& is not directly visible", Par, Entity (Par));
            else
               return;
            end if;
         end if;

         Next (Item);
      end loop;

      --  On exit, package is not mentioned in a previous with_clause.
      --  Check if its prefix is.

      if Nkind (Nam) = N_Expanded_Name then
         Check_In_Previous_With_Clause (N, Prefix (Nam));

      elsif Pack /= Any_Id then
         Error_Msg_NE ("& is not visible", Nam, Pack);
      end if;
   end Check_In_Previous_With_Clause;

   ---------------------------------
   -- Check_Library_Unit_Renaming --
   ---------------------------------

   procedure Check_Library_Unit_Renaming (N : Node_Id; Old_E : Entity_Id) is
      New_E : Entity_Id;

   begin
      if Nkind (Parent (N)) /= N_Compilation_Unit then
         return;

      elsif Scope (Old_E) /= Standard_Standard
        and then not Is_Child_Unit (Old_E)
      then
         Error_Msg_N ("renamed unit must be a library unit", Name (N));

      elsif Present (Parent_Spec (N))
        and then Nkind (Unit (Parent_Spec (N))) = N_Generic_Package_Declaration
        and then not Is_Child_Unit (Old_E)
      then
         Error_Msg_N
           ("renamed unit must be a child unit of generic parent", Name (N));

      elsif Nkind (N) in N_Generic_Renaming_Declaration
         and then  Nkind (Name (N)) = N_Expanded_Name
         and then Is_Generic_Instance (Entity (Prefix (Name (N))))
         and then Is_Generic_Unit (Old_E)
      then
         Error_Msg_N
           ("renamed generic unit must be a library unit", Name (N));

      elsif Ekind (Old_E) = E_Package
        or else Ekind (Old_E) = E_Generic_Package
      then
         --  Inherit categorization flags

         New_E := Defining_Entity (N);
         Set_Is_Pure                  (New_E, Is_Pure           (Old_E));
         Set_Is_Preelaborated         (New_E, Is_Preelaborated  (Old_E));
      end if;
   end Check_Library_Unit_Renaming;

   ---------------
   -- End_Scope --
   ---------------

   procedure End_Scope is
      Id    : Entity_Id;
      Prev  : Entity_Id;
      Outer : Entity_Id;

   begin
      Id := First_Entity (Current_Scope);

      while Present (Id) loop
         --  An entity in the current scope is not necessarily the first one
         --  on its homonym chain. Find its predecessor if any,
         --  If it is an internal entity, it will not be in the visibility
         --  chain altogether,  and there is nothing to unchain.

         if Id /= Current_Entity (Id) then
            Prev := Current_Entity (Id);
            while Present (Prev)
              and then Present (Homonym (Prev))
              and then Homonym (Prev) /= Id
            loop
               Prev := Homonym (Prev);
            end loop;

            --  Skip to end of loop if Id is not in the visibility chain

            if No (Prev) or else Homonym (Prev) /= Id then
               goto Next_Ent;
            end if;

         else
            Prev := Empty;
         end if;

         Outer := Homonym (Id);
         Set_Is_Immediately_Visible (Id, False);

         while Present (Outer) and then Scope (Outer) = Current_Scope loop
            Outer := Homonym (Outer);
         end loop;

         --  Reset homonym link of other entities, but do not modify link
         --  between entities in current scope, so that the back-end can have
         --  a proper count of local overloadings.

         if No (Prev) then
            Set_Name_Entity_Id (Chars (Id), Outer);

         elsif Scope (Prev) /= Scope (Id) then
            Set_Homonym (Prev,  Outer);
         end if;

         <<Next_Ent>>
            Next_Entity (Id);
      end loop;

      --  If the scope generated freeze actions, place them before the
      --  current declaration and analyze them. Type declarations and
      --  the bodies of initialization procedures can generate such nodes.
      --  We follow the parent chain until we reach a list node, which is
      --  the enclosing list of declarations. If the list appears within
      --  a protected definition, move freeze nodes outside the protected
      --  type altogether.

      if Present
         (Scope_Stack.Table (Scope_Stack.Last).Pending_Freeze_Actions)
      then
         declare
            Decl : Node_Id;
            L    : constant List_Id := Scope_Stack.Table
                    (Scope_Stack.Last).Pending_Freeze_Actions;

         begin
            if Is_Itype (Current_Scope) then
               Decl := Associated_Node_For_Itype (Current_Scope);
            else
               Decl := Parent (Current_Scope);
            end if;

            Pop_Scope;

            while not (Is_List_Member (Decl))
            loop
               Decl := Parent (Decl);
            end loop;

            Insert_List_Before_And_Analyze (Decl, L);
         end;

      else
         Pop_Scope;
      end if;

   end End_Scope;

   ---------------------
   -- End_Use_Clauses --
   ---------------------

   procedure End_Use_Clauses (Clause : Node_Id) is
      U   : Node_Id;

   begin
      U := Clause;
      while Present (U) loop
         if Nkind (U) = N_Use_Package_Clause then
            End_Use_Package (U);
         end if;

         Next_Use_Clause (U);
      end loop;
   end End_Use_Clauses;

   ---------------------
   -- End_Use_Package --
   ---------------------

   procedure End_Use_Package (N : Node_Id) is
      Pack_Name : Node_Id;
      Pack      : Entity_Id;
      Id        : Entity_Id;
      Elmt      : Elmt_Id;

      function Is_Primitive_Operator
        (Op   : Entity_Id;
         F    : Entity_Id)
         return Boolean;
      --  Check whether Op is a primitive operator of a use-visible type

      ---------------------------
      -- Is_Primitive_Operator --
      ---------------------------

      function Is_Primitive_Operator
        (Op   : Entity_Id;
         F    : Entity_Id)
         return Boolean
      is
         T : constant Entity_Id := Etype (F);

      begin
         return In_Use (T)
           and then Scope (T) = Scope (Op);
      end Is_Primitive_Operator;

   --  Start of processing for End_Use_Package

   begin
      Pack_Name := First (Names (N));

      while Present (Pack_Name) loop
         Pack := Entity (Pack_Name);

         if Ekind (Pack) = E_Package then

            if In_Open_Scopes (Pack) then
               null;

            elsif not Redundant_Use (Pack_Name) then
               Set_In_Use (Pack, False);
               Id := First_Entity (Pack);

               while Present (Id) loop

                  --  Preserve use-visibility of operators that are primitive
                  --  operators of a type that is use_visible through an active
                  --  use_type clause.

--                    if Nkind (Id) = N_Defining_Operator_Symbol
--                         and then
--                           (Is_Primitive_Operator (Id, First_Formal (Id))
--                              or else
--                            (Present (Next_Formal (First_Formal (Id)))
--                               and then
--                                 Is_Primitive_Operator
--                                   (Id, Next_Formal (First_Formal (Id)))))
--                    then
--                       null;
--  
--                    else
                     Set_Is_Potentially_Use_Visible (Id, False);
--                  end if;

                  if Is_Private_Type (Id)
                    and then Present (Full_View (Id))
                  then
                     Set_Is_Potentially_Use_Visible (Full_View (Id), False);
                  end if;

                  Next_Entity (Id);
               end loop;

               if Present (Renamed_Object (Pack)) then
                  Set_In_Use (Renamed_Object (Pack), False);
               end if;

               if Chars (Pack) = Name_System
                 and then Scope (Pack) = Standard_Standard
                 and then Present_System_Aux
               then
                  Id := First_Entity (System_Aux_Id);

                  while Present (Id) loop
                     Set_Is_Potentially_Use_Visible (Id, False);

                     if Is_Private_Type (Id)
                       and then Present (Full_View (Id))
                     then
                        Set_Is_Potentially_Use_Visible (Full_View (Id), False);
                     end if;

                     Next_Entity (Id);
                  end loop;

                  Set_In_Use (System_Aux_Id, False);
               end if;

            else
               Set_Redundant_Use (Pack_Name, False);
            end if;

         end if;

         Next (Pack_Name);
      end loop;

      if Present (Hidden_By_Use_Clause (N)) then
         Elmt := First_Elmt (Hidden_By_Use_Clause (N));

         while Present (Elmt) loop
            Set_Is_Immediately_Visible (Node (Elmt));
            Next_Elmt (Elmt);
         end loop;

         Set_Hidden_By_Use_Clause (N, No_Elist);
      end if;
   end End_Use_Package;

   ----------------------
   -- Find_Direct_Name --
   ----------------------

   procedure Find_Direct_Name (N : Node_Id) is
      E    : Entity_Id;
      E2   : Entity_Id;
      Msg  : Boolean;

      Inst : Entity_Id := Empty;
      --  Enclosing instance, if any.

      Homonyms : Entity_Id;
      --  Saves start of homonym chain

      Nvis_Entity : Boolean;
      --  Set True to indicate that at there is at least one entity on the
      --  homonym chain which, while not visible, is visible enough from the
      --  user point of view to warrant an error message of "not visible"
      --  rather than undefined.

      function From_Actual_Package (E : Entity_Id) return Boolean;
      --  Returns true if the entity is declared in a package that is
      --  an actual for a formal package of the current instance. Such an
      --  entity requires special handling because it may be use-visible
      --  but hides directly visible entities defined outside the instance.

      function Known_But_Invisible (E : Entity_Id) return Boolean;
      --  This function determines whether the entity E (which is not
      --  visible) can reasonably be considered to be known to the writer
      --  of the reference. This is a heuristic test, used only for the
      --  purposes of figuring out whether we prefer to complain that an
      --  entity is undefined or invisible (and identify the declaration
      --  of the invisible entity in the latter case). The point here is
      --  that we don't want to complain that something is invisible and
      --  then point to something entirely mysterious to the writer.

      procedure Nvis_Messages;
      --  Called if there are no visible entries for N, but there is at least
      --  one non-directly visible, or hidden declaration. This procedure
      --  outputs an appropriate set of error messages.

      procedure Undefined (Nvis : Boolean);
      --  This function is called if the current node has no corresponding
      --  visible entity or entities. The value set in Msg indicates whether
      --  an error message was generated (multiple error messages for the
      --  same variable are generally suppressed, see body for details).
      --  Msg is True if an error message was generated, False if not. This
      --  value is used by the caller to determine whether or not to output
      --  additional messages where appropriate. The parameter is set False
      --  to get the message "X is undefined", and True to get the message
      --  "X is not visible".

      -------------------------
      -- From_Actual_Package --
      -------------------------

      function From_Actual_Package (E : Entity_Id) return Boolean is
         Scop : constant Entity_Id := Scope (E);
         Act  : Entity_Id;

      begin
         if not In_Instance then
            return False;
         else
            Inst := Current_Scope;

            while Present (Inst)
              and then Ekind (Inst) /= E_Package
              and then not Is_Generic_Instance (Inst)
            loop
               Inst := Scope (Inst);
            end loop;

            if No (Inst) then
               return False;
            end if;

            Act := First_Entity (Inst);

            while Present (Act) loop
               if Ekind (Act) = E_Package then

                  --  Check for end of actuals list

                  if Renamed_Object (Act) = Inst then
                     return False;

                  elsif Present (Associated_Formal_Package (Act))
                    and then Renamed_Object (Act) = Scop
                  then
                     --  Entity comes from (instance of) formal package

                     return True;

                  else
                     Next_Entity (Act);
                  end if;

               else
                  Next_Entity (Act);
               end if;
            end loop;

            return False;
         end if;
      end From_Actual_Package;

      -------------------------
      -- Known_But_Invisible --
      -------------------------

      function Known_But_Invisible (E : Entity_Id) return Boolean is
         Fname : File_Name_Type;

      begin
         --  Entities in Standard are always considered to be known

         if Sloc (E) <= Standard_Location then
            return True;

         --  An entity that does not come from source is always considered
         --  to be unknown, since it is an artifact of code expansion.

         elsif not Comes_From_Source (E) then
            return False;

         --  In gnat internal mode, we consider all entities known

         elsif GNAT_Mode then
            return True;
         end if;

         --  Here we have an entity that is not from package Standard, and
         --  which comes from Source. See if it comes from an internal file.

         Fname := Unit_File_Name (Get_Source_Unit (E));

         --  Case of from internal file

         if Is_Internal_File_Name (Fname) then

            --  Private part entities in internal files are never considered
            --  to be known to the writer of normal application code.

            if Is_Hidden (E) then
               return False;
            end if;

            --  Entities from System packages other than System and
            --  System.Storage_Elements are not considered to be known.
            --  System.Auxxxx files are also considered known to the user.

            --  Should refine this at some point to generally distinguish
            --  between known and unknown internal files ???

            Get_Name_String (Fname);

            return
              Name_Len < 2
                or else
              Name_Buffer (1 .. 2) /= "s-"
                or else
              Name_Buffer (3 .. 8) = "stoele"
                or else
              Name_Buffer (3 .. 5) = "aux";

         --  If not an internal file, then entity is definitely known,
         --  even if it is in a private part (the message generated will
         --  note that it is in a private part)

         else
            return True;
         end if;
      end Known_But_Invisible;

      -------------------
      -- Nvis_Messages --
      -------------------

      procedure Nvis_Messages is
         Ent    : Entity_Id;
         Hidden : Boolean := False;

      begin
         Undefined (Nvis => True);

         if Msg then

            --  First loop does hidden declarations

            Ent := Homonyms;
            while Present (Ent) loop
               if Is_Potentially_Use_Visible (Ent) then

                  if not Hidden then
                     Error_Msg_N ("multiple use clauses cause hiding!", N);
                     Hidden := True;
                  end if;

                  Error_Msg_Sloc := Sloc (Ent);
                  Error_Msg_N ("hidden declaration#!", N);
               end if;

               Ent := Homonym (Ent);
            end loop;

            --  If we found hidden declarations, then that's enough, don't
            --  bother looking for non-visible declarations as well.

            if Hidden then
               return;
            end if;

            --  Second loop does non-directly visible declarations

            Ent := Homonyms;
            while Present (Ent) loop
               if not Is_Potentially_Use_Visible (Ent) then

                  --  Do not bother the user with unknown entities

                  if not Known_But_Invisible (Ent) then
                     goto Continue;
                  end if;

                  Error_Msg_Sloc := Sloc (Ent);

                  --  Output message noting that there is a non-visible
                  --  declaration, distinguishing the private part case.

                  if Is_Hidden (Ent) then
                     Error_Msg_N ("non-visible (private) declaration#!", N);
                  else
                     Error_Msg_N ("non-visible declaration#!", N);

                     if Is_Compilation_Unit (Ent)
                       and then
                         Nkind (Parent (Parent (N))) = N_Use_Package_Clause
                     then
                        Error_Msg_NE
                         ("\possibly missing with_clause for&", N, Ent);
                     end if;
                  end if;

                  --  Set entity and its containing package as referenced. We
                  --  can't be sure of this, but this seems a better choice
                  --  to avoid unused entity messages.

                  if Comes_From_Source (Ent) then
                     Set_Referenced (Ent);
                     Set_Referenced (Cunit_Entity (Get_Source_Unit (Ent)));
                  end if;
               end if;

               <<Continue>>
               Ent := Homonym (Ent);
            end loop;

         end if;
      end Nvis_Messages;

      ---------------
      -- Undefined --
      ---------------

      procedure Undefined (Nvis : Boolean) is
         Emsg : Error_Msg_Id;

      begin
         --  We should never find an undefined internal name. If we do, then
         --  see if we have previous errors. If so, ignore on the grounds that
         --  it is probably a cascaded message (e.g. a block label from a badly
         --  formed block). If no previous errors, then we have a real internal
         --  error of some kind so raise an exception.

         if Is_Internal_Name (Chars (N)) then
            if Total_Errors_Detected /= 0 then
               return;
            else
               raise Program_Error;
            end if;
         end if;

         --  A very specialized error check, if the undefined variable is
         --  a case tag, and the case type is an enumeration type, check
         --  for a possible misspelling, and if so, modify the identifier

         --  Named aggregate should also be handled similarly ???

         if Nkind (N) = N_Identifier
           and then Nkind (Parent (N)) = N_Case_Statement_Alternative
         then
            Get_Name_String (Chars (N));

            declare
               Case_Str : constant String    := Name_Buffer (1 .. Name_Len);
               Case_Stm : constant Node_Id   := Parent (Parent (N));
               Case_Typ : constant Entity_Id := Etype (Expression (Case_Stm));

               Lit : Node_Id;

            begin
               if Is_Enumeration_Type (Case_Typ)
                 and then Case_Typ /= Standard_Character
                 and then Case_Typ /= Standard_Wide_Character
               then
                  Lit := First_Literal (Case_Typ);
                  Get_Name_String (Chars (Lit));

                  if Chars (Lit) /= Chars (N)
                    and then Is_Bad_Spelling_Of
                      (Case_Str, Name_Buffer (1 .. Name_Len))
                  then
                     Error_Msg_Node_2 := Lit;
                     Error_Msg_N
                       ("& is undefined, assume misspelling of &", N);
                     Rewrite (N, New_Occurrence_Of (Lit, Sloc (N)));
                     return;
                  end if;

                  Lit := Next_Literal (Lit);
               end if;
            end;
         end if;

         --  Normal processing

         Set_Entity (N, Any_Id);
         Set_Etype  (N, Any_Type);

         --  We use the table Urefs to keep track of entities for which we
         --  have issued errors for undefined references. Multiple errors
         --  for a single name are normally suppressed, however we modify
         --  the error message to alert the programmer to this effect.

         for J in Urefs.First .. Urefs.Last loop
            if Chars (N) = Chars (Urefs.Table (J).Node) then
               if Urefs.Table (J).Err /= No_Error_Msg
                 and then Sloc (N) /= Urefs.Table (J).Loc
               then
                  Error_Msg_Node_1 := Urefs.Table (J).Node;

                  if Urefs.Table (J).Nvis then
                     Change_Error_Text (Urefs.Table (J).Err,
                       "& is not visible (more references follow)");
                  else
                     Change_Error_Text (Urefs.Table (J).Err,
                       "& is undefined (more references follow)");
                  end if;

                  Urefs.Table (J).Err := No_Error_Msg;
               end if;

               --  Although we will set Msg False, and thus suppress the
               --  message, we also set Error_Posted True, to avoid any
               --  cascaded messages resulting from the undefined reference.

               Msg := False;
               Set_Error_Posted (N, True);
               return;
            end if;
         end loop;

         --  If entry not found, this is first undefined occurrence

         if Nvis then
            Error_Msg_N ("& is not visible!", N);
            Emsg := Get_Msg_Id;

         else
            Error_Msg_N ("& is undefined!", N);
            Emsg := Get_Msg_Id;

            --  Now check for possible misspellings

            Get_Name_String (Chars (N));

            declare
               E      : Entity_Id;
               Ematch : Entity_Id := Empty;

               Last_Name_Id : constant Name_Id :=
                                Name_Id (Nat (First_Name_Id) +
                                           Name_Entries_Count - 1);

               S  : constant String (1 .. Name_Len) :=
                      Name_Buffer (1 .. Name_Len);

            begin
               for N in First_Name_Id .. Last_Name_Id loop
                  E := Get_Name_Entity_Id (N);

                  if Present (E)
                     and then (Is_Immediately_Visible (E)
                                 or else
                               Is_Potentially_Use_Visible (E))
                  then
                     Get_Name_String (N);

                     if Is_Bad_Spelling_Of
                          (Name_Buffer (1 .. Name_Len), S)
                     then
                        Ematch := E;
                        exit;
                     end if;
                  end if;
               end loop;

               if Present (Ematch) then
                  Error_Msg_NE ("\possible misspelling of&", N, Ematch);
               end if;
            end;
         end if;

         --  Make entry in undefined references table unless the full
         --  errors switch is set, in which case by refraining from
         --  generating the table entry, we guarantee that we get an
         --  error message for every undefined reference.

         if not All_Errors_Mode then
            Urefs.Increment_Last;
            Urefs.Table (Urefs.Last).Node := N;
            Urefs.Table (Urefs.Last).Err  := Emsg;
            Urefs.Table (Urefs.Last).Nvis := Nvis;
            Urefs.Table (Urefs.Last).Loc  := Sloc (N);
         end if;

         Msg := True;
      end Undefined;

   --  Start of processing for Find_Direct_Name

   begin
      --  If the entity pointer is already set, this is an internal node, or
      --  a node that is analyzed more than once, after a tree modification.
      --  In such a case there is no resolution to perform, just set the type.

      if Present (Entity (N)) then
         if Is_Type (Entity (N)) then
            Set_Etype (N, Entity (N));

         else
            declare
               Entyp : constant Entity_Id := Etype (Entity (N));

            begin
               --  One special case here. If the Etype field is already set,
               --  and references the packed array type corresponding to the
               --  etype of the referenced entity, then leave it alone. This
               --  happens for trees generated from Exp_Pakd, where expressions
               --  can be deliberately "mis-typed" to the packed array type.

               if Is_Array_Type (Entyp)
                 and then Is_Packed (Entyp)
                 and then Present (Etype (N))
                 and then Etype (N) = Packed_Array_Type (Entyp)
               then
                  null;

               --  If not that special case, then just reset the Etype

               else
                  Set_Etype (N, Etype (Entity (N)));
               end if;
            end;
         end if;

         return;
      end if;

      --  Here if Entity pointer was not set, we need full visibility analysis
      --  First we generate debugging output if the debug E flag is set.

      if Debug_Flag_E then
         Write_Str ("Looking for ");
         Write_Name (Chars (N));
         Write_Eol;
      end if;

      Homonyms := Current_Entity (N);
      Nvis_Entity := False;

      E := Homonyms;
      while Present (E) loop

         --  If entity is immediately visible or potentially use
         --  visible, then process the entity and we are done.

         if Is_Immediately_Visible (E) then
            goto Immediately_Visible_Entity;

         elsif Is_Potentially_Use_Visible (E) then
            goto Potentially_Use_Visible_Entity;

         --  Note if a known but invisible entity encountered

         elsif Known_But_Invisible (E) then
            Nvis_Entity := True;
         end if;

         --  Move to next entity in chain and continue search

         E := Homonym (E);
      end loop;

      --  If no entries on homonym chain that were potentially visible,
      --  and no entities reasonably considered as non-visible, then
      --  we have a plain undefined reference, with no additional
      --  explanation required!

      if not Nvis_Entity then
         Undefined (Nvis => False);

      --  Otherwise there is at least one entry on the homonym chain that
      --  is reasonably considered as being known and non-visible.

      else
         Nvis_Messages;
      end if;

      return;

      --  Processing for a potentially use visible entry found. We must search
      --  the rest of the homonym chain for two reasons. First, if there is a
      --  directly visible entry, then none of the potentially use-visible
      --  entities are directly visible (RM 8.4(10)). Second, we need to check
      --  for the case of multiple potentially use-visible entries hiding one
      --  another and as a result being non-directly visible (RM 8.4(11)).

      <<Potentially_Use_Visible_Entity>> declare
         Only_One_Visible : Boolean := True;
         All_Overloadable : Boolean := Is_Overloadable (E);

      begin
         E2 := Homonym (E);

         while Present (E2) loop
            if Is_Immediately_Visible (E2) then

               --  If the use-visible entity comes from the actual for a
               --  formal package, it hides a directly visible entity from
               --  outside the instance.

               if From_Actual_Package (E)
                 and then Scope_Depth (E2) < Scope_Depth (Inst)
               then
                  goto Found;
               else
                  E := E2;
                  goto Immediately_Visible_Entity;
               end if;

            elsif Is_Potentially_Use_Visible (E2) then
               Only_One_Visible := False;
               All_Overloadable := All_Overloadable and Is_Overloadable (E2);
            end if;

            E2 := Homonym (E2);
         end loop;

         --  On falling through this loop, we have checked that there are no
         --  immediately visible entities. Only_One_Visible is set if exactly
         --  one potentially use visible entity exists. All_Overloadable is
         --  set if all the potentially use visible entities are overloadable.
         --  The condition for legality is that either there is one potentially
         --  use visible entity, or if there is more than one, then all of them
         --  are overloadable.

         if Only_One_Visible or All_Overloadable then
            goto Found;

         --  If there is more than one potentially use-visible entity and at
         --  least one of them non-overloadable, we have an error (RM 8.4(11).
         --  Note that E points to the first such entity on the homonym list.
         --  Special case: if one of the entities is declared in an actual
         --  package, it was visible in the generic, and takes precedence over
         --  other entities that are potentially use-visible. Same if it is
         --  declared in a local instantiation of the current instance.

         else
            if In_Instance then
               Inst := Current_Scope;

               --  Find current instance.

               while Present (Inst)
                 and then Inst /= Standard_Standard
               loop
                  if Is_Generic_Instance (Inst) then
                     exit;
                  end if;

                  Inst := Scope (Inst);
               end loop;

               E2 := E;

               while Present (E2) loop
                  if From_Actual_Package (E2)
                    or else
                      (Is_Generic_Instance (Scope (E2))
                        and then Scope_Depth (Scope (E2)) > Scope_Depth (Inst))
                  then
                     E := E2;
                     goto Found;
                  end if;

                  E2 := Homonym (E2);
               end loop;

               Nvis_Messages;
               return;

            else
               Nvis_Messages;
               return;
            end if;
         end if;
      end;

      --  Come here with E set to the first immediately visible entity on
      --  the homonym chain. This is the one we want unless there is another
      --  immediately visible entity further on in the chain for a more
      --  inner scope (RM 8.3(8)).

      <<Immediately_Visible_Entity>> declare
         Level : Int;
         Scop  : Entity_Id;

      begin
         --  Find scope level of initial entity. When compiling  through
         --  Rtsfind, the previous context is not completely invisible, and
         --  an outer entity may appear on the chain, whose scope is below
         --  the entry for Standard that delimits the current scope stack.
         --  Indicate that the level for this spurious entry is outside of
         --  the current scope stack.

         Level := Scope_Stack.Last;
         loop
            Scop := Scope_Stack.Table (Level).Entity;
            exit when Scop = Scope (E);
            Level := Level - 1;
            exit when Scop = Standard_Standard;
         end loop;

         --  Now search remainder of homonym chain for more inner entry
         --  If the entity is Standard itself, it has no scope, and we
         --  compare it with the stack entry directly.

         E2 := Homonym (E);
         while Present (E2) loop
            if Is_Immediately_Visible (E2) then
               for J in Level + 1 .. Scope_Stack.Last loop
                  if Scope_Stack.Table (J).Entity = Scope (E2)
                    or else Scope_Stack.Table (J).Entity = E2
                  then
                     Level := J;
                     E := E2;
                     exit;
                  end if;
               end loop;
            end if;

            E2 := Homonym (E2);
         end loop;

         --  At the end of that loop, E is the innermost immediately
         --  visible entity, so we are all set.
      end;

      --  Come here with entity found, and stored in E

      <<Found>> begin

         Set_Entity (N, E);

         if Is_Type (E) then
            Set_Etype (N, E);
         else
            Set_Etype (N, Get_Full_View (Etype (E)));
         end if;

         if Debug_Flag_E then
            Write_Str (" found  ");
            Write_Entity_Info (E, "      ");
         end if;

         --  If the Ekind of the entity is Void, it means that all homonyms
         --  are hidden from all visibility (RM 8.3(5,14-20)). However, this
         --  test is skipped if the current scope is a record and the name is
         --  a pragma argument expression (case of Atomic and Volatile pragmas
         --  and possibly other similar pragmas added later, which are allowed
         --  to reference components in the current record).

         if Ekind (E) = E_Void
           and then
             (not Is_Record_Type (Current_Scope)
               or else Nkind (Parent (N)) /= N_Pragma_Argument_Association)
         then
            Premature_Usage (N);

         --  If the entity is overloadable, collect all interpretations
         --  of the name for subsequent overload resolution. We optimize
         --  a bit here to do this only if we have an overloadable entity
         --  that is not on its own on the homonym chain.

         elsif Is_Overloadable (E)
           and then (Present (Homonym (E)) or else Current_Entity (N) /= E)
         then
            Collect_Interps (N);

         --  Case of non-overloadable entity, set the entity providing that
         --  we do not have the case of a discriminant reference within a
         --  default expression. Such references are replaced with the
         --  corresponding discriminal, which is the formal corresponding to
         --  to the discriminant in the initialization procedure.

         else
            --  Entity is unambiguous, indicate that it is referenced here
            --  One slightly odd case is that we do not want to set the
            --  Referenced flag if the entity is a label, and the identifier
            --  is the label in the source, since this is not a reference
            --  from the point of view of the user

            if Nkind (Parent (N)) = N_Label then
               declare
                  R : constant Boolean := Referenced (E);

               begin
                  Set_Referenced (E, R);
               end;

            end if;

            --  Set Entity, with style check if need be. If this is a
            --  discriminant reference, it must be replaced by the
            --  corresponding discriminal, that is to say the parameter
            --  of the initialization procedure that corresponds to the
            --  discriminant. If this replacement is being performed, there
            --  is no style check to perform.

            --  This replacement must not be done if we are currently
            --  processing a generic spec or body, because the discriminal
            --  has not been not generated in this case.

            if not In_Default_Expression
              or else Inside_A_Generic
            then
               Set_Entity (N, E);
            end if;
         end if;
      end;
   end Find_Direct_Name;

   ------------------------
   -- Find_Expanded_Name --
   ------------------------

   --  This routine searches the homonym chain of the entity until it finds
   --  an entity declared in the scope denoted by the prefix. If the entity
   --  is private, it may nevertheless be immediately visible, if we are in
   --  the scope of its declaration.

   procedure Find_Expanded_Name (N : Node_Id) is
      Selector  : constant Node_Id := Selector_Name (N);
      Candidate : Entity_Id        := Empty;
      P_Name    : Entity_Id;
      O_Name    : Entity_Id;
      Id        : Entity_Id;

   begin
      P_Name := Entity (Prefix (N));
      O_Name := P_Name;

      --  If the prefix is a renamed package, look for the entity
      --  in the original package.

      if Ekind (P_Name) = E_Package
        and then Present (Renamed_Object (P_Name))
      then
         P_Name := Renamed_Object (P_Name);

         --  Rewrite node with entity field pointing to renamed object

         Rewrite (Prefix (N), New_Copy (Prefix (N)));
         Set_Entity (Prefix (N), P_Name);
      end if;

      Id := Current_Entity (Selector);

      while Present (Id) loop

         if Scope (Id) = P_Name then
            Candidate := Id;

            if Is_Child_Unit (Id) then
               exit when Is_Visible_Child_Unit (Id)
                 or else Is_Immediately_Visible (Id);

            else
               exit when not Is_Hidden (Id)
                 or else Is_Immediately_Visible (Id);
            end if;
         end if;

         Id := Homonym (Id);
      end loop;

      if No (Id)
        and then (Ekind (P_Name) = E_Procedure
                    or else
                  Ekind (P_Name) = E_Function)
        and then Is_Generic_Instance (P_Name)
      then
         --  Expanded name denotes entity in (instance of) generic subprogram.
         --  The entity may be in the subprogram instance, or may denote one of
         --  the formals, which is declared in the enclosing wrapper package.

         P_Name := Scope (P_Name);
         Id := Current_Entity (Selector);

         while Present (Id) loop
            exit when  Scope (Id) = P_Name;
            Id := Homonym (Id);
         end loop;
      end if;

      if No (Id) or else Chars (Id) /=  Chars (Selector) then

         Set_Etype (N, Any_Type);

         --  If we are looking for an entity defined in System, try to
         --  find it in the child package that may have been provided as
         --  an extension to System. The Extend_System pragma will have
         --  supplied the name of the extension, which may have to be loaded.

         if Chars (P_Name) = Name_System
           and then Scope (P_Name) = Standard_Standard
           and then Present (System_Extend_Unit)
           and then Present_System_Aux (N)
         then
            Set_Entity (Prefix (N), System_Aux_Id);
            Find_Expanded_Name (N);
            return;

--           elsif Nkind (Selector) = N_Operator_Symbol
--             and then Has_Implicit_Operator (N)
--           then
--              --  There is an implicit instance of the predefined operator in
--              --  the given scope. The operator entity is defined in Standard.
--              --  Has_Implicit_Operator makes the node into an Expanded_Name.
--  
--              return;

         elsif Nkind (Selector) = N_Character_Literal
           and then Has_Implicit_Character_Literal (N)
         then
            --  If there is no literal defined in the scope denoted by the
            --  prefix, the literal may belong to (a type derived from)
            --  Standard_Character, for which we have no explicit literals.

            return;

         else
            --  If the prefix is a single concurrent object, use its
            --  name in  the error message, rather than that of the
            --  anonymous type.

	    Error_Msg_Node_2 := P_Name;

            if P_Name = System_Aux_Id then
               P_Name := Scope (P_Name);
               Set_Entity (Prefix (N), P_Name);
            end if;

            if Present (Candidate) then

               if Is_Child_Unit (Candidate) then
                  Error_Msg_N
                    ("missing with_clause for child unit &", Selector);
               else
                  Error_Msg_NE ("& is not a visible entity of&", N, Selector);
               end if;

            else
               --  Within the instantiation of a child unit, the prefix may
               --  denote the parent instance, but the selector has the
               --  name of the original child. Find whether we are within
               --  the corresponding instance, and get the proper entity, which
               --  can only be an enclosing scope.

               if O_Name /= P_Name
                 and then In_Open_Scopes (P_Name)
                 and then Is_Generic_Instance (P_Name)
               then
                  declare
                     S : Entity_Id := Current_Scope;
                     P : Entity_Id;

                  begin
                     for J in reverse 0 .. Scope_Stack.Last loop
                        S := Scope_Stack.Table (J).Entity;

                        exit when S = Standard_Standard;

                        if Ekind (S) = E_Function
                          or else Ekind (S) = E_Package
                          or else Ekind (S) = E_Procedure
                        then
                           P := Generic_Parent (Specification
                                  (Unit_Declaration_Node (S)));

                           if Present (P)
                             and then Chars (Scope (P)) = Chars (O_Name)
                             and then Chars (P) = Chars (Selector)
                           then
                              Id := S;
                              goto found;
                           end if;
                        end if;

                     end loop;
                  end;
               end if;

               if Chars (P_Name) = Name_Ada
                 and then Scope (P_Name) = Standard_Standard
               then
                  Error_Msg_Node_2 := Selector;
                  Error_Msg_NE ("missing with for `&.&`", N, P_Name);

               --  If this is a selection from a dummy package, then
               --  suppress the error message, of course the entity
               --  is missing if the package is missing!

               elsif Sloc (Error_Msg_Node_2) = No_Location then
                  null;

               --  Here we have the case of an undefined component

               else

                  Error_Msg_NE ("& not declared in&", N, Selector);

                  --  Check for misspelling of some entity in prefix.

                  Id := First_Entity (P_Name);
                  Get_Name_String (Chars (Selector));

                  declare
                     S  : constant String (1 .. Name_Len) :=
                            Name_Buffer (1 .. Name_Len);
                  begin
                     while Present (Id) loop
                        Get_Name_String (Chars (Id));
                        if Is_Bad_Spelling_Of
                          (Name_Buffer (1 .. Name_Len), S)
                          and then not Is_Internal_Name (Chars (Id))
                        then
                           Error_Msg_NE
                             ("possible misspelling of&", Selector, Id);
                           exit;
                        end if;

                        Next_Entity (Id);
                     end loop;
                  end;

                  --  Specialize the message if this may be an instantiation
                  --  of a child unit that was not mentioned in the context.

                  if Nkind (Parent (N)) = N_Package_Instantiation
                    and then Is_Generic_Instance (Entity (Prefix (N)))
                    and then Is_Compilation_Unit
                     (Generic_Parent (Parent (Entity (Prefix (N)))))
                  then
                     Error_Msg_NE
                      ("\possible missing with clause on child unit&",
                        N, Selector);
                  end if;
               end if;
            end if;

            Id := Any_Id;
         end if;
      end if;

      <<found>>

      Change_Selected_Component_To_Expanded_Name (N);

      --  Do style check and generate reference, but skip both steps if this
      --  entity has homonyms, since we may not have the right homonym set
      --  yet. The proper homonym will be set during the resolve phase.

      if Has_Homonym (Id) then
         Set_Entity (N, Id);
      else
         Set_Entity (N, Id);
      end if;

      if Is_Type (Id) then
         Set_Etype (N, Id);
      else
         Set_Etype (N, Get_Full_View (Etype (Id)));
      end if;

      --  If the Ekind of the entity is Void, it means that all homonyms
      --  are hidden from all visibility (RM 8.3(5,14-20)).

      if Ekind (Id) = E_Void then
         Premature_Usage (N);

      elsif Is_Overloadable (Id)
        and then Present (Homonym (Id))
      then
         declare
            H : Entity_Id := Homonym (Id);

         begin
            while Present (H) loop
               if Scope (H) = Scope (Id) then
                  Collect_Interps (N);
                  exit;
               end if;

               H := Homonym (H);
            end loop;

            --  If an extension of System is present, collect possible
            --  explicit overloadings declared in the extension.

            if Chars (P_Name) = Name_System
              and then Scope (P_Name) = Standard_Standard
              and then Present (System_Extend_Unit)
              and then Present_System_Aux (N)
            then
               H := Current_Entity (Id);

               while Present (H) loop
                  if Scope (H) = System_Aux_Id then
                     Add_One_Interp (N, H, Etype (H));
                  end if;

                  H := Homonym (H);
               end loop;
            end if;
         end;
      end if;

--        if Nkind (Selector_Name (N)) = N_Operator_Symbol
--          and then Scope (Id) /= Standard_Standard
--        then
--           --  In addition to user-defined operators in the given scope,
--           --  there may be an implicit instance of the predefined
--           --  operator. The operator (defined in Standard) is found
--           --  in Has_Implicit_Operator, and added to the interpretations.
--           --  Procedure Add_One_Interp will determine which hides which.
--  
--           if Has_Implicit_Operator (N) then
--              null;
--           end if;
--        end if;
   end Find_Expanded_Name;

   -------------------------
   -- Find_Renamed_Entity --
   -------------------------

   function Find_Renamed_Entity
     (N         : Node_Id;
      Nam       : Node_Id;
      New_S     : Entity_Id;
      Is_Actual : Boolean := False) return Entity_Id
   is
      Ind   : Interp_Index;
      I1    : Interp_Index := 0; -- Suppress junk warnings
      It    : Interp;
      It1   : Interp;
      Old_S : Entity_Id;
      Inst  : Entity_Id;

      function Enclosing_Instance return Entity_Id;
      --  If the renaming determines the entity for the default of a formal
      --  subprogram nested within another instance, choose the innermost
      --  candidate. This is because if the formal has a box, and we are within
      --  an enclosing instance where some candidate interpretations are local
      --  to this enclosing instance, we know that the default was properly
      --  resolved when analyzing the generic, so we prefer the local
      --  candidates to those that are external. This is not always the case
      --  but is a reasonable heuristic on the use of nested generics.
      --  The proper solution requires a full renaming model.

      function Within (Inner, Outer : Entity_Id) return Boolean;
      --  Determine whether a candidate subprogram is defined within
      --  the enclosing instance. If yes, it has precedence over outer
      --  candidates.

      function Is_Visible_Operation (Op : Entity_Id) return Boolean;
      --  If the renamed entity is an implicit operator, check whether it is
      --  visible because its operand type is properly visible. This
      --  check applies to explicit renamed entities that appear in the
      --  source in a renaming declaration or a formal subprogram instance,
      --  but not to default generic actuals with a name.

      ------------------------
      -- Enclosing_Instance --
      ------------------------

      function Enclosing_Instance return Entity_Id is
         S : Entity_Id;

      begin
         if not Is_Generic_Instance (Current_Scope)
           and then not Is_Actual
         then
            return Empty;
         end if;

         S := Scope (Current_Scope);

         while S /= Standard_Standard loop

            if Is_Generic_Instance (S) then
               return S;
            end if;

            S := Scope (S);
         end loop;

         return Empty;
      end Enclosing_Instance;

      --------------------------
      -- Is_Visible_Operation --
      --------------------------

      function Is_Visible_Operation (Op : Entity_Id) return Boolean is
         Scop : Entity_Id;
         Typ  : Entity_Id;
         Btyp : Entity_Id;

      begin
         if Ekind (Op) /= E_Operator
           or else Scope (Op) /= Standard_Standard
           or else (In_Instance
                      and then
                        (not Is_Actual
                           or else Present (Enclosing_Instance)))
         then
            return True;

         else
            --  For a fixed point type operator, check the resulting type,
            --  because it may be a mixed mode integer * fixed operation.


               Typ := Etype (First_Formal (New_S));

            Btyp := Base_Type (Typ);

            if Nkind (Nam) /= N_Expanded_Name then
               return (In_Open_Scopes (Scope (Btyp))
                        or else Is_Potentially_Use_Visible (Btyp)
                        or else In_Use (Btyp)
                        or else In_Use (Scope (Btyp)));

            else
               Scop := Entity (Prefix (Nam));

               if Ekind (Scop) = E_Package
                 and then Present (Renamed_Object (Scop))
               then
                  Scop := Renamed_Object (Scop);
               end if;

               --  Operator is visible if prefix of expanded name denotes
               --  scope of type, or else type type is defined in System_Aux
               --  and the prefix denotes System.

               return Scope (Btyp) = Scop
                 or else (Scope (Btyp) = System_Aux_Id
                           and then Scope (Scope (Btyp)) = Scop);
            end if;
         end if;
      end Is_Visible_Operation;

      ------------
      -- Within --
      ------------

      function Within (Inner, Outer : Entity_Id) return Boolean is
         Sc : Entity_Id := Scope (Inner);

      begin
         while Sc /= Standard_Standard loop

            if Sc = Outer then
               return True;
            else
               Sc := Scope (Sc);
            end if;
         end loop;

         return False;
      end Within;

      function Report_Overload return Entity_Id;
      --  List possible interpretations, and specialize message in the
      --  case of a generic actual.

      function Report_Overload return Entity_Id is
      begin
         if Is_Actual then
            Error_Msg_NE
              ("ambiguous actual subprogram&, " &
                 "possible interpretations: ", N, Nam);
         else
            Error_Msg_N
              ("ambiguous subprogram, " &
                 "possible interpretations: ", N);
         end if;

         List_Interps (Nam, N);
         return Old_S;
      end Report_Overload;

   --  Start of processing for Find_Renamed_Entry

   begin
      Old_S := Any_Id;
      Candidate_Renaming := Empty;

      if not Is_Overloaded (Nam) then
         if Entity_Matches_Spec (Entity (Nam), New_S)
           and then Is_Visible_Operation (Entity (Nam))
         then
            Old_S := Entity (Nam);

         elsif
           Present (First_Formal (Entity (Nam)))
             and then Present (First_Formal (New_S))
             and then (Base_Type (Etype (First_Formal (Entity (Nam))))
                        = Base_Type (Etype (First_Formal (New_S))))
         then
            Candidate_Renaming := Entity (Nam);
         end if;

      else
         Get_First_Interp (Nam, Ind, It);

         while Present (It.Nam) loop

            if Entity_Matches_Spec (It.Nam, New_S)
               and then Is_Visible_Operation (It.Nam)
            then
               if Old_S /= Any_Id then

                  --  Note: The call to Disambiguate only happens if a
                  --  previous interpretation was found, in which case I1
                  --  has received a value.

                  It1 := Disambiguate (Nam, I1, Ind, Etype (Old_S));

                  if It1 = No_Interp then

                     Inst := Enclosing_Instance;

                     if Present (Inst) then

                        if Within (It.Nam, Inst) then
                           return (It.Nam);

                        elsif Within (Old_S, Inst) then
                           return (Old_S);

                        else
                           return Report_Overload;
                        end if;

                     else
                        return Report_Overload;
                     end if;

                  else
                     Old_S := It1.Nam;
                     exit;
                  end if;

               else
                  I1 := Ind;
                  Old_S := It.Nam;
               end if;

            elsif
              Present (First_Formal (It.Nam))
                and then Present (First_Formal (New_S))
                and then  (Base_Type (Etype (First_Formal (It.Nam)))
                            = Base_Type (Etype (First_Formal (New_S))))
            then
               Candidate_Renaming := It.Nam;
            end if;

            Get_Next_Interp (Ind, It);
         end loop;

         Set_Entity (Nam, Old_S);
         Set_Is_Overloaded (Nam, False);
      end if;

      return Old_S;
   end Find_Renamed_Entity;

   -----------------------------
   -- Find_Selected_Component --
   -----------------------------

   procedure Find_Selected_Component (N : Node_Id) is
      P : constant Node_Id := Prefix (N);

      P_Name : Entity_Id;
      --  Entity denoted by prefix

      P_Type : Entity_Id;
      --  and its type

      Nam : Node_Id;

   begin
      Analyze (P);

      if Nkind (P) = N_Error then
         return;

      --  If the selector already has an entity, the node has been
      --  constructed in the course of expansion, and is known to be
      --  valid. Do not verify that it is defined for the type (it may
      --  be a private component used in the expansion of record equality).

      elsif Present (Entity (Selector_Name (N))) then

         if No (Etype (N))
           or else Etype (N) = Any_Type
         then
            declare
               Sel_Name : constant Node_Id   := Selector_Name (N);
               Selector : constant Entity_Id := Entity (Sel_Name);
               C_Etype  : Node_Id;

            begin
               Set_Etype (Sel_Name, Etype (Selector));

               if not Is_Entity_Name (P) then
                  Resolve (P);
               end if;

               --  Build an actual subtype except for the first parameter
               --  of an init proc, where this actual subtype is by
               --  definition incorrect, since the object is uninitialized
               --  (and does not even have defined discriminants etc.)

               if Is_Entity_Name (P)
                 and then Ekind (Entity (P)) = E_Function
               then
                  Nam := New_Copy (P);

                  if Is_Overloaded (P) then
                     Save_Interps (P, Nam);
                  end if;

                  Rewrite (P,
                    Make_Function_Call (Sloc (P), Name => Nam));
                  Analyze_Call (P);
                  Analyze_Selected_Component (N);
                  return;

               elsif Ekind (Selector) = E_Component
                 and then (not Is_Entity_Name (P)
                            or else Chars (Entity (P)) /= Name_uInit)
               then
                  C_Etype :=
                    Build_Actual_Subtype_Of_Component (
                      Etype (Selector), N);
               else
                  C_Etype := Empty;
               end if;

               if No (C_Etype) then
                  C_Etype := Etype (Selector);
               else
--                  Insert_Action (N, C_Etype);
                  C_Etype := Defining_Identifier (C_Etype);
               end if;

               Set_Etype (N, C_Etype);
            end;

         --  If the selected component appears within a default expression
         --  and it has an actual subtype, the pre-analysis has not yet
         --  completed its analysis, because Insert_Actions is disabled in
         --  that context. Within the init proc of the enclosing type we
         --  must complete this analysis, if an actual subtype was created.

--           elsif Inside_Init_Proc then
--              declare
--                 Typ  : constant Entity_Id := Etype (N);
--                 Decl : constant Node_Id   := Declaration_Node (Typ);
--  
--              begin
--                 if Nkind (Decl) = N_Subtype_Declaration
--                   and then not Analyzed (Decl)
--                   and then Is_List_Member (Decl)
--                   and then No (Parent (Decl))
--                 then
--                    Remove (Decl);
--                    Insert_Action (N, Decl);
--                 end if;
--              end;
         end if;

         return;

      elsif Is_Entity_Name (P) then
         P_Name := Entity (P);

         --  The prefix may denote an enclosing type which is the completion
         --  of an incomplete type declaration.

         if Is_Type (P_Name) then
            Set_Entity (P, Get_Full_View (P_Name));
            Set_Etype  (P, Entity (P));
            P_Name := Entity (P);
         end if;

         P_Type := Base_Type (Etype (P));

         if Debug_Flag_E then
            Write_Str ("Found prefix type to be ");
            Write_Entity_Info (P_Type, "      "); Write_Eol;
         end if;

         --  First check for components of a record object (not the
         --  result of a call, which is handled below).

         if Is_Appropriate_For_Record (P_Type)
           and then not Is_Overloadable (P_Name)
           and then not Is_Type (P_Name)
         then
            --  Selected component of record. Type checking will validate
            --  name of selector.

            Analyze_Selected_Component (N);

         elsif (In_Open_Scopes (P_Name)
                  and then Ekind (P_Name) /= E_Void
                  and then not Is_Overloadable (P_Name))
         then
            --  Prefix denotes an enclosing loop, block, i.e. an
            --  enclosing construct that is not a subprogram.

            Find_Expanded_Name (N);

         elsif Ekind (P_Name) = E_Package then
            Find_Expanded_Name (N);

         elsif Is_Overloadable (P_Name) then

            --  The subprogram may be a renaming (of an enclosing scope) as
            --  in the case of the name of the generic within an instantiation.

            if (Ekind (P_Name) = E_Procedure
                 or else Ekind (P_Name) = E_Function)
              and then Present (Alias (P_Name))
              and then Is_Generic_Instance (Alias (P_Name))
            then
               P_Name := Alias (P_Name);
            end if;

            if Is_Overloaded (P) then

               --  The prefix must resolve to a unique enclosing construct.

               declare
                  Found : Boolean := False;
                  Ind   : Interp_Index;
                  It    : Interp;

               begin
                  Get_First_Interp (P, Ind, It);

                  while Present (It.Nam) loop

                     if In_Open_Scopes (It.Nam) then
                        if Found then
                           Error_Msg_N (
                              "prefix must be unique enclosing scope", N);
                           Set_Entity (N, Any_Id);
                           Set_Etype  (N, Any_Type);
                           return;

                        else
                           Found := True;
                           P_Name := It.Nam;
                        end if;
                     end if;

                     Get_Next_Interp (Ind, It);
                  end loop;
               end;
            end if;

            if In_Open_Scopes (P_Name) then
               Set_Entity (P, P_Name);
               Set_Is_Overloaded (P, False);
               Find_Expanded_Name (N);

            else
               --  If no interpretation as an expanded name is possible, it
               --  must be a selected component of a record returned by a
               --  function call. Reformat prefix as a function call, the
               --  rest is done by type resolution. If the prefix is a
               --  procedure or entry, as is P.X;  this is an error.

               if Ekind (P_Name) /= E_Function
                 and then (not Is_Overloaded (P)
                             or else
                           Nkind (Parent (N)) = N_Procedure_Call_Statement)
               then

                  --  Prefix may mention a package that is hidden by a local
                  --  declaration: let the user know. Scan the full homonym
                  --  chain, the candidate package may be anywhere on it.

                  if Present (Homonym (Current_Entity (P_Name))) then

                     P_Name := Current_Entity (P_Name);

                     while Present (P_Name) loop
                        exit when Ekind (P_Name) = E_Package;
                        P_Name := Homonym (P_Name);
                     end loop;

                     if Present (P_Name) then
                        Error_Msg_Sloc := Sloc (Entity (Prefix (N)));

                        Error_Msg_NE
                          ("package& is hidden by declaration#",
                            N, P_Name);

                        Set_Entity (Prefix (N), P_Name);
                        Find_Expanded_Name (N);
                        return;
                     else
                        P_Name := Entity (Prefix (N));
                     end if;
                  end if;

                  Error_Msg_NE
                    ("invalid prefix in selected component&", N, P_Name);
                  Change_Selected_Component_To_Expanded_Name (N);
                  Set_Entity (N, Any_Id);
                  Set_Etype (N, Any_Type);

               else
                  Nam := New_Copy (P);
                  Save_Interps (P, Nam);
                  Rewrite (P,
                    Make_Function_Call (Sloc (P), Name => Nam));
                  Analyze_Call (P);
                  Analyze_Selected_Component (N);
               end if;
            end if;

         --  Remaining cases generate various error messages

         else
            --  Format node as expanded name, to avoid cascaded errors

            Change_Selected_Component_To_Expanded_Name (N);
            Set_Entity  (N, Any_Id);
            Set_Etype   (N, Any_Type);

            --  Issue error message, but avoid this if error issued already.
            --  Use identifier of prefix if one is available.

            if P_Name = Any_Id  then
               null;

            elsif Ekind (P_Name) = E_Void then
               Premature_Usage (P);

            elsif Nkind (P) /= N_Attribute_Reference then
               Error_Msg_N (
                "invalid prefix in selected component&", P);

               if Is_Access_Type (P_Type)
                 and then Ekind (Designated_Type (P_Type)) = E_Incomplete_Type
               then
                  Error_Msg_N
                    ("\dereference must not be of an incomplete type " &
                       "('R'M 3.10.1)", P);
               end if;

            else
               Error_Msg_N (
                "invalid prefix in selected component", P);
            end if;
         end if;

      else
         --  If prefix is not the name of an entity, it must be an expression,
         --  whose type is appropriate for a record. This is determined by
         --  type resolution.

         Analyze_Selected_Component (N);
      end if;
   end Find_Selected_Component;

   ---------------
   -- Find_Type --
   ---------------

   procedure Find_Type (N : Node_Id) is
      C      : Entity_Id;
      T      : Entity_Id;
      T_Name : Entity_Id;

   begin
      if N = Error then
         return;

      elsif Nkind (N) = N_Attribute_Reference then

         --  Class attribute. 
	 
         if Attribute_Name (N) = Name_Class then
            Check_Restriction (No_Dispatch, N);
            Find_Type (Prefix (N));

            --  Propagate error from bad prefix

            if Etype (Prefix (N)) = Any_Type then
               Set_Entity (N, Any_Type);
               Set_Etype  (N, Any_Type);
               return;
            end if;

            T := Base_Type (Entity (Prefix (N)));

            --  Case of non-tagged type

            if not Is_Tagged_Type (T) then
               if Ekind (T) = E_Incomplete_Type then

                  --  It is legal to denote the class type of an incomplete
                  --  type. The full type will have to be tagged, of course.

                  Set_Is_Tagged_Type (T);
                  Make_Class_Wide_Type (T);
                  Set_Entity (N, Class_Wide_Type (T));
                  Set_Etype  (N, Class_Wide_Type (T));

               elsif Ekind (T) = E_Private_Type
                 and then not Is_Generic_Type (T)
                 and then In_Private_Part (Scope (T))
               then
                  --  The Class attribute can be applied to an untagged
                  --  private type fulfilled by a tagged type prior to
                  --  the full type declaration (but only within the
                  --  parent package's private part). Create the class-wide
                  --  type now and check that the full type is tagged
                  --  later during its analysis. Note that we do not
                  --  mark the private type as tagged, unlike the case
                  --  of incomplete types, because the type must still
                  --  appear untagged to outside units.

                  if not Present (Class_Wide_Type (T)) then
                     Make_Class_Wide_Type (T);
                  end if;

                  Set_Entity (N, Class_Wide_Type (T));
                  Set_Etype  (N, Class_Wide_Type (T));

               else
                  --  Should we introduce a type Any_Tagged and use
                  --  Wrong_Type here, it would be a bit more consistent???

                  Error_Msg_NE
                    ("tagged type required, found}",
                     Prefix (N), First_Subtype (T));
                  Set_Entity (N, Any_Type);
                  return;
               end if;

            --  Case of tagged type

            else
               C := Class_Wide_Type (Entity (Prefix (N)));
               Set_Entity (N, C);
               Set_Etype (N, C);
            end if;

         --  All other attributes are invalid in a subtype mark

         else
            Error_Msg_N ("invalid attribute in subtype mark", N);
         end if;

      else
         Analyze (N);

         if Is_Entity_Name (N) then
            T_Name := Entity (N);
         else
            Error_Msg_N ("subtype mark required in this context", N);
            Set_Etype (N, Any_Type);
            return;
         end if;

         if T_Name  = Any_Id or else Etype (N) = Any_Type then

            --  Undefined id. Make it into a valid type

            Set_Entity (N, Any_Type);

         elsif not Is_Type (T_Name)
           and then T_Name /= Standard_Void_Type
         then
            Error_Msg_Sloc := Sloc (T_Name);
            Error_Msg_N ("subtype mark required in this context", N);
            Error_Msg_NE ("\found & declared#", N, T_Name);
            Set_Entity (N, Any_Type);

         else
            T_Name := Get_Full_View (T_Name);

            if In_Open_Scopes (T_Name) then
	       Error_Msg_N ("type declaration cannot refer to itself", N);

               Set_Etype (N, Any_Type);
               Set_Entity (N, Any_Type);
               Set_Error_Posted (T_Name);
               return;
            end if;

            Set_Entity (N, T_Name);
            Set_Etype  (N, T_Name);
         end if;
      end if;

      if Present (Etype (N)) and then Comes_From_Source (N) then
         if Is_Floating_Point_Type (Etype (N)) then
            Check_Restriction (No_Floating_Point, N);
         end if;
      end if;
   end Find_Type;

   -------------------
   -- Get_Full_View --
   -------------------

   function Get_Full_View (T_Name : Entity_Id) return Entity_Id is
   begin
      if Ekind (T_Name) = E_Incomplete_Type
        and then Present (Full_View (T_Name))
      then
         return Full_View (T_Name);

      elsif Is_Class_Wide_Type (T_Name)
        and then Ekind (Root_Type (T_Name)) = E_Incomplete_Type
        and then Present (Full_View (Root_Type (T_Name)))
      then
         return Class_Wide_Type (Full_View (Root_Type (T_Name)));

      else
         return T_Name;
      end if;
   end Get_Full_View;

   ------------------------------------
   -- Has_Implicit_Character_Literal --
   ------------------------------------

   function Has_Implicit_Character_Literal (N : Node_Id) return Boolean is
      Id      : Entity_Id;
      Found   : Boolean := False;
      P       : constant Entity_Id := Entity (Prefix (N));
      Priv_Id : Entity_Id := Empty;

   begin
      if Ekind (P) = E_Package
        and then not In_Open_Scopes (P)
      then
         Priv_Id := First_Private_Entity (P);
      end if;

      if P = Standard_Standard then
         Change_Selected_Component_To_Expanded_Name (N);
         Rewrite (N, Selector_Name (N));
         Analyze (N);
         Set_Etype (Original_Node (N), Standard_Character);
         return True;
      end if;

      Id := First_Entity (P);

      while Present (Id)
        and then Id /= Priv_Id
      loop
         if Is_Character_Type (Id)
           and then (Root_Type (Id) = Standard_Character
                       or else Root_Type (Id) = Standard_Wide_Character)
           and then Id = Base_Type (Id)
         then
            --  We replace the node with the literal itself, resolve as a
            --  character, and set the type correctly.

            if not Found then
               Change_Selected_Component_To_Expanded_Name (N);
               Rewrite (N, Selector_Name (N));
               Analyze (N);
               Set_Etype (N, Id);
               Set_Etype (Original_Node (N), Id);
               Found := True;

            else
               --  More than one type derived from Character in given scope.
               --  Collect all possible interpretations.

               Add_One_Interp (N, Id, Id);
            end if;
         end if;

         Next_Entity (Id);
      end loop;

      return Found;
   end Has_Implicit_Character_Literal;

   ---------------------------
   -- Has_Implicit_Operator --
   ---------------------------

   function Has_Implicit_Operator (N : Node_Id) return Boolean is
      Op_Id   : constant Name_Id   := Chars (Selector_Name (N));
      P       : constant Entity_Id := Entity (Prefix (N));
      Id      : Entity_Id;
      Priv_Id : Entity_Id := Empty;

      procedure Add_Implicit_Operator
        (T       : Entity_Id;
         Op_Type : Entity_Id := Empty);
      --  Add implicit interpretation to node N, using the type for which
      --  a predefined operator exists. If the operator yields a boolean
      --  type, the Operand_Type is implicitly referenced by the operator,
      --  and a reference to it must be generated.

      ---------------------------
      -- Add_Implicit_Operator --
      ---------------------------

      procedure Add_Implicit_Operator
        (T       : Entity_Id;
         Op_Type : Entity_Id := Empty)
      is
         Predef_Op : Entity_Id;

      begin
         Predef_Op := Current_Entity (Selector_Name (N));

         while Present (Predef_Op)
           and then Scope (Predef_Op) /= Standard_Standard
         loop
            Predef_Op := Homonym (Predef_Op);
         end loop;

         if Nkind (N) = N_Selected_Component then
            Change_Selected_Component_To_Expanded_Name (N);
         end if;

         Add_One_Interp (N, Predef_Op, T);

         --  For operators with unary and binary interpretations, add both

         if Present (Homonym (Predef_Op)) then
            Add_One_Interp (N, Homonym (Predef_Op), T);
         end if;
      end Add_Implicit_Operator;

   --  Start of processing for Has_Implicit_Operator

   begin

      if Ekind (P) = E_Package
        and then not In_Open_Scopes (P)
      then
         Priv_Id := First_Private_Entity (P);
      end if;

      Id := First_Entity (P);

      case Op_Id is

         --  Boolean operators: an implicit declaration exists if the scope
         --  contains a declaration for a derived Boolean type, or for an
         --  array of Boolean type.

         when Name_Op_And | Name_Op_Not | Name_Op_Or  | Name_Op_Xor =>

            while Id  /= Priv_Id loop

               if Valid_Boolean_Arg (Id)
                 and then Id = Base_Type (Id)
               then
                  Add_Implicit_Operator (Id);
                  return True;
               end if;

               Next_Entity (Id);
            end loop;

         --  Equality: look for any non-limited type. Result is Boolean.

         when Name_Op_Eq | Name_Op_Ne =>

            while Id  /= Priv_Id loop

               if Is_Type (Id)
                 and then Id = Base_Type (Id)
               then
                  Add_Implicit_Operator (Standard_Boolean, Id);
                  return True;
               end if;

               Next_Entity (Id);
            end loop;

         --  Comparison operators: scalar type, or array of scalar.

         when Name_Op_Lt | Name_Op_Le | Name_Op_Gt | Name_Op_Ge =>

            while Id  /= Priv_Id loop
               if (Is_Scalar_Type (Id)
                 or else (Is_Array_Type (Id)
                           and then Is_Scalar_Type (Component_Type (Id))))
                 and then Id = Base_Type (Id)
               then
                  Add_Implicit_Operator (Standard_Boolean, Id);
                  return True;
               end if;

               Next_Entity (Id);
            end loop;

         --  Arithmetic operators: any numeric type

         when Name_Op_Abs      |
              Name_Op_Add      |
              Name_Op_Mod      |
              Name_Op_Rem      |
              Name_Op_Subtract |
              Name_Op_Multiply |
              Name_Op_Divide   |
              Name_Op_Expon    =>

            while Id  /= Priv_Id loop
               if Is_Numeric_Type (Id)
                 and then Id = Base_Type (Id)
               then
                  Add_Implicit_Operator (Id);
                  return True;
               end if;

               Next_Entity (Id);
            end loop;

         --  Concatenation: any one-dimensional array type

         when Name_Op_Concat =>

            while Id  /= Priv_Id loop
               if Is_Array_Type (Id) and then Number_Dimensions (Id) = 1
                 and then Id = Base_Type (Id)
               then
                  Add_Implicit_Operator (Id);
                  return True;
               end if;

               Next_Entity (Id);
            end loop;

         --  What is the others condition here? Should we be using a
         --  subtype of Name_Id that would restrict to operators ???

         when others => null;

      end case;

      --  If we fall through, then we do not have an implicit operator

      return False;

   end Has_Implicit_Operator;

   --------------------
   -- In_Open_Scopes --
   --------------------

   function In_Open_Scopes (S : Entity_Id) return Boolean is
   begin
      --  Since there are several scope stacks maintained by Scope_Stack each
      --  delineated by Standard (see comments by definition of Scope_Stack)
      --  it is necessary to end the search when Standard is reached.

      for J in reverse 0 .. Scope_Stack.Last loop
         if Scope_Stack.Table (J).Entity = S then
            return True;
         end if;

         --  We need Is_Active_Stack_Base to tell us when to stop rather
         --  than checking for Standard_Standard because there are cases
         --  where Standard_Standard appears in the middle of the active
         --  set of scopes. This affects the declaration and overriding
         --  of private inherited operations in instantiations of generic
         --  child units.

         exit when Scope_Stack.Table (J).Is_Active_Stack_Base;
      end loop;

      return False;
   end In_Open_Scopes;

   -----------------------------
   -- Inherit_Renamed_Profile --
   -----------------------------

   procedure Inherit_Renamed_Profile (New_S : Entity_Id; Old_S : Entity_Id) is
      New_F : Entity_Id;
      Old_F : Entity_Id;
      Old_T : Entity_Id;
      New_T : Entity_Id;

   begin
      if Ekind (Old_S) = E_Operator then

         New_F := First_Formal (New_S);

         while Present (New_F) loop
            Set_Etype (New_F, Base_Type (Etype (New_F)));
            Next_Formal (New_F);
         end loop;

         Set_Etype (New_S, Base_Type (Etype (New_S)));

      else
         New_F := First_Formal (New_S);
         Old_F := First_Formal (Old_S);

         while Present (New_F) loop
            New_T := Etype (New_F);
            Old_T := Etype (Old_F);

            --  If the new type is a renaming of the old one, as is the
            --  case for actuals in instances, retain its name, to simplify
            --  later disambiguation.

            if Nkind (Parent (New_T)) = N_Subtype_Declaration
              and then Is_Entity_Name (Subtype_Indication (Parent (New_T)))
              and then Entity (Subtype_Indication (Parent (New_T))) = Old_T
            then
               null;
            else
               Set_Etype (New_F, Old_T);
            end if;

            Next_Formal (New_F);
            Next_Formal (Old_F);
         end loop;

         if Ekind (Old_S) = E_Function
           or else Ekind (Old_S) = E_Enumeration_Literal
         then
            Set_Etype (New_S, Etype (Old_S));
         end if;
      end if;
   end Inherit_Renamed_Profile;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Urefs.Init;
   end Initialize;

   -------------------------
   -- Install_Use_Clauses --
   -------------------------

   procedure Install_Use_Clauses (Clause : Node_Id) is
      U  : Node_Id := Clause;
      P  : Node_Id;
      Id : Entity_Id;

   begin
      while Present (U) loop

         --  Case of USE package

         if Nkind (U) = N_Use_Package_Clause then
            P := First (Names (U));

            while Present (P) loop
               Id := Entity (P);

               if Ekind (Id) = E_Package then

                  if In_Use (Id) then
                     Set_Redundant_Use (P, True);

                  elsif Present (Renamed_Object (Id))
                    and then In_Use (Renamed_Object (Id))
                  then
                     Set_Redundant_Use (P, True);

                  else
                     Use_One_Package (Id, U);
                  end if;
               end if;

               Next (P);
            end loop;

         --  case of USE TYPE

         else
            P := First (Subtype_Marks (U));

            while Present (P) loop
               if not Is_Entity_Name (P)
                 or else No (Entity (P))
               then
                  null;
               end if;

               Next (P);
            end loop;
         end if;

         Next_Use_Clause (U);
      end loop;
   end Install_Use_Clauses;

   -------------------------------
   -- Is_Appropriate_For_Record --
   -------------------------------

   function Is_Appropriate_For_Record
     (T    : Entity_Id)
      return Boolean
   is
   begin
      return
        Present (T)
          and then (Is_Record_Type (T)
                      or else (Is_Access_Type (T)
                                 and then
                                   Is_Record_Type (Designated_Type (T))));
   end Is_Appropriate_For_Record;

   ---------------
   -- New_Scope --
   ---------------

   procedure New_Scope (S : Entity_Id) is
      E : Entity_Id;

   begin
      if Ekind (S) = E_Void then
         null;

      --  Set scope depth if not a non-concurrent type, and we have not
      --  yet set the scope depth. This means that we have the first
      --  occurrence of the scope, and this is where the depth is set.

      elsif (not Is_Type (S))
        and then not Scope_Depth_Set (S)
      then
         if S = Standard_Standard then
            Set_Scope_Depth_Value (S, Uint_0);

         elsif Is_Child_Unit (S) then
            Set_Scope_Depth_Value (S, Uint_1);

         elsif not Is_Record_Type (Current_Scope) then
            if Ekind (S) = E_Loop then
               Set_Scope_Depth_Value (S, Scope_Depth (Current_Scope));
            else
               Set_Scope_Depth_Value (S, Scope_Depth (Current_Scope) + 1);
            end if;
         end if;
      end if;

      Scope_Stack.Increment_Last;

      declare
         SST : Scope_Stack_Entry renames Scope_Stack.Table (Scope_Stack.Last);

      begin
         SST.Entity                         := S;
         SST.Save_Scope_Suppress            := Scope_Suppress;
         SST.Save_Local_Entity_Suppress     := Local_Entity_Suppress.Last;

         if Scope_Stack.Last > Scope_Stack.First then
            SST.Component_Alignment_Default := Scope_Stack.Table
                                                 (Scope_Stack.Last - 1).
                                                   Component_Alignment_Default;
         end if;

         SST.Last_Subprogram_Name           := null;
         SST.Is_Transient                   := False;
         SST.Node_To_Be_Wrapped             := Empty;
         SST.Pending_Freeze_Actions         := No_List;
         SST.Actions_To_Be_Wrapped_Before   := No_List;
         SST.Actions_To_Be_Wrapped_After    := No_List;
         SST.First_Use_Clause               := Empty;
         SST.Is_Active_Stack_Base           := False;
      end;

      if Debug_Flag_W then
         Write_Str ("--> new scope: ");
         Write_Name (Chars (Current_Scope));
         Write_Str (", Id=");
         Write_Int (Int (Current_Scope));
         Write_Str (", Depth=");
         Write_Int (Int (Scope_Stack.Last));
         Write_Eol;
      end if;

      --  Copy from Scope (S) the categorization flags to S, this is not
      --  done in case Scope (S) is Standard_Standard since propagation
      --  is from library unit entity inwards.

      if S /= Standard_Standard
        and then Scope (S) /= Standard_Standard
        and then not Is_Child_Unit (S)
      then
         E := Scope (S);

         if Nkind (E) not in N_Entity then
            return;
         end if;

         --  We only propagate inwards for library level entities,
         --  inner level subprograms do not inherit the categorization.

         if Is_Library_Level_Entity (S) then
            Set_Is_Preelaborated (S, Is_Preelaborated (E));
            Set_Categorization_From_Scope (E => S, Scop => E);
         end if;
      end if;
   end New_Scope;

   ---------------
   -- Pop_Scope --
   ---------------

   procedure Pop_Scope is
      SST : Scope_Stack_Entry renames Scope_Stack.Table (Scope_Stack.Last);

   begin
      if Debug_Flag_E then
         Write_Info;
      end if;

      Scope_Suppress := SST.Save_Scope_Suppress;
      Local_Entity_Suppress.Set_Last (SST.Save_Local_Entity_Suppress);

      if Debug_Flag_W then
         Write_Str ("--> exiting scope: ");
         Write_Name (Chars (Current_Scope));
         Write_Str (", Depth=");
         Write_Int (Int (Scope_Stack.Last));
         Write_Eol;
      end if;

      End_Use_Clauses (SST.First_Use_Clause);

      --  If the actions to be wrapped are still there they will get lost
      --  causing incomplete code to be generated. It is better to abort in
      --  this case (and we do the abort even with assertions off since the
      --  penalty is incorrect code generation)

      if SST.Actions_To_Be_Wrapped_Before /= No_List
           or else
         SST.Actions_To_Be_Wrapped_After  /= No_List
      then
         return;
      end if;

      --  Free last subprogram name if allocated, and pop scope

      Free (SST.Last_Subprogram_Name);
      Scope_Stack.Decrement_Last;
   end Pop_Scope;

   ---------------------
   -- Premature_Usage --
   ---------------------

   procedure Premature_Usage (N : Node_Id) is
      Kind : constant Node_Kind := Nkind (Parent (Entity (N)));
      E    : Entity_Id := Entity (N);

   begin
      --  Within an instance, the analysis of the actual for a formal object
      --  does not see the name of the object itself. This is significant
      --  only if the object is an aggregate, where its analysis does not do
      --  any name resolution on component associations. (see 4717-008). In
      --  such a case, look for the visible homonym on the chain.

      if In_Instance
        and then Present (Homonym (E))
      then
         E := Homonym (E);

         while Present (E)
           and then not In_Open_Scopes (Scope (E))
         loop
            E := Homonym (E);
         end loop;

         if Present (E) then
            Set_Entity (N, E);
            Set_Etype (N, Etype (E));
            return;
         end if;
      end if;

      if Kind  = N_Component_Declaration then
         Error_Msg_N
           ("component&! cannot be used before end of record declaration", N);

      elsif Kind  = N_Parameter_Specification then
         Error_Msg_N
           ("formal parameter&! cannot be used before end of specification",
            N);

      elsif Kind  = N_Procedure_Specification
        or else Kind = N_Function_Specification
      then
         Error_Msg_N
           ("subprogram&! cannot be used before end of its declaration",
            N);
      else
         Error_Msg_N
           ("object& cannot be used before end of its declaration!", N);
      end if;
   end Premature_Usage;

   ------------------------
   -- Present_System_Aux --
   ------------------------

   function Present_System_Aux (N : Node_Id := Empty) return Boolean is
      Loc      : Source_Ptr;
      Aux_Name : Name_Id;
      Unum     : Unit_Number_Type;
      Withn    : Node_Id;
      With_Sys : Node_Id;
      The_Unit : Node_Id;

      function Find_System (C_Unit : Node_Id) return Entity_Id;
      --  Scan context clause of compilation unit to find a with_clause
      --  for System.

      function Find_System (C_Unit : Node_Id) return Entity_Id is
         With_Clause : Node_Id;

      begin
         With_Clause := First (Context_Items (C_Unit));

         while Present (With_Clause) loop
            if (Nkind (With_Clause) = N_With_Clause
              and then Chars (Name (With_Clause)) = Name_System)
              and then Comes_From_Source (With_Clause)
            then
               return With_Clause;
            end if;

            Next (With_Clause);
         end loop;

         return Empty;
      end Find_System;

   --  Start of processing for Present_System_Aux

   begin
      --  The child unit may have been loaded and analyzed already.

      if Present (System_Aux_Id) then
         return True;

      --  If no previous pragma for System.Aux, nothing to load

      elsif No (System_Extend_Unit) then
         return False;

      --  Use the unit name given in the pragma to retrieve the unit.
      --  Verify that System itself appears in the context clause of the
      --  current compilation. If System is not present, an error will
      --  have been reported already.

      else
         With_Sys := Find_System (Cunit (Current_Sem_Unit));

         The_Unit := Unit (Cunit (Current_Sem_Unit));

         if No (With_Sys)
           and then (Nkind (The_Unit) = N_Package_Body
                      or else (Nkind (The_Unit) = N_Subprogram_Body
                        and then not Acts_As_Spec (Cunit (Current_Sem_Unit))))
         then
            With_Sys := Find_System (Library_Unit (Cunit (Current_Sem_Unit)));
         end if;

         if No (With_Sys)
           and then Present (N)
         then
            --  If we are compiling a subunit, we need to examine its
            --  context as well (Current_Sem_Unit is the parent unit);

            The_Unit := Parent (N);

            while Nkind (The_Unit) /= N_Compilation_Unit loop
               The_Unit := Parent (The_Unit);
            end loop;

         end if;

         if No (With_Sys) then
            return False;
         end if;

         Loc := Sloc (With_Sys);
         Get_Name_String (Chars (Expression (System_Extend_Unit)));
         Name_Buffer (8 .. Name_Len + 7) := Name_Buffer (1 .. Name_Len);
         Name_Buffer (1 .. 7) := "system.";
         Name_Buffer (Name_Len + 8) := '%';
         Name_Buffer (Name_Len + 9) := 's';
         Name_Len := Name_Len + 9;
         Aux_Name := Name_Find;

         Unum :=
           Load_Unit
             (Load_Name  => Aux_Name,
              Required   => False,
              Subunit    => False,
              Error_Node => With_Sys);

         if Unum /= No_Unit then
            Semantics (Cunit (Unum));
            System_Aux_Id :=
              Defining_Entity (Specification (Unit (Cunit (Unum))));

            Withn := Make_With_Clause (Loc,
              Name =>
                Make_Expanded_Name (Loc,
                  Chars  => Chars (System_Aux_Id),
                  Prefix =>
                    New_Reference_To (Scope (System_Aux_Id), Loc),
                  Selector_Name =>
                    New_Reference_To (System_Aux_Id, Loc)));

            Set_Entity (Name (Withn), System_Aux_Id);

            Set_Library_Unit          (Withn, Cunit (Unum));
            Set_Corresponding_Spec    (Withn, System_Aux_Id);
            Set_First_Name            (Withn, True);
            Set_Implicit_With         (Withn, True);

            Insert_After (With_Sys, Withn);
            Mark_Rewrite_Insertion (Withn);
            Set_Context_Installed (Withn);

            return True;

         --  Here if unit load failed

         else
            Error_Msg_Name_1 := Name_System;
            Error_Msg_Name_2 := Chars (Expression (System_Extend_Unit));
            Error_Msg_N
              ("extension package `%.%` does not exist",
               Opt.System_Extend_Unit);
            return False;
         end if;
      end if;
   end Present_System_Aux;

   -------------------------
   -- Restore_Scope_Stack --
   -------------------------

   procedure Restore_Scope_Stack (Handle_Use : Boolean := True) is
      E         : Entity_Id;
      S         : Entity_Id;
      Comp_Unit : Node_Id;
      In_Child  : Boolean := False;
      Full_Vis  : Boolean := True;
      SS_Last   : constant Int := Scope_Stack.Last;

   begin
      --  Restore visibility of previous scope stack, if any.

      for J in reverse 0 .. Scope_Stack.Last loop
         exit when  Scope_Stack.Table (J).Entity = Standard_Standard
            or else No (Scope_Stack.Table (J).Entity);

         S := Scope_Stack.Table (J).Entity;

         if not Is_Hidden_Open_Scope (S) then

            --  If the parent scope is hidden, its entities are hidden as
            --  well, unless the entity is the instantiation currently
            --  being analyzed.

            if not Is_Hidden_Open_Scope (Scope (S))
              or else not Analyzed (Parent (S))
              or else Scope (S) = Standard_Standard
            then
               Set_Is_Immediately_Visible (S, True);
            end if;

            E := First_Entity (S);

            while Present (E) loop
               if Is_Child_Unit (E) then
                  Set_Is_Immediately_Visible (E,
                    Is_Visible_Child_Unit (E) or else In_Open_Scopes (E));
               else
                  Set_Is_Immediately_Visible (E, True);
               end if;

               Next_Entity (E);

               if not Full_Vis then
                  exit when E = First_Private_Entity (S);
               end if;
            end loop;

            --  The visibility of child units (siblings of current compilation)
            --  must be restored in any case. Their declarations may appear
            --  after the private part of the parent.

            if not Full_Vis
              and then Present (E)
            then
               while Present (E) loop
                  if Is_Child_Unit (E) then
                     Set_Is_Immediately_Visible (E,
                       Is_Visible_Child_Unit (E) or else In_Open_Scopes (E));
                  end if;

                  Next_Entity (E);
               end loop;
            end if;
         end if;

         if Is_Child_Unit (S)
            and not In_Child     --  check only for current unit.
         then
            In_Child := True;

            --  restore visibility of parents according to whether the child
            --  is private and whether we are in its visible part.

            Comp_Unit := Parent (Unit_Declaration_Node (S));

            if Nkind (Comp_Unit) = N_Compilation_Unit
              and then Private_Present (Comp_Unit)
            then
               Full_Vis := True;

            elsif (Ekind (S) = E_Package
                    or else Ekind (S) = E_Generic_Package)
              and then (In_Private_Part (S)
                         or else In_Package_Body (S))
            then
               Full_Vis := True;

            elsif (Ekind (S) = E_Procedure
                    or else Ekind (S) = E_Function)
              and then Has_Completion (S)
            then
               Full_Vis := True;
            else
               Full_Vis := False;
            end if;
         else
            Full_Vis := True;
         end if;
      end loop;

      if SS_Last >= Scope_Stack.First
        and then Scope_Stack.Table (SS_Last).Entity /= Standard_Standard
        and then Handle_Use
      then
         Install_Use_Clauses (Scope_Stack.Table (SS_Last).First_Use_Clause);
      end if;
   end Restore_Scope_Stack;

   ----------------------
   -- Save_Scope_Stack --
   ----------------------

   procedure Save_Scope_Stack (Handle_Use : Boolean := True) is
      E       : Entity_Id;
      S       : Entity_Id;
      SS_Last : constant Int := Scope_Stack.Last;

   begin
      if SS_Last >= Scope_Stack.First
        and then Scope_Stack.Table (SS_Last).Entity /= Standard_Standard
      then
         if Handle_Use then
            End_Use_Clauses (Scope_Stack.Table (SS_Last).First_Use_Clause);
         end if;

         --  If the call is from within a compilation unit, as when
         --  called from Rtsfind, make current entries in scope stack
         --  invisible while we analyze the new unit.

         for J in reverse 0 .. SS_Last loop
            exit when  Scope_Stack.Table (J).Entity = Standard_Standard
               or else No (Scope_Stack.Table (J).Entity);

            S := Scope_Stack.Table (J).Entity;
            Set_Is_Immediately_Visible (S, False);
            E := First_Entity (S);

            while Present (E) loop
               Set_Is_Immediately_Visible (E, False);
               Next_Entity (E);
            end loop;
         end loop;

      end if;
   end Save_Scope_Stack;

   -------------
   -- Set_Use --
   -------------

   procedure Set_Use (L : List_Id) is
      Decl      : Node_Id;
      Pack_Name : Node_Id;
      Pack      : Entity_Id;

   begin
      if Present (L) then
         Decl := First (L);

         while Present (Decl) loop
            if Nkind (Decl) = N_Use_Package_Clause then
               Chain_Use_Clause (Decl);
               Pack_Name := First (Names (Decl));

               while Present (Pack_Name) loop
                  Pack := Entity (Pack_Name);

                  if Ekind (Pack) = E_Package
                    and then Applicable_Use (Pack_Name)
                  then
                     Use_One_Package (Pack, Decl);
                  end if;

                  Next (Pack_Name);
               end loop;
            end if;

            Next (Decl);
         end loop;
      end if;
   end Set_Use;

   ---------------------
   -- Use_One_Package --
   ---------------------

   procedure Use_One_Package (P : Entity_Id; N : Node_Id) is
      Id               : Entity_Id;
      Prev             : Entity_Id;
      Current_Instance : Entity_Id := Empty;
      Real_P           : Entity_Id;

   begin
      if Ekind (P) /= E_Package then
         return;
      end if;

      Set_In_Use (P);

      --  Find enclosing instance, if any.

      if In_Instance then
         Current_Instance := Current_Scope;

         while not Is_Generic_Instance (Current_Instance) loop
            Current_Instance := Scope (Current_Instance);
         end loop;

         if No (Hidden_By_Use_Clause (N)) then
            Set_Hidden_By_Use_Clause (N, New_Elmt_List);
         end if;
      end if;

      --  If unit is a package renaming, indicate that the renamed
      --  package is also in use (the flags on both entities must
      --  remain consistent, and a subsequent use of either of them
      --  should be recognized as redundant).

      if Present (Renamed_Object (P)) then
         Set_In_Use (Renamed_Object (P));
         Real_P := Renamed_Object (P);
      else
         Real_P := P;
      end if;

      --  Loop through entities in one package making them potentially
      --  use-visible.

      Id := First_Entity (P);
      while Present (Id)
        and then Id /= First_Private_Entity (P)
      loop
         Prev := Current_Entity (Id);

         while Present (Prev) loop
            if Is_Immediately_Visible (Prev)
              and then (not Is_Overloadable (Prev)
                         or else not Is_Overloadable (Id)
                         or else (Type_Conformant (Id, Prev)))
            then
               if No (Current_Instance) then

                  --  Potentially use-visible entity remains hidden

                  goto Next_Usable_Entity;

               --  A use clause within an instance hides outer global
               --  entities, which are not used to resolve local entities
               --  in the instance. Note that the predefined entities in
               --  Standard could not have been hidden in the generic by
               --  a use clause, and therefore remain visible. Other
               --  compilation units whose entities appear in Standard must
               --  be hidden in an instance.

               --  To determine whether an entity is external to the instance
               --  we compare the scope depth of its scope with that of the
               --  current instance. However, a generic actual of a subprogram
               --  instance is declared in the wrapper package but will not be
               --  hidden by a use-visible entity.

               elsif not Is_Hidden (Id)
                 and then not Is_Wrapper_Package (Scope (Prev))
                 and then Scope_Depth (Scope (Prev)) <
                          Scope_Depth (Current_Instance)
                 and then (Scope (Prev) /= Standard_Standard
                            or else Sloc (Prev) > Standard_Location)
               then
                  Set_Is_Potentially_Use_Visible (Id);
                  Set_Is_Immediately_Visible (Prev, False);
                  Append_Elmt (Prev, Hidden_By_Use_Clause (N));
               end if;

            --  A user-defined operator is not use-visible if the
            --  predefined operator for the type is immediately visible,
            --  which is the case if the type of the operand is in an open
            --  scope. This does not apply to user-defined operators that
            --  have operands of different types, because the predefined
            --  mixed mode operations (multiplication and division) apply to
            --  universal types and do not hide anything.

            elsif Ekind (Prev) = E_Operator
              and then Operator_Matches_Spec (Prev, Id)
              and then In_Open_Scopes
               (Scope (Base_Type (Etype (First_Formal (Id)))))
              and then (No (Next_Formal (First_Formal (Id)))
                         or else Etype (First_Formal (Id))
                           = Etype (Next_Formal (First_Formal (Id)))
                         or else Chars (Prev) = Name_Op_Expon)
            then
               goto Next_Usable_Entity;
            end if;

            Prev := Homonym (Prev);
         end loop;

         --  On exit, we know entity is not hidden, unless it is private.

         if not Is_Hidden (Id)
           and then ((not Is_Child_Unit (Id))
                       or else Is_Visible_Child_Unit (Id))
         then
            Set_Is_Potentially_Use_Visible (Id);

            if Is_Private_Type (Id)
              and then Present (Full_View (Id))
            then
               Set_Is_Potentially_Use_Visible (Full_View (Id));
            end if;
         end if;

         <<Next_Usable_Entity>>
            Next_Entity (Id);
      end loop;

      --  Child units are also made use-visible by a use clause, but they
      --  may appear after all visible declarations in the parent entity list.

      while Present (Id) loop

         if Is_Child_Unit (Id)
           and then Is_Visible_Child_Unit (Id)
         then
            Set_Is_Potentially_Use_Visible (Id);
         end if;

         Next_Entity (Id);
      end loop;

      if Chars (Real_P) = Name_System
        and then Scope (Real_P) = Standard_Standard
        and then Present_System_Aux (N)
      then
         Use_One_Package (System_Aux_Id, N);
      end if;

   end Use_One_Package;

   ----------------
   -- Write_Info --
   ----------------

   procedure Write_Info is
      Id : Entity_Id := First_Entity (Current_Scope);

   begin
      --  No point in dumping standard entities

      if Current_Scope = Standard_Standard then
         return;
      end if;

      Write_Str ("========================================================");
      Write_Eol;
      Write_Str ("        Defined Entities in ");
      Write_Name (Chars (Current_Scope));
      Write_Eol;
      Write_Str ("========================================================");
      Write_Eol;

      if No (Id) then
         Write_Str ("-- none --");
         Write_Eol;

      else
         while Present (Id) loop
            Write_Entity_Info (Id, " ");
            Next_Entity (Id);
         end loop;
      end if;

      if Scope (Current_Scope) = Standard_Standard then

         --  Print information on the current unit itself

         Write_Entity_Info (Current_Scope, " ");
      end if;

      Write_Eol;
   end Write_Info;

   -----------------
   -- Write_Scopes --
   -----------------

   procedure Write_Scopes is
      S : Entity_Id;

   begin
      for J in reverse 1 .. Scope_Stack.Last loop
         S :=  Scope_Stack.Table (J).Entity;
         Write_Int (Int (S));
         Write_Str (" === ");
         Write_Name (Chars (S));
         Write_Eol;
      end loop;
   end Write_Scopes;

end Sem_Ch8;
