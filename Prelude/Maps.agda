open import Prelude.Init
open import Prelude.DecEq
open import Prelude.Semigroup

module Prelude.Maps {K V : Set} where

open import Prelude.Maps.Interface                   -- abstract interface
import Prelude.Maps.AsPartialFunctions4 {K}{V} as M₁ -- implementations
module Imp = M₁                                      -- pick an implementation

open Mapᴵ {K = K} {V = V} record {Imp} public
_ = Map ∋ m ∪ ∅
  where postulate m : Map

open DecMapᴵ record {Imp} public

private wb = WithBuildᴵ ∋ record {Imp}
open WithBuildᴵ wb public
_ = Map ∋ buildMap (const nothing) ∪ buildMap (λ k → just (f k))
  where postulate f : K → V

module _ ⦃ _ : DecEq K ⦄ where

  open WithSingletonᴵ record {Imp} public
  _ = Map ∋ singleton (k , v) ∪ singleton (k , v)
    where postulate k : K; v : V

  open CommandDSL wb public

  -- open DecEqMapᴵ {K = K} {V = V} record {Imp} public