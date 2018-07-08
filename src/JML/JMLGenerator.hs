module JML.JMLGenerator where

import Types
import UpgradePPDATE
import ErrM
import Control.Lens hiding(Context,pre,assign)

----------------------
-- Class Invariants --
----------------------

getCInvariants :: CInvariants -> String 
getCInvariants []           = ""
getCInvariants (cinv:cinvs) = fromCInvariant2JML cinv ++ getCInvariants cinvs

fromCInvariant2JML :: CInvariant -> String
fromCInvariant2JML (CI _ body) =
  "\n  /*@ public invariant\n" 
  ++ "    @ " ++ body ++ ";\n"
  ++ "    @*/ \n" 

-------------------
-- Hoare Triples --
-------------------

getHTs :: UpgradePPD PPDATE -> HTjml
getHTs = genJMLConstsAll'

genJMLConstsAll' :: UpgradePPD PPDATE -> HTjml
genJMLConstsAll' ppd = 
 let ppdate = getValue ppd
     cs     = ppdate ^. htsGet
 in map (over _4 (\ y -> "  /*@ \n" ++ y ++ "    @*/\n")) $ genJMLConsts' cs []

genJMLConsts' :: HTriples -> HTjml -> HTjml
genJMLConsts' [] xs     = xs
genJMLConsts' (c:cs) xs = let mn = _methodCN c ^. mname
                              cl = _methodCN c ^. clinf
                              ov = _methodCN c ^. overl
                          in genJMLConsts' cs (updateJMLForM' c mn cl ov xs)

updateJMLForM' :: HT -> MethodName -> ClassInfo -> Overriding -> HTjml -> HTjml
updateJMLForM' c mn cl ov []                       = [(mn, cl, ov,fromHT2JML' c)]
updateJMLForM' c mn cl ov (x:xs) = if (mn == (x ^. _1) && cl == (x ^. _2) && ov == (x ^. _3))
                                   then (_4 %~ (\ jml -> jml ++ "    @\n    @ also\n    @\n" ++ fromHT2JML' c) $ x):xs
                                   else x:updateJMLForM' c mn cl ov xs

fromHT2JML' :: HT -> String
fromHT2JML' ht =  
  "    @ public normal_behaviour\n"
  ++ "    @ " ++ requires (ht ^. pre) (ht ^. htName)
  ++ "    @ " ++ ensures (ht ^. post)
  ++ "    @ " ++ assign (ht ^. assignable)
  ++ "    @ diverges true;\n" -- partial correctness

-- bool variable added to be able to identify the Hoare triple
-- associated to the jml specification when analysing the .xml file
requires :: Pre -> HTName -> String
requires p cn = "requires " ++ cn ++ " && " ++ p ++ ";\n"

ensures :: Post -> String
ensures p = "ensures " ++ p ++ ";\n"

assign :: Assignable -> String
assign ass = "assignable " ++ ass ++ ";\n"


