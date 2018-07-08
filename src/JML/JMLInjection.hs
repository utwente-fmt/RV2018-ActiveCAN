module JML.JMLInjection(injectJMLannotations) where

import Types
import JML.JMLGenerator
import CommonFunctions
import System.Directory
import Data.Char
import UpgradePPDATE
import ErrM
import Java.JavaLanguage
import System.IO
import Control.Lens hiding(Context,pre)

-------------------------------------------------
-- Injecting JML annotations for Hoare triples --
-------------------------------------------------

injectJMLannotations :: UpgradePPD PPDATE -> FilePath -> FilePath -> IO ()
injectJMLannotations ppd jpath output_addr = 
 let toAnalyse_add = output_addr ++ "workspace/files2analyse"
 in do createDirectoryIfMissing False toAnalyse_add
       copyFiles jpath toAnalyse_add
       prepareTmpFiles ppd toAnalyse_add jpath
       return ()

------------------------------------- 
-- Generating annotated temp files --
-------------------------------------

prepareTmpFiles :: UpgradePPD PPDATE -> FilePath -> FilePath -> IO [()]
prepareTmpFiles ppd output_add jpath = 
 do let (ppdate, env) = fromOK $ runStateT ppd emptyEnv
    let imports       = ppdate ^. importsGet
    let cinvs         = ppdate ^. cinvariantsGet
    let ys            = splitCInvariants cinvs []
    let consts        = ppdate ^. htsGet
    let xs            = splitClassHT consts
    let join_xs       = joinClassHT xs []
    let jinfo         = javaFilesInfo env
    let consts_jml    = getHTs ppd
    let imports'      = [i | i <- imports,not (elem ((\ (Import s) -> s) i) importsInKeY)]
    sequence $ map (\ i -> annotateTmpFiles i output_add jpath jinfo ys join_xs consts_jml) imports'


annotateTmpFiles :: Import -> FilePath -> FilePath -> [(String, ClassInfo, JavaFilesInfo)] 
                    -> [(Class, CInvariants)] -> [(ClassInfo, [HTName])] 
                    -> HTjml -> IO ()
annotateTmpFiles i output_add jpath jinfo ys jxs consts_jml = 
  do (main, cl) <- makeAddFile i
     let jpath'      = jpath ++ "/" ++ main
     let output_add' = output_add ++ "/" ++ main
     createDirectoryIfMissing True output_add'
     let file        = jpath' ++ "/" ++ (cl ++ ".java")  
     let tmp         = output_add' ++ "/" ++ (cl ++ ".java")
     r <- readFile file
     let dummyVars  = generateDBMFile cl jxs r
     let cinvs      = generateTmpFileCInv cl ys dummyVars
     let nullable   = updateTmpFileCInv cl jinfo cinvs
     let specPublic = updateSpecPublic cl jinfo nullable
     let contracts  = genTmpFilesConst (main,cl) consts_jml specPublic
     writeFile tmp contracts     

---------------------------------------------
-- Injecting JML annotations for contracts --
---------------------------------------------

genTmpFilesConst :: (String, ClassInfo) -> HTjml -> String -> String
genTmpFilesConst (main, cl) [] r     = r
genTmpFilesConst (main, cl) (x:xs) r = 
 let mn  = x ^. _1
     cl' = x ^. _2
     ov  = x ^. _3
     jml = x ^. _4
 in do if (cl == cl') 
       then do let (ys, zs) = if (mn == cl)
                              then lookForConstructorDef mn (lines r)
                              else lookForMethodDef mn ov (lines r)
               let r' = (unlines ys) ++ jml ++ (unlines zs)
               genTmpFilesConst (main, cl) xs r'
       else genTmpFilesConst (main, cl) xs r


lookForMethodDef :: MethodName -> Overriding -> [String] -> ([String], [String])
lookForMethodDef mn _ []        = error $ "Something went wrong when annotating the method " ++ mn ++ ".\n"
lookForMethodDef mn ov (xs:xss) = 
 let ys = splitOnIdentifier mn xs
 in if (length ys == 1)
    then (xs:a, b) --method name does not appear in the line
    else let zs     = (clean.head.tail) ys 
             beginl = (words.head) ys 
         in if ((head zs) == '(')
            then if (length beginl == 1)
                 then (xs:a, b) --not a method definition (does not have modifier or type)
                 else let ws = (clean.head) beginl
                      in if (elem ws javaModifiers)
                         then let ts = splitOnIdentifier "," $ fst $ splitAtClosingParen 0 $ tail zs in
                              if checkArguments ov ts
                              then ([], xs:xss)
                              else (xs:a, b) --not the intended method (overloading)
                         else (xs:a, b) --not a method definition (does not start with modifier)
            else (xs:a, b) --not referring to a method
                where (a, b) = lookForMethodDef mn ov xss

checkArguments :: Overriding -> [String] -> Bool
checkArguments _ []           = False
checkArguments OverNil _      = True
checkArguments (Over []) [[]] = True
checkArguments (Over []) _    = False
checkArguments (Over ts) [[]] = False
checkArguments (Over ts) ts'  =  
 let types = map (head.words) ts'
 in ts == types

lookForConstructorDef :: MethodName -> [String] -> ([String], [String])
lookForConstructorDef mn []       = error $ "Something went wrong when checking the constructor " ++ mn ++ ".\n"
lookForConstructorDef mn (xs:xss) = 
 let ys = splitOnIdentifier mn xs
 in if (length ys <= 1 || length ys > 2)
    then (xs:a, b)
    else let zs     = (clean.head.tail) ys 
             beginl = (clean.head) ys 
         in if (null beginl || elem beginl javaModifiers)
            then if ((head zs) == '(')
                 then ([], xs:xss)
                 else (xs:a, b)
            else (xs:a, b)
                where (a, b) = lookForConstructorDef mn xss

-------------------------------------------
-- Adds spec_public to private variables --
-------------------------------------------

updateSpecPublic :: String -> [(String, ClassInfo, JavaFilesInfo)] -> String -> String
updateSpecPublic cl jinfo r = 
 let varsc    = getListOfTypesAndVars cl jinfo
     methodsc = getListOfTypesAndMethods cl jinfo
     (ys, zs) = lookForClassBeginning cl (lines r)
 in (unlines ys) ++ (unlines (searchAndAnnotateMethods (searchAndAnnotateVarsSP zs varsc) methodsc))

searchAndAnnotateVarsSP :: [String] -> [(String, String, String)] -> [String]
searchAndAnnotateVarsSP xss []     = xss
searchAndAnnotateVarsSP xss (ys:yss) = 
 if not (ys ^._1 == "private")
 then searchAndAnnotateVarsSP xss yss
 else let xss' = annotateSpecPublic ys xss
      in searchAndAnnotateVarsSP xss' yss

annotateSpecPublic :: (String,String, String) -> [String] -> [String]
annotateSpecPublic (mod,t,v) []       = []
annotateSpecPublic (mod,t,v) (xs:xss) = 
 let ident = t ++ " " ++ v
     ys    = splitOnIdentifier ident xs
 in if (length ys == 1)
    then xs:annotateSpecPublic (mod,t, v) xss
    else let xs' = (head ys) ++ " /*@ spec_public @*/ " ++ ident ++ (head.tail) ys
         in xs':xss

searchAndAnnotateMethods :: [String] -> [(String, String, String)] -> [String]
searchAndAnnotateMethods xss []     = xss
searchAndAnnotateMethods xss (ys:yss) = 
 if not (ys ^._3 == "private")
 then searchAndAnnotateMethods xss yss
 else let xss' = annotateSpecPublicM ys xss
      in searchAndAnnotateMethods xss' yss

annotateSpecPublicM :: (String,String, String) -> [String] -> [String]
annotateSpecPublicM (t,v,mod) []       = []
annotateSpecPublicM (t,v,mod) (xs:xss) = 
 let ident = t ++ " " ++ v
     ys    = splitOnIdentifier ident xs
 in if (length ys == 1)
    then xs:annotateSpecPublicM (t, v, mod) xss
    else let xs' = (head ys) ++ " /*@ spec_public @*/ " ++ ident ++ (head.tail) ys
         in xs':xss

-------------------------------------
-- Adds nullable to class variables --
-------------------------------------

updateTmpFileCInv :: String -> [(String, ClassInfo, JavaFilesInfo)] -> String -> String
updateTmpFileCInv cl jinfo r =
 let varsc    = getListOfTypesAndVars cl jinfo
     (ys, zs) = lookForClassBeginning cl (lines r)
 in (unlines ys) ++ (unlines (searchAndAnnotateVars zs varsc))

searchAndAnnotateVars :: [String] -> [(String, String, String)] -> [String]
searchAndAnnotateVars xss []               = xss
searchAndAnnotateVars xss ((mods,t,v):yss) = 
 if (elem t primitiveJavaTypes)
 then searchAndAnnotateVars xss yss
 else let xss' = annotateNullable (t,v) xss
      in searchAndAnnotateVars xss' yss

--TODO: This method may need to be upgraded
annotateNullable :: (String, String) -> [String] -> [String]
annotateNullable (t, v) []       = []
annotateNullable (t, v) (xs:xss) = 
 let ident = t ++ " " ++ v
     ys    = splitOnIdentifier ident xs
 in if (length ys == 1)
    then xs:annotateNullable (t, v) xss
    else let xs' = (head ys) ++ " /*@ nullable @*/ " ++ ident ++ (head.tail) ys
         in xs':xss


----------------------------------------------------
-- Injecting JML annotations for Class Invariants --
----------------------------------------------------

splitCInvariants :: CInvariants -> [(Class, CInvariants)] -> [(Class, CInvariants)]
splitCInvariants [] acum           = acum
splitCInvariants (cinv:cinvs) acum = splitCInvariants cinvs (updateAcum cinv acum)
 
updateAcum :: CInvariant -> [(Class, CInvariants)] -> [(Class, CInvariants)]
updateAcum cinv@(CI class' body) []               = [(class', [cinv])]
updateAcum cinv@(CI class' body) ((cl, cinvs):as) = 
 if (class' == cl)
 then (cl, cinv:cinvs):as
 else (cl,cinvs):updateAcum cinv as

generateTmpFileCInv :: String -> [(Class, CInvariants)] -> String -> String
generateTmpFileCInv cl xs r =
 let cinvs_jml = getCInvariants $ getCInvs' xs cl
     (ys, zs)  = lookForClassBeginning cl (lines r)
 in (unlines ys) ++ cinvs_jml ++ (unlines zs) 

lookForClassBeginning :: ClassInfo -> [String] -> ([String], [String])
lookForClassBeginning c []       = error $  "Something went wrong when checking a class invariant for the class " ++ c  ++ ".\n"
lookForClassBeginning c (xs:xss) = let ys = splitOnIdentifier ("class " ++ c) xs
                                   in if (length ys == 1)
                                      then (xs:a, b)
                                      else let (ts,zs) = splitAtIdentifier '{' $ (head.tail) ys
                                           in if (null zs)
                                              then splitOpeningBracket (xs:xss)                                                   
                                              else ([xs], xss)
                                           where (a, b) = lookForClassBeginning c xss


splitOpeningBracket :: [String] -> ([String],[String])
splitOpeningBracket []       = ([],[])
splitOpeningBracket (xs:xss) = 
 let ys = splitOnIdentifier "{" xs
 in if (length ys == 1)
    then (xs:a,b)
    else ([xs++"\n"],"\n":xss)
       where (a,b) = splitOpeningBracket xss

getCInvs' :: [(Class, CInvariants)] -> Class -> CInvariants
getCInvs' [] _           = []
getCInvs' ((cl', cinvs):xs) cl = if (cl' == cl)
                                then cinvs
                                else getCInvs' xs cl

---------------------------------------
-- Injecting dummy boolean variables --
---------------------------------------

generateDBMFile :: String -> [(ClassInfo, [HTName])] -> String -> String
generateDBMFile cl xs r =
 let dummy_vars = map genDummyVarJava $ lookForConstsNames cl xs
     (ys, zs)   = lookForClassBeginning cl (lines r)
 in (unlines ys) ++ concat dummy_vars ++ (unlines zs) 


genDummyVarJava :: HTName -> String
genDummyVarJava cn = "  public static final boolean " ++ cn ++ " = true;\n"

lookForConstsNames :: ClassInfo -> [(ClassInfo, [HTName])] -> [HTName]
lookForConstsNames cn []             = []
lookForConstsNames cn ((cn', cs):xs) = if (cn == cn')
                                       then cs
                                       else lookForConstsNames cn xs 

splitClassHT :: HTriples -> [(ClassInfo, HTName)]
splitClassHT []     = []
splitClassHT (c:cs) = (_methodCN c ^. clinf, c ^. htName) : splitClassHT cs

joinClassHT :: [(ClassInfo, HTName)] -> [(ClassInfo, [HTName])] -> [(ClassInfo, [HTName])]
joinClassHT [] jcc     = jcc
joinClassHT (x:xs) jcc = joinClassHT xs (updateJCC x jcc) 

updateJCC :: (ClassInfo, HTName) -> [(ClassInfo, [HTName])] -> [(ClassInfo, [HTName])]
updateJCC (cn, c) []            = [(cn, [c])]
updateJCC (cn, c) ((cn',cs):xs) = if (cn == cn')
                                  then (cn', c:cs) : xs
                                  else (cn', cs):updateJCC (cn, c) xs
