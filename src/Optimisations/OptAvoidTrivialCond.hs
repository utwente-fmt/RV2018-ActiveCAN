module Optimisations.OptAvoidTrivialCond(avoidStrengthening) where 


import Types
import CommonFunctions
import UpgradePPDATE

---------------------------------------------------------------
-- Avoid strengthening Hoare triples with trivial conditions --
---------------------------------------------------------------

avoidStrengthening :: [String] -> [String]
avoidStrengthening = checkMiddleExcluded 

--If middle excluded, then verify original precondition
checkMiddleExcluded :: [String] -> [String]
checkMiddleExcluded [xs,ys] = 
 let xs' = "!(" ++ xs ++ ")"
     ys' = "!(" ++ ys ++ ")"
 in if ys == xs' || xs == ys'
    then ["true"]
    else [xs,ys]
checkMiddleExcluded xss     = xss

