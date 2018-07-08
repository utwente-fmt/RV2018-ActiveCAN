module ReplicatedAutomataGenerator(generateRA) where

import Types
import CommonFunctions
import RefinementPPDATE
import UpgradePPDATE
import qualified Data.Map as Map
import Data.Maybe
import Control.Lens

generateRA :: HT -> Int -> Env -> Property
generateRA c n env = 
 Property (c ^. htName)
          (States [State "start" InitNil []] 
                  [State "postOK" InitNil []] 
                  [State "bad" InitNil []] 
                  [State "idle" InitNil []])
          (makeTransitions c n env)
          PNIL

makeTransitions :: HT -> Int -> Env -> Transitions
makeTransitions c n env =
   let trig    = getTriggerDef (_methodCN c ^. overl) c (allTriggers env) ^. tName
       bs      = snd $ getValue $ lookForAllExitTriggerArgs env c
       cn      = c ^. htName
       oldExpM = oldExpTypes env
       checkId = "id.equals(idAuxPPD) && "
       zs      = if getOldExpr oldExpM cn == "" then "" else ",oldExpAux"
       nvar    = if null zs then "" else "CopyUtilsPPD.copy(msgPPD.getOldExpr(),oldExpAux); "
       idle_to_postok = Arrow trig (checkId ++ "HoareTriplesPPD." ++ cn ++ "_post(" ++ bs ++ zs ++ ")") ("System.out.println(\"    " ++ cn ++ "_postOK \\n \");")
       idle_to_bad    = Arrow trig (checkId ++ "!HoareTriplesPPD." ++ cn ++ "_post(" ++ bs ++ zs ++ ")") ("System.out.println(\"    " ++ cn ++ "_bad \\n \");")
       start_to_idle  = Arrow ("rh" ++ show n) "" ("CopyUtilsPPD.copy(MessagesPPD.getId(msgPPD),idAuxPPD) ; " ++ nvar ++ "System.out.println(\"    " ++ cn ++ "_preOK \\n\");")
   in [Transition "start" start_to_idle "idle",
      Transition "idle" idle_to_postok "postOK",
      Transition "idle" idle_to_bad "bad"
      ]


