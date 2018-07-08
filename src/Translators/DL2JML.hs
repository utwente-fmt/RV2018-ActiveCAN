module Translators.DL2JML where

import Types
import CommonFunctions


-------------
-- ! (not) --
-------------

addParenthesisNot :: String -> String
addParenthesisNot s = 
 let xs = splitOnIdentifier "&&" s
 in if (length xs > 1)
    then joinAnds $ map (addParenthesis.trim) xs
    else addParenthesis s

addParenthesis :: String -> String
addParenthesis []       = ""
addParenthesis s@(c:cs) = 
 if (c == '!')
 then "!(" ++ cs ++ ")"
 else s

joinAnds :: [String] -> String
joinAnds [xs]     = xs
joinAnds (xs:xss) = xs ++ " && " ++ joinAnds xss

--------------------------
-- Remove/replace Self. --
--------------------------

removeSelf :: String -> String
removeSelf s = let xs = splitOnIdentifier "self." s
               in concat xs

replaceSelfWith :: String -> String -> String
replaceSelfWith with s = let xs = splitOnIdentifier "self" s
                         in head xs ++ concat (map (with ++) (tail xs))


--------------------------
-- Remove dl_strContent --
--------------------------

removeDLstrContent :: String -> String
removeDLstrContent s =
 let xs = splitOnIdentifier "\\dl_strContent(" s
 in if length xs == 1 
    then s 
    else concat $ head xs:map (uncurry (++).splitAtClosingParen 0) (tail xs)

