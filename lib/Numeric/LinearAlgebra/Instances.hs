{-# OPTIONS_GHC -fglasgow-exts -fallow-undecidable-instances #-}
-----------------------------------------------------------------------------
{- |
Module      :  Numeric.LinearAlgebra.Instances
Copyright   :  (c) Alberto Ruiz 2006
License     :  GPL-style

Maintainer  :  Alberto Ruiz (aruiz at um dot es)
Stability   :  provisional
Portability :  portable

This module exports Show, Eq, Num, Fractional, and Floating instances for Vector and Matrix.

In the context of the standard numeric operators, one-component vectors and matrices automatically expand to match the dimensions of the other operand.

-}
-----------------------------------------------------------------------------

module Numeric.LinearAlgebra.Instances(
) where

import Numeric.LinearAlgebra.Linear
import Numeric.GSL.Vector
import Data.Packed.Matrix
import Data.Packed.Vector
import Complex
import Data.List(transpose,intersperse)
import Foreign(Storable)

------------------------------------------------------------------

instance (Show a, Field a) => (Show (Matrix a)) where
    show m = (sizes++) . dsp . map (map show) . toLists $ m
        where sizes = "("++show (rows m)++"><"++show (cols m)++")\n"

dsp as = (++" ]") . (" ["++) . init . drop 2 . unlines . map (" , "++) . map unwords' $ transpose mtp
    where
        mt = transpose as
        longs = map (maximum . map length) mt
        mtp = zipWith (\a b -> map (pad a) b) longs mt
        pad n str = replicate (n - length str) ' ' ++ str
        unwords' = concat . intersperse ", "

instance (Show a, Storable a) => (Show (Vector a)) where
    show v = (show (dim v))++" |> " ++ show (toList v)

------------------------------------------------------------------

adaptScalar f1 f2 f3 x y
    | dim x == 1 = f1   (x@>0) y
    | dim y == 1 = f3 x (y@>0)
    | otherwise = f2 x y

liftMatrix2' :: (Field t, Field a, Field b) => (Vector a -> Vector b -> Vector t) -> Matrix a -> Matrix b -> Matrix t
liftMatrix2' f m1 m2 | compat' m1 m2 = reshape (max (cols m1) (cols m2)) (f (flatten m1) (flatten m2))
                     | otherwise    = error "nonconformant matrices in liftMatrix2'"

compat' :: Matrix a -> Matrix b -> Bool
compat' m1 m2 = rows m1 == 1 && cols m1 == 1
             || rows m2 == 1 && cols m2 == 1
             || rows m1 == rows m2 && cols m1 == cols m2

instance (Eq a, Field a) => Eq (Vector a) where
    a == b = dim a == dim b && toList a == toList b

instance (Linear Vector a) => Num (Vector a) where
    (+) = adaptScalar addConstant add (flip addConstant)
    negate = scale (-1)
    (*) = adaptScalar scale mul (flip scale)
    signum = liftVector signum
    abs = liftVector abs
    fromInteger = fromList . return . fromInteger

instance (Eq a, Field a) => Eq (Matrix a) where
    a == b = cols a == cols b && flatten a == flatten b

instance (Linear Vector a) => Num (Matrix a) where
    (+) = liftMatrix2' (+)
    (-) = liftMatrix2' (-)
    negate = liftMatrix negate
    (*) = liftMatrix2' (*)
    signum = liftMatrix signum
    abs = liftMatrix abs
    fromInteger = (1><1) . return . fromInteger

---------------------------------------------------

instance (Linear Vector a) => Fractional (Vector a) where
    fromRational n = fromList [fromRational n]
    (/) = adaptScalar f divide g where
        r `f` v = scaleRecip r v
        v `g` r = scale (recip r) v

-------------------------------------------------------

instance (Linear Vector a, Fractional (Vector a)) => Fractional (Matrix a) where
    fromRational n = (1><1) [fromRational n]
    (/) = liftMatrix2' (/)

---------------------------------------------------------

instance Floating (Vector Double) where
    sin   = vectorMapR Sin
    cos   = vectorMapR Cos
    tan   = vectorMapR Tan
    asin  = vectorMapR ASin
    acos  = vectorMapR ACos
    atan  = vectorMapR ATan
    sinh  = vectorMapR Sinh
    cosh  = vectorMapR Cosh
    tanh  = vectorMapR Tanh
    asinh = vectorMapR ASinh
    acosh = vectorMapR ACosh
    atanh = vectorMapR ATanh
    exp   = vectorMapR Exp
    log   = vectorMapR Log
    sqrt  = vectorMapR Sqrt
    (**)  = adaptScalar (vectorMapValR PowSV) (vectorZipR Pow) (flip (vectorMapValR PowVS))
    pi    = fromList [pi]

-------------------------------------------------------------

instance Floating (Vector (Complex Double)) where
    sin   = vectorMapC Sin
    cos   = vectorMapC Cos
    tan   = vectorMapC Tan
    asin  = vectorMapC ASin
    acos  = vectorMapC ACos
    atan  = vectorMapC ATan
    sinh  = vectorMapC Sinh
    cosh  = vectorMapC Cosh
    tanh  = vectorMapC Tanh
    asinh = vectorMapC ASinh
    acosh = vectorMapC ACosh
    atanh = vectorMapC ATanh
    exp   = vectorMapC Exp
    log   = vectorMapC Log
    sqrt  = vectorMapC Sqrt
    (**)  = adaptScalar (vectorMapValC PowSV) (vectorZipC Pow) (flip (vectorMapValC PowVS))
    pi    = fromList [pi]

-----------------------------------------------------------

instance (Linear Vector a, Floating (Vector a)) => Floating (Matrix a) where
    sin   = liftMatrix sin
    cos   = liftMatrix cos
    tan   = liftMatrix tan
    asin  = liftMatrix asin
    acos  = liftMatrix acos
    atan  = liftMatrix atan
    sinh  = liftMatrix sinh
    cosh  = liftMatrix cosh
    tanh  = liftMatrix tanh
    asinh = liftMatrix asinh
    acosh = liftMatrix acosh
    atanh = liftMatrix atanh
    exp   = liftMatrix exp
    log   = liftMatrix log
    (**)  = liftMatrix2' (**)
    sqrt  = liftMatrix sqrt
    pi    = (1><1) [pi]
