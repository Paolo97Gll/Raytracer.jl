SET cathedral LOAD "/home/xaco/Desktop/blue_skies.jpg"
SET material Material(.emitted_radiance Pigment.Image(cathedral))
SET sky_sphere Shape.Sphere(.material material, .transformation SCALE 10)
UNSET material

#= a block comment =#
#= this even spans 
   multiple lines =#

SET 
	red   <1,0,0>
	green <0,1,0>
	blue  <0,0,1>

SET
	red_material       Material(.brdf Brdf.Diffuse(Pigment.Uniform(red)))
	green_material     Material(.brdf Brdf.Diffuse(Pigment.Uniform(green)))
	blue_material      Material(.brdf Brdf.Diffuse(Pigment.Uniform(blue)))
	checkered_material Material(.brdf Brdf.Diffuse(Pigment.Checkered(.N 4)))

SET 
	strange_cube     Shape.Cube    (.material red_material,   .transformation ROTATE(.Y 45 * .Z 45))
	strange_cylinder Shape.Cylinder(.material green_material, .transformation ROTATE(.Y 90) * SCALE(.X 0.5, .Y 0.7, .Z 2))

SPAWN 
	Shape.Cylinder(.material blue_material,      .transformation TRANSLATE(.Y 1.5, .Z 1) * SCALE(.Z 4))
	Shape.Plane   (.material checkered_material, .transformation TRANSLATE(.Z -1))
	Shape.Sphere  (.material green_material,     .transformation TRANSLATE(.Y -3.5, .X 4))
	DIFF(strange_cube, strange_cylinder)
	sky_sphere

SET pos {-1, -0.3, 1}
SPAWN Light(.position pos, .color <5, 5, 5>)

SET camera Camera.Perspective(.transformation ROTATE(.Z 20) * TRANSLATE(.X -1.5))

# DUMP.ALL
USING
	camera 
	Renderer.PointLight()
	Image(1000, 1000)
	Tracer()