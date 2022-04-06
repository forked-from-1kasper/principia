# PRINCIPIA

## Synopsis

PRINCIPIA is a theorem prover for proving stuff like “1 + 1 = 2”.
Its (almost) only inference rule is substitution rule: from τ we can deduce τ[α′/α, β′/β, …] where “α′/α” is the substitution “α” by “α′”.

It is insipiried by [Metamath](http://us.metamath.org/downloads/metamath.pdf) and [some Metamath-like systems](http://us.metamath.org/other.html#mmrelated).

Requires OCaml 4.08.1+, ocamlbuild, ocamllex and Menhir.

```bash
$ git clone https://github.com/groupoid/principia
$ cd principia
$ make
ocamlbuild -use-menhir principia.native
Finished, 29 targets (29 cached) in 00:00:03.
$ ./principia.native check examples/logic.lisp
```

Binaries can be found on [GitHub actions](https://github.com/forked-from-1kasper/principia/actions) (in “artifacts”).

## Example

Peano numbers:

```
(postulate
  ─────── 0-def
  (0 nat)

      (x nat)
  ────────────── succ-def
  ((succ x) nat))

(define 1 (succ 0))
(define 2 (succ 1))
```

## Types

Unlike [Metamath](http://us.metamath.org/downloads/metamath.pdf) and like [Bourbaki](https://www.quicklisp.org/beta/UNOFFICIAL/docs/bourbaki/doc/bourbaki-3.7.pdf) terms in PRINCIPIA are represented as S-expressions.
They will be converted to an internal AST, which is defined inductively.
`[τ₁ τ₂ ...]` in terms is converted to `(@ τ₁ τ₂ ...)`.

```
Name = <Unicode character (except “(”, “)”, “[”, “]”, “"”, “'”) sequence>
Term = Lit Name
     | Var Name
     | FVar Name
     | Hole
     | Symtree (Term list)
```

| Term    | Description |
| ------- | ----------- |
| Var     | Symbol from variable list will be treated as variable: α, β, γ etc. Variables (unlike literals) can be substituted. |
| FVar    | *(Freezed)* variables given in hypothesis. Cannot be substituted. It prevents us from deducing “⊥” from hypothesis “α”. |
| Lit     | Any other symbol is literal (constant). For example, literals can represent “∀”, “∃” or “+” symbols. |
| Symtree | Variables and literals can be grouped into trees. Trees are represented using S-expressions: `(a b c ...)` |
| Hole    | As hole will be treated only underscore “_” symbol. It is used in “bound” command. |

## Syntax

Not only terms, but the whole syntax uses S-expressions.

## variables
`(variables α β γ ...)` adds “α”, “β”, “γ” etc to the variable list.


## macroexpand
`(macroexpand τ₁ τ₂ τ₃ ...)` performs macro expansion of τ₁, τ₂ etc.


## infix
`(infix ⊗ prec)` declares “⊗” as an infix operator with precedence “prec”.
Then it can be used in such way: `(# a ⊗ b ⊗ c ...)` will be converted to `(a ⊗ (b ⊗ (c ...)))`.
Multiple infix operators in one form will be resolved according to their precedences.
But be careful: by default, trees inside `(# ...)` will **not** be resolved as infix.
So, `(# a ⊗ (b ⊗ c ⊗ d))` is not `(a ⊗ (b ⊗ (c ⊗ d)))`, but it is `(a ⊗ (b ⊗ c ⊗ d))`.
Also note that there is distinction between `(a ⊗ (b ⊗ c))` and `(a ⊗ b ⊗ c)`.

## bound
`(bound (Π x _) (Σ y _) ...)` declares “Π” and “Σ” as bindings.
Generally binding can have another form rather than `(φ x _)`.
It can be, for example, `(λ (x : _) _)`.

Bound variables (they appear in declaration) have special meaning.
We cannot do three things with them:
* Replace the bound variable with Lit or Symtree. This prevents us, for example, from deducing `(λ (succ : ℕ) (succ (succ succ)))` (this is obviosly meaningless) from `(λ (x : ℕ) (succ (succ x)))`.
* Replace the bound variable with a variable that is present in the term. This prevents from deducing wrong things like `(∀ b (∃ b (b > b)))` from `(∀ a (∃ b (a > b)))`.
* Replace (bound or not) variable with a bound variable.

## postulate
(1) is premises.<br>
(2) is inference rule name.<br>
(3) is conclusion.

```
(postulate

  h₁ h₂ h₃ ...         ;; (1)
  ──────────── axiom-1 ;; (2)
       h               ;; (3)

  g₁ g₂ g₃ ...
  ──────────── axiom-2
       g
  ...)
```


## lemma, theorem
(1) is premise names.<br>
(2) is premises self.<br>
(3) is lemma/theorem name.<br>
(4) is conclusion.<br>
(5) is application of theorem/axiom g₁/g₂/gₙ in which variable α₁/β₁/ε₁ is replaced with term τ₁/ρ₁/μ₁, variable α₂/β₂/ε₂ is replaced with term τ₂/ρ₂/μ₂, and so on.

```
(theorem

  ─── f₁ ─── f₂ ─── f₃               ;; (1)
   h₁     h₂     h₃    ...           ;; (2)
  ──────────────────────── theorem-1 ;; (3)
              h                      ;; (4)
  
  g₁ [α₁ ≔ τ₁ α₂ ≔ τ₂ ...]
  g₂ [β₁ ≔ ρ₁ β₂ ≔ ρ₂ ...]
  ...
  gₙ [ε₁ ≔ μ₁ ε₂ ≔ μ₂ ...]) ;; (5)
```
