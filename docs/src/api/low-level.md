# Low-level API

## Colors and images

We use the `ColorTypes.RGB` from [ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl). Our package extends the methods of this type, for example by implementing sum and difference between two color instances. We also add iterability and broadcasting.

```@autodocs
Modules = [Raytracer]
Private = false
Pages   = ["colors.jl", "hdrimage.jl"]
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
