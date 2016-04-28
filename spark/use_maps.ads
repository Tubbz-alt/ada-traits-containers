pragma Ada_2012;
with Formal_Hashed_Maps;
pragma Elaborate_All (Formal_Hashed_Maps);

package Use_Maps with SPARK_Mode is
   package My_Maps is new Formal_Hashed_Maps
     (Integer, Natural, 0);
   use My_Maps;
   use type My_Maps.Cursor;
   use My_Maps.Formal_Model.P;
   use My_Maps.Formal_Model.K;
   use My_Maps.Formal_Model.M;

   function My_Contains (S : My_Maps.Map; K : Positive) return Boolean is
     (Find (S, K) /= No_Element) with
   Post => My_Contains'Result = Contains (S, K);

   --  My_Find iterates through the set to find K.

   function My_Find (S : My_Maps.Map; K : Positive) return Cursor with
     Post => My_Find'Result = Find (S, K);

   function F (E : Integer) return Integer is
      (if E in -100 .. 100 then E * 2 else E);

   --  The first two versions of Apply_F store in R the image of every element
   --  of S through F while the last two modify S in place. The difference
   --  between the two versions of each pair is that one is specified using
   --  only elements (we don't care about keys) while the other specifies
   --  that keys are preserved.

   procedure Apply_F (S : My_Maps.Map; R : in out My_Maps.Map) with
     Pre  => Capacity (R) >= Length (S),
     Post => Capacity (R) = Capacity (R)'Old
     and Length (R) = Length (S)
     and (for all E of Model (S) =>
              (for some G of Model (R) => G = F (E)))
     and (for all G of Model (R) =>
              (for some E of Model (S) => G = F (E)));

   procedure Apply_F_2 (S : My_Maps.Map; R : in out My_Maps.Map) with
     Pre  => Capacity (R) >= Length (S),
     Post => Capacity (R) = Capacity (R)'Old
     and Length (R) = Length (S)
     and (for all K in Model (R) => Mem (Model (S), K))
     and (for all K in Model (S) =>
              Mem (Model (R), K)
          and then Element (Model (R), K)  = F (Element (Model (S), K)));

   procedure Apply_F_3 (S : in out My_Maps.Map) with
     Post => Capacity (S) = Capacity (S)'Old
     and Length (S) = Length (S)'Old
     and (for all E of Model (S)'Old =>
              (for some G of Model (S) => G = F (E)))
     and (for all G of Model (S) =>
              (for some E of Model (S)'Old => G = F (E)));

   procedure Apply_F_4 (S : in out My_Maps.Map) with
     Post => Capacity (S) = Capacity (S)'Old
     and Length (S) = Length (S)'Old
     and Keys (S) = Keys (S)'Old
     and (for all K in Model (S) =>
              Element (Model (S), K)  = F (Element (Model (S)'Old, K)));

   --  Checks wether two maps have a disjoint set of keys.

   function Are_Disjoint (S1, S2 : My_Maps.Map) return Boolean with
     Post => Are_Disjoint'Result =
       (for all E in Model (S2) => not Mem (Model (S1), E));

   function P (E : Integer) return Boolean is
     (E >= 0);

   --  Checks that the union of two maps for which P is true only contains
   --  elements for which P is true.

   procedure Union_P (S1 : in out My_Maps.Map; S2 : My_Maps.Map) with
     Pre  => (for all E of Model (S1) => P (E))
     and (for all E of Model (S2) => P (E))
     and Capacity (S1) - Length (S1) >= Length (S2),
     Post => (for all E of Model (S1) => P (E));

   --  Test links between high-level model, lower-level position based model
   --  and lowest-level, cursor based model of a map.

   function Q (E : Integer) return Boolean;

   procedure From_Keys_To_Model (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all I in 1 .. Length (S) =>
                    Q (Element (Model (S), Get (Keys (S), I)))),
     Post   => (for all E of Model (S) => Q (E));

   procedure From_Model_To_Keys (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all E of Model (S) => Q (E)),
     Post   => (for all I in 1 .. Length (S) =>
                    Q (Element (Model (S), Get (Keys (S), I))));

   procedure From_Keys_To_Cursors (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all I in 1 .. Length (S) =>
                    Q (Element (Model (S), Get (Keys (S), I)))),
     Post   => (for all Cu in Positions (S) =>
                    Q (Element (Model (S), Get (Keys (S),
                  Get (Positions (S), Cu)))));

   procedure From_Cursors_To_Keys (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all Cu in Positions (S) =>
                    Q (Element (Model (S), Get (Keys (S),
                  Get (Positions (S), Cu))))),
     Post   => (for all I in 1 .. Length (S) =>
                    Q (Element (Model (S), Get (Keys (S), I))));

   procedure From_Model_To_Cursors (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all E of Model (S) => Q (E)),
     Post   => (for all Cu in Positions (S) =>
                    Q (Element (Model (S), Get (Keys (S),
                  Get (Positions (S), Cu)))));

   procedure From_Cursors_To_Model (S : My_Maps.Map) with
     Ghost,
     Global => null,
     Pre    => (for all Cu in Positions (S) =>
                  Q (Element (Model (S), Get (Keys (S),
                    Get (Positions (S), Cu))))),
     Post   => (for all E of Model (S) => Q (E));
end Use_Maps;
