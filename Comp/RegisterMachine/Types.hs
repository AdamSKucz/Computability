module Comp.RegisterMachine.Types (
    Natural,
    Register,
    Location,
    Instruction(..),
    RegisterMachine,
    RegisterState,
    RMState
) where

import Data.Map (Map)
import Data.Natural (Natural)

type Register = Natural
type Location = Natural
data Instruction = 
    HALT
  | INC Register Location
  | DEC Register Location Location
  deriving (Read, Show, Eq)
type RegisterMachine = [Instruction]
type RegisterState = Map Register Natural
type RMState = (RegisterMachine, Location, RegisterState)