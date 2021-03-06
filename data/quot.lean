/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Quotients -- extends the core library
-/
variables {α : Sort*} {β : Sort*}

@[simp] theorem quotient.eq [r : setoid α] {x y : α} : ⟦x⟧ = ⟦y⟧ ↔ x ≈ y :=
⟨quotient.exact, quotient.sound⟩

theorem forall_quotient_iff {α : Type*} [r : setoid α] {p : quotient r → Prop} :
  (∀a:quotient r, p a) ↔ (∀a:α, p ⟦a⟧) :=
⟨assume h x, h _, assume h a, a.induction_on h⟩

@[simp] lemma quotient.lift_beta [s : setoid α] (f : α → β) (h : ∀ (a b : α), a ≈ b → f a = f b) (x : α):
quotient.lift f h (quotient.mk x) = f x := rfl

@[simp] lemma quotient.lift_on_beta [s : setoid α] (f : α → β) (h : ∀ (a b : α), a ≈ b → f a = f b) (x : α):
quotient.lift_on (quotient.mk x) f h = f x := rfl

/-- Choose an element of the equivalence class using the axiom of choice.
  Sound but noncomputable. -/
noncomputable def quot.out {r : α → α → Prop} (q : quot r) : α :=
classical.some (quot.exists_rep q)

/-- Unwrap the VM representation of a quotient to obtain an element of the equivalence class.
  Computable but unsound. -/
meta def quot.unquot {r : α → α → Prop} : quot r → α := unchecked_cast

@[simp] theorem quot.out_eq {r : α → α → Prop} (q : quot r) : quot.mk r q.out = q :=
classical.some_spec (quot.exists_rep q)

/-- Choose an element of the equivalence class using the axiom of choice.
  Sound but noncomputable. -/
noncomputable def quotient.out [s : setoid α] : quotient s → α := quot.out

@[simp] theorem quotient.out_eq [s : setoid α] (q : quotient s) : ⟦q.out⟧ = q := q.out_eq

theorem quotient.mk_out [s : setoid α] (a : α) : ⟦a⟧.out ≈ a :=
quotient.exact (quotient.out_eq _)

instance pi_setoid {ι : Sort*} {α : ι → Sort*} [∀ i, setoid (α i)] : setoid (Π i, α i) :=
{ r := λ a b, ∀ i, a i ≈ b i,
  iseqv := ⟨
    λ a i, setoid.refl _,
    λ a b h i, setoid.symm (h _),
    λ a b c h₁ h₂ i, setoid.trans (h₁ _) (h₂ _)⟩ }

noncomputable def quotient.choice {ι : Type*} {α : ι → Type*} [S : ∀ i, setoid (α i)]
  (f : ∀ i, quotient (S i)) : @quotient (Π i, α i) (by apply_instance) :=
⟦λ i, (f i).out⟧

theorem quotient.choice_eq {ι : Type*} {α : ι → Type*} [∀ i, setoid (α i)]
  (f : ∀ i, α i) : quotient.choice (λ i, ⟦f i⟧) = ⟦f⟧ :=
quotient.sound $ λ i, quotient.mk_out _

/-- `trunc α` is the quotient of `α` by the always-true relation. This
  is related to the propositional truncation in HoTT, and is similar
  in effect to `nonempty α`, but unlike `nonempty α`, `trunc α` is data,
  so the VM representation is the same as `α`, and so this can be used to
  maintain computability. -/
def {u} trunc (α : Sort u) : Sort u := @quot α (λ _ _, true)

theorem true_equivalence : @equivalence α (λ _ _, true) :=
⟨λ _, trivial, λ _ _ _, trivial, λ _ _ _ _ _, trivial⟩

namespace trunc

/-- Constructor for `trunc α` -/
def mk (a : α) : trunc α := quot.mk _ a

/-- Any constant function lifts to a function out of the truncation -/
def lift (f : α → β) (c : ∀ a b : α, f a = f b) : trunc α → β :=
quot.lift f (λ a b _, c a b)

theorem ind {β : trunc α → Prop} : (∀ a : α, β (mk a)) → ∀ q : trunc α, β q := quot.ind

protected theorem lift_beta (f : α → β) (c) (a : α) : lift f c (mk a) = f a := rfl

@[reducible, elab_as_eliminator]
protected def lift_on (q : trunc α) (f : α → β)
  (c : ∀ a b : α, f a = f b) : β := lift f c q

@[elab_as_eliminator]
protected theorem induction_on {β : trunc α → Prop} (q : trunc α)
  (h : ∀ a, β (mk a)) : β q := ind h q

theorem exists_rep (q : trunc α) : ∃ a : α, mk a = q := quot.exists_rep q

attribute [elab_as_eliminator]
protected theorem induction_on₂
   {C : trunc α → trunc β → Prop} (q₁ : trunc α) (q₂ : trunc β) (h : ∀ a b, C (mk a) (mk b)) : C q₁ q₂ :=
trunc.induction_on q₁ $ λ a₁, trunc.induction_on q₂ (h a₁)

protected theorem eq (a b : trunc α) : a = b :=
trunc.induction_on₂ a b (λ x y, quot.sound trivial)

instance : subsingleton (trunc α) := ⟨trunc.eq⟩

def bind (q : trunc α) (f : α → trunc β) : trunc β :=
trunc.lift_on q f (λ a b, trunc.eq _ _)

def map (f : α → β) (q : trunc α) : trunc β := bind q (trunc.mk ∘ f)

instance : monad trunc :=
{ pure := @trunc.mk,
  bind := @trunc.bind }

instance : is_lawful_monad trunc :=
{ id_map := λ α q, trunc.eq _ _,
  pure_bind := λ α β q f, rfl,
  bind_assoc := λ α β γ x f g, trunc.eq _ _ }

variable {C : trunc α → Sort*}

@[reducible, elab_as_eliminator]
protected def rec
   (f : Π a, C (mk a)) (h : ∀ (a b : α), (eq.rec (f a) (trunc.eq (mk a) (mk b)) : C (mk b)) = f b)
   (q : trunc α) : C q :=
quot.rec f (λ a b _, h a b) q

@[reducible, elab_as_eliminator]
protected def rec_on (q : trunc α) (f : Π a, C (mk a))
  (h : ∀ (a b : α), (eq.rec (f a) (trunc.eq (mk a) (mk b)) : C (mk b)) = f b) : C q :=
trunc.rec f h q

@[reducible, elab_as_eliminator]
protected def rec_on_subsingleton
   [∀ a, subsingleton (C (mk a))] (q : trunc α) (f : Π a, C (mk a)) : C q :=
trunc.rec f (λ a b, subsingleton.elim _ (f b)) q

/-- Noncomputably extract a representative of `trunc α` (using the axiom of choice). -/
noncomputable def out : trunc α → α := quot.out

@[simp] theorem out_eq (q : trunc α) : mk q.out = q := trunc.eq _ _

end trunc

theorem nonempty_of_trunc (q : trunc α) : nonempty α :=
let ⟨a, _⟩ := q.exists_rep in ⟨a⟩
