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
-- Reflex is originally developed by Artics
------------------------------------------------------------------------------

with Artics.Graph.Cells_Interfaces; use Artics.Graph.Cells_Interfaces;
with Artics.Objects; use Artics.Objects;

with Artics.Graph.Events; use Artics.Graph.Events;
with Artics.Geometry; use Artics.Geometry;
with Artics.Geometry.Points; use Artics.Geometry.Points;

package Artics.Graph.Events.Scale_And_Translate_Events is
   
   use Artics.Graph.Events.Graph_Events;
   use Artics.Graph.Events.Graph_Listeners;
   use Artics.Graph.Events.Graph_Events_Sources;
   
   type Scale_And_Translate_Event_Record is new Graph_Event_Record with private;
   type Scale_And_Translate_Event_Ptr is 
     access all Scale_And_Translate_Event_Record;
   type Scale_And_Translate_Event_Class_Ptr is 
     access all Scale_And_Translate_Event_Record'Class;
   
   No_Scale_And_Translate_Event_Record  : 
     constant Scale_And_Translate_Event_Record;
   
   function New_Scale_And_Translate_Event return Scale_And_Translate_Event_Ptr;
   
   function New_Scale_And_Translate_Event
     (Scale              : Coordinate;
      Previous_Scale     : Coordinate;
      Translate          : Point_Record;
      Previous_Translate : Point_Record)
     return Scale_And_Translate_Event_Ptr;
   
   procedure Free_Scale_And_Translate_Event
     (This : in out Scale_And_Translate_Event_Ptr);
   
   function Get_Scale
     (This : access Scale_And_Translate_Event_Record'Class) return Coordinate;
   
   procedure Set_Scale
     (This : access Scale_And_Translate_Event_Record'Class;
     Scale : Coordinate);
   
   function Get_Previous_Scale
     (This : access Scale_And_Translate_Event_Record'Class) return Coordinate;
   
   procedure Set_Previous_Scale
     (This : access Scale_And_Translate_Event_Record'Class;
     Scale : Coordinate);
   
   function Get_Translate
     (This : access Scale_And_Translate_Event_Record'Class) return Point_Record;
   
   procedure Set_Translate
     (This      : access Scale_And_Translate_Event_Record'Class;
      Translate : Point_Record);
   
   function Get_Previous_Translate
     (This : access Scale_And_Translate_Event_Record'Class) return Point_Record;
   
   procedure Set_Previous_Translate
     (This      : access Scale_And_Translate_Event_Record'Class;
      Translate : Point_Record);
   
private
   
   type Scale_And_Translate_Event_Record is new Graph_Event_Record with record
      Scale              : Coordinate;
      Previous_Scale     : Coordinate;
      Translate          : Point_Record;
      Previous_Translate : Point_Record;
   end record;
   
   No_Scale_And_Translate_Event_Record  : 
     constant Scale_And_Translate_Event_Record := 
     Scale_And_Translate_Event_Record'
     (No_Graph_Event_Record with 
      Scale              => No_Coordinate,
      Previous_Scale     => No_Coordinate,
      Translate          => No_Point_Record,
      Previous_Translate => No_Point_Record);
   
end Artics.Graph.Events.Scale_And_Translate_Events;
