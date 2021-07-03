# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Raytracer.jl logo

# Set variables using symbolic constructors
SET
	white  <1.000,1.000,1.000>
	red    <0.800,0.235,0.204>
	green  <0.212,0.592,0.145>
	purple <0.580,0.345,0.694>

SET
	background <1,1,1>
	ambient_ratio 0

SET light_multiplier 5e1

# Declare the needed Raytracer settings
# Object are constructed in-place using named constructors
USING
	Camera.Perspective(.transformation TRANSLATE(.X -3))
	Image(500, 500)
	Renderer.PointLight(.ambient_color $background * ambient_ratio$, .background_color background)
	Tracer(.samples_per_side 8)

# Set variables using named constructors and keyword arguments
SET
	red_material    Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(red)))
	green_material  Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(green)))
	purple_material Material(.brdf Brdf.Diffuse(.pigment Pigment.Uniform(purple)))

SET
	offset 1.5

# These svariables are constructed by referring 
# to previously declared variables and through
# mathematical expressions surrounded by `$`
SET
	ll_sphere    Shape.Sphere  (.material red_material,    .transformation TRANSLATE(.Y $ offset * 3/4$, .Z $-offset/2$))
	lr_cylinder  Shape.Cylinder(.material purple_material, .transformation TRANSLATE(.Y $-offset * 3/4$, .Z $-offset/2$) * SCALE 1.5)
	uc_cube      Shape.Cube    (.material green_material,  .transformation TRANSLATE(.Z $offset$) * SCALE 1.5)

SET
	light    Light(.color $white * light_multiplier$, .position {-2, 0, 0}, .linear_radius 1)

# Spawns the given shapes and lights into the world,
# This means they will be rendered by Raytracer
# If a shape or light is not spawned it is ignored in the rendering process.
SPAWN
	ll_sphere
	uc_cube
	lr_cylinder
	light