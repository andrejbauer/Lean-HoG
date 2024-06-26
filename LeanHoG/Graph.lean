import LeanHoG.Edge
import Std
import Std.Data.RBMap.Basic
import Mathlib.Data.Set.Finite

namespace LeanHoG

structure Graph where
  vertexSize : Nat
  edgeSet : EdgeSet vertexSize

/-- The type of graph vertices -/
@[reducible]
def Graph.vertex (G : Graph) := Fin G.vertexSize

/-- The set of all the vertices -/
def Graph.vertexSet (G : Graph) : Set G.vertex := { u : G.vertex | u = u }

/-- A finite subset of vertices -/
@[reducible]
def Graph.vertexSubset (G : Graph) := Std.RBSet G.vertex compare

/-- A map from vertices -/
def Graph.vertexMap (G : Graph) (α : Type) : Type := Std.RBMap G.vertex α compare

lemma Graph.vertexSetFinite (G : Graph) : Set.Finite G.vertexSet := by
  apply Iff.mp Set.finite_coe_iff
  infer_instance

/-- The underlying type of edges, i.e., pairs (i,j) such that j < i < G.vertexSize. -/
@[reducible]
def Graph.edgeType (G : Graph) := Edge G.vertexSize

/-- The type of edges -/
@[reducible]
def Graph.edge (G : Graph) := { e : G.edgeType // G.edgeSet.contains e }

@[reducible]
def Graph.edge_compare (G : Graph) := (Edge.linearOrder G.vertexSize).compare

@[reducible]
def Graph.fst {G : Graph} (e : G.edgeType) : G.vertex := e.fst

@[reducible]
def Graph.snd {G : Graph} (e : G.edgeType) : G.vertex :=
  ⟨e.snd, e.snd.prop⟩

/-- the number of eges in a graph -/
def Graph.edgeSize (G : Graph) := Fintype.card G.edge

/-- The vertex adjacency relation as a boolean map -/
def Graph.badjacent {G : Graph} : G.vertex → G.vertex → Bool :=
  fun u v =>
    ltByCases u v
      (fun u_lt_v => G.edgeSet.contains (Edge.mk u v u_lt_v))
      (fun _ => false)
      (fun v_lt_u => G.edgeSet.contains (Edge.mk v u v_lt_u))

/-- The vertex adjacency relations -/
def Graph.adjacent {G : Graph} : G.vertex → G.vertex → Prop :=
  fun u v => G.badjacent u v

instance (G : Graph) : DecidableRel G.adjacent := by
  intros u v
  unfold Graph.adjacent
  infer_instance

/-- Adjacent vertices are connected by an edge -/
def Graph.adjacentEdge {G : Graph} {u v : G.vertex} :
  G.adjacent u v → G.edge := by
  apply ltByCases u v
  · intros u_lt_v uv
    constructor
    case val => exact Edge.mk u v u_lt_v
    case property => simp_all [u_lt_v, ltByCases, adjacent, badjacent]
  · intro u_eq_v
    intro H
    simp [u_eq_v, ltByCases, adjacent, badjacent] at H
  · intros v_lt_u uv
    constructor
    case val => exact Edge.mk v u v_lt_u
    case property => simp_all [v_lt_u, not_lt_of_lt, ltByCases, adjacent, badjacent]

/-- Adjacency is irreflexive. -/
lemma Graph.irreflexiveAdjacent (G : Graph) :
  ∀ (v : G.vertex), ¬ adjacent v v := by simp [ltByCases, adjacent, badjacent]

/-- Adjacency is symmetric. -/
lemma Graph.symmetricAdjacent (G : Graph) :
  ∀ (u v : G.vertex), adjacent u v → adjacent v u := by
    intros u v
    apply ltByCases u v <;> (intro h ; simp [ltByCases, not_lt_of_lt, h, adjacent, badjacent])

lemma member_rbset (G : Graph) (e : G.edgeType) : e ∈ G.edgeSet ↔ G.edgeSet.Mem e := by
  constructor
  · intro H
    exact H
  · intro H
    exact H

lemma member_rbnode (G : Graph) (e : G.edgeType) : e ∈ G.edgeSet.1 ↔ G.edgeSet.1.EMem e := by
  constructor
  · intro H
    exact H
  · intro H
    exact H

lemma edge_in_node (G : Graph) (e : G.edgeType) : e ∈ G.edgeSet ↔ e ∈ G.edgeSet.1 := by
  apply Iff.intro
  · rw [member_rbset, member_rbnode]
    unfold Std.RBSet.Mem
    unfold Std.RBNode.EMem
    unfold Std.RBSet.MemP
    unfold Std.RBNode.MemP
    rw [Std.RBNode.Any_def]
    rw [Std.RBNode.Any_def]
    intro H
    apply Exists.elim H
    intro a H'
    obtain ⟨belongs, compare⟩ := H'
    rw [compare_eq_iff_eq] at compare
    use a
  · rw [member_rbset, member_rbnode]
    unfold Std.RBSet.Mem
    unfold Std.RBNode.EMem
    unfold Std.RBSet.MemP
    unfold Std.RBNode.MemP
    rw [Std.RBNode.Any_def]
    rw [Std.RBNode.Any_def]
    intro H
    apply Exists.elim H
    intro a H'
    obtain ⟨belongs, compare⟩ := H'
    rw [← compare_eq_iff_eq] at compare
    use a


lemma Graph.adj_impl_ex_edge (G: Graph) (u v : G.vertex) (e : G.edge) : (adj : G.adjacent u v) → u < v → G.adjacentEdge adj = e → G.fst e = u ∧ G.snd e = v := by
  intro adj comp
  unfold adjacentEdge
  simp [comp]
  intro v
  subst v
  simp

/-
The problem here is that the RBSet checks for membership using the cmp function while the RBNode checks if we have this exact element
-/
/-- An efficient way of checking that a statement holds for all edges. -/
lemma Graph.all_edges (G : Graph) (p : G.edgeType → Prop) [DecidablePred p] :
    G.edgeSet.all p = true → ∀ (e : G.edge), p e
  := by
    unfold Std.RBSet.all
    rw [Std.RBNode.all_iff]
    rw [Std.RBNode.All_def]
    intro H e
    specialize H e
    have member : e.1 ∈ G.edgeSet := by
      rw [← Std.RBSet.contains_iff]
      exact e.2
    rw [edge_in_node] at member
    apply H at member
    apply of_decide_eq_true at member
    exact member

/--
  For a symmetric relation on vertices, if it holds for all endpoints of all edges,
  then it holds for all pairs of adjacent vertices. This is useful for checking
  statements about adjacent vertices, as we can just check all edges instead of
  all pairs of vertices (and skipping the non-adjacent ones).
-/
def Graph.all_adjacent_of_edges {G : Graph} (R : G.vertex → G.vertex → Prop) :
    (∀ u v, R u v → R v u) →
    (∀ (e : G.edge), R (G.fst e) (G.snd e)) →
    (∀ u v, G.adjacent u v → R u v)
  := by
  intro R_symm all_edge u v uv
  apply ltByCases u v
  · intro u_lt_v
    let A := all_edge (G.adjacentEdge uv)
    simp [adjacentEdge, ltByCases, u_lt_v] at A
    exact A
  · intro eq
    exfalso
    apply G.irreflexiveAdjacent u
    rw [←eq] at uv
    assumption
  · intro v_lt_u
    let A := all_edge (G.adjacentEdge uv)
    simp [adjacentEdge, ltByCases, v_lt_u, not_lt_of_lt] at A
    apply R_symm
    exact A

/-- The neighborhood of a vertex. -/
@[reducible]
def Graph.neighborhood (G : Graph) (v : G.vertex) :=
  { u : G.vertex // G.badjacent v u }

/-- The degree of a vertex. -/
def Graph.degree (G : Graph) (v : G.vertex) : Nat := Fintype.card (G.neighborhood v)

/-- The minimal vertex degree, equals ⊤ for empty graph. -/
def Graph.minDegree (G : Graph) : WithTop Nat :=
  Finset.inf (Fin.fintype G.vertexSize).elems (fun v => G.degree v)

def Graph.minimumDegree (G : Graph) : Nat :=
  match G.minDegree with
  | some n => n
  | none => 0

/-- The maximal vertex degree, equals ⊥ for empty graph. -/
def Graph.maxDegree (G : Graph) : WithBot Nat :=
  Finset.sup (Fin.fintype G.vertexSize).elems (fun v => G.degree v)

end LeanHoG
