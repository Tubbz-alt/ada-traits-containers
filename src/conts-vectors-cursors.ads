------------------------------------------------------------------------------
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
-- This library is free software;  you can redistribute it and/or modify it --
-- under terms of the  GNU General Public License  as published by the Free --
-- Software  Foundation;  either version 3,  or (at your  option) any later --
-- version. This library is distributed in the hope that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE.                            --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

--  Convenience package for creating the cursors traits for a Vector.
--  These cursor traits cannot be instantiated in Generic_Vectors itself,
--  since the Vector type is frozen too late.
--  We also assume that Vector might be a child of Vectors.Vector, not the
--  same type directly, so we need to have proxies for the cursor
--  subprograms

pragma Ada_2012;
with Conts.Cursors;
with Conts.Vectors.Generics;

generic
   with package Vectors is new Conts.Vectors.Generics (<>);
package Conts.Vectors.Cursors with SPARK_Mode is

   subtype Vector   is Vectors.Vector;
   subtype Index    is Vectors.Index_Type;

   package Impl is
      function Index_First (Self : Vector'Class) return Index
         is (Index'First) with Inline;

      function "-" (Left, Right : Index) return Integer
         is (Integer (Vectors.To_Count (Left))
             - Integer (Vectors.To_Count (Right)));

      function "+" (Left : Index; N : Integer) return Index
         is (Vectors.To_Index
              (Count_Type (Integer (Vectors.To_Count (Left)) + N)));
   end Impl;

   package Random_Cursors is new Conts.Cursors.Random_Traits
     (Container_Type => Vector'Class,
      Index_Type     => Index,
      Returned_Type  => Vectors.Nodes.Elements.Returned,
      Element_Type   => Vectors.Nodes.Elements.Element,
      First          => Impl.Index_First,
      Element        => Vectors.Element,
      Set_Element    => Vectors.Replace_Element,
      Last           => Vectors.Last,
      "-"            => Impl."-",
      "+"            => Impl."+");
   package Constant_Random renames Random_Cursors.Constant_Random;
   package Constant_Bidirectional
      renames Constant_Random.Constant_Bidirectional;
   package Constant_Forward renames Constant_Bidirectional.Constant_Forward;

end Conts.Vectors.Cursors;
