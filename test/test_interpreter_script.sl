# This is a comment
SPAWN number -9.0
# This is a very long
# multiline comment
# I can do what I want here: 9i ò @ # "
DESPAWN number
SPAWN another_number +9e-3
SPAWN from_an_expression $ 1 + (1 - another_number * 2.5) ^ 3 $
SPAWN string "string"
SPAWN color_list [<1.0, 3, 4>, <7, 9, (10*2)>]
@ # Here I can't anymore
"incomplete string
9i # Numbers and identifiers must be separated
