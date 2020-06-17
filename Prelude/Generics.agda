{- Meta-programming utilities -}
module Prelude.Generics where

open import Function
open import Reflection
open import Reflection.TypeChecking.MonadSyntax using (pure; _<*>_; _<$>_) -- for idiom brackets to work
open import Reflection.Term
open import Reflection.Argument using (unArg)

open import Data.Unit
open import Data.Product hiding (map)
open import Data.Bool
open import Data.String hiding (show; length) renaming (_++_ to _<>_)
open import Data.Maybe hiding (map; _>>=_)
open import Data.List
open import Data.Fin using (toℕ)
open import Data.Nat

open import Relation.Nullary
open import Relation.Binary.PropositionalEquality
  hiding ([_])

open import Prelude.Lists
open import Prelude.Show

private
  variable
    A B : Set

-- ** Errors, debugging

error : String → TC A
error s = typeError [ strErr s ]

print : String → TC ⊤
print s = debugPrint "Prelude.Generics" 5 [ strErr s ]
-- e.g. set {-# OPTIONS -v Prelude.Generics:10 #-} to enable messages.

-- ** Smart constructors

-- arguments
pattern vArg x = arg (arg-info visible relevant) x
pattern hArg x = arg (arg-info hidden relevant) x
pattern hArg?  = hArg unknown

-- variables
pattern # n = var n []
pattern #_⟦_⟧ n x = var n (vArg x ∷ [])
pattern #_⟦_∣_⟧ n x y = var n (vArg x ∷ vArg y ∷ [])

-- patterns
pattern `_ x = Pattern.var x
pattern `∅   = Pattern.absurd

-- clauses
pattern ⟦∅⟧           = Clause.absurd-clause (vArg `∅ ∷ [])
pattern ⟦⇒_⟧    k     = Clause.clause [] k
pattern ⟦_⇒_⟧   x k   = Clause.clause (vArg x ∷ []) k
pattern ⟦_∣_⇒_⟧ x y k = Clause.clause (vArg x ∷ vArg y ∷ []) k

-- lambdas
pattern `λ_⇒_     x k   = lam visible (abs x k)
pattern `λ⟦_∣_⇒_⟧ x y k = `λ x ⇒ `λ y ⇒ k

pattern `λ∅ = pat-lam (⟦∅⟧ ∷ []) []
pattern `λ⟦_⇒_⟧ p k = pat-lam (⟦ p ⇒ k ⟧ ∷ []) []
pattern `λ⟦_⇒_∣_⇒_⟧ p₁ k₁ p₂ k₂ = pat-lam (⟦ p₁ ⇒ k₁ ⟧ ∷ ⟦ p₂ ⇒ k₂ ⟧ ∷ []) []

-- function application
pattern _∙ n = def n []
pattern _∙⟦_⟧ n x = def n (vArg x ∷ [])
pattern _∙⟦_∣_⟧ n x y = def n (vArg x ∷ vArg y ∷ [])
pattern _∙⟦_∣_∣⟧ n x y = def n (vArg x ∷ vArg y ∷ [])

pattern _◆ n = con n []
pattern _◆⟦_⟧ n x = con n (vArg x ∷ [])
pattern _◆⟦_∣_⟧ n x y = con n (vArg x ∷ vArg y ∷ [])

pattern _◇ n = Pattern.con n []
pattern _◇⟦_⟧ n x = Pattern.con n (vArg x ∷ [])
pattern _◇⟦_∣_⟧ n x y = Pattern.con n (vArg x ∷ vArg y ∷ [])

-- monadic utilities
traverse : (A → TC B) → List A → TC (List B)
traverse f []       = return []
traverse f (x ∷ xs) = ⦇ f x ∷ traverse f xs ⦈

forM : List A → (A → TC B) → TC (List B)
forM []       _ = return []
forM (x ∷ xs) f = ⦇ f x ∷ forM xs f ⦈

return⊤ : TC A → TC ⊤
return⊤ k = k >> return tt

-- other utilities

unArgs : List (Arg A) → List A
unArgs = map unArg

{-# TERMINATING #-}
mapVariables : (String → String) → (Pattern → Pattern)
mapVariables f (Pattern.var s)      = Pattern.var (f s)
mapVariables f (Pattern.con c args) = Pattern.con c $ map (λ{ (arg i p) → arg i (mapVariables f p) }) args
mapVariables _ p                    = p

viewTy : Type → List (Arg Type) × Type
viewTy (Π[ _ ∶ a ] ty) = map₁ (a ∷_) (viewTy ty)
viewTy ty              = [] , ty

argTys : Type → List (Arg Type)
argTys = proj₁ ∘ viewTy

resultTy : Type → Type
resultTy = proj₂ ∘ viewTy

tyName : Type → Maybe Name
tyName (con n _) = just n
tyName (def n _) = just n
tyName _         = nothing

args : Term → List (Arg Term)
args (var _ xs)  = xs
args (def _ xs)  = xs
args (con _ xs)  = xs
args _           = []

args′ : Term → List Term
args′ = map unArg ∘ args

mapVars : (ℕ → ℕ) → (Type → Type)
mapVars′ : (ℕ → ℕ) → (List (Arg Type) → List (Arg Type))

mapVars f (var x args) = var (f x) (mapVars′ f args)
mapVars f (def c args) = def c (mapVars′ f args)
mapVars f (con c args) = con c (mapVars′ f args)
mapVars _ ty           = ty

mapVars′ f []              = []
mapVars′ f (arg i ty ∷ xs) = arg i (mapVars f ty) ∷ mapVars′ f xs

varsToUnknown : Type → Type
varsToUnknown′ : List (Arg Type) → List (Arg Type)

varsToUnknown (var _ _)  = unknown
varsToUnknown (def c xs) = def c (varsToUnknown′ xs)
varsToUnknown (con c xs) = con c (varsToUnknown′ xs)
varsToUnknown ty         = ty

varsToUnknown′ []              = []
varsToUnknown′ (arg i ty ∷ xs) = arg i (varsToUnknown ty) ∷ varsToUnknown′ xs

parameters : Definition → ℕ
parameters (data-type pars _) = pars
parameters _                  = 0

vArgs : List (Arg A) → List A
vArgs [] = []
vArgs (vArg x ∷ xs) = x ∷ vArgs xs
vArgs (_      ∷ xs) = vArgs xs

remove-iArgs : List (Arg A) → List (Arg A)
remove-iArgs [] = []
remove-iArgs (iArg x ∷ xs) = remove-iArgs xs
remove-iArgs (x      ∷ xs) = x ∷ remove-iArgs xs

hide : Arg A → Arg A
hide (vArg x) = hArg x
hide (hArg x) = hArg x
hide (iArg x) = iArg x
hide a        = a

∀indices⋯ : List (Arg Type) → Type → Type
∀indices⋯ []       ty = ty
∀indices⋯ (i ∷ is) ty = Π[ "_" ∶ hide i ] (∀indices⋯ is ty)

apply⋯ : List (Arg Type) → Name → Type
apply⋯ is n = def n $ remove-iArgs (map (λ{ (n , arg i _) → arg i (# (length is ∸ suc (toℕ n)))}) (enumerate is))

mkPattern : Name → TC ( Pattern         -- ^ generated pattern for given constructor
                      × ℕ               -- ^ # of introduced variables
                      × List (ℕ × Type) -- ^ generated variables along with their type
                      )
mkPattern c = do
  tys ← (vArgs ∘ argTys) <$> getType c
  let n = length tys
  return $ Pattern.con c (applyUpTo (λ i → vArg (` ("x" <> show i))) n)
         , n
         , map (map₁ ((n ∸_) ∘ suc ∘ toℕ)) (enumerate tys)

-- *** Deriving
Derivation = List ( Name -- name of the type to derive an instance for
                  × Name -- identifier of the function/instance to generate
                  )
           → TC ⊤ -- computed instance to unquote

record Derivable (F : Set → Set) : Set where
  field
    DERIVE' : Derivation
open Derivable {{...}} public

DERIVE : ∀ F {{_ : Derivable F}} → Derivation
DERIVE F = DERIVE' {F = F}
