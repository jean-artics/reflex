------------------------------------------------------------------------------
--                                                                          --
--                         REFLEX COMPILER COMPONENTS                       --
--                                                                          --
--          Copyright (C) 1992-2011, Free Software Foundation, Inc.         --
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
-- Reflex is originally developed  by the Artics team at Grenoble.          --
--                                                                          --
------------------------------------------------------------------------------

package body Artics.String_Stream is

   -----------
   -- Write --
   -----------

   procedure Write
     (Stream : in out String_Stream_Type;
      Item   : Stream_Element_Array)
   is
      Str : String (1 .. Integer (Item'Length));
      S   : Integer := Str'First;
   begin
      for J in Item'Range loop
         Str (S) := Character'Val (Item (J));
         S := S + 1;
      end loop;
      Append (Stream.Str, Str);
   end Write;

   ----------
   -- Open --
   ----------

   procedure Open
     (Stream : in out String_Stream_Type'Class;
      Str    : String) is
   begin
      Stream.Str        := To_Unbounded_String (Str);
      Stream.Read_Index := 1;
   end Open;

   ----------
   -- Read --
   ----------

   procedure Read
     (Stream : in out String_Stream_Type;
      Item   :    out Stream_Element_Array;
      Last   :    out Stream_Element_Offset)
   is
      Str : constant String := Slice
        (Stream.Str, Stream.Read_Index, Stream.Read_Index + Item'Length - 1);
      J   : Stream_Element_Offset := Item'First;
   begin
      for S in Str'Range loop
         Item (J) := Stream_Element (Character'Pos (Str (S)));
         J := J + 1;
      end loop;
      Last := Item'First + Str'Length - 1;
      Stream.Read_Index := Stream.Read_Index + Item'Length;
   end Read;

end Artics.String_Stream;
