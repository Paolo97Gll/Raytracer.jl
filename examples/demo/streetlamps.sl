# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Point-light renderer example script with streetlamps

SET
	white  <  1,  1,  1>
	black  <0.3,0.3,0.3>
	ground <  0,  1,  0>

SET light_multiplier 5e2

USING
	Camera.Perspective(.aspect_ratio $16/9$ , .transformation  ROTATE(.Y 15) * TRANSLATE(.X -3))
	Image(1280, 720)
	Renderer.PointLight(.ambient_color $white * 0.05$ )
	Tracer(.samples_per_side 4)

SET
	white_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(white)))
	black_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(black)))
	ground_material Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(ground)))

UNSET ground

SET
 	outer_sphere Shape.Sphere  (.material black_material)
	inner_sphere Shape.Sphere  (.material white_material,  .transformation SCALE 0.99)
	box1         Shape.Cube    (.material black_material,  .transformation TRANSLATE(.Z -0.5) * SCALE(.X 2))
	box2         Shape.Cube    (.material black_material,  .transformation TRANSLATE(.Z -0.5) * SCALE(.Y 2))
  	pole         Shape.Cylinder(.material black_material,  .transformation TRANSLATE(.Z -2.5) * SCALE(.Z 3) )
	ground       Shape.Plane   (.material ground_material, .transformation TRANSLATE(.Z -4))

SET
	bowl DIFF(UNITE(outer_sphere, inner_sphere), FUSE(box1, box2))
	streetlamp UNITE(bowl, pole)

SET
	streetlight    Light(.color $white * light_multiplier$, .position {0, 0, 0}, .linear_radius 0.5)

SPAWN
	ground
	streetlight
	streetlamp

UNSET
	outer_sphere inner_sphere
	box1 box2
	pole
	ground
	bowl
	streetlamp
	streetlight

SET
	x 10
	y 5

SET
	transposition TRANSLATE(.X x, .Y y)

SET
 	outer_sphere Shape.Sphere  (.material black_material,  .transformation transposition)
	inner_sphere Shape.Sphere  (.material white_material,  .transformation transposition * SCALE 0.99)
	box1         Shape.Cube    (.material black_material,  .transformation transposition * TRANSLATE(.Z -0.5) * SCALE(.X 2))
	box2         Shape.Cube    (.material black_material,  .transformation transposition * TRANSLATE(.Z -0.5) * SCALE(.Y 2))
  	pole         Shape.Cylinder(.material black_material,  .transformation transposition * TRANSLATE(.Z -2.5) * SCALE(.Z 3) )
	ground       Shape.Plane   (.material ground_material, .transformation transposition * TRANSLATE(.Z -4))

SET
	bowl DIFF(UNITE(outer_sphere, inner_sphere), FUSE(box1, box2))
	streetlamp UNITE(bowl, pole)

SET
	streetlight    Light(.color $white * light_multiplier$, .position {x, y, 0}, .linear_radius 0.5)

SPAWN
	ground
	streetlight
	streetlamp
