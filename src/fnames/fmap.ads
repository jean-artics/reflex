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

--  This package keeps two mappings: from unit names to file names,
--  and from file names to path names.

with Types; use Types;
with Namet; use Namet;

package Fmap is

   procedure Initialize (File_Name : String);
   --  Initialize the mappings from the mapping file File_Name.
   --  If the mapping file is incorrect (non existent file, truncated file,
   --  duplicate entries), output a warning and do not initialize the mappings.
   --  Record the state of the mapping tables in case Update is called
   --  later on.

   function Mapped_Path_Name (File : File_Name_Type) return File_Name_Type;
   --  Return the path name mapped to the file name File.
   --  Return No_File if File is not mapped.

   function Mapped_File_Name (Unit : Unit_Name_Type) return File_Name_Type;
   --  Return the file name mapped to the unit name Unit.
   --  Return No_File if Unit is not mapped.
   --  Return Error_Name if it is forbidden.

   procedure Add_To_File_Map
     (Unit_Name : Unit_Name_Type;
      File_Name : File_Name_Type;
      Path_Name : File_Name_Type);
   --  Add mapping of Unit_Name to File_Name and of File_Name to Path_Name

   procedure Update_Mapping_File (File_Name : String);
   --  If Add_To_File_Map has been called (after Initialize or any time
   --  if Initialize has not been called), append the new entries to the
   --  mapping file whose file name is File_Name.

   procedure Reset_Tables;
   --  Initialize all the internal data structures. This procedure is used
   --  when several compilations are performed by the same process (by GNSA
   --  for ASIS, for example) to remove any existing mappings from a previous
   --  compilation.

   procedure Add_Forbidden_File_Name (Name : Name_Id);
   --  Indicate that a source file name is forbidden.
   --  This is used by gnatmake when there are Locally_Removed_Files in
   --  extending projects.

   procedure Remove_Forbidden_File_Name (Name : Name_Id);
   --  Indicate that a source file name that was forbidden is no longer
   --  forbidden. Used by gnatmake when a locally removed file is redefined
   --  in another extending project.

end Fmap;
