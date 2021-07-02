# this script does not need to define a renderer to be used since it
# will be determined in the Julia scripts in this folder

USING 
    Image(1000, 1000)
	Camera.Perspective(.transformation TRANSLATE(.X -3))
	Tracer()

SET 
	white  <1.000,1.000,1.000>
	red    <0.800,0.235,0.204>
	green  <0.212,0.592,0.145>
	purple <0.580,0.345,0.694>

SET 
	white_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(white)))
	red_material    Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(red)))
	green_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(green)))
	purple_material Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(purple)))

SPAWN
	Shape.Plane(.material green_material, .transformation TRANSLATE(.Z -1))
	Shape.Cylinder(.material red_material, .transformation TRANSLATE(.Y 1.5 ) * SCALE(.Z 2))
	Shape.Cube(.material purple_material, .transformation TRANSLATE(.X 5, .Y -1.5 ) * SCALE(.Z 2))