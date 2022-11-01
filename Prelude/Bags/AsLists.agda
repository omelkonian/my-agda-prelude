open import Prelude.Init; open SetAsType
open L.Mem using (∈-filter⁻; ∈-filter⁺; ∈-++⁻; ∈-++⁺ˡ; ∈-++⁺ʳ)
open L.Uniq using (filter⁺; ++⁺; map⁺)
open import Prelude.General
open import Prelude.Lists
open import Prelude.DecLists
open import Prelude.Membership
open import Prelude.DecEq
open import Prelude.Measurable
open import Prelude.Bifunctor
open import Prelude.Decidable
open import Prelude.Apartness
open import Prelude.Ord
open import Prelude.ToList
open import Prelude.FromList
open import Prelude.Semigroup
open import Prelude.InferenceRules
open import Prelude.Setoid

import Relation.Binary.Reasoning.Setoid as BinSetoid

module Prelude.Bags.AsLists {A : Type} ⦃ _ : DecEq A ⦄ where

-- ** basic definitions

-- Bags as lists with no duplicates and a counter for each element.
record Bag : Type where
  constructor mkBag
  field list : List A
open Bag
syntax Bag {A = A} = Set⟨ A ⟩

private variable
  x x′ y y′ z z′ : A
  xs ys zs : List A
  Xs Ys Zs s s′ s″ s₁ s₂ s₃ s₁₂ s₂₃ : Bag
  P : Pred A 0ℓ

-----------------------------------------------------------------------
-- Lifting from list predicates/relations to set predicates/relations.

private
  record Lift (F : Type → Type₁) : Type₁ where
    field ↑ : F (List A) → F Bag
  open Lift ⦃...⦄

  instance
    Lift-Pred : Lift Pred₀
    Lift-Pred .↑ P = P ∘ list

    Lift-Rel : Lift Rel₀
    Lift-Rel .↑ _~_ = _~_ on list

-- e.g. All/Any predicates for sets
All' Any' : Pred₀ A → Pred₀ Bag
All' = ↑ ∘ All
Any' = ↑ ∘ Any

infixr 8 _─_
infixr 6 _∪_
infix 4 _∈ˢ_ _∉ˢ_ _∈ˢ?_ _∉ˢ?_

_∈ˢ_ _∉ˢ_ : A → Bag → Type
o ∈ˢ xs = o ∈ list xs
o ∉ˢ xs = ¬ (o ∈ˢ xs)

_∈ˢ?_ : Decidable² _∈ˢ_
o ∈ˢ? xs = o ∈? list xs

_∉ˢ?_ : Decidable² _∉ˢ_
o ∉ˢ? xs = o ∉? list xs

filter′ : Decidable¹ P → Bag → Bag
filter′ P? (mkBag xs) = mkBag (filter P? xs)

count′ : ∀ {P : Pred A 0ℓ} → Decidable¹ P → Bag → ℕ
count′ P? = count P? ∘ list

∅ : Bag
∅ = mkBag []

singleton : A → Bag
singleton a = mkBag [ a ]

singletonN : A × ℕ → Bag
singletonN (a , n) = mkBag $ L.replicate n a

singleton∈ˢ : x′ ∈ˢ singleton x ↔ x′ ≡ x
singleton∈ˢ = (λ where (here refl) → refl) , (λ where refl → here refl)

_∪_ _─_ : Op₂ Bag
mkBag xs ∪ mkBag ys = mkBag (xs ◇ ys)
mkBag xs ─ mkBag ys = mkBag (xs ∸[bag] ys)


-- ∈-∪⁻ : ∀ x xs ys → x ∈ˢ (xs ∪ ys) → x ∈ˢ xs ⊎ x ∈ˢ ys
-- ∈-∪⁻ x xs ys x∈ = map₂ (∈-─⁻ x ys xs) (∈-++⁻ {v = x} (list xs) {ys = list (ys ─ xs)} x∈)

-- ∈-∪⁺ˡ : ∀ x xs ys → x ∈ˢ xs → x ∈ˢ (xs ∪ ys)
-- ∈-∪⁺ˡ x xs ys x∈ = ∈-++⁺ˡ x∈

-- ∈-∪⁺ʳ : ∀ x xs ys → x ∈ˢ ys → x ∈ˢ (xs ∪ ys)
-- ∈-∪⁺ʳ x xs ys x∈ with x ∈ˢ? xs
-- ... | yes x∈ˢ = ∈-∪⁺ˡ x xs ys x∈ˢ
-- ... | no  x∉  = ∈-++⁺ʳ (list xs) (∈-filter⁺ (_∉ˢ? xs) x∈ x∉)

-- ⋃ : (A → Bag) → Bag → Bag
-- ⋃ f = foldr _∪_ ∅ ∘ map f ∘ list

-- ** relational properties
∉∅ : ∀ x → ¬ x ∈ˢ ∅
∉∅ _ ()

-- ∈-─⁻ : ∀ x xs ys → x ∈ˢ (xs ─ ys) → x ∈ˢ xs
-- ∈-─⁻ x xs ys x∈ = proj₁ (∈-filter⁻ (_∉ˢ? ys) x∈)

-- ∈-─⁺ : ∀ x xs ys → x ∈ˢ xs → ¬ x ∈ˢ ys → x ∈ˢ (xs ─ ys)
-- ∈-─⁺ x xs ys x∈ x∉ = ∈-filter⁺ ((_∉ˢ? ys)) x∈ x∉

_⊆ˢ_ _⊇ˢ_ _⊈ˢ_ _⊉ˢ_ : Rel Bag _
_⊆ˢ_ = _⊆[bag]_ on list
s ⊇ˢ s′ = s′ ⊆ˢ s
s ⊈ˢ s′ = ¬ s ⊆ˢ s′
s ⊉ˢ s′ = ¬ s ⊇ˢ s′

-- ⊆ˢ-trans : Transitive _⊆ˢ_
-- ⊆ˢ-trans ij ji = ji ∘ ij

_≈ˢ_ : Rel₀ Bag
s ≈ˢ s′ = (s ⊆ˢ s′) × (s′ ⊆ˢ s)

_≈?ˢ_ = Decidable² _≈ˢ_ ∋ dec²

postulate ≈ˢ-equiv : IsEquivalence _≈ˢ_
-- ≈ˢ-equiv = record
--   { refl  = {!λ where refl → ?!}
--   ; sym   = {!!}
--   ; trans = {!!}
--   }
open IsEquivalence ≈ˢ-equiv public
  renaming (refl to ≈ˢ-refl; sym to ≈ˢ-sym; trans to ≈ˢ-trans)

≈ˢ-setoid : Setoid 0ℓ 0ℓ
≈ˢ-setoid = record { Carrier = Bag; _≈_ = _≈ˢ_; isEquivalence = ≈ˢ-equiv }

module ≈ˢ-Reasoning = BinSetoid ≈ˢ-setoid

open Alg _≈ˢ_

instance
  Setoid-Bag : ISetoid Bag
  Setoid-Bag = λ where
    .relℓ → 0ℓ
    ._≈_  → _≈ˢ_

  SetoidLaws-Bag : Setoid-Laws Bag
  SetoidLaws-Bag .isEquivalence = ≈ˢ-equiv

  Semigroup-Bag : Semigroup Bag
  Semigroup-Bag ._◇_ = _∪_

  SemigroupLaws-Bag : SemigroupLaws Bag _≈ˢ_
  SemigroupLaws-Bag = record {◇-assocʳ = p; ◇-comm = q}
    where
      p : Associative (_◇_ {A = Bag})
      p xs ys zs = ≈-reflexive
                 $ cong mkBag $ L.++-assoc (list xs) (list ys) (list zs)

      postulate q : Commutative (_◇_ {A = Bag})
      -- q (mkBag []) (mkBag ys) rewrite L.++-identityʳ ys = ≈-refl
      -- q (mkBag (x ∷ xs)) (mkBag ys) = {!!}

-- ≈ˢ⇒⊆ˢ : s ≈ˢ s′ → s ⊆ˢ s′
-- ≈ˢ⇒⊆ˢ = proj₁

-- ≈ˢ⇒⊆ˢ˘ : s ≈ˢ s′ → s′ ⊆ˢ s
-- ≈ˢ⇒⊆ˢ˘ = proj₂

-- ∅─-identityʳ : RightIdentity ∅ _─_
-- ∅─-identityʳ s rewrite L.filter-all (_∉? []) {xs = list s} All∉[] = ≈ˢ-refl {x = s}

-- ∅∪-identityˡ : LeftIdentity ∅ _∪_
-- ∅∪-identityˡ xs =
--   begin ∅ ∪ xs ≈⟨ ≈ˢ-refl {xs ─ ∅} ⟩
--         xs ─ ∅ ≈⟨ ∅─-identityʳ xs ⟩
--         xs ∎
--   where open ≈ˢ-Reasoning


-- ∪-∅ : (Xs ∪ Ys) ≈ˢ ∅ → (Xs ≈ˢ ∅) × (Ys ≈ˢ ∅)
-- ∪-∅ {Xs}{Ys} p = (≈ˢ⇒⊆ˢ {Xs ∪ Ys}{∅} p ∘ ∈-∪⁺ˡ _ Xs Ys , λ ())
--                , (≈ˢ⇒⊆ˢ {Xs ∪ Ys}{∅} p ∘ ∈-∪⁺ʳ _ Xs Ys , λ ())

-- ∪-∅ˡ : (Xs ∪ Ys) ≈ˢ ∅ → Xs ≈ˢ ∅
-- ∪-∅ˡ {Xs}{Ys} = proj₁ ∘ ∪-∅ {Xs}{Ys}

-- ∪-∅ʳ : (Xs ∪ Ys) ≈ˢ ∅ → Ys ≈ˢ ∅
-- ∪-∅ʳ {Xs}{Ys} = proj₂ ∘ ∪-∅ {Xs}{Ys}

-- ** apartness
instance
  Apart-Bag : Bag // Bag
  Apart-Bag ._♯_ s s′ = ∀ {k} → ¬ (k ∈ˢ s × k ∈ˢ s′)

_♯?ˢ_ = Decidable² (_♯_ {A = Bag}) ∋ dec²

-- _[_↦_] : Bag → A → ℕ → Type
-- m [ k ↦ n ] = m ⁉ k ≡ n

-- _[_↦_]∅ : Bag → K → ℕ → Type
-- m [ k ↦ n ]∅ = m [ k ↦ n ] × ∀ k′ → k′ ≢ k → k′ ∉ᵈ m

♯-comm : s ♯ s′ → s′ ♯ s
♯-comm elim = elim ∘ Product.swap

-- ∈-∩⇒¬♯ : x ∈ˢ (Xs ∩ Ys) → ¬ (Xs ♯ Ys)
-- ∈-∩⇒¬♯ {Xs = Xs}{Ys} x∈ xs♯ys = contradict (≈ˢ⇒⊆ˢ {s = Xs ∩ Ys} {s′ = ∅} xs♯ys x∈)

-- ♯-skipˡ : ∀ xs ys (zs : Bag) → (xs ∪ ys) ♯ zs → ys ♯ zs
-- ♯-skipˡ xs ys zs p = ∪-∅ {xs ∩ zs}{ys ∩ zs}
--   (let open ≈ˢ-Reasoning in
--    begin
--     (xs ∩ zs) ∪ (ys ∩ zs)
--    ≈˘⟨ ∪-∩ {xs}{ys}{zs} ⟩
--     (xs ∪ ys) ∩ zs
--    ≈⟨ p ⟩
--      ∅
--    ∎)
--   .proj₂

⟨_◇_⟩≡_ : 3Rel₀ Bag
⟨ m ◇ m′ ⟩≡ m″ = (m ∪ m′) ≈ m″

-- ** list conversion
instance
  ToList-Bag : ToList Bag A
  ToList-Bag .toList = list

  FromList-Bag : FromList A Bag
  FromList-Bag .fromList = mkBag

∈ˢ-fromList : x ∈ xs ↔ x ∈ˢ fromList xs
∈ˢ-fromList = id , id

postulate
  ∪-comm : Commutative _∪_
  ⊎≡-comm : Symmetric (⟨_◇_⟩≡ s)

-- ** decidability of set equality
unquoteDecl DecEq-Bag = DERIVE DecEq [ quote Bag , DecEq-Bag ]
instance
  Measurable-Set : Measurable Bag
  Measurable-Set = record {∣_∣ = length ∘ list}

record Bag⁺ : Type where
  constructor _⊣_
  field set   : Bag
        .set⁺ : ∣ set ∣ > 0
syntax Bag⁺ {A = A} = Bag⁺⟨ A ⟩

instance
  DecEq-Bag⁺ : DecEq Bag⁺
  DecEq-Bag⁺ ._≟_ (s ⊣ _) (s′ ⊣ _) with s ≟ s′
  ... | yes refl = yes refl
  ... | no  ¬eq  = no λ where refl → ¬eq refl

mkSet⁺ : (s : Bag) ⦃ _ : True (∣ s ∣ >? 0) ⦄ → Bag⁺
mkSet⁺ s ⦃ pr ⦄ = s ⊣ toWitness pr

fromList⁺ : (xs : List A) ⦃ _ : True (length xs >? 0) ⦄ → Bag⁺
fromList⁺ = mkSet⁺ ∘ fromList

toList'⁺ : Bag⁺ → List⁺ A
toList'⁺ (s ⊣ _) with x ∷ xs ← list s = x ∷ xs
