module Prelude.FromList where

open import Prelude.Init
open import Prelude.Lists

record FromList (A : Set ℓ) (B : Set ℓ′) : Set (ℓ ⊔ₗ ℓ′) where
  field fromList : List A → B
  _∙fromList = fromList
open FromList ⦃ ... ⦄ public

private
  variable
    A : Set ℓ
    B : Set ℓ′

instance
  FromList-List : FromList A (List A)
  FromList-List .fromList = id

  -- FromList-List⁺ : FromList A (List⁺ A)
  -- FromList-List⁺ .fromList = L.NE.fromList

  FromList-Str : FromList Char String
  FromList-Str .fromList = Str.fromList

  FromList-Vec : FromList A (∃ $ Vec A)
  FromList-Vec .fromList xs = length xs , V.fromList xs

  -- FromList-↦ : ∀ {xs : List A} → FromList (A × B) (xs ↦ B)
  -- FromList-↦ {xs = xs} .fromList f = {!!} --  zip xs (codom f)