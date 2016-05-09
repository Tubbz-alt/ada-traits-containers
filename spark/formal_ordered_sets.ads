pragma Ada_2012;
with Functional_Sequences;
with Functional_Maps;
with Functional_Sets;

generic
   type Element_Type (<>) is private;
   with function "<" (E1, E2 : Element_Type) return Boolean;
   --  Comparison over elements. BEWARE: "=" and "<" should be compatible.

package Formal_Ordered_Sets with SPARK_Mode is

   package Element_Sets is
      type Set is tagged limited private;
      type Cursor is private;
      No_Element : constant Cursor;
   private
      pragma SPARK_Mode (Off);
      type Cursor is record
         I : Natural;
      end record;
      type Set is tagged limited null record;
      No_Element : constant Cursor := (I => 0);
   end Element_Sets;
   --  Instance of the container package. That would be better if it was
   --  instantiated in the private part but then the Cursor type could not be
   --  used to instanciate the Functional_Maps package for the Formal_Model.
   --  To be replaced with an instance of the proper Set package.

   subtype Cursor is Element_Sets.Cursor;
   use all type Element_Sets.Cursor;
   pragma Unevaluated_Use_Of_Old (Allow);

   No_Element : Cursor renames Element_Sets.No_Element;

   type Set is tagged limited private with
     Default_Initial_Condition => Length (Set) = 0,
     Iterable => (First       => First_Primitive,
                  Next        => Next_Primitive,
                  Has_Element => Has_Element_Primitive,
                  Element     => Element_Primitive);
   --  Sets are empty when default initialized

   function Capacity (Self : Set'Class) return Natural with
     Import;

   function Length (Self : Set'Class) return Natural with
     Import,
     Post => Length'Result <= Capacity (Self);
   --  The length of a set is always smaller than its capacity

   package Formal_Model is

      --  This package should be Ghost if possible. Currently, the compiler
      --  complains that the parent type of a Ghost type extension shall be
      --  Ghost (see OA30-006).

      package P is new Functional_Maps
        (Element_Type => Positive,
         Key_Type     => Cursor);
      package E is new Functional_Sequences
        (Index_Type   => Positive,
         Element_Type => Element_Type);
      package M is new Functional_Sets
        (Element_Type => Element_Type);

      function Model (Self : Set'Class) return M.Set with
        Import;
      --  The highlevel model of a set is a set of elements. Neither cursors
      --  nor order of elements are represented in this model.

      pragma Annotate (GNATprove, Iterable_For_Proof, "Model", Model);

      function Elements (Self : Set'Class) return E.Sequence with
      --  The Elements sequence represents the underlying list structure of
      --  sets that is used for iteration. It does not model cursors.

        Import,
        Post => E.Length (Elements'Result) = Length (Self)

        --  It only contains elements contained of Model.

        and then (for all I in 1 .. Length (Self) =>
                      M.Mem (Model (Self), E.Get (Elements'Result, I)))

        --  It contains all the elements contained of Model.

        and then (for all Element of Model (Self) =>
                      (for some I in 1 .. Length (Self) =>
                             E.Get (Elements'Result, I) = Element))

        --  It is sorted in increasing order.

        and then
            (for all I in 1 .. Length (Self) =>
               (for all J in 1 .. Length (Self) =>
                    (E.Get (Elements'Result, I) < E.Get (Elements'Result, J))
                      = (I < J)));

      function Positions (Self : Set'Class) return P.Map with
      --  The Positions map is used to model cursors. It only contains valid
      --  cursors and map them to their position in the container.

        Import,
        Post => not P.Mem (Positions'Result, No_Element)

        --  Positions of cursors are smaller than the container's length.

        and then
          (for all I of Positions'Result =>
             P.Get (Positions'Result, I) in 1 .. Length (Self)

           --  No two cursors have the same position. Note that we do not state
           --  that there is a cursor in the map for each position, as it is
           --  rarely needed.

           and then
             (for all J of Positions'Result =>
                (if P.Get (Positions'Result, I) = P.Get (Positions'Result, J)
                 then I = J)));

      procedure Lift_Abstraction_Level (Self : Set'Class) with
        Import,
        Global => null,
        Post   =>
          (for all I in 1 .. Length (Self) =>
             (for some Position of Positions (Self) =>
                E.Get (Elements (Self),  P.Get (Positions (Self), Position)) =
                E.Get (Elements (Self), I)));
      --  Lift_Abstraction_Level is a ghost procedure that does nothing but
      --  assume that we can access to the same elements by iterating over
      --  positions or cursors.
      --  This information is not generally useful except when switching from
      --  a lowlevel, cursor aware view of a container, to a highlevel position
      --  based view.
   end Formal_Model;

   package M renames Formal_Model.M;
   package E renames Formal_Model.E;
   package P renames Formal_Model.P;

   use type M.Set;
   use type E.Sequence;
   use type P.Map;

   function Model (Self : Set'Class) return M.Set
                   renames Formal_Model.Model;
   function Elements (Self : Set'Class) return E.Sequence
                   renames Formal_Model.Elements;
   function Positions (Self : Set'Class) return P.Map
                   renames Formal_Model.Positions;

   function Element (Self : Set'Class; Position : Cursor) return Element_Type
   with
     Import,
     Pre  => P.Mem (Positions (Self), Position),

     --  Query Positions to get the position of Position in L and use it to
     --  fetch the corresponding element in Elements.

     Post => Element'Result =
       E.Get (Elements (Self), P.Get (Positions (Self), Position));

   --  The subprograms used for iteration over cursors are axiomatized using
   --  Positions only. They are inverse of the Positions map as they allow
   --  to create a valid cursor per position in the container.

   function First (Self : Set'Class) return Cursor with
     Import,
     Post => (if Length (Self) = 0 then First'Result = No_Element
              else P.Mem (Positions (Self), First'Result) and then
                  P.Get (Positions (Self), First'Result) = 1);

   procedure Next (Self : Set'Class; Position : in out Cursor) with
     Import,
     Pre  => P.Mem (Positions (Self), Position),
     Post => (if P.Get (Positions (Self), Position'Old) = Length (Self)
              then Position = No_Element
              else P.Mem (Positions (Self), Position)
                and then P.Get (Positions (Self), Position) =
                  P.Get (Positions (Self), Position'Old) + 1);

   function Has_Element (Self : Set'Class; Position : Cursor) return Boolean
   with
     Import,
     Post => Has_Element'Result = P.Mem (Positions (Self), Position);

   function Contains (Self : Set'Class; Element : Element_Type) return Boolean
   with
     Import,
     Post => Contains'Result = M.Mem (Model (Self), Element);

   function Find (Self : Set'Class; Element : Element_Type) return Cursor with
     Import,
     Post =>

       --  Either Element is not in the model and the result is No_Element

       (Find'Result = No_Element
        and not M.Mem (Model (Self), Element))

     --  or the result is a valid cursor and Element is stored at its position
     --  in S.

     or else
       (M.Mem (Model (Self), Element)
        and P.Mem (Positions (Self), Find'Result)
        and E.Get (Elements (Self),
                 P.Get (Positions (Self), Find'Result)) = Element);

   procedure Include (Self : in out Set'Class; Element : Element_Type) with
   --  Insert an element Element in Self if Element is not already in present.

     Import,
     Pre  => Length (Self) < Capacity (Self)
     or else M.Mem (Model (Self), Element),
     Post => Capacity (Self) = Capacity (Self)'Old

     --  If Element is already in Self, then the model is unchanged.

     and (if M.Mem (Model (Self)'Old, Element) then
            Length (Self) = Length (Self)'Old
            and Model (Self) = Model (Self)'Old
            and Elements (Self) = Elements (Self)'Old
            and Positions (Self) = Positions (Self)'Old

            --  If Element is not in Self, then Element is a new element of its
            --  model.

          else Length (Self) = Length (Self)'Old + 1
            and M.Is_Add (Model (Self)'Old, Element, Model (Self))

            --  Elements that are located before Element in Self are preserved.

            and (for all I in 1 .. Length (Self) - 1 =>
                  (if I < P.Get (Positions (Self), Find (Self, Element))
                   then E.Get (Elements (Self)'Old, I) =
                        E.Get (Elements (Self), I)

                   --  Other elements are shifted by 1.

                   else E.Get (Elements (Self)'Old, I) =
                       E.Get (Elements (Self), I + 1)))

            --  Cursors that were valid in Self are still valid and continue
            --  designating the same element.

            and (for all Position of Positions (Self)'Old =>
                   P.Mem (Positions (Self), Position) and
                 E.Get (Elements (Self), P.Get (Positions (Self), Position)) =
                 E.Get (Elements (Self)'Old,
                        P.Get (Positions (Self)'Old, Position)))

            --  Cursors designating elements smaller than Element in Self are
            --  preserved.

            and (for all Position of Positions (Self)'Old =>
                   (if E.Get (Elements (Self),
                            P.Get (Positions (Self), Position)) < Element
                    then P.Get (Positions (Self), Position) =
                         P.Get (Positions (Self)'Old, Position)

                    --  Other cursors are shifted by 1.

                    else P.Get (Positions (Self), Position) =
                         P.Get (Positions (Self)'Old, Position) + 1)));

   procedure Exclude (Self : in out Set'Class; Element : Element_Type) with
   --  Remove an element Element of Self if it is present.

     Import,
     Post => Capacity (Self) = Capacity (Self)'Old

     --  If Element is not in Self, then the model is unchanged.

     and (if not M.Mem (Model (Self)'Old, Element) then
            Length (Self) = Length (Self)'Old
            and Model (Self) = Model (Self)'Old
            and Elements (Self) = Elements (Self)'Old
            and Positions (Self) = Positions (Self)'Old

          --  If Element is in Self, then Element is removed from its model.

          else Length (Self) = Length (Self)'Old - 1
            and M.Is_Add (Model (Self), Element, Model (Self)'Old)

            --  Elements that were located before Element in Self are
            --  preserved.

            and (for all I in 1 .. Length (Self) =>
                  (if I < P.Get (Positions (Self)'Old,
                                  Find (Self, Element)'Old)
                   then E.Get (Elements (Self), I) =
                        E.Get (Elements (Self)'Old, I)

                   --  Other elements are shifted by 1.

                   else E.Get (Elements (Self), I) =
                        E.Get (Elements (Self)'Old, I + 1)))

            --  Cursors that are valid in Self were already valid and continue
            --  designating the same element.

            and (for all Position of Positions (Self) =>
                   P.Mem (Positions (Self)'Old, Position) and
                 E.Get (Elements (Self), P.Get (Positions (Self), Position)) =
                 E.Get (Elements (Self)'Old,
                        P.Get (Positions (Self)'Old, Position)))

            --  Cursors designating elements smaller than Element in Self are
            --  preserved.

            and (for all Position of Positions (Self) =>
                   (if E.Get (Elements (Self),
                            P.Get (Positions (Self), Position)) < Element
                    then P.Get (Positions (Self)'Old, Position) =
                         P.Get (Positions (Self), Position)

                    --  Other cursors are shifted by 1.

                    else P.Get (Positions (Self)'Old, Position) =
                         P.Get (Positions (Self), Position) + 1)));

   procedure Union (Self : in out Set'Class; Source : Set'Class) with
   --  Include in Self all the elements of Source

     Import,
     Pre  => Length (Source) <= Capacity (Self) - Length (Self),
     Post => Capacity (Self) = Capacity (Self)'Old

     --  The model of Self is the union of the previous model of Self and the
     --  model of Source.

     and M.Is_Union (Model (Self)'Old, Model (Source), Model (Self))

     --  No more than Length (Source) elements were added to Source. We could
     --  be more precise by using the length of the Intersection if we had a
     --  notion of length on functional sets.

     and Length (Self) in
       Length (Self)'Old .. Length (Self)'Old + Length (Source)

     --  Cursors that were valid in Self are still valid and continue
     --  designating the same element.
     --  Nothing is said about the order of elements in Self after the call.

     and (for all Position of Positions (Self)'Old =>
              P.Mem (Positions (Self), Position)
          and E.Get (Elements (Self), P.Get (Positions (Self), Position)) =
              E.Get (Elements (Self)'Old,
                     P.Get (Positions (Self)'Old, Position)));

   procedure Intersection (Self : in out Set'Class; Source : Set'Class) with
   --  Exclude from Self all the elements of Source

     Import,
     Post => Capacity (Self) = Capacity (Self)'Old

     --  The model of Self is the intersection of the previous model of Self
     --  and the model of Source.

     and M.Is_Intersection (Model (Self)'Old, Model (Source), Model (Self))

     --  The length of Self can only have shrinked. We could be more precise by
     --  stating that at most Length (Source) elements have been removed from
     --  Self.

     and Length (Self) in 0 .. Length (Self)'Old

     --  Cursors that are valid in Self we already valid and continue
     --  designating the same element.
     --  Nothing is said about the order of elements in Self after the call.

     and (for all Position of Positions (Self) =>
              P.Mem (Positions (Self)'Old, Position)
          and E.Get (Elements (Self), P.Get (Positions (Self), Position)) =
            E.Get (Elements (Self)'Old,
                   P.Get (Positions (Self)'Old, Position)));

   procedure Clear (Self : in out Set'Class)
   with
     Import,
     Post => Capacity (Self) = Capacity (Self)'Old
     and then Length (Self) = 0
     and then M.Is_Empty (Model (Self));

   function First_Primitive (Self : Set) return Cursor with Import;
   function Element_Primitive
     (Self : Set; Position : Cursor) return Element_Type
   with
     Import,
     Pre'Class => Has_Element (Self, Position),
     Post'Class => Has_Element (Self, Position)
       and then Element_Primitive'Result = Element (Self, Position);
   function Has_Element_Primitive
     (Self : Set; Position : Cursor) return Boolean
   with
     Import,
     Post'Class =>
       Has_Element_Primitive'Result = Has_Element (Self, Position);
   function Next_Primitive
     (Self : Set; Position : Cursor) return Cursor
   with
     Import,
     Pre'Class => Has_Element (Self, Position);

private
   pragma SPARK_Mode (Off);

   type Set is new Element_Sets.Set with null record;

end Formal_Ordered_Sets;
