module Translators.PPDATE2Script(ppd2Script) where

import Types
import CommonFunctions
import Control.Lens hiding(Context,pre)

------------------------------
-- ppDATE to input language --
------------------------------

ppd2Script :: PPDATE -> String
ppd2Script ppd = 
 case ppd of
      PPDATE imps global temps cinvs hts ms ->
            writePPDImports imps
            ++ writePPDGlobal global
            ++ writePPDTemps temps
            ++ writePPDCinvs cinvs
            ++ writePPDHts hts
            ++ writePPDMethods ms


writePPDImports :: Imports -> String
writePPDImports imps = 
 "IMPORTS {\n"
 ++ unlines (map show imps)
 ++ "}\n\n"

writePPDGlobal :: Global -> String
writePPDGlobal (Global ctxt) = 
 "GLOBAL {\n\n"
 ++ writePPDContext ctxt
 ++ "}\n\n"

writePPDContext :: Context -> String
writePPDContext (Ctxt vars acts trs props fors) =
 writePPDVariables vars
 ++ writePPDActs acts
 ++ writePPDTriggers trs
 ++ writePPDProps props
 ++ writePPDForeaches fors

writePPDVariables :: Variables -> String
writePPDVariables []   = ""
writePPDVariables vars =
 "VARIABLES {\n"
 ++ unlines (map show vars)
 ++ "}\n\n"

writePPDActs :: ActEvents -> String
writePPDActs []   = ""
writePPDActs acts = 
 "ACTEVENTS {\n"
 ++ addComma (map show acts) ++ "\n"
 ++ "}\n\n"

writePPDTriggers :: Triggers -> String
writePPDTriggers []  = ""
writePPDTriggers trs = 
 "TRIGGERS {\n"
 ++ unlines (map show trs)
 ++ "}\n\n"

writePPDProps :: Property -> String
writePPDProps PNIL                    = ""
writePPDProps (PINIT nm tmp bds prop) = 
 "PROPERTY " ++ nm ++ " {\n"
 ++ "PINIT { (" ++ tmp ++ "," ++ bds ++ ") }\n"
 ++ "}\n\n"
 ++ writePPDProps prop
writePPDProps (Property nm sts trans prop) = 
 "PROPERTY " ++ nm ++ " {\n\n"
 ++ writePPDStates sts
 ++ writePPDTransitions trans
 ++ "}\n\n"
 ++ writePPDProps prop

writePPDStates :: States -> String
writePPDStates (States start acc bad normal) =
 let acc'    = map show acc
     bad'    = map show bad
     normal' = map show normal
     start'  = map show start
 in "STATES \n{\n"
    ++ writePPDState "STARTING" start'
    ++ writePPDState "ACCEPTING" acc'
    ++ writePPDState "BAD" bad'
    ++ writePPDState "NORMAL" normal'    
    ++ "}\n\n"

writePPDState :: String -> [String] -> String
writePPDState iden xs = if null (filter (\c -> c /= "") xs)
                        then ""
                        else iden ++ " { " ++ concat xs ++ "}\n"
 

writePPDTransitions :: Transitions -> String
writePPDTransitions []    = ""
writePPDTransitions trans = 
 "TRANSITIONS {\n"
 ++ unlines (map show trans)
 ++ "}\n\n"

writePPDForeaches :: Foreaches -> String
writePPDForeaches []          = ""
writePPDForeaches fors@(f:fs) = unlines (map writePPDForeach fors)
 
writePPDForeach :: Foreach -> String
writePPDForeach foreach = 
 "FOREACH (" ++ addComma (map show (foreach ^. getArgsForeach)) ++ ") {\n\n"
 ++ writePPDContext (foreach ^. getCtxtForeach)
 ++ "}\n\n"

writePPDTemps :: Templates -> String
writePPDTemps TempNil      = ""
writePPDTemps (Temp temps) =
 "TEMPLATES {\n\n"
 ++ unlines (map writePPDTemp temps)
 ++ "}\n\n" 

writePPDTemp :: Template -> String
writePPDTemp (Template id bnds vars acts trs prop) = 
 "TEMPLATE " ++ id ++ " (" ++ addComma (map show bnds) ++ ")" ++ " {\n\n"
 ++ writePPDVariables vars
 ++ writePPDActs acts
 ++ writePPDTriggers trs
 ++ writePPDProps prop
 ++ "}\n\n"


writePPDCinvs :: CInvariants -> String
writePPDCinvs []    = ""
writePPDCinvs cinvs = 
 "CINVARIANTS {\n"
 ++ writePPDCinvs' cinvs
 ++ "}\n\n"

writePPDCinvs' :: CInvariants -> String
writePPDCinvs' []                 = ""
writePPDCinvs' (CInvNil:cinvs)    = writePPDCinvs' cinvs
writePPDCinvs' (inv:cinvs)        =
 show inv ++ "\n" ++ writePPDCinvs' cinvs

writePPDHts :: HTriples -> String
writePPDHts []  = ""
writePPDHts hts =
 "HTRIPLES {\n\n"
 ++ writePPDHts' hts
 ++ "}\n\n"

writePPDHts' :: HTriples -> String
writePPDHts' []      = ""
writePPDHts' (h:hts) = 
 "HT " ++ h ^. htName ++ " {\n"
 ++ "PRE { " ++ h ^. pre ++" }\n"
 ++ "METHOD { " ++ (_methodCN h) ^. clinf ++ "." ++ (_methodCN h) ^. mname ++ show ((_methodCN h) ^. overl) ++ " }\n"
 ++ "POST { " ++ h ^. post ++" }\n"
 ++ "ASSIGNABLE { " ++ h ^. assignable ++" }\n"
 ++ "}\n\n"
 ++ writePPDHts' hts

writePPDMethods :: Methods -> String
writePPDMethods [] = ""
writePPDMethods xs = xs
