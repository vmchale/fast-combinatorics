import           Data.List                 (zipWith4)
import           Numeric.Combinatorics
import           Numeric.Integer
import           Numeric.NumberTheory
import           Numeric.Pure
import           Test.Hspec
import           Test.Hspec.QuickCheck
import           Test.QuickCheck.Arbitrary

tooBig :: Int -> Int -> Bool
tooBig x y = go x y >= 2 ^ (16 :: Integer)
    where
        go :: Int -> Int -> Integer
        go m n = fromIntegral m ^ (fromIntegral n :: Integer)

agree :: (Eq a, Show b, Integral b, Arbitrary b) => String -> (b -> a) -> (b -> a) -> SpecWith ()
agree s f g = describe s $
    prop "should agree with the pure Haskell function" $
        \n -> n < 1 || f n == g n

check :: (Eq a, Show a) => String -> (Int -> IO a) -> (Integer -> a) -> Int -> SpecWith ()
check s f g n = describe s $
    it ("should work for n=" ++ show n) $
        f n >>= (`shouldBe` g (fromIntegral n))

main :: IO ()
main = hspec $ parallel $ do

    sequence_ $ zipWith3 agree
        ["totient", "tau", "littleOmega"]
        [totient, tau, littleOmega]
        [hsTotient, hsTau, hsLittleOmega]

    sequence_ $ zipWith3 agree
        ["isPrime", "isPerfect"]
        [isPrime, isPerfect]
        [hsIsPrime, hsIsPerfect]

    describe "totient" $
        prop "should be equal to m-1 for m prime" $
            \m -> m < 1 || not (isPrime m) || totient m == m - 1
    describe "totient" $
        prop "should satisfy Fermat's little theorem" $
            \a m -> a < 1 || m < 2 || gcd a m /= 1 || tooBig a m || (a ^ totient m) `mod` m == 1

    -- TODO property test w/ recurrence relations?
    sequence_ $ zipWith4 check
        ["factorial", "choose"]
        [factorial, choose 101]
        [hsFactorial, hsChoose 101]
        [3141, 16]
