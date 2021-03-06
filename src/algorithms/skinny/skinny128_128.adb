--  Copyright (C) 2017  bg nerilex <bg@nerilex.org>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
with Skinny_Types; use Skinny_Types;

package body Skinny128_128 is

   function Initialize (Tweakey : in Key_T) return Context_T is
   begin
      return Context_T(Core.Initialize(Tweakey));
   end Initialize;

   function Encrypt
     (Context : in Context_T;
      Block   : in Block_T) return Block_T is
   begin
      return Core.Encrypt(Core.Context_T(Context), Block);
   end;

   function Decrypt
     (Context : in Context_T;
      Block   : in Block_T) return Block_T is
   begin
      return Core.Decrypt(Core.Context_T(Context), Block);
   end;

   function Permute_State(In_State : State_T) return State_T is
      type Map_Entry_T is record
         Row : Row_Index_T;
         Col : Column_Index_T;
      end record;
      Map : constant array (Row_Index_T, Column_Index_T) of Map_Entry_T :=
        ( ((3, 2), (4, 4), (3, 1), (4, 2)),
          ((3, 3), (4, 3), (4, 1), (3, 4)),
          ((1, 1), (1, 2), (1, 3), (1, 4)),
          ((2, 1), (2, 2), (2, 3), (2, 4)) );
      Tmp : State_T;
      index : Map_Entry_T;
   begin
      for row in Row_Index_T loop
         for col in Column_Index_T loop
            index := Map(row, col);
            Tmp(row)(col) := In_State(index.Row)(index.Col);
         end loop;
      end loop;
      return Tmp;
   end Permute_State;


   function TK_Update(Tk : Tweakey_State_T) return Tweakey_State_T is
      Tmp : Tweakey_State_T;
   begin
      Tmp(1) := Permute_State(Tk(1));
      return Tmp;
   end;

   function Get_Round_Tweakey(Tk : Tweakey_State_T) return Round_Tweakey_T is
      Round_Tweakey : Round_Tweakey_T;
      Tmp : Cell_T;
      Col : Column_Index_T;
      Row : Row_Index_T;
   begin
      for  i in 0 .. Round_Tweakey'Length - 1 loop
         Tmp := 0;
         Row := Row_Index_T(1 + (i / 4));
         Col := Column_Index_T(1 + (i mod 4));
         for state in Tk'Range loop
            Tmp := Tmp xor Tk(state)(Row)(Col);
         end loop;
         Round_Tweakey(Round_Tweakey'First + i) := Tmp;
      end loop;

      return Round_Tweakey;
   end;

   function Load_Tweakey(Key : u8_Array) return Tweakey_State_T is
      Tk : Tweakey_State_T;
   begin
      Tk(1)(1) := Row_T(Key( 1 ..  4));
      Tk(1)(2) := Row_T(Key( 5 ..  8));
      Tk(1)(3) := Row_T(Key( 9 .. 12));
      Tk(1)(4) := Row_T(Key(13 .. 16));
      return Tk;
   end;



end Skinny128_128;
