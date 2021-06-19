# This is a comment
Shape.Sphere()
Camera.Perspective(.aspect_ratio 2, .transformation TRANSLATE(.X 3))
SCALE 30
TRANSLATE(.X 30, .Y 90, .Z 180)
ROTATE(.X 30 * .Y 90 * .Z 180)
Transformation[6, 0, 0, 0, 
               0, 6, 0, 0, 
               0, 0, 6, 0, 
               0, 0, 0, 6]
Material(Brdf.Specular(.pigment Pigment.Checkered(.N 16, .color_on <1,1,1>)))
SPAWN number -9.0
# This is a very long
# multiline comment
# I can do what I want here: 9i ò @ # "
DESPAWN number
SPAWN another_number +9e-3
SPAWN from_an_expression $ round(1 + (1 - another_number * 2.5) ^ 3) $
SPAWN string "string"
SPAWN color_list [<1.0, 3, 4>, <7, 9, (10*2)>]
@ # Here I can't anymore
"incomplete string
9i # Numbers and identifiers must be separated
