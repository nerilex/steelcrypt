--  Copyright (C) 2015  bg nerilex <bg@nerilex.org>
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

with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Crypto.Types; use Crypto.Types;
with Crypto.Types.X;
 use Crypto.Types.X.Utils_u8;

with Pi32Cipher_Spec;

procedure Test_Pi32Cipher is

   package PiCipher renames Pi32Cipher_Spec;

   type Arcfour_SBox_T is array (u8) of u8;

   type Arcfour_Context_T is record
      S : Arcfour_SBox_T;
      I : u8;
      J : u8;
   end record;

   Prng : Arcfour_Context_T;

   procedure Initialize_Prng (Key : in u8_Array) is
      j : u8 := 0;
   begin
      for i in u8'Range loop
         Prng.S (i) := i;
      end loop;
      for i in u8'Range loop
         j := j + Prng.S (i) + Key (Key'First + Integer (i) mod Key'Length);
         Swap (Prng.S (i), Prng.S (j));
      end loop;
      Prng.I := 0;
      Prng.J := 0;
   end Initialize_Prng;

   function Random_Byte return u8 is
   begin
      Prng.I := Prng.I + 1;
      Prng.J := Prng.J + Prng.S (Prng.I);
      Swap (Prng.S (Prng.I), Prng.S (Prng.J));
      return Prng.S (Prng.S (Prng.I) + Prng.S (Prng.J));
   end Random_Byte;

   procedure Random_Fill (Data : out u8_Array) is
   begin
      for i in Data'Range loop
         Data (i) := Random_Byte;
      end loop;
   end Random_Fill;

   procedure Print_Item (Label : in String; Data : in u8_Array) is
   begin
      Put_Line
        (Label &
         " (" &
         Trim (Source => Integer'Image (Data'Length), Side => Both) &
         ") = " &
         To_Hex (A => Data, Upper_Case => True));
   end Print_Item;

   procedure Single_Testvector
     (Msg          : in u8_Array;
      AD           : in u8_Array;
      Secret_Nonce : in u8_Array;
      Public_Nonce : in u8_Array;
      Key          : in u8_Array)
   is
      Msg_Check : u8_Array (Msg'Range);
      Smn_Check : u8_Array (Secret_Nonce'Range);
      Is_Valid  : Boolean;
      Crypt     : constant u8_Array :=
        PiCipher.Encrypt
          (Msg          => Msg,
           AD           => AD,
           Public_Nonce => Public_Nonce,
           Secret_Nonce => Secret_Nonce,
           Key          => Key);
   begin
      Print_Item ("KEY", Key);
      Print_Item ("NPUB", Public_Nonce);
      Print_Item ("NSEC", Secret_Nonce);
      Print_Item ("MSG", Msg);
      Print_Item ("AD", AD);
      Print_Item ("CIPHER", Crypt);
      PiCipher.Decrypt
        (Is_Valid     => Is_Valid,
         Msg          => Msg_Check,
         Secret_Nonce => Smn_Check,
         Cipher       => Crypt,
         AD           => AD,
         Public_Nonce => Public_Nonce,
         Key          => Key);
      if not Is_Valid then
         Put_Line ("! Error: verification failed!");
      end if;
      New_Line;
   end Single_Testvector;

   procedure Testvectors
     (Key_Length          : in Natural;
      Public_Nonce_Length : in Natural)
   is
      Msg          : u8_Array (1 .. 3 * PiCipher.Block_Bytes / 2);
      AD           : u8_Array (1 .. 3 * PiCipher.Block_Bytes / 2);
      Public_Nonce : u8_Array (1 .. Public_Nonce_Length);
      Secret_Nonce : u8_Array (1 .. PiCipher.Secret_Message_Number_Bytes);
      Key          : u8_Array (1 .. Key_Length);
      Counter      : Positive := 1;
   begin
      declare
         Key_Bits : constant String :=
           Trim (Source => Integer'Image (Key_Length * 8), Side => Both);
         Seed : constant String :=
           PiCipher.Cipher_Name &
           ((3 - Key_Bits'Length) * "0") &
           Key_Bits &
           "v2 (" &
           Trim (Source => Integer'Image (Public_Nonce_Length), Side => Both) &
           " byte nonce)";
      begin
         Initialize_Prng (From_Ascii (Seed));
      end;

      for Msg_Len in 0 .. Msg'Last loop
         for AD_Len in 0 .. AD'Last loop
            Put_Line
              ("[msg_len = " & Trim (Integer'Image (Msg_Len), Both) & "]");
            Put_Line
              ("[ad_len = " & Trim (Integer'Image (AD_Len), Both) & "]");
            New_Line;
            for i in 1 .. 9 loop
               Put_Line
                 ("[vector #" &
                  Trim (Integer'Image (Counter), Both) &
                  " (" &
                  Trim (Integer'Image (i), Both) &
                  ")]");
               Counter := Counter + 1;
               Random_Fill (Key);
               Random_Fill (Public_Nonce);
               if i < 9 then
                  Random_Fill (Secret_Nonce);
               end if;
               Random_Fill (AD (1 .. AD_Len));
               Random_Fill (Msg (1 .. Msg_Len));
               if i < 9 then
                  Single_Testvector
                    (Msg          => Msg (1 .. Msg_Len),
                     AD           => AD (1 .. AD_Len),
                     Secret_Nonce => Secret_Nonce,
                     Public_Nonce => Public_Nonce,
                     Key          => Key);
               else
                  Single_Testvector
                    (Msg          => Msg (1 .. Msg_Len),
                     AD           => AD (1 .. AD_Len),
                     Secret_Nonce => Secret_Nonce (1 .. 0),
                     Public_Nonce => Public_Nonce,
                     Key          => Key);
               end if;
            end loop;
         end loop;
      end loop;

   end Testvectors;

   Key_Sizes           : constant array (1 .. 2) of Natural := (128, 256);
   Public_Nonce_Length : constant                           := 16;
   File                : File_Type;
begin
   for i in Key_Sizes'Range loop
      Create
        (File => File,
         Name =>
           "testvectors/pi-cipher/" &
           PiCipher.Cipher_Name &
           Trim (Integer'Image (Key_Sizes (i)), Both) &
           "_" &
           Trim (Integer'Image (Public_Nonce_Length), Both) &
           ".test-vectors",
         Mode => Out_File);
      Set_Output (File);
      Put_Line ("# Testvectors for " & PiCipher.Cipher_Name);
      Put_Line
        ("#   key size: " &
         Trim (Integer'Image (Key_Sizes (i)), Both) &
         " bits");
      Put_Line
        ("#   nonce size: " &
         Trim (Integer'Image (Public_Nonce_Length * 8), Both) &
         " bits");
      New_Line;
      Testvectors (Key_Sizes (i) / 8, Public_Nonce_Length);
      Close (File);
      Set_Output (Standard_Output);
   end loop;

end Test_Pi32Cipher;
