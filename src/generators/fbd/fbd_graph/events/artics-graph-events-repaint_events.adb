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

with Ada.Unchecked_Deallocation;

package body Artics.Graph.Events.Repaint_Events is
   
   ------------------------
   -- New_Repaint_Event --
   ------------------------
   
   function New_Repaint_Event return Repaint_Event_Ptr is
      Evt : Repaint_Event_Ptr := 
	new Repaint_Event_Record'(No_Repaint_Event_Record);
   begin
      Set_Event_Type (Evt, Event_Repaint);
      return Evt;
  end New_Repaint_Event;
  
   -----------------------
   -- New_Repaint_Event --
   -----------------------
   
  function New_Repaint_Event 
    (Region : Rectangle_Record) return Repaint_Event_Ptr is
     
     Evt : Repaint_Event_Ptr := New_Repaint_Event;
  begin
     Evt.Region := Region;
     return Evt;
  end New_Repaint_Event;
  
  ------------------------
  -- Free_Repaint_Event --
  ------------------------
  
  procedure Free_Repaint_Event (This : in out Repaint_Event_Ptr) is
     procedure Free is new Ada.Unchecked_Deallocation
       (Repaint_Event_Record, Repaint_Event_Ptr);
  begin
     Free (This);
  end Free_Repaint_Event;
  
  ----------------
  -- Get_Region --
  ----------------
  
  function Get_Region
    (Evt : access Repaint_Event_Record) return Rectangle_Record is
  begin
     return Evt.Region;
  end Get_Region;
  
  ----------------
   -- Set_Region --
   ----------------
   
   procedure Set_Region
     (Evt    : access Repaint_Event_Record;
      Region : Rectangle_Record) is
   begin
      Evt.Region := Region;
   end Set_Region;
   
end Artics.Graph.Events.Repaint_Events;
