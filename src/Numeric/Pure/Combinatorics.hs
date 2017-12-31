module Numeric.Pure.Combinatorics ( hsIsPrime
                                  , hsFactorial
                                  , hsChoose
                                  ) where

hsIsPrime :: Int -> Bool
hsIsPrime 1 = False
hsIsPrime x = all ((/=0) . (x `mod`)) [2..m]
    where m = floor (sqrt (fromIntegral x :: Float))

hsFactorial :: Int -> Int
hsFactorial 0 = 1
hsFactorial n = n * hsFactorial (n-1)

hsChoose :: Int -> Int -> Int
hsChoose n k = product [ n + 1 - i | i <- [1..k] ] `div` hsFactorial k
