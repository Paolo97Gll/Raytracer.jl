# test constructors and SET do work 
SET camera Camera.Perspective(.aspect_ratio 2, .transformation TRANSLATE(.X 3))
ROTATE sphere Shape.Sphere()
SET scaling SCALE 30
SET translation TRANSLATE(.X 30, .Y 90, .Z 180)
SET rotation ROTATE(.X 30 * .Y 90 * .Z 180)
# newlines are not an obstacle
SET transformation Transformation([6, 0, 0, 0, 
                                   0, 6, 0, 0, 
                                   0, 0, 6, 0, 
                                   0, 0, 0, 6])
SET material Material(Brdf.Specular(.pigment Pigment.Checkered(.N 16, .color_on <1,1,1>)))
SET light Light(.position {0, 0, 1})
SET image LOAD "test/memorial.pfm"
SET a_number 9
# check all variables have been printed on terminal
DUMP.variables
# try the UNSET command
UNSET rotation
# try adding something to the world
SPAWN sphere light
# check if it worked
DUMP.ALL