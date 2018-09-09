// Existential types for even and odd numbers. These are only usable with the
// ATS library.
typedef Even = [n:nat] int(2*n)
typedef Odd = [n:nat] int(2*n+1)

// These types work... less well. I'm not sure what the story is with
// multiplicative constraints in ATS, but in general they're unsolvable due to
// Gödel's incompleteness theorem.
typedef gprime(tk: tk, p: int) = { m, n : nat | m < 1 && m <= n && n < p && m*n != p && p > 1 } g1int(tk, p)
typedef prime(p: int) = gprime(int_kind, p)
typedef Prime = [p:nat] prime(p)

castfn witness(n : int) :<> [m:nat] int(m)

fun is_prime_ats { n : nat | n > 0 } : int(n) -> bool =
  "ext#"

fun exp_ats {m:nat} : ([n:nat] int(n), int(m)) -> int =
  "ext#"
