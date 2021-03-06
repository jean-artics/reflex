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

with Types; use Types;
package Treepr is

--  This package provides printing routines for the abstract syntax tree
--  These routines are intended only for debugging use.

   procedure Tree_Dump;
   --  This routine is called from the GNAT main program to dump trees as
   --  requested by debug options (including tree of Standard if requested).

   procedure Print_Tree_Node (N : Node_Id; Label : String := "");
   --  Prints a single tree node, without printing descendants. The Label
   --  string is used to preface each line of the printed output.

   procedure Print_Tree_List (L : List_Id);
   --  Prints a single node list, without printing the descendants of any
   --  of the nodes in the list

   procedure Print_Tree_Elist (E : Elist_Id);
   --  Prints a single node list, without printing the descendants of any
   --  of the nodes in the list

   procedure Print_Node_Subtree (N : Node_Id);
   --  Prints the subtree routed at a specified tree node, including all
   --  referenced descendants.

   procedure Print_List_Subtree (L : List_Id);
   --  Prints the subtree consisting of the given node list and all its
   --  referenced descendants.

   procedure Print_Elist_Subtree (E : Elist_Id);
   --  Prints the subtree consisting of the given element list and all its
   --  referenced descendants.

   procedure pe (E : Elist_Id);
   pragma Export (Ada, pe);
   --  Debugging procedure (to be called within gdb)
   --  same as Print_Tree_Elist

   procedure pl (L : List_Id);
   pragma Export (Ada, pl);
   --  Debugging procedure (to be called within gdb)
   --  same as Print_Tree_List

   procedure pn (N : Node_Id);
   pragma Export (Ada, pn);
   --  Debugging procedure (to be called within gdb)
   --  same as Print_Tree_Node with Label = ""

   procedure pt (N : Node_Id);
   pragma Export (Ada, pt);
   --  Debugging procedure (to be called within gdb)
   --  same as Print_Node_Subtree

end Treepr;
