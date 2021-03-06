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

--  This package provides a set of routines to deal with file extensions

with Ada.Strings.Fixed;
with MLib.Tgt;

package body MLib.Fil is

   use Ada;

   package Target renames MLib.Tgt;

   ------------
   -- Ext_To --
   ------------

   function Ext_To
     (Filename : String;
      New_Ext  : String := "")
      return     String
   is
      use Strings.Fixed;
      J : constant Natural :=
            Index (Source  =>  Filename,
                   Pattern => ".",
                   Going   => Strings.Backward);

   begin
      if J = 0 then
         if New_Ext = "" then
            return Filename;
         else
            return Filename & "." & New_Ext;
         end if;

      else
         if New_Ext = "" then
            return Head (Filename, J - 1);
         else
            return Head (Filename, J - 1) & '.' & New_Ext;
         end if;
      end if;
   end Ext_To;

   -------------
   -- Get_Ext --
   -------------

   function Get_Ext (Filename : in String) return String is
      use Strings.Fixed;

      J : constant Natural :=
            Index (Source  =>  Filename,
                   Pattern => ".",
                   Going   => Strings.Backward);

   begin
      if J = 0 then
         return "";
      else
         return Filename (J .. Filename'Last);
      end if;
   end Get_Ext;

   ----------------
   -- Is_Archive --
   ----------------

   function Is_Archive (Filename : String) return Boolean is
      Ext : constant String := Get_Ext (Filename);

   begin
      return Target.Is_Archive_Ext (Ext);
   end Is_Archive;

   ----------
   -- Is_C --
   ----------

   function Is_C (Filename : in String) return Boolean is
      Ext : constant String := Get_Ext (Filename);

   begin
      return Target.Is_C_Ext (Ext);
   end Is_C;

   ------------
   -- Is_Obj --
   ------------

   function Is_Obj (Filename : in String) return Boolean is
      Ext : constant String := Get_Ext (Filename);

   begin
      return Target.Is_Object_Ext (Ext);
   end Is_Obj;

end MLib.Fil;
