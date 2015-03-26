pragma Ada_2012;
with Ada.Text_IO; use Ada.Text_IO;

package body Conts.Lists is

   -------------------------------
   -- Bounded_List_Nodes_Traits --
   -------------------------------

   package body Bounded_List_Nodes_Traits is

      --------------
      -- Allocate --
      --------------

      procedure Allocate
         (Self    : in out Nodes_List'Class;
          Element : Stored_Element_Type;
          N       : out Node_Access)
      is
      begin
         if Self.Free > 0 then
            N := Node_Access (Self.Free);
            Self.Free := Integer (Self.Nodes (Count_Type (N)).Next);
         else
            N := Node_Access (abs Self.Free + 1);
            Self.Free := Self.Free - 1;
         end if;

         Self.Nodes (Count_Type (N)) :=
            (Element  => Element,
             Previous => Null_Node_Access,
             Next     => Null_Node_Access);
      end Allocate;

      --------------
      -- Set_Next --
      --------------

      procedure Set_Next
         (Self : in out Nodes_List'Class; N, Next : Node_Access) is
      begin
         Self.Nodes (Count_Type (N)).Next := Next;
      end Set_Next;

      ------------------
      -- Set_Previous --
      ------------------

      procedure Set_Previous
         (Self : in out Nodes_List'Class; N, Previous : Node_Access) is
      begin
         Self.Nodes (Count_Type (N)).Previous := Previous;
      end Set_Previous;
   end Bounded_List_Nodes_Traits;

   ---------------------------------
   -- Unbounded_List_Nodes_Traits --
   ---------------------------------

   package body Unbounded_List_Nodes_Traits is

      --------------
      -- Allocate --
      --------------

      procedure Allocate
         (Self    : in out Nodes_Container'Class;
          Element : Stored_Element_Type;
          N       : out Node_Access)
      is
         pragma Unreferenced (Self);
      begin
         N := new Node;
         if N /= null then
            N.Element := Element;
         end if;
      end Allocate;

      --------------
      -- Set_Next --
      --------------

      procedure Set_Next
         (Self : in out Nodes_Container'Class; N, Next : Node_Access)
      is
         pragma Unreferenced (Self);
      begin
         N.Next := Next;
      end Set_Next;

      ------------------
      -- Set_Previous --
      ------------------

      procedure Set_Previous
         (Self : in out Nodes_Container'Class; N, Previous : Node_Access)
      is
         pragma Unreferenced (Self);
      begin
         N.Previous := Previous;
      end Set_Previous;

   end Unbounded_List_Nodes_Traits;

   -------------------
   -- Generic_Lists --
   -------------------

   package body Generic_Lists is
      use All_Nodes;

      ------------
      -- Append --
      ------------

      procedure Append
         (Self    : in out List'Class;
          Element : Element_Type)
      is
         N : Node_Access;
      begin
         Allocate
            (Self,
             All_Nodes.Elements.Convert_From (Element),
             New_Node => N);

         if Enable_Asserts and then N = Null_Access then
            raise Storage_Error with "Allocating node failed";
         end if;

         if Self.Tail = Null_Access then
            Self.Tail := N;
            Self.Head := Self.Tail;
         else
            Set_Next (Self, Self.Tail, Next => N);
            Set_Previous (Self, N, Previous => Self.Tail);
            Self.Tail := N;
         end if;

         Self.Size := Self.Size + 1;
      end Append;

      ------------
      -- Length --
      ------------

      function Length (Self : List'Class) return Count_Type is
      begin
         return Self.Size;
      end Length;

      --------------
      -- Capacity --
      --------------

      function Capacity (Self : List'Class) return Count_Type is
         pragma Unreferenced (Self);
      begin
         return Count_Type'Last;
      end Capacity;

      -----------
      -- First --
      -----------

      function First (Self : List'Class) return Cursor is
      begin
         return (Current => Self.Head);
      end First;

      -------------
      -- Element --
      -------------

      function Element
         (Self : List'Class; Position : Cursor) return Element_Type is
      begin
         if Enable_Asserts and then Position.Current = Null_Access then
            raise Program_Error with "Invalid position in list";
         end if;

         return All_Nodes.Elements.Convert_To
            (Get_Element (Self, Position.Current));
      end Element;

      --------------------
      -- Stored_Element --
      --------------------

      function Stored_Element
         (Self : List'Class; Position : Cursor) return Stored_Element_Type is
      begin
         if Enable_Asserts and then Position.Current = Null_Access then
            raise Program_Error with "Invalid position in list";
         end if;

         return Get_Element (Self, Position.Current);
      end Stored_Element;

      -----------------
      -- Has_Element --
      -----------------

      function Has_Element
         (Self : List'Class; Position : Cursor) return Boolean
      is
         pragma Unreferenced (Self);
      begin
         return Position.Current /= Null_Access;
      end Has_Element;

      ----------
      -- Next --
      ----------

      function Next
         (Self : List'Class; Position : Cursor) return Cursor is
      begin
         if Position.Current = Null_Access then
            return Position;
         else
            return (Current => Get_Next (Self, Position.Current));
         end if;
      end Next;

      --------------
      -- Previous --
      --------------

      function Previous
         (Self : List'Class; Position : Cursor) return Cursor is
      begin
         if Position.Current = Null_Access then
            return Position;
         else
            return (Current => Get_Previous (Self, Position.Current));
         end if;
      end Previous;

      ----------
      -- Next --
      ----------

      procedure Next (Self : List'Class; Position : in out Cursor) is
      begin
         Position := Next (Self, Position);
      end Next;

      --------------
      -- Finalize --
      --------------

      procedure Finalize (Self : in out List) is
         pragma Unreferenced (Self);
      begin
         Put ("Finalize");
      end Finalize;
   end Generic_Lists;

end Conts.Lists;
