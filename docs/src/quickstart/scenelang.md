# Basic SceneLang usage

As it has been seen in the [Basic CLI tool usage](@ref) section, scenes can be rendered by the `render` command starting from a SceneLang script.

SceneLang is a custom Domain-Specific Language (DSL) conceived to allow an easy description of scenes that can be rendered by Raytracer. A SceneLang script must be stored in a file with the `.sl` extension and must contain a series of instructions aimed at constructing an image.

!!! tip
    If you use Visual Studio Code, you can install the [SceneLang Highlighter]((https://marketplace.visualstudio.com/items?itemName=samuele-colombo.scenelang-highlighter)) extension, which add support for syntax highlighting.

We refer to the [SceneLang documentation](@ref scenelang) for an in-depth explanation on how the language works, but a simple example of how the scripting language works is the script that generates the Raytracer.jl logo. This script can be found in `examples/logo.sl`.

```julia
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
```
To render this script one must invoke, from the root directory of Raytracer, the following command

```shell
julia raytracer_cli.jl render image examples/logo.sl --with-tonemapping -O "logo" -e "png" -l 1
```
which results in the `logo.pfm` and `logo.png` files being created.

It is possible to alter the properties of this image using the `--var` option of the CLI tool. For example one can modify the script so that the offset between the shapes is a little greater and the background is black then we can override the values declared in the script by invoking the following command

```shell
julia raytracer_cli.jl render image examples/logo.sl --var "offset 2, background <0,0,0>" --with-tonemapping -O "logo" -e "png" -l 0.5
```

The `examples` folder is full of various scripts that explore the capabilitiers of the Raytracer CLI tool and SceneLang. We suggest to take a look at them and try and execute them with various settings to get a feel on how to use these powerful features.
