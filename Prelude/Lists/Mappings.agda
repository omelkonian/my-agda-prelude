------------------------------------------------------------------------
-- Mappings as total functions from membership proofs of a finite list.

module Prelude.Lists.Mappings where

open import Prelude.Init
open L.Mem using (_∈_; mapWith∈; ∈-++⁻)
open L.Perm using (∈-resp-↭; Any-resp-↭)
open import Prelude.General using (⟫_)
open import Prelude.Lists.Membership

private variable
  a b : Level
  A : Set a
  B : Set b

  x : A
  xs xs′ ys zs : List A
  P : Pred₀ A

-- mapWith∈
infixr 0 _↦′_ _↦_

_↦′_ : List A → (A → Set ℓ) → Set _
xs ↦′ P = ∀ {x} → x ∈ xs → P x

map↦ = _↦′_
syntax map↦ xs (λ x → f) = ∀[ x ∈ xs ] f

_↦_ : List A → Set b → Set _
xs ↦ B = xs ↦′ const B

dom : ∀ {xs : List A} → xs ↦′ P → List A
dom {xs = xs} _ = xs

codom : xs ↦ B → List B
codom = mapWith∈ _

weaken-↦ : xs ↦′ P → ys ⊆ xs → ys ↦′ P
weaken-↦ f ys⊆xs = f ∘ ys⊆xs

cons-↦ : (x : A) → P x → xs ↦′ P → (x ∷ xs) ↦′ P
cons-↦ _ y _ (here refl) = y
cons-↦ _ _ f (there x∈)  = f x∈

uncons-↦ : (x ∷ xs) ↦′ P → xs ↦′ P
uncons-↦ = _∘ there

permute-↦ : xs ↭ ys → xs ↦′ P → ys ↦′ P
permute-↦ xs↭ys xs↦ = xs↦ ∘ L.Perm.∈-resp-↭ (↭-sym xs↭ys)

_++/↦_ : xs ↦′ P → ys ↦′ P → xs ++ ys ↦′ P
xs↦ ++/↦ ys↦ = ∈-++⁻ _ >≡> λ where
  (inj₁ x∈) → xs↦ x∈
  (inj₂ y∈) → ys↦ y∈

_++/↦_⊣≡_ : xs ↦′ P → ys ↦′ P → zs ≡ xs ++ ys → zs ↦′ P
f ++/↦ g ⊣≡ refl = f ++/↦ g

extend-↦ : zs ↭ xs ++ ys → xs ↦′ P → ys ↦′ P → zs ↦′ P
extend-↦ zs↭ xs↦ ys↦ = permute-↦ (↭-sym zs↭) (xs↦ ++/↦ ys↦)

cong-↦ : xs ↦′ P → xs′ ≡ xs → xs′ ↦′ P
cong-↦ f refl = f

Any-resp-↭∘Any-resp-↭˘ : ∀ {A : Set} {x : A} {xs ys : List A}
    (p↭ : xs ↭ ys)
    (x∈ : x ∈ xs)
    --——————————————————————————————————————————
  → (Any-resp-↭ (↭-sym p↭) ∘ Any-resp-↭ p↭) x∈ ≡ x∈
Any-resp-↭∘Any-resp-↭˘ ↭-refl _ = refl
Any-resp-↭∘Any-resp-↭˘ (↭-prep _ _) (here _) = refl
Any-resp-↭∘Any-resp-↭˘ (↭-prep x p↭) (there p)
  = cong there $ Any-resp-↭∘Any-resp-↭˘ p↭ p
Any-resp-↭∘Any-resp-↭˘ (↭-swap _ _ _) (here _) = refl
Any-resp-↭∘Any-resp-↭˘ (↭-swap _ _ _) (there (here _)) = refl
Any-resp-↭∘Any-resp-↭˘ (↭-swap x y p↭) (there (there p))
  = cong there $ cong there $ Any-resp-↭∘Any-resp-↭˘ p↭ p
Any-resp-↭∘Any-resp-↭˘ (↭-trans p↭ p↭′) p
  rewrite Any-resp-↭∘Any-resp-↭˘ p↭′ (Any-resp-↭ p↭ p)
  = Any-resp-↭∘Any-resp-↭˘ p↭ p

∈-resp-↭∘∈-resp-↭˘ : ∀ {A : Set} {x : A} {xs ys : List A}
    (p↭ : xs ↭ ys)
    (x∈ : x ∈ xs)
    --——————————————————————————————————————————
  → (∈-resp-↭ (↭-sym p↭) ∘ ∈-resp-↭ p↭) x∈ ≡ x∈
∈-resp-↭∘∈-resp-↭˘ = Any-resp-↭∘Any-resp-↭˘

-- Pointwise equality of same-domain mappings.
module _ {A : Set} {xs : List A} {P : Pred₀ A} where
  _≗↦_ : Rel₀ (xs ↦′ P)
  f ≗↦ f′ = ∀ {x : A} (x∈ : x ∈ xs) → f x∈ ≡ f′ x∈

  _≗⟨_⟩↦_ : ∀ {ys : List A} →
    (ys ↦′ P) → (p↭ : xs ↭ ys) → (xs ↦′ P) → Set
  f′ ≗⟨ p↭ ⟩↦ f = ∀ {x : A} (x∈ : x ∈ xs) → f′ (∈-resp-↭ p↭ x∈) ≡ f x∈

  permute-≗↦ : ∀ {ys : List A}
    → (p↭ : xs ↭ ys)
    → (f : xs ↦′ P)
      --——————————————————————————————————————
    → permute-↦ p↭ f ≗⟨ p↭ ⟩↦ f
  permute-≗↦ p↭ f {x} x∈ =
    begin
      permute-↦ p↭ f (∈-resp-↭ p↭ x∈)
    ≡⟨⟩
      (f ∘ ∈-resp-↭ (↭-sym p↭)) (∈-resp-↭ p↭ x∈)
    ≡⟨⟩
      f (∈-resp-↭ (↭-sym p↭) $ ∈-resp-↭ p↭ x∈)
    ≡⟨ cong f (∈-resp-↭∘∈-resp-↭˘ p↭ x∈) ⟩
      f x∈
    ∎ where open ≡-Reasoning

  permute-↦∘permute-↦˘ : ∀ {ys : List A}
    → (p↭ : xs ↭ ys)
    → (f : xs ↦′ P)
      --——————————————————————————————————————
    → permute-↦ (↭-sym p↭) (permute-↦ p↭ f) ≗↦ f
  permute-↦∘permute-↦˘ p↭ f {x} x∈
    rewrite permute-≗↦ p↭ f x∈
          | L.Perm.↭-sym-involutive p↭
    = cong f $ Any-resp-↭∘Any-resp-↭˘ p↭ x∈

++/↦-there : (f : x ∷ xs ↦′ P) (g : ys ↦′ P)
  → ((f ∘ there) ++/↦ g) ≗↦ ((f ++/↦ g) ∘ there)
++/↦-there {xs = []}         _ _ {_} _        = refl
++/↦-there {xs = _ ∷ _}      _ _ {_} (here _) = refl
++/↦-there {xs = xs@(_ ∷ _)} _ _ {_} (there x∈)
  with ∈-++⁻ xs (there x∈)
... | inj₁ _ = refl
... | inj₂ _ = refl

uncons-≗↦ : (f : x ∷ xs ↦′ P) (g : ys ↦′ P)
  → uncons-↦ (f ++/↦ g) ≗↦ (uncons-↦ f ++/↦ g)
uncons-≗↦ f g {y} y∈ =
  begin uncons-↦ (f ++/↦ g) y∈  ≡⟨⟩
        (f ++/↦ g) (there y∈)   ≡⟨ sym $ ++/↦-there f g y∈ ⟩
        ((f ∘ there) ++/↦ g) y∈ ≡⟨⟩
        (uncons-↦ f ++/↦ g) y∈  ∎ where open ≡-Reasoning

-- Pointwise equality of ⊆-related mappings.
module _ {A : Set} {xs ys : List A} {P : Pred₀ A} where
  _≗⟨_⊆⟩↦_ : ys ↦′ P → (p : ys ⊆ xs) → xs ↦′ P → Set
  f′ ≗⟨ p ⊆⟩↦ f = f′ ≗↦ (f ∘ p)

  weaken-≗↦ : (p : ys ⊆ xs) (f : xs ↦′ P)
    → weaken-↦ f p ≗⟨ p ⊆⟩↦ f
  weaken-≗↦ _ _ _ = refl

  _≗↦ˡ_ : xs ++ ys ↦′ P → xs ↦′ P → Set
  fg ≗↦ˡ f = (fg ∘ L.Mem.∈-++⁺ˡ) ≗↦ f

  ++-≗↦ˡ : (f : xs ↦′ P) (g : ys ↦′ P)
    → (f ++/↦ g) ≗↦ˡ f
  ++-≗↦ˡ _ _ (here _) = refl
  ++-≗↦ˡ _ _ (there x∈) rewrite ∈-++⁻∘∈-++⁺ˡ {ys = ys} x∈ = refl

  _≗↦ʳ_ : xs ++ ys ↦′ P → ys ↦′ P → Set
  fg ≗↦ʳ g = (fg ∘ L.Mem.∈-++⁺ʳ _) ≗↦ g

  ++-≗↦ʳ : (f : xs ↦′ P) (g : ys ↦′ P)
    → (f ++/↦ g) ≗↦ʳ g
  ++-≗↦ʳ f g y∈ with ⟫ xs
  ... | ⟫ [] = refl
  ... | ⟫ _ ∷ xs′ rewrite ∈-++⁻∘∈-++⁺ʳ {xs = xs} y∈ = refl

  _≗↦ˡʳ_,_ : xs ++ ys ↦′ P → xs ↦′ P → ys ↦′ P → Set
  fg ≗↦ˡʳ f , g = (fg ≗↦ˡ f) × (fg ≗↦ʳ g)

  ++-≗↦ˡʳ : (f : xs ↦′ P) (g : ys ↦′ P)
    → (f ++/↦ g) ≗↦ˡʳ f , g
  ++-≗↦ˡʳ f g = ++-≗↦ˡ f g , ++-≗↦ʳ f g
