SET cathedral LOAD "/home/xaco/Desktop/blue_skies.jpg"
SET material Material(.emitted_radiance Pigment.Image(cathedral))
SET sky_sphere Shape.Sphere(.material material, .transformation SCALE 10)
UNSET material

SET red   <1,0,0>
SET green <0,1,0>
SET blue  <0,0,1>

SET red_material       Material(.brdf Brdf.Diffuse(Pigment.Uniform(red)))
SET green_material     Material(.brdf Brdf.Diffuse(Pigment.Uniform(green)))
SET blue_material      Material(.brdf Brdf.Diffuse(Pigment.Uniform(blue)))
SET checkered_material Material(.brdf Brdf.Diffuse(Pigment.Checkered(.N 4)))

SET strange_cube     Shape.Cube    (.material red_material,   .transformation ROTATE(.Y 45 * .Z 45))
SET strange_cylinder Shape.Cylinder(.material green_material, .transformation ROTATE(.Y 90) * SCALE(.X 0.5, .Y 0.7, .Z 2))

SPAWN Shape.Cylinder(.material blue_material,      .transformation TRANSLATE(.Y 1.5, .Z 1) * SCALE(.Z 4))
SPAWN Shape.Plane   (.material checkered_material, .transformation TRANSLATE(.Z -1))
SPAWN Shape.Sphere  (.material green_material,     .transformation TRANSLATE(.Y -3.5, .X 4))
SPAWN DIFF(strange_cube, strange_cylinder)
SPAWN sky_sphere

SET pos {0,0,2} #{-1, -0.3, 1}
SPAWN Light(.position pos, .color <5, 5, 5>)

SET camera Camera.Perspective(.transformation ROTATE(.Z 0 * .Y 90) * TRANSLATE(.X -1.5))

# DUMP.ALL
USING camera 
USING Renderer.PointLight()
USING Image(1000, 1000)
USING Tracer()