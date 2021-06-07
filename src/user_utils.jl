# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# High-level utilities
# TODO write docstrings


function tonemapping(input_file::String,
                     output_file::String,
                     alpha::Float32,
                     gamma::Float32;
                     disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "\n-> TONE MAPPING PROCESS")
    print(io, "Loading input file '$(input_file)'...")
    image = load(input_file) |> HdrImage
    print(io, " done!\nApplying tone mapping... ")
    image = normalize_image(image, alpha) |> clamp_image
    image = γ_correction(image, gamma)
    print(io, " done!\nSaving final image to '$(output_file)'...")
    save(output_file, image.pixel_matrix)
    println(io, " done!")
end


#####################################################################


function load_scene(renderer_type::Type{<:Renderer})
    world = World()
    coords_list = map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01))
    if renderer_type <: OnOffRenderer
        cube_vertices = [Sphere(transformation = translation(coords * 0.5f0) * scaling(1f0/10)) for coords ∈ coords_list]
        other_spheres = [Sphere(transformation = translation([0f0, 0f0, -0.5f0]) * scaling(1f0/10)),
                         Sphere(transformation = translation([0f0, 0.5f0, 0f0]) * scaling(1f0/10))]
        append!(world, cube_vertices, other_spheres)
        return OnOffRenderer(world)
    elseif renderer_type <: FlatRenderer
        cube_vertices = [Sphere(transformation = translation(coords * 0.5f0) * scaling(1f0/10),
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(CYAN))))
                         for coords ∈ coords_list]
        other_spheres = [Sphere(transformation = translation([0f0, 0f0, -0.5f0]) * scaling(1f0/10),
                                material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{4}(color_on = RED, color_off = GREEN)))),
                         Sphere(transformation = translation([0f0, 0.5f0, 0f0]) * scaling(1f0/10),
                                material = Material(brdf = DiffuseBRDF(pigment = ImagePigment(HdrImage([RED GREEN BLUE MAGENTA])))))]
        ground = [Plane(transformation = translation([0f0, 0f0, -1f0]),
                        material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{4}())))]
        sky = [Plane(transformation = translation([0f0, 0f0, 10f0]),
                     material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(WHITE))))]
        append!(world, cube_vertices, other_spheres, ground, sky)
        return FlatRenderer(world)
    elseif renderer_type <: PathTracer
        ground = [Plane(transformation = translation([0f0, 0f0, -1f0]),
                        material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{4}(color_on = RGB(0.3f0, 0.5f0, 0.1f0), color_off = RGB(0.1f0, 0.2f0, 0.5f0)),
                                                               reflectance = 0.5f0)))]
        sky = [Plane(transformation = translation([0f0, 0f0, 100f0]),
                     material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(BLACK)),
                                         emitted_radiance = UniformPigment(RGB(1f0, 1f0, 1.2f0))))]
        # other_spheres = [Sphere(transformation = translation([0.5f0, 0.7f0, 0.1f0]),
        #                         material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.2f0, 0.7f0, 0.8f0))))),
        #                  Sphere(transformation = translation([-0.2f0, -0.8f0, -0.8f0]) * scaling(0.5f0),
        #                         material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.6f0, 0.2f0, 0.3f0)))))]
        other_spheres = [Sphere(transformation = translation([0f0, 0f0, -0.8f0]),
                                material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.55f0, 0.55f0, 0.55f0))))),
                         Sphere(transformation = translation([4f0, 0f0, -0.2f0]) * scaling(0.8),
                                material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.6f0, 0.2f0, 0.3f0))))),
                         Sphere(transformation = translation([0f0, 4f0, 0f0]),
                                material = Material(brdf = DiffuseBRDF(pigment = UniformPigment(RGB(0.2f0, 0.7f0, 0.8f0))))),
                         Sphere(transformation = translation([0f0, -5f0, 0.5f0]) * scaling(1.5),
                                material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(06f0, 0.75f0, 0.2f0))))),
                         Sphere(transformation = translation([-4f0, 0f0, 2f0]) * scaling(0.6),
                                material = Material(brdf = SpecularBRDF(pigment = UniformPigment(RGB(0.2f0, 0.6f0, 0.3f0)))))]
        append!(world, ground, sky, other_spheres)
        return PathTracer(world, max_depth=5, n=1)
    else
        error("`Renderer` subtype $renderer_type is not supported by this function.")
    end
end

function load_tracer(image_resolution::Tuple{Int, Int},
                     camera_type::Type{<:Camera},
                     camera_position::Tuple{Float32, Float32, Float32},
                     camera_orientation::Tuple{Float32, Float32, Float32},
                     screen_distance::Float32;
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
    ImageTracer(image, camera)
end

function rendering!(image_tracer::ImageTracer, renderer::Renderer; use_threads::Bool = true, disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "Rendering image...")
    fire_all_rays!(image_tracer, renderer, use_threads=use_threads, enable_progress_bar=!disable_output)
end

function demo(output_file::String,
              image_resolution::Tuple{Int, Int},
              camera_type::Type{<:Camera},
              camera_position::Tuple{Float32, Float32, Float32},
              camera_orientation::Tuple{Float32, Float32, Float32},
              screen_distance::Float32,
              renderer_type::Type{<:Renderer},
              alpha::Float32,
              gamma::Float32;
              use_threads::Bool = true,
              disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "\n-> RENDERING")
    print(io, "Loading scene...")
    renderer = load_scene(renderer_type)
    println(io, " done!")
    image_tracer = load_tracer(image_resolution, camera_type, camera_position, camera_orientation, screen_distance, disable_output=disable_output)
    rendering!(image_tracer, renderer, use_threads=use_threads, disable_output=disable_output)
    print(io, "Saving pfm image...")
    input_file = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    save(input_file, permutedims(image_tracer.image.pixel_matrix))
    println(io, " done!")
    tonemapping(input_file, output_file, alpha, gamma, disable_output=disable_output)
end
