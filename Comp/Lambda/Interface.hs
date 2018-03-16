{-# LANGUAGE FlexibleContexts #-}

module Comp.Lambda.Interface (
  makeHumanFriendly
) where 

import Control.Monad.State.Class (MonadState, state, gets, modify)
import Control.Monad.State (evalState)

import Data.Set (Set, union)
import qualified Data.Set as Set

import Data.Maybe (isJust, fromJust)

import Data.Natural

import Comp.Theory.Class (Comp(..))

import Comp.Lambda.Types
import Comp.Lambda.Util
import Comp.Lambda.Terms
import Comp.Lambda.Comp
import Comp.Lambda.Parser

import Debug.Trace (trace)

-- TODO: test and verify tH out of makeHumanFriendly
-- ///TODO: rewrite as a makeHumanFriendly :: LambdaTerm -> LambdaTerm function

humanFriendlySubs :: LambdaTerm -> Var -> LambdaTerm -> LambdaTerm
humanFriendlySubs m x n = evalState (subsMX n) (Set.singleton x `union` variables m `union` variables n)
  where subsMX :: (MonadState (Set Var) m) => LambdaTerm -> m LambdaTerm
        subsMX (V y)
          | y == x          = return m
          | otherwise       = return $ V y
        subsMX (Lambda y n)
          | y == x          = return $ Lambda y n
          | isAbsent y m
            || isAbsent x n = do
              n' <- subsMX n
              return $ Lambda y n'
          | otherwise       = do
              z <- gets getNewVarExcept
              modify $ Set.insert z
              n' <- subsMX $ subsVar z y n
              return $ Lambda z n'
          where z = getNewVar [m, V x]
        subsMX (App n1 n2)  = do
          n1' <- subsMX n1
          n2' <- subsMX n2
          return $ App n1' n2'

{-
-- uses outer-most, left-most reduction order    
hfOneStepBetaReduce :: LambdaTerm -> Maybe LambdaTerm
hfOneStepBetaReduce (App (Lambda x m) n) 
  = Just $ humanFriendlySubs n x m
hfOneStepBetaReduce (Lambda x m) 
  | isJust mm' = Just $ Lambda x m'
  where mm' = hfOneStepBetaReduce m
        m' = fromJust mm'
hfOneStepBetaReduce (App m n) 
  | isJust mm' = Just $ App m' n
  | isJust mn' = Just $ App m n'
  where mm' = hfOneStepBetaReduce m
        mn' = hfOneStepBetaReduce n
        m' = fromJust mm'
        n' = fromJust mn'
hfOneStepBetaReduce l = Nothing
          
humanFriendlyBNF :: LambdaTerm -> LambdaTerm
humanFriendlyBNF m = case hfOneStepBetaReduce m of
                      Just m' -> humanFriendlyBNF m'
                      Nothing -> m
-}

hfVars :: [Var]
hfVars = [ c : s | s <- "" : hfVars, c <- alphabet]
  where alphabet = ['a'..'z']

-- TODO: implement
makeHumanFriendly :: LambdaTerm -> LambdaTerm
makeHumanFriendly lt = evalState (go lt) $ filter (`notElem` freeVariables lt) hfVars
  where go :: MonadState [Var] m => LambdaTerm -> m LambdaTerm
        go (Lambda x lt)  = do
          x' <- state $ \(h:t) -> (h, t)
          lt' <- go lt
          return . Lambda x' $ humanFriendlySubs (V x') x lt'
          --trace ("lt' = " ++ prettyShow lt') .
          --  trace ("returning = " ++ (prettyShow . Lambda x' $ humanFriendlySubs (V x') x lt')) . 
          --  return . Lambda x' $ humanFriendlySubs (V x') x lt'
        go (V x)          = return $ V x
        go (App l1 l2)    = do
          l1' <- go l1
          l2' <- go l2
          return $ App l1' l2'

churchAsFunction :: LambdaTerm -> (a -> a) -> a -> a
churchAsFunction (Lambda f' (Lambda x' l)) f x = go l
  where go (V v)          | v == x' = x
        go (App (V v) l') | v == f' = f (go l')
        go _                        = undefined
churchAsFunction lt f x = error $ "This is not a church numeral: " ++ prettyShow lt
        
toNatural :: LambdaTerm -> Natural
toNatural n = churchAsFunction (toBNF n) (+1) 0

instance Comp LambdaTerm where
  computeC lt ns = toNatural $ applyToAll [churchNum n | n <- ns] lt
  
  succC = succF
  zeroC = zeroF
  projC = projF
  composeC = composeF
  primRecC = primRecF
  minimizeC = minimizeF
  
  constC = churchNum