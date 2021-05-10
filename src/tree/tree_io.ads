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

--  This package contains the routines used to read and write the tree files
--  used by ASIS. Only the actual read and write routines are here. The open,
--  create and close routines are elsewhere (in Osint in the compiler, and in
--  the tree read driver for the tree read interface).

with GNAT.OS_Lib; use GNAT.OS_Lib;
with System;      use System;
with Types;       use Types;

package Tree_IO is

   Tree_Format_Error : exception;
   --  Raised if a format error is detected in the input file

   procedure Tree_Read_Initialize (Desc : File_Descriptor);
   --  Called to initialize reading of a tree file. This call must be made
   --  before calls to Tree_Read_xx. No calls to Tree_Write_xx are permitted
   --  after this call.

   procedure Tree_Read_Data (Addr : Address; Length : Int);
   --  Checks that the Length provided is the same as what has been provided
   --  to the corresponding Tree_Write_Data from the current tree file,
   --  Tree_Format_Error is raised if it is not the case. If Length is
   --  correct and non zero, reads Length bytes of information into memory
   --  starting at Addr from the current tree file.

   procedure Tree_Read_Bool (B : out Boolean);
   --  Reads a single boolean value. The boolean value must have been written
   --  with a call to the Tree_Write_Bool procedure.

   procedure Tree_Read_Char (C : out Character);
   --  Reads a single character. The character must have been written with a
   --  call to the Tree_Write_Char procedure.

   procedure Tree_Read_Int (N : out Int);
   --  Reads a single integer value. The integer must have been written with
   --  a call to the Tree_Write_Int procedure.

   procedure Tree_Read_Str (S : out String_Ptr);
   --  Read string, allocate on heap, and return pointer to allocated string
   --  which always has a lower bound of 1.

   procedure Tree_Read_Terminate;
   --  Called after reading all data, checks that the buffer pointers is at
   --  the end of file, raising Tree_Format_Error if not.

   procedure Tree_Write_Initialize (Desc : File_Descriptor);
   --  Called to initialize writing of a tree file. This call must be made
   --  before calls to Tree_Write_xx. No calls to Tree_Read_xx are permitted
   --  after this call.

   procedure Tree_Write_Data (Addr : Address; Length : Int);
   --  Writes Length then, if Length is not null, Length bytes of data
   --  starting at Addr to current tree file

   procedure Tree_Write_Bool (B : Boolean);
   --  Writes a single boolean value to the current tree file

   procedure Tree_Write_Char (C : Character);
   --  Writes a single character to the current tree file

   procedure Tree_Write_Int (N : Int);
   --  Writes a single integer value to the current tree file

   procedure Tree_Write_Str (S : String_Ptr);
   --  Write out string value referenced by S. Low bound must be 1.

   procedure Tree_Write_Terminate;
   --  Terminates writing of the file (flushing the buffer), but does not
   --  close the file (the caller is responsible for closing the file).

end Tree_IO;