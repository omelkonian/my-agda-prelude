module Prelude.Lists.Count where

open import Prelude.Init
open Nat.Ord
open Nat using (_≤_)
open import Prelude.General
open import Prelude.Null
open import Prelude.Lists.Empty

private variable
  A : Set ℓ; B : Set ℓ′
  x : A; xs ys : List A

count : ∀ {P : Pred A ℓ} → Decidable¹ P → List A → ℕ
count P? = length ∘ filter P?

module _ {P : Pred A ℓ} (P? : Decidable¹ P) where
  count-step≤ : count P? xs ≤ count P? (x ∷ xs)
  count-step≤ {xs = xs} {x = x} with P? x
  ... | yes _ = Nat.≤-step Nat.≤-refl
  ... | no  _ = Nat.≤-refl

  count-++ : ∀ xs {ys} → count P? (xs ++ ys) ≡ count P? xs + count P? ys
  count-++ xs = trans (cong length $ L.filter-++ P? xs _)
                      (L.length-++ $ filter P? xs)

  length-count : count P? xs ≤ length xs
  length-count {xs = xs} = L.length-filter P? xs

  postulate
    ⊆⇒count≤ : xs ⊆ ys → count P? xs ≤ count P? ys
    count≡0⇒null-filter : count P? xs ≡ 0 → Null $ filter P? xs
    count≡0⇒All¬ : count P? xs ≡ 0 → All (¬_ ∘ P) xs
    count-map⁺ : ∀ {f : B → A}
      → count (P? ∘ f) xs
      ≡ count P? (map f xs)
    count-single : ∀ {x xs}
      → count P? (x ∷ xs) ≡ 1
      → P x
      → All (x ≢_) xs
    -- count-single {P = P} {P?} {x} {xs} count≡1 px
    --   with P? x
    -- ... | no ¬px = ⊥-elim $ ¬px px
    -- ... | yes _  = L.All.¬Any⇒All¬ xs h
    --   where
    --     h : x ∉ xs
    --     h x∈ = {!!}

module _ (f : A → Maybe B) where
  countNothing countJust : List A → ℕ
  countNothing = count (is-nothing? ∘ f)
  countJust    = count (is-just? ∘ f)

  count-⊤⊥ : length xs ≡ countJust xs + countNothing xs
  count-⊤⊥ {xs = []} = refl
  count-⊤⊥ {xs = x ∷ xs}
    with IH ← count-⊤⊥ {xs = xs}
    with f x
  ... | just _ = cong suc IH
  ... | nothing
    rewrite Nat.+-suc (countJust xs) (countNothing xs)
    = cong suc IH