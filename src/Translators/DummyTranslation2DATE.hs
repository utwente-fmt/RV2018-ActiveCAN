module Translators.DummyTranslation2DATE(translate) where

import Types
import CommonFunctions
import UpgradePPDATE
import ErrM
import qualified Data.Map as Map
import Data.Maybe


translate :: UpgradePPD PPDATE -> FilePath -> IO ()
translate ppd fpath =
 do let (ppdate, env) = (\(Ok x) -> x) $ runStateT ppd emptyEnv
    putStrLn "Translating ppDATE to DATE."
    writeFile fpath (writeImports (importsGet ppdate))
    appendFile fpath (writeGlobal ppdate env)
    appendFile fpath (writeMethods (methodsGet ppdate))
    putStrLn $ "Translation completed."

---------------------
-- IMPORTS section --
---------------------

getImports :: Imports -> String
getImports []            = ""
getImports (Import s:xs) = "import " ++ s ++ ";\n" ++ getImports xs

writeImports :: Imports -> String
writeImports xss = "IMPORTS {\n" ++ getImports xss ++ "}\n\n"

--------------------
-- GLOBAL section --
--------------------

writeGlobal :: PPDATE -> Env -> String
writeGlobal ppdate env = let global = ctxtGet $ globalGet ppdate
                             consts = htsGet ppdate
                             vars   = variables global
                             es     = triggers global
                             prop   = property global
                             fors   = foreaches global
                             vars'  = if null vars then "" else "VARIABLES {\n" ++ writeVariables vars ++ "}\n\n"
                         in "GLOBAL {\n\n"
                            ++ vars'
                            ++ writeTriggers es
                            ++ writeProperties prop consts es env
                            ++ writeForeach fors consts env
                            -- ++ "}\n"

---------------
-- Variables --
---------------

writeVariables :: Variables -> String
writeVariables []     = ""
writeVariables (v:vs) = writeVariable v ++ ";\n" ++ writeVariables vs

writeVariable :: Variable -> String
writeVariable (Var vm t vdec) = writeVarModifier vm ++ " "
                                ++ t ++ " "
                                ++ flattenVariables (map writeVarDecl vdec)

writeVarModifier :: VarModifier -> String
writeVarModifier VarModifierNil   = ""
writeVarModifier VarModifierFinal = "final"

writeVarDecl :: VarDecl -> String
writeVarDecl (VarDecl id (VarInit ve)) = id ++ " = " ++ ve
writeVarDecl (VarDecl id VarInitNil)   = id

flattenVariables :: [String] -> String
flattenVariables []       = ""
flattenVariables [x]      = x
flattenVariables (x:y:xs) = x ++ "," ++ flattenVariables (y:xs)

--------------
-- Triggers --
--------------

writeTriggers :: Triggers -> String
writeTriggers [] = ""
writeTriggers es = "EVENTS {\n"
                   ++ writeAllTriggers es
                   ++ "}\n\n"

writeAllTriggers :: Triggers -> String
writeAllTriggers []     = ""
writeAllTriggers (e:es) = (getTrigger e) ++ writeAllTriggers es

getTrigger :: TriggerDef -> String
getTrigger (TriggerDef e arg cpe wc) =
 let wc' = if (wc == "") then "" else " where {" ++ wc ++ "}"
 in e ++ "(" ++ getBindArgs' arg ++ ") = " ++ getCpe cpe ++ wc' ++ "\n"


getCpe :: CompoundTrigger -> String
getCpe (Collection (CECollection xs)) = "{" ++ getCollectionCpeCompoundTrigger xs ++ "}"
getCpe ce@(OnlyIdPar _)               = getCpeCompoundTrigger ce
getCpe ce@(OnlyId _)                  = getCpeCompoundTrigger ce
getCpe ce@(ClockEvent _ _)            = getCpeCompoundTrigger ce
getCpe ce@(NormalEvent _ _ _ _)       = getCpeCompoundTrigger ce


getCollectionCpeCompoundTrigger :: [CompoundTrigger] -> String
getCollectionCpeCompoundTrigger []   = ""
getCollectionCpeCompoundTrigger [ce] = getCpeCompoundTrigger ce
getCollectionCpeCompoundTrigger (ce:y:ys) = getCpeCompoundTrigger ce ++ " | " ++ getCollectionCpeCompoundTrigger (y:ys)

getCpeCompoundTrigger :: CompoundTrigger -> String
getCpeCompoundTrigger (OnlyIdPar id)                 = "{" ++ id ++ "()" ++ "}"
getCpeCompoundTrigger (OnlyId id)                    = "{" ++ id ++ "}"
getCpeCompoundTrigger (ClockEvent id n)              = "{" ++ id ++ "@" ++ show n ++ "}"
getCpeCompoundTrigger (NormalEvent bind id bs ev)    = "{" ++ getBinding bind ++ id ++ "(" ++ getBindArgs bs ++ ")"
                                                     ++ getTriggerVariation' ev ++ "}"
getCpeCompoundTrigger _                              = ""

getBindArgs :: [Bind] -> String
getBindArgs []                 = ""
getBindArgs [BindId id]        = id
getBindArgs ((BindId id):y:ys) = id ++ "," ++ getBindArgs (y:ys)
getBindArgs (BindStar:ys)      = "*," ++ getBindArgs ys

getBinding :: Binding -> String
getBinding (BindingVar BindStar)        = "*."
getBinding (BindingVar (BindType t id)) = t ++ " " ++ id ++ "."
getBinding (BindingVar (BindId id))     = id ++ "."

getTriggerVariation' :: TriggerVariation -> String
getTriggerVariation' EVEntry      = "uponEntry"
getTriggerVariation' (EVExit xs)  = "uponReturning(" ++ auxGetTriggerVariation' xs ++ ")"
getTriggerVariation' (EVThrow xs) = "uponThrowing(" ++ auxGetTriggerVariation' xs ++ ")"
getTriggerVariation' (EVHadle xs) = "uponHandling(" ++ auxGetTriggerVariation' xs ++ ")"

auxGetTriggerVariation' :: [Bind] -> String
auxGetTriggerVariation' []           = ""
auxGetTriggerVariation' [BindId ret] = ret

----------------
-- Properties --
----------------

writeProperties :: Property -> HTriples -> Triggers -> Env -> String
writeProperties PNIL _ _ _         = ""
writeProperties prop consts es env =
 let fors   = forsVars env --list of foreach variables
     xs     = getProperties prop consts es env
 in if (null fors)
    then xs
    else xs ++ "\n}\n"


getProperties :: Property -> HTriples -> Triggers -> Env -> String
getProperties = writeProperty

writeProperty :: Property -> HTriples -> Triggers -> Env -> String
writeProperty PNIL _ _ _                                   = ""
writeProperty (Property name states trans props) cs es env =
  "PROPERTY " ++ name ++ " \n{\n\n"
  ++ writeStates cs states
  ++ writeTransitions trans [] states es env
  ++ "}\n\n"
  ++ writeProperty props cs es env

writeStates :: HTriples -> States -> String
writeStates cs (States acc bad normal start) =
 let acc'    = getStates acc cs
     bad'    = getStates bad cs
     normal' = getStates normal cs
     start'  = getStates start cs
 in "STATES \n{\n"
    ++ writeState "ACCEPTING" acc'
    ++ writeState "BAD" bad'
    ++ writeState "NORMAL" normal'
    ++ writeState "STARTING" start'
    ++ "}\n\n"

writeState :: String -> String -> String
writeState iden xs = if (clean xs == "")
                     then ""
                     else iden ++ " { " ++ xs ++ "}\n"

getStates :: [State] -> HTriples -> String
getStates [] _                   = ""
getStates (State n ic cns:xs) cs = n ++ " " ++ getInitCode' ic ++ (wrapper.addComma.removeDuplicates) (genContractInfo cns cs) ++ getStates xs cs

wrapper :: String -> String
wrapper [] = "{}"
wrapper xs = "{returnThis(\"" ++ xs ++ "\")} "

genContractInfo :: [HTName] -> HTriples -> [String]
genContractInfo [] _        = []
genContractInfo [cn] cs     = [getInfo cn cs]
genContractInfo (cn:cns) cs = getInfo cn cs : genContractInfo cns cs

getInfo :: HTName -> HTriples -> String
getInfo cn []     = ""
getInfo cn (c:cs) =
 if htName c == cn
 then (fst.methodCN) c ++ "." ++ (snd.methodCN) c
 else getInfo cn cs

getInitCode' :: InitialCode -> String
getInitCode' InitNil         = ""
getInitCode' (InitProg java) = "{" ++ init java ++ "}"

--HTriples [] -> Replicated Automata
--HTriples non-empty -> Property transitions instrumentation
writeTransitions :: Transitions -> HTriples -> States -> Triggers -> Env -> String
writeTransitions ts [] _ _ _ =
 "TRANSITIONS \n{ \n"
 ++ concat (map getTransition ts)
 ++ "}\n\n"
writeTransitions ts (c:cs) states es env =
 "TRANSITIONS \n{ \n"
  ++ (concat (map getTransition (getTransitionsGeneral (c:cs) states ts es env)))
  ++ "}\n\n"

getTransition :: Transition -> String
getTransition (Transition q (Arrow e c act) q') =
     q ++ " -> " ++ q' ++ " [" ++ e ++ " \\ "  ++ c ++ " \\ " ++ act ++ "]\n"

getTransitionsGeneral :: HTriples -> States -> Transitions -> Triggers -> Env -> Transitions
getTransitionsGeneral cs (States acc bad nor star) ts es env =
 let ts1 = generateTransitions acc cs ts es env
     ts2 = generateTransitions bad cs ts1 es env
     ts3 = generateTransitions nor cs ts2 es env
     ts4 = generateTransitions star cs ts3 es env
 in ts4

generateTransitions :: [State] -> HTriples -> Transitions -> Triggers -> Env -> Transitions
generateTransitions [] _ ts _ _                              = ts
generateTransitions ((State ns ic []):xs) cs ts es env       = generateTransitions xs cs ts es env
generateTransitions ((State ns ic l@(_:_)):xs) cs ts es env  = let ts' = accumTransitions l ns cs ts es env
                                                               in generateTransitions xs cs ts' es env

accumTransitions :: [HTName] -> NameState -> HTriples -> Transitions -> Triggers -> Env -> Transitions
accumTransitions [] _ _ ts _ _                = ts
accumTransitions (cn:cns) ns consts ts es env =
 let ts' = generateTransition cn ns consts ts es env
 in accumTransitions cns ns consts ts' es env

generateTransition :: HTName -> NameState -> HTriples -> Transitions -> Triggers -> Env -> Transitions
generateTransition p ns cs ts es env = let c             = lookForHT p cs
                                           mn            = snd $ methodCN c
                                           e             = lookForEntryTrigger (allTriggers env) mn
                                           (lts, nonlts) = lookForLeavingTransitions e ns ts
                                       in if (null lts)
                                          then ts ++ [(makeTransitionAlg1Cond ns e c env)]
                                          else ts


makeTransitionAlg1Cond :: NameState -> Trigger -> HT -> Env -> Transition
makeTransitionAlg1Cond ns e c env =
 let cn      = htName c
     oldExpM = oldExpTypes env
     esinf   = map fromJust $ filter (/= Nothing) $ map getInfoTrigger (allTriggers env)
     esinf'  = filter (/="") $ lookfor esinf e
     arg     = if null esinf'
               then ""
               else init $ foldr (\x xs -> x ++ "," ++ xs) "" $ map (head.tail.words) $ esinf'
     c'      = "HoareTriplesPPD." ++ cn ++ "_pre(" ++ arg ++ ")"
     act     = getExpForOld oldExpM cn ++ " h" ++ show (chGet c) ++ ".send(" ++ msg ++ ");"
     zs      = getExpForOld oldExpM cn
     type_   = if null zs then "PPD" else "Old_" ++ cn
     old     = if null zs then "" else "," ++ cn
     msg     = "new Messages" ++ type_ ++ "(id" ++ old ++ ")"
 in Transition ns (Arrow e c' act) ns

getExpForOld :: OldExprM -> HTName -> String
getExpForOld oldExpM cn =
 case Map.lookup cn oldExpM of
      Nothing -> ""
      Just xs -> if null xs
                 then ""
                 else cn ++ " = " ++ initOldExpr xs cn ++ ";"

initOldExpr :: OldExprL -> HTName -> String
initOldExpr oel cn =
 "new Old_" ++ cn ++ "(" ++ addComma (map (\(x,_,_) -> x) oel) ++ ")"

lookForHT :: PropertyName -> HTriples -> HT
lookForHT p []     = error $ "Wow! The impossible happened when checking the property "++ p ++ " on a state.\n"
lookForHT p (c:cs) = if (htName c == p)
                     then c
                     else lookForHT p cs

lookForLeavingTransitions :: Trigger -> NameState -> Transitions -> (Transitions, Transitions)
lookForLeavingTransitions e ns []                                        = ([],[])
lookForLeavingTransitions e ns (t@(Transition q (Arrow e' c act) q'):ts) = if (e == e')
                                                                           then if (ns == q && ns /= q')
                                                                                then (t:a, b)
                                                                                else (a, t:b)
                                                                           else (a,t:b)
                                                                                where (a, b) = lookForLeavingTransitions e ns ts

-------------
-- Foreach --
-------------

writeForeach :: Foreaches -> HTriples -> Env -> String
writeForeach [] _ _                         = ""
writeForeach [Foreach args ctxt] consts env =
 let vars   = variables ctxt
     es     = triggers ctxt
     prop   = property ctxt
     fors   = foreaches ctxt
     vars'  = if (null vars)
              then ""
              else "VARIABLES {\n" ++ writeVariables vars ++ "}\n\n"
 in "FOREACH (" ++ getForeachArgs args ++ ") {\n\n"
    ++ vars'
    ++ writeTriggers es
    ++ writeProperties prop consts es env
    ++ writeForeach fors consts env
    ++ "}\n"

getForeachArgs :: [Args] -> String
getForeachArgs []               = ""
getForeachArgs [Args t id]      = t ++ " " ++ id
getForeachArgs (Args t id:y:ys) = t ++ " " ++ id ++ "," ++ getForeachArgs (y:ys)


---------------------
-- Methods section --
---------------------

writeMethods :: Methods -> String
writeMethods methods = "\n" ++  methods
