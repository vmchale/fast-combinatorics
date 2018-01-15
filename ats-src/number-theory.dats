#include "share/atspre_staload.hats"
#include "ats-src/numerics.dats"
#include "contrib/atscntrb-hx-intinf/mylibies.hats"

staload "prelude/SATS/integer.sats"
staload UN = "prelude/SATS/unsafe.sats"
staload "contrib/atscntrb-hx-intinf/SATS/intinf_vt.sats"

#define ATS_MAINATSFLAG 1

// m | n
fn divides(m : int, n : int) :<> bool =
  n % m = 0

fnx gcd {k : nat}{l : nat} (m : int(l), n : int(k)) : int =
  if n > 0 then
    gcd(n, witness(m % n))
  else
    m

fn lcm {k : nat}{l : nat} (m : int(l), n : int(k)) : int =
  (m / gcd(m, n)) * n

// stream all divisors of an integer.
fn divisors(n : intGte(1)) : stream_vt(intGt(0)) =
  case+ n of
    | 1 => $ldelay(stream_vt_cons(1, $ldelay(stream_vt_nil)))
    | _ => let
      fun loop { k : nat | k > 0 }{ m : nat | m > 0 } (n : int(k), acc : int(m)) : stream_vt(intGt(0)) =
        if acc >= sqrt_int(n) then
          if n % acc = 0 then
            if n / acc != acc then
              let
                var x: intGt(0) = $UN.cast(n / acc)
              in
                $ldelay(stream_vt_cons(acc, $ldelay(stream_vt_cons(x, $ldelay(stream_vt_nil)))))
              end
            else
              $ldelay(stream_vt_cons(acc, $ldelay(stream_vt_nil)))
          else
            $ldelay(stream_vt_nil)
        else
          if n % acc = 0 then
            let
              var x: intGt(0) = $UN.cast(n / acc)
            in
              $ldelay(stream_vt_cons(acc, $ldelay(stream_vt_cons(x, (loop(n, acc + 1))))))
            end
          else
            loop(n, acc + 1)
    in
      loop(n, 1)
    end

// prime divisors of an integer
fn prime_divisors(n : intGte(1)) : stream_vt(int) =
  stream_vt_filter_cloptr(divisors(n), lam x => is_prime($UN.cast(x)))

fn div_gt_zero(n : intGte(0), p : intGt(1)) : intGte(0) =
  $UN.cast(n / p)

// FIXME require that it be prime.
fun exp_mod_prime(a : intGte(0), n : intGte(0), p : intGt(1)) : int =
  let
    var a1 = a % p
    var n1 = n % (p - 1)
  in
    case+ a of
      | 0 => 0
      | x =>> 
        begin
          if n > 0 then
            let
              var n2: intGte(0) = $UN.cast(half(n1))
              var i2 = n1 % 2
              var sq_a: intGte(0) = $UN.cast(a * a % p)
            in
              if i2 = 0 then
                exp_mod_prime(sq_a, n2, p)
              else
                let
                  var y = a * exp_mod_prime(sq_a, n2, p)
                in
                  y
                end
            end
          else
            1
        end
  end

// Jacobi symbol for positive integers. See here: http://mathworld.wolfram.com/JacobiSymbol.html
fun jacobi(a : intGte(0), n : Odd) : int =
  let
    fun legendre { p : int | p >= 2 } (a : intGte(0), p : int(p)) : intBtwe(~1, 1) =
      case+ p % a of
        | 0 => 0
        | _ => let
          var i = exp_mod_prime(a, (p - 1) / 2, p)
        in
          case+ i of
            | i when i % (p - 1) = 0 => ~1
            | i when i % p = 0 => 0
            | _ => 1
        end
    
    fun get_multiplicity(n : intGte(0), p : intGt(1)) : intGte(0) =
      case+ n % p of
        | 0 => 1 + get_multiplicity(div_gt_zero(n, p), p)
        | _ => 0
    
    fun loop { m : int | m > 1 } (acc : int(m)) : int =
      if acc > n then
        1
      else
        if a % acc = 0 && is_prime(acc) then
          loop(acc + 1) * exp(legendre(acc, n), get_multiplicity(a, acc))
        else
          loop(acc + 1)
  in
    loop(2)
  end

fn count_divisors(n : intGte(1)) : int =
  stream_vt_length(divisors(n))

fn sum_divisors(n : intGte(1)) : int =
  let
    val x: stream_vt(int) = divisors(n)
  in
    stream_vt_foldleft_cloptr(x, 0, lam (acc, next) => g0int_add(acc, next))
  end

fn is_perfect(n : intGte(1)) : bool =
  sum_divisors(n) = n

fun rip { n : nat | n > 0 }{ p : nat | p > 0 } .<n>. (n : int(n), p : int(p)) :<> [ r : nat | r <= n && r > 0 ] int(r) =
  if n % p != 0 then
    n
  else
    if n / p > 0 then
      let
        var n1 = n / p
      in
        if n1 < n then
          $UN.cast(rip(n1, p))
        else
          1
      end
    else
      1

fun prime_factors(n : intGte(1)) : stream_vt(int) =
  let
    fun loop { k : nat | k > 0 }{ m : nat | m > 0 } (n : int(k), acc : int(m)) : stream_vt(int) =
      if acc >= n then
        if is_prime(n) then
          $ldelay(stream_vt_cons(n, $ldelay(stream_vt_nil)))
        else
          $ldelay(stream_vt_nil)
      else
        if n % acc = 0 && is_prime(acc) then
          if n / acc > 0 then
            $ldelay(stream_vt_cons(acc, loop(rip(n, acc), 1)))
          else
            $ldelay(stream_vt_cons(acc, $ldelay(stream_vt_nil)))
        else
          loop(n, acc + 1)
  in
    loop(n, 1)
  end

// distinct prime divisors
fn little_omega(n : intGte(1)) : int =
  stream_vt_length(prime_factors(n))

// Euler's totient function.
fn totient(n : intGte(1)) :<> int =
  case+ n of
    | 1 => 1
    | n =>> 
      begin
        let
          fnx loop { k : nat | k >= 2 }{ m : nat | m > 0 && k >= m } .<k-m>. (i : int(m), n : int(k)) :<> int =
            if i >= n then
              if is_prime(n) then
                n - 1
              else
                n
            else
              if n % i = 0 && is_prime(i) && i != n then
                (loop(i + 1, n) / i) * (i - 1)
              else
                loop(i + 1, n)
        in
          loop(1, n)
        end
      end

// The sum of all φ(m) for m between 1 and n 
fun totient_sum(n : intGte(1)) : Intinf =
  let
    fnx loop { n : nat | n >= 1 }{ m : nat | m >= n } .<m-n>. (i : int(n), bound : int(m)) : Intinf =
      if i < bound then
        let
          var x = loop(i + 1, bound)
          var y = add_intinf0_int(x, witness(totient(i)))
        in
          y
        end
      else
        int2intinf(witness(totient(i)))
  in
    loop(1, n)
  end

extern
fun chinese_remainder {n : nat} (residues : list_vt(int, n), moduli : list_vt(int, n)) : Option_vt(int)