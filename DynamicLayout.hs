-- DynamicLayout Haskell API — generate layout JSON from Haskell code.
--
-- Single-file module. Zero dependencies outside base (no lens, no aeson needed for generation).
-- Works on GHC 8.10+.
--
-- Example:
--   import DynamicLayout (begin, fieldset, label, endFieldset, button, endLayout)
--   main = putStrLn $ endLayout $
--     fieldset "Info" $ label "Hello from Haskell!" $
--     endFieldset $ button "ok" "OK" "primary" True $
--     begin "My Page"

module DynamicLayout where

import Data.List (intercalate)

data Builder = Builder { bbuf :: String, bdepth :: Int, bcomma :: Bool, bcnt :: Int }
  deriving Show

begin :: String -> Builder
begin t = Builder { bbuf = "{\"ui\":{\n    \"title\": \"" ++ esc t ++ "\",\n    \"layout\": [", bdepth = 2, bcomma = False, bcnt = 0 }

endLayout :: Builder -> String
endLayout b = bbuf b' ++ "\n  ]\n}"
  where b' = put "\n  ],\n  \"translations\": {},\n  \"userAccess\": { \"cancel\": true }" b

put :: String -> Builder -> Builder
put s b = b { bbuf = bbuf b ++ s }

indent :: Builder -> Builder
indent b = put ('\n' : replicate (bdepth b * 2) ' ') b

cm :: Builder -> Builder
cm b = if bcomma b then put "," b { bcomma = False } else b

esc :: String -> String
esc = concatMap (\c -> case c of
    '"'  -> "\\\""; '\\' -> "\\\\"; '\n' -> "\\n"; '\r' -> "\\r"; '\t' -> "\\t"
    _    -> [c])

kv :: String -> String -> Builder -> Builder
kv k v b = cm b' `put` "," `indent` `put` ('"' : esc k ++ "\": \"" ++ esc v ++ "\"")
  where b' = b { bcomma = True }

kvint :: String -> Int -> Builder -> Builder
kvint k v b = cm b' `put` "," `indent` `put` ('"' : esc k ++ "\": " ++ show v)
  where b' = b { bcomma = True }

kvbool :: String -> Builder -> Builder
kvbool k b = cm b' `put` "," `indent` `put` ('"' : esc k ++ "\": true")
  where b' = b { bcomma = True }

obj :: Builder -> Builder
obj b = cm b `put` "," `indent` `put` "{" `inc`
  where inc b0 = b0 { bdepth = bdepth b0 + 1, bcomma = False }

closeObj :: Builder -> Builder
closeObj b = b' { bdepth = bdepth b' - 1, bcomma = True } `indent` `put` "}"
  where b' = b { bcomma = False }

arr :: String -> Builder -> Builder
arr k b = cm b `put` "," `indent` `put` ('"' : esc k ++ "\": [") `inc`
  where inc b0 = b0 { bdepth = bdepth b0 + 1, bcomma = False }

closeArr :: Builder -> Builder
closeArr b = b' { bdepth = bdepth b' - 1, bcomma = True } `indent` `put` "]"
  where b' = b { bcomma = False }

key :: String -> Builder -> (String, Builder)
key p b = (p ++ "_" ++ show (bcnt b + 1), b { bcnt = bcnt b + 1 })

withKey :: (String -> Builder -> Builder) -> String -> Builder -> Builder
withKey f p b = let (k, b') = key p b in f k b'

-- Containers
fieldset :: String -> Builder -> Builder
fieldset t b = obj' $ kv "type" "FIELDSET" `kv "key" k `kv "title" t `arr "content"
  where (obj', (k, _)) = (obj, key "fs" b)

endFieldset :: Builder -> Builder
endFieldset = closeArr . closeObj

-- Display
label :: String -> Builder -> Builder
label t = withKey (\k -> obj . kv "type" "LABEL" . kv "key" k . kv "label" t . closeObj) "l"

alert :: String -> String -> Builder -> Builder
alert m c = withKey (\k -> obj . kv "type" "ALERT" . kv "key" k . kv "message" m . kv "color" c . closeObj) "a"

badge :: String -> String -> Builder -> Builder
badge t c = withKey (\k -> obj . kv "type" "BADGE" . kv "key" k . kv "title" t . kv "color" c . closeObj) "bd"

spacer :: Int -> Builder -> Builder
spacer px = withKey (\k -> obj . kv "type" "SPACER" . kv "key" k . kvint "width" px . closeObj) "sp"

-- Inputs
input :: String -> String -> Bool -> Builder -> Builder
input i l r = withKey (\k -> obj . kv "type" "INPUT" . kv "key" k . kv "id" i . kv "label" l . req . closeObj) "i"
  where req = if r then kvbool "required" else id

checkbox :: String -> String -> Builder -> Builder
checkbox i l = withKey (\k -> obj . kv "type" "CHECKBOX" . kv "key" k . kv "id" i . kv "label" l . closeObj) "cb"

-- Actions
button :: String -> String -> String -> Bool -> Builder -> Builder
button i t c d = withKey (\k -> obj . kv "type" "BUTTON" . kv "key" k . kv "id" i . kv "title" t . kv "color" c . def . closeObj) "btn"
  where def = if d then kvbool "default" else id
