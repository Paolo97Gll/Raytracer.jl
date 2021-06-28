# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# High-level utilities


"""
    tonemapping(input_file::String,
                output_file::String,
                α::Float32,
                γ::Float32
                ; disable_output::Bool = false)

Load a pfm hdr image, apply the tone mapping, and save the generated ldr image.

`input_file` is the path to a valid PFM image. `output_file` is the path in which save the generated image + the name
of the output file. The output format is deduced by the extension of the output file: if the name is `example.jpg`,
the image will be exported in JPEG format. `α` is the normalization coefficient. `γ` is the actor of the γ correction.

If `disable_output` is `true`, no message is printed.
"""
function tonemapping(input_file::String,
                     output_file::String,
                     α::Float32,
                     γ::Float32;
                     disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "\n-> TONE MAPPING PROCESS")
    print(io, "Loading input file '$(input_file)'...")
    image = load(input_file) |> HdrImage
    print(io, " done!\nApplying tone mapping... ")
    image = normalize(image, α) |> clamp
    image = γ_correction(image, γ)
    print(io, " done!\nSaving final image to '$(output_file)'...")
    save(output_file, image.pixel_matrix)
    println(io, " done!")
end


#####################################################################


"""
    demo_load_scene(renderer_type::Type{<:Renderer},
                    pt_n::Int,
                    pt_max_depth::Int,
                    pt_roulette_depth::Int)

Private function to create a renderer for the [`demo`](@ref) function.
"""
function demo_load_scene(renderer_type::Type{<:Renderer},
                    pt_n::Int,
                    pt_max_depth::Int,
                    pt_roulette_depth::Int)
    world = World()
    if renderer_type <: OnOffRenderer
        coords_list = map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01))
        append!(coords_list, [[0f0, 0f0, -1f0], [0f0, 1f0, 0f0]])
        cube_vertices = [Sphere(transformation = translation(coords * 1.1f0) * scaling(0.22)) for coords ∈ coords_list]
        append!(world, cube_vertices)
        return OnOffRenderer(world)
    elseif renderer_type <: FlatRenderer
        coords_list = map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01))
        translation_factor, scaling_factor = 1.1f0, scaling(0.22)
        cube_vertices = [Sphere(transformation = translation(coords * translation_factor) * scaling_factor,
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(CYAN))))
                         for coords ∈ coords_list]
        other_spheres = [Sphere(transformation = translation([0f0, 1f0, 0f0] * translation_factor) * scaling_factor,
                                material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{8}(color_on = RED, color_off = GREEN)))),
                         Sphere(transformation = translation([0f0, 0f0, -1f0] * translation_factor) * scaling_factor,
                                material = Material(brdf = DiffuseBRDF(pigment = ImagePigment(HdrImage([RED GREEN BLUE MAGENTA])))))]
        ground = [Plane(transformation = translation([0f0, 0f0, -2f0]),
                        material = Material(brdf = DiffuseBRDF(pigment =CheckeredPigment{4}())))]
        sky = [Sphere(transformation = translation([0f0, 0f0, 0f0]) * scaling(100),
                      material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(WHITE))))]
        append!(world, cube_vertices, other_spheres, ground, sky)
        return FlatRenderer(world)
    elseif renderer_type <: PathTracer
        ground = [Plane(transformation = translation([0f0, 0f0, -1f0]),
                        material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{6}(color_on = RGB(0.3f0, 0.5f0, 0.1f0), color_off = RGB(0.1f0, 0.2f0, 0.5f0)))))]
        sky = [Sphere(transformation = translation([0f0, 0f0, 0f0]) * scaling(100),
                      material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(BLACK)),
                                          emitted_radiance = UniformPigment(WHITE)))]
        other_spheres = [Sphere(transformation = translation([0.5f0, 0.7f0, 0.1f0]),
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.2f0, 0.7f0, 0.8f0))))),
                         Sphere(transformation = translation([-0.2f0, -0.8f0, -0.8f0]) * scaling(0.5f0),
                                material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.6f0, 0.2f0, 0.3f0)))))]
        # other_spheres = [Sphere(transformation = translation([0f0, 0f0, -0.8f0]),
        #                         material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.55f0, 0.55f0, 0.55f0))))),
        #                  Sphere(transformation = translation([-4f0, 0f0, -0.5f0]) * scaling(0.8),
        #                         material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.6f0, 0.2f0, 0.3f0))))),
        #                  Sphere(transformation = translation([0f0, 4f0, 0f0]),
        #                         material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.2f0, 0.7f0, 0.8f0))))),
        #                  Sphere(transformation = translation([0f0, -5f0, 0.5f0]) * scaling(1.5),
        #                         material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(06f0, 0.75f0, 0.2f0))))),
        #                  Sphere(transformation = translation([4f0, 0f0, 2f0]) * scaling(0.6),
        #                         material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.4f0, 0.6f0, 0.4f0)))))]
        append!(world, ground, sky, other_spheres)
        return PathTracer(world, n = pt_n, max_depth=pt_max_depth, roulette_depth = pt_roulette_depth)
    elseif renderer_type <: PointLightRenderer
        ground = [Plane(transformation = translation([0f0, 0f0, -1f0]),
                        material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{6}(color_on = RGB(0.3f0, 0.5f0, 0.1f0), color_off = RGB(0.1f0, 0.2f0, 0.5f0)))))]
        sky = [Sphere(transformation = translation([0f0, 0f0, 0f0]) * scaling(100),
                      material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(WHITE * 1f-2))))]
        other_spheres = [Sphere(transformation = translation([0.5f0, 0.7f0, 0.1f0]),
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.2f0, 0.7f0, 0.8f0))))),
                         Sphere(transformation = translation([-0.2f0, -0.8f0, -0.8f0]) * scaling(0.5f0),
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.6f0, 0.2f0, 0.3f0)))))]
        append!(world, ground, sky, other_spheres)
        lights = Lights([PointLight(position=Point(0, 0, 10f0))])
        return PointLightRenderer(world, lights, BLACK, WHITE * 1f-3)
    else
        error("`Renderer` subtype $renderer_type is not supported by this function.")
    end
end

"""
    demo_load_tracer(image_resolution::Tuple{Int, Int},
                     camera_type::Type{<:Camera},
                     camera_position::Tuple{Float32, Float32, Float32},
                     camera_orientation::Tuple{Float32, Float32, Float32},
                     screen_distance::Float32,
                     samples_per_side::Int
                     ; disable_output::Bool = false)

Private function to create a tracer for the [`demo`](@ref) function.
"""
function demo_load_tracer(image_resolution::Tuple{Int, Int},
                          camera_type::Type{<:Camera},
                          camera_position::Tuple{Float32, Float32, Float32},
                          camera_orientation::Tuple{Float32, Float32, Float32},
                          screen_distance::Float32,
                          samples_per_side::Int;
                          disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    print(io, "Loading tracing informations...")
    image = HdrImage(image_resolution...)
    angx, angy, angz = deg2rad.(camera_orientation)
    transformation = (rotationX(angx) * rotationY(angy) * rotationZ(angz)) * translation(camera_position...)
    if camera_type <: PerspectiveCamera
        camera = PerspectiveCamera(//(image_resolution...), transformation, screen_distance)
    elseif camera_type <: OrthogonalCamera
        camera = OrthogonalCamera(//(image_resolution...), transformation)
    else
        error("`Camera` subtype $camera_type is not supported by this function.")
    end
    println(io, " done!")
    ImageTracer(image, camera, samples_per_side=samples_per_side)
end

"""
    demo(;output_file::String = "demo.jpg",
          camera_type::Type{<:Camera} = PerspectiveCamera,
          camera_position::Tuple{Float32, Float32, Float32} = (-3f0, 0f0, 0f0),
          camera_orientation::Tuple{Float32, Float32, Float32} = (0f0, 0f0, 0f0),
          screen_distance::Float32 = 2f0,
          image_resolution::Tuple{Int, Int} = (540,540),
          samples_per_side::Int = 0,
          renderer_type::Type{<:Renderer} = PathTracer,
          pt_n::Int = 10,
          pt_max_depth::Int = 2,
          pt_roulette_depth::Int = 3,
          α::Float32 = 0.75f0,
          γ::Float32 = 1f0,
          use_threads::Bool = true,
          disable_output::Bool = false)

Create a demo image.

# Arguments

- `output_file`: output LDR file name (the HDR file will have the same name, but with "pfm" extension).
- `camera_type`: choose camera type ("perspective" or "orthogonal").
- `camera_position`: camera position in the scene as "X,Y,Z".
- `camera_orientation`: camera orientation as "angX,angY,angZ".
- `screen_distance`: only for "perspective" camera: distance between camera and screen.
- `image_resolution`: resolution of the rendered image.
- `renderer_type`: type of renderer to use ("onoff", "flat" or "path").
- `samples_per_side`: number of samples per pixel (must be a perfect square).
- `pt_n`: number of rays fired for mc integration (path-tracer only).
- `pt_max_depth`: maximum number of reflections for each ray (path-tracer only).
- `pt_roulette_depth`: depth of the russian-roulette algorithm (path-tracer only).
- `α`: scaling factor for the normalization process.
- `γ`: gamma value for the tone mapping process.
- `use_threads`: use macro `Threads.@threads`.
- `disable_output`: if `true`, no message is printed.
"""
function demo(;output_file::String = "demo.jpg",
               camera_type::Type{<:Camera} = PerspectiveCamera,
               camera_position::Tuple{Float32, Float32, Float32} = (-3f0, 0f0, 0f0),
               camera_orientation::Tuple{Float32, Float32, Float32} = (0f0, 0f0, 0f0),
               screen_distance::Float32 = 2f0,
               image_resolution::Tuple{Int, Int} = (540,540),
               renderer_type::Type{<:Renderer} = PathTracer,
               samples_per_side::Int = 0,
               pt_n::Int = 10,
               pt_max_depth::Int = 2,
               pt_roulette_depth::Int = 3,
               α::Float32 = 0.75f0,
               γ::Float32 = 1f0,
               use_threads::Bool = true,
               disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "\n-> RENDERING")
    print(io, "Loading scene...")
    renderer = demo_load_scene(renderer_type, pt_n, pt_max_depth, pt_roulette_depth)
    println(io, " done!")
    image_tracer = demo_load_tracer(image_resolution, camera_type, camera_position, camera_orientation, screen_distance, samples_per_side, disable_output=disable_output)
    println(io, "Rendering image...")
    fire_all_rays!(image_tracer, renderer, use_threads=use_threads, enable_progress_bar=!disable_output)
    print(io, "Saving pfm image...")
    input_file = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    save(input_file, permutedims(image_tracer.image.pixel_matrix))
    println(io, " done!")
    tonemapping(input_file, output_file, α, γ, disable_output=disable_output)
end
