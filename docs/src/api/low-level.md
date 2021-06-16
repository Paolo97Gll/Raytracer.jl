# [Low-level API](@id low_level_api)

## Contents

```@contents
Pages = ["low-level.md"]
Depth = 3
```

## Colors and images

We use the `ColorTypes.RGB` from [ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl). Our package extends the methods of this type, for example by implementing sum and difference between two color instances. We also add iterability and broadcasting.

### Colors

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["colors.jl"]
```

### HDR image

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["hdrimage.jl"]
```

## Geometry

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["geometry.jl"]
```

## Transformations

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["transformations.jl"]
```

## Ray

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["ray.jl"]
```

## Cameras

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["cameras.jl"]
```

## Materials, BRDF and pigments

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["materials.jl"]
```

## Shapes

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["hitrecord.jl", "shapes.jl", "world.jl"]
```

### Simple shapes

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["shapes/cube.jl", "shapes/cylinder.jl", "shapes/plane.jl", "shapes/sphere.jl"]
```

### Composite shapes

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["shapes/csg.jl"]
```

### AABB

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["shapes/aabb.jl"]
```

## Lights

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["lights.jl"]
```

## PCG random number generator

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["pcg.jl"]
```

## Renderer

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["renderers.jl"]
```

## Image tracer

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["imagetracer.jl"]
```

## Index

```@index
Modules = [Raytracer]
Pages   = ["low-level.md"]
```
