module Optimisations.Optimisations where 


import Types
import CommonFunctions
import UpgradePPDATE
import Translators.DL2JML
import Optimisations.OptAvoidTrivialCond
import Control.Lens hiding(Context,pre)
import ParserActions.ParserAct
import qualified ParserActions.AbsActions as Abs
import ParserActions.PrintActions
import ErrM

--------------------------------------------------------------
-- Deductive verification to partially verify Hoare triples --
--------------------------------------------------------------

-- Remove Hoare triples which were fully proved --

optimisedProvenHTs :: HTriples -> (HTName -> a -> a) -> a -> a
optimisedProvenHTs [] f ps     = ps
optimisedProvenHTs (c:cs) f ps = f (c ^. htName) $ optimisedProvenHTs cs f ps

refinePropertyOptTemplates :: HTName -> Templates -> Templates
refinePropertyOptTemplates _ TempNil       = TempNil
refinePropertyOptTemplates cn (Temp temps) = Temp $ map (refineTemplate cn) temps

refineTemplate :: HTName -> Template -> Template
refineTemplate cn temp = tempProp %~ removeStatesProp cn $ temp

refinePropertyOptGlobal :: HTName -> Global -> Global
refinePropertyOptGlobal cn global = ctxtGet %~ (refineContext cn) $ global

refineContext :: HTName -> Context -> Context
refineContext cn ctxt = 
 ctxt & property %~ cproved2null cn . removeStatesProp cn
      & foreaches %~ (map (refineForeach cn))

refineForeach :: HTName -> Foreach -> Foreach
refineForeach cn foreach = getCtxtForeach %~ (refineContext cn) $ foreach

removeStatesProp :: HTName -> Property -> Property
removeStatesProp _ PNIL               = PNIL
removeStatesProp _ p@(PINIT _ _ _ _)  = p
removeStatesProp cn prop = let States acc bad nor star = pStates prop
                               acc'   = map (\s -> removeStateProp s cn) acc
                               bad'   = map (\s -> removeStateProp s cn) bad
                               nor'   = map (\s -> removeStateProp s cn) nor
                               star'  = map (\s -> removeStateProp s cn) star
                               states = States acc' bad' nor' star'
                           in Property (pName prop) states (pTransitions prop) (removeStatesProp cn (pProps prop))

removeStateProp :: State -> HTName -> State
removeStateProp (State ns ic cns) cn = State ns ic (removePropInState cn cns)

removePropInState :: HTName -> [HTName] -> [HTName]
removePropInState cn []        = []
removePropInState cn (cn':cns) = if (cn == cn')
                                 then cns
                                 else cn':removePropInState cn cns

-- Replaces fully proved Hoare triples used as arguments in actions \create by null
cproved2null :: HTName -> Property -> Property
cproved2null _ PNIL               = PNIL
cproved2null _ p@(PINIT _ _ _ _)  = p
cproved2null cn prop = 
 let trans = pTransitions prop 
 in Property (pName prop) (pStates prop) (replaceByNull cn trans) (cproved2null cn (pProps prop))

replaceByNull :: HTName -> Transitions -> Transitions
replaceByNull cn = foldr (\ x xs -> (rTransByNull cn x) : xs) []

rTransByNull :: HTName -> Transition -> Transition
rTransByNull cn tran = tran { arrow = rArrowByNull cn (arrow tran) } 

rArrowByNull :: HTName -> Arrow -> Arrow
rArrowByNull cn arr = 
 case parse (action arr) of 
      Bad s -> error s
      Ok (Abs.Actions ac) -> 
          let acts = map (rActionsByNull cn) ac
              arr' = printTree acts
          in arr { action = arr' }

rActionsByNull :: HTName -> Abs.Action -> Abs.Action
rActionsByNull cn (Abs.ActCreate id args) = Abs.ActCreate id (map (rArgsByNull cn) args)
rActionsByNull cn act = act 

rArgsByNull :: HTName -> Abs.Args -> Abs.Args
rArgsByNull cn (Abs.ArgsId (Abs.IdAct id)) = 
 if (trim id == cn)
 then Abs.ArgsId (Abs.IdAct "null")
 else Abs.ArgsId (Abs.IdAct id)
rArgsByNull cn (Abs.ArgsS s)               =
 if (trim s == cn)
 then Abs.ArgsS "null"
 else Abs.ArgsS s
rArgsByNull cn arg                         = arg



-- Strengthen preconditions --

strengthenPre :: HTriples -> HTriples
strengthenPre []      = []
strengthenPre (h:hts) = 
 let newpre = (removeSelf.head.(^. newPRe)) h
     pre'   = "(" ++ h ^. pre ++ ") && " ++ newpre
 in if ((head.(^. newPRe)) h == "(true)")
    then h:strengthenPre hts
    else (pre .~ pre' $ h):strengthenPre hts

---------------------------------------------------------------
-- Avoid strengthening Hoare triples with trivial conditions --
---------------------------------------------------------------

simplify :: [String] -> [String]
simplify = avoidStrengthening 

