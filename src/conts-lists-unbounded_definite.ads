--  Unbounded lists of constrained elements

pragma Ada_2012;

generic
   type Element_Type is private;

   Enable_Asserts : Boolean := False;
   --  If True, extra asserts are added to the code. Apart from them, this
   --  code runs with all compiler checks disabled.

package Conts.Lists.Unbounded_Definite is

   package Elements is new Definite_Elements_Traits (Element_Type);
   package Nodes is new Unbounded_List_Nodes_Traits
      (Elements              => Elements.Elements,
       Controlled_Or_Limited => Controlled_Base_List);
   package Lists is new Generic_Lists
      (All_Nodes      => Nodes.Nodes,
       Enable_Asserts => Enable_Asserts);
   use Lists;

   type List is new Lists.List with null record
      with Iterable => (First       => First_Primitive,
                        Next        => Next_Primitive,
                        Has_Element => Has_Element_Primitive,
                        Element     => Element_Primitive);
   subtype Cursor is Lists.Cursor;

   function First (Self : List'Class) return Cursor
      is (Lists.Class_Wide_First (Self));
   function Element (Self : List'Class; Position : Cursor) return Element_Type
      is (Lists.Class_Wide_Element (Self, Position));
   function Has_Element (Self : List'Class; Position : Cursor) return Boolean
      is (Lists.Class_Wide_Has_Element (Self, Position));
   function Next (Self : List'Class; Position : Cursor) return Cursor
      is (Lists.Class_Wide_Next (Self, Position));
   function Previous (Self : List'Class; Position : Cursor) return Cursor
      is (Lists.Class_Wide_Previous (Self, Position));
   pragma Inline (First, Element, Has_Element, Next, Previous);
   --  Renames for all the subprograms in Lists, for people that do not use
   --  the Ada2005 notation for primitive operations.
   --  Alternatively, people should "use" the Lists nested package.

   package Bidirectional_Cursors is new Bidirectional_Cursors_Traits
      (Container    => List'Class,
       Cursor       => Cursor,
       Element_Type => Element_Type);
   package Forward_Cursors renames Bidirectional_Cursors.Forward_Cursors;

end Conts.Lists.Unbounded_Definite;
