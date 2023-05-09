import OrdEq
import TreeSet
import TreeMap

namespace HoG

-- The endpoints of an edge must be sorted
structure Edge (vertexSize : Nat) : Type :=
  fst : Fin vertexSize
  snd : Fin fst
  -- uncomment once https://github.com/leanprover-community/mathlib4/pull/3198 is merged
  -- deriving Fintype

-- smart constructor used to load JSON files
def Edge.mk' (n a b : Nat) (H1 : Nat.blt a n = true) (H2 : Nat.blt b a = true) : Edge n :=
  ⟨⟨a, Nat.le_of_ble_eq_true H1⟩, ⟨b, Nat.le_of_ble_eq_true H2⟩⟩

-- Get rid of this stuff once the above "deriving Fintype" works
def Graph.edgeEquiv (vertexSize : Nat) : (fst : Fin vertexSize) × Fin fst ≃ Edge vertexSize where
  toFun z := ⟨z.1, z.2⟩
  invFun c := ⟨c.fst, c.snd⟩
  left_inv := fun _ => rfl
  right_inv := fun _ => rfl

instance Edge_Fintype (vertexSize : Nat): Fintype (Edge vertexSize) :=
  Fintype.ofEquiv _ (Graph.edgeEquiv vertexSize)

def Edge.compare {m : Nat} (u v : Edge m) : Ordering :=
  match Ord.compare u.fst.val v.fst.val with
  | .lt => .lt
  | .eq => Ord.compare u.snd.val v.snd.val
  | .gt => .gt

instance Edge_Ord (m : Nat): Ord (Edge m) where
  compare := Edge.compare

instance Edge_OrdEq (m : Nat) : OrdEq (Edge m) := by
  constructor
  intros u v
  simp [compare, Edge_Ord, Edge.compare, compareOfLessAndEq]
  cases (lt_trichotomy u.fst v.fst) with
  | inl H =>
    simp [H]
    intro u_eq_v
    rw [u_eq_v] at H
    apply lt_irrefl v.fst
    assumption
  | inr G =>
    cases G with
    | inl H =>
      cases (lt_trichotomy u.snd.val v.snd.val) with
      | inl u_lt_v =>
        simp [H, u_lt_v]
        intro u_eq_v
        rw [u_eq_v] at u_lt_v
        apply lt_irrefl v.snd.val u_lt_v
      | inr G' =>
        cases G' with
        | inl u_eq_v =>
          simp [H, u_eq_v]
          revert H ; revert u_eq_v
          cases u <;> cases v <;> simp
          intros eq₂ eq₁
          simp [eq₁]
          have foo := heq_iff_eq.mp




    | inr H =>
      simp [H, not_lt_of_lt]






structure Graph : Type :=
  vertexSize : Nat
  edgeTree : STree (Edge vertexSize)
  -- edgeCorrect : edgeTree.correct := by rfl

-- the type of graph vertices
@[simp, reducible]
def Graph.vertex (G : Graph) := Fin G.vertexSize

-- the underlying type of edges (pairs (i,j) such that j < i < G.vertexSize)
@[simp]
def Graph.edgeType (G : Graph) := Edge G.vertexSize

instance Graph_edgeType_Finset (G : Graph) : Finset G.edgeType :=
  (Edge_Fintype G.vertexSize).elems

-- the type of edges
@[simp]
def Graph.edge (G : Graph) := { e : G.edgeType // e ∈ G.edgeTree }

@[simp]
def Graph.fst {G : Graph} (e : G.edgeType) : G.vertex := e.fst

@[simp]
def Graph.snd {G : Graph} (e : G.edgeType) : G.vertex :=
  ⟨e.snd, lt_trans e.snd.isLt e.fst.isLt⟩

instance Graph_edge_Fintype (G : Graph) : Fintype G.edge := by
  sorry

-- the number of eges in a graph
def Graph.edgeSize (G : Graph) := Fintype.card G.edge

-- the vertex adjacency relation
@[simp]
def Graph.badjacent {G : Graph} : G.vertex → G.vertex → Bool :=
  fun u v =>
    lt_by_cases u v
      (fun u_lt_v => G.edgeTree.mem (Edge.mk v (Fin.mk u u_lt_v)))
      (fun _ => false)
      (fun v_lt_u => G.edgeTree.mem (Edge.mk u (Fin.mk v v_lt_u)))

@[simp]
def Graph.adjacent {G : Graph} : G.vertex → G.vertex → Prop :=
  fun u v => G.badjacent u v

-- adjacent vertices induce an edge
@[simp]
def Graph.adjacentEdge {G : Graph} {u v : G.vertex} :
  G.adjacent u v → G.edge := by
  apply lt_by_cases u v
  · intros u_lt_v uv
    constructor
    case val => exact Edge.mk v ⟨u, u_lt_v⟩
    case property => simp_all [u_lt_v, lt_by_cases]
  · intro u_eq_v
    intro H
    simp [u_eq_v, lt_by_cases] at H
  · intros v_lt_u uv
    constructor
    case val => exact Edge.mk u ⟨v, v_lt_u⟩
    case property => simp_all [v_lt_u, not_lt_of_lt, lt_by_cases]

lemma Graph.adjacentEdge_lt_fst {G : Graph} {u v : G.vertex} (uv : G.adjacent u v):
  u < v -> G.fst (G.adjacentEdge uv).val = v := by
  intro u_lt_v
  simp [u_lt_v, lt_by_cases]

lemma Graph.adjacentEdge_gt_fst {G : Graph} {u v : G.vertex} (uv : G.adjacent u v):
  v < u -> G.fst (G.adjacentEdge uv).val = u := by
  intro v_lt_u
  simp [v_lt_u, not_lt_of_lt, lt_by_cases]

lemma Graph.adjacentEdge_lt_snd {G : Graph} {u v : G.vertex} (uv : G.adjacent u v):
  u < v -> G.snd (G.adjacentEdge uv).val = u := by
  intro u_lt_v
  apply Fin.eq_of_val_eq
  simp [u_lt_v, lt_by_cases]
  sorry

lemma Graph.adjacentEdge_gt_snd {G : Graph} {u v : G.vertex} (uv : G.adjacent u v):
  v < u -> G.snd (G.adjacentEdge uv).val = v := by
  sorry

lemma Graph.irreflexiveNeighbor (G : Graph) :
  ∀ (v : G.vertex), ¬ adjacent v v := by simp [lt_by_cases]

lemma Graph.symmetricNeighbor (G : Graph) :
  ∀ (u v : G.vertex), adjacent u v → adjacent v u := by
    intros u v
    apply lt_by_cases u v <;> (intro h ; simp [lt_by_cases, not_lt_of_lt, h])

end HoG
