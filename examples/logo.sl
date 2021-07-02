# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Raytracer.jl logo

SET
	white  <1.000,1.000,1.000>
	red    <0.800,0.235,0.204>
	green  <0.212,0.592,0.145>
	purple <0.580,0.345,0.694>

SET light_multiplier 5e1

USING
	Camera.Perspective(.transformation TRANSLATE(.X -3))
	Image(500, 500)
	Renderer.PointLight(.ambient_color $white * 0.0$, .background_color white)
	Tracer(.samples_per_side 8)

SET
	red_material    Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(red)))
	green_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(green)))
	purple_material Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(purple)))

SET
	offset 1.5

SET
	ll_sphere    Shape.Sphere  (.material red_material,    .transformation TRANSLATE(.Y $ offset * 3/4$, .Z $-offset/2$))
	lr_cylinder  Shape.Cylinder(.material purple_material, .transformation TRANSLATE(.Y $-offset * 3/4$, .Z $-offset/2$) * SCALE 1.5)
	uc_cube      Shape.Cube    (.material green_material,  .transformation TRANSLATE(.Z $offset$) * SCALE 1.5)

SET
	light    Light(.color $white * light_multiplier$, .position {-2, 0, 0}, .linear_radius 1)

SPAWN
	ll_sphere
	uc_cube
	lr_cylinder
	light
