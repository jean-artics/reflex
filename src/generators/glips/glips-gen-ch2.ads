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

package Glips.Gen.Ch2 is

   procedure Generate_Defining_Character_Literal
     (This : access Glips_Generator_Record;
      Node : Node_id);

   procedure Generate_Defining_Identifier
     (This        : access Glips_Generator_Record;
      Node        : Node_Id;
      Declaration : Boolean := False);
   
   --  ??? procedure Generate_Defining_Operator_Symbol (Node : Node_id);

   procedure Generate_Expanded_Name
     (This : access Glips_Generator_Record;
      Node : Node_id);

   procedure Generate_Identifier
     (This : access Glips_Generator_Record;
      Node : Node_id);

   procedure Generate_Selected_Component
     (This : access Glips_Generator_Record;
      Node : Node_id);
   
   procedure Generate_Type_Name
     (This : access Glips_Generator_Record;
      Typ  : Entity_Id);
   
end Glips.Gen.Ch2;
