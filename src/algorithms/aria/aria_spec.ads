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

with Crypto.Types; use Crypto.Types;
with Crypto.Types.X;

use Crypto.Types.X.Utils_u8;

package ARIA_Spec is

   subtype Key_128 is Block_128_Bit;
   subtype Key_192 is Block_192_Bit;
   subtype Key_256 is Block_256_Bit;

   type Context_T is private;

   type Plaintext is new Block_128_Bit;
   type Ciphertext is new Block_128_Bit;

   procedure Initialize (Context : out Context_T; Key : in u8_Array);
   procedure Encrypt (Context : in Context_T; Block : in out Block_128_Bit);
   procedure Decrypt (Context : in Context_T; Block : in out Block_128_Bit);

private

   type PreKey_T is new Block_128_Bit;
   type PreKeys_T is array (1 .. 4) of PreKey_T;
   type Num_Rounds is range 1 .. 16;

   type Context_T is record
      W      : PreKeys_T;
      Rounds : Num_Rounds;
   end record;

end ARIA_Spec;
