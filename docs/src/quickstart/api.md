# Basic API usage

Using the API, you can interact directly with the renderer.

## Image generation

Let's assume we want to render a sphere in the origin using a flat renderer.

First, import the module:

```@repl 1
using Raytracer
```

We need to create the scene. All the shapes of the image must be included in a [`World`](@ref) instance.

```@repl 1
world = World()
```

Then, we need to create the shape and add it to `world`. Here we create a [`Sphere`](@ref) with radius 2 in the origin, with a [`DiffuseBRDF`](@ref). The pigment of the BRDF is a [`CheckeredPigment`](@ref) with a [`RED`](@ref) and [`GREEN`](@ref) pattern.

```@repl 1
sphere = Sphere(
    transformation = scaling(2),
    material = Material(
        brdf = DiffuseBRDF(
            pigment = CheckeredPigment{8}(
                color_on = RED,
                color_off = GREEN
            )
        )
    )
)
append!(world, [sphere])
```

Now we can choose the renderer. For this example, we use a [`FlatRenderer`](@ref).

```@repl 1
renderer = FlatRenderer(world)
```

Now we need to create a [`Camera`](@ref), representing an obesrver. For this example, we use a [`PerspectiveCamera`](@ref) positioned at the point ``(-10,0,0)`` and looking the origin.

```@repl 1
camera = PerspectiveCamera(
    aspect_ratio = 16//9,
    screen_distance = 3,
    transformation = translation(-10,0,0)
)
```

Now we can create the [`ImageTracer`](@ref), with the observer informations, an empty FHD [`HdrImage`](@ref) and no antialiasing:

```@repl 1
image = HdrImage(1920, 1080)
image_tracer = ImageTracer(image, camera)
```

Now we can render the image, using the function [`fire_all_rays!`](@ref):

```julia-repl
julia> fire_all_rays!(image_tracer, renderer)
Progress: 100%|███████████████████████████████████████| Time: 0:00:03
```

Finally, we can save the generated HDR image. Remmember to use `permutedims` when saving the image, otherwise you will have a wrong image!

```julia-repl
julia> save("myimage.pfm", permutedims(image_tracer.image.pixel_matrix))
24883218
```

## Tone mapping

We can apply tone mapping to an HDR image to get a LDR image, like a jpeg or png file.

```julia-repl
julia> tonemapping("myimage.pfm", "myimage.jpg", 0.5f0, 1f0)

-> TONE MAPPING PROCESS
Loading input file 'myimage.pfm'... done!
Applying tone mapping...  done!
Saving final image to 'myimage.jpg'... done!
```

The final image is:

![](https://i.imgur.com/8ZT232A.jpg)
