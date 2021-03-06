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

with Atree;
with Elists;
with Fname;
with Lib;
with Namet;
with Nlists;
with Opt;
with Osint.C;
with Repinfo;
with Sinput;
with Stand;
with Stringt;
with Uintp;
with Urealp;

procedure Tree_Gen is
begin
   if Opt.Tree_Output then
      Osint.C.Tree_Create;
      Opt.Tree_Write;
      Atree.Tree_Write;
      Elists.Tree_Write;
      Fname.Tree_Write;
      Lib.Tree_Write;
      Namet.Tree_Write;
      Nlists.Tree_Write;
      Sinput.Tree_Write;
      Stand.Tree_Write;
      Stringt.Tree_Write;
      Uintp.Tree_Write;
      Urealp.Tree_Write;
      Repinfo.Tree_Write;
      Osint.C.Tree_Close;
   end if;
end Tree_Gen;
