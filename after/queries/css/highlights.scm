;extends
; Extra CSS captures so it colors like VS Code. The colors themselves are set
; in init.lua (the vscode theme block).

; The . # : :: are part of the selector, so they're gold like the name
(class_selector "." @type)
(id_selector "#" @constant)
(pseudo_class_selector ":" @attribute)
(pseudo_element_selector "::" @attribute)
(universal_selector "*" @character.special)  ; * is gold, not an operator

; Keyword values (gray, auto, solid, sans-serif, screen) are orange like
; strings, but not custom properties (--brand), which stay light blue
((plain_value) @string
  (#not-lua-match? @string "^[-][-]"))
(keyword_query) @string
(color_value "#" @string)

; Units (px, %, em) are green like the number in front of them
(unit) @number
