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

function load_tracer(image_resolution::Tuple{Int, Int},
                     camera_type::String,
                     camera_position::Tuple{Float32, Float32, Float32},
                     camera_orientation::Tuple{Float32, Float32, Float32},
                     screen_distance::Float32;
                     disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    print(io, "Loading tracing informations...")
    image = HdrImage(image_resolution...)
    angx, angy, angz = deg2rad.(camera_orientation)
    transformation = (rotationX(angx) * rotationY(angy) * rotationZ(angz)) * translation(camera_position...)
    if camera_type == "perspective"
        camera = PerspectiveCamera(//(image_resolution...), transformation, screen_distance)
    elseif camera_type == "orthogonal"
        camera = OrthogonalCamera(//(image_resolution...), transformation)
    else
        # TODO throw error
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
              camera_type::String,
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
    if renderer_type <: OnOffRenderer
        world = World(undef, 10)
        for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
            world[i] = Sphere(transformation = translation(coords * 0.5f0) * scaling(1f0/10))
        end
        world[end-1:end] = [Sphere(transformation = translation([0f0, 0f0, -0.5f0]) * scaling(1f0/10)), Sphere(transformation = translation([0f0, 0.5f0, 0f0]) * scaling(1f0/10))]
        renderer = renderer_type(world, WHITE, BLACK)
    elseif renderer_type <: FlatRenderer
        world = World(undef, 11)
        for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
            world[i] = Sphere(transformation = translation(coords * 0.5f0) * scaling(1f0/10), 
                              material = Material(brdf = 
                                DiffuseBRDF(pigment = 
                                    UniformPigment(RGB(0f0, 1f0, 0f0))
                                )
                              )
                             )
        end
        world[end-2] = Plane(transformation = translation([0f0, 0f0, -1f0]), material = Material(brdf = DiffuseBRDF(pigment = CheckeredPigment{4}())))
        world[end-1:end] = [Sphere(transformation = translation([0f0, 0f0, -0.5f0]) * scaling(1f0/10),
                                   material = Material(brdf = 
                                        DiffuseBRDF(pigment = 
                                            CheckeredPigment{4}(color_on  = RGB(1f0, 0f0, 0f0), 
                                                                color_off = RGB(0f0, 1f0, 0f0)
                                                               )
                                        )
                                   )
                                  ), 
                            Sphere(transformation = translation([0f0, 0.5f0, 0f0]) * scaling(1f0/10),
                                   material = Material(brdf = 
                                        DiffuseBRDF(pigment = 
                                            ImagePigment(HdrImage([RGB(1f0, 0f0, 0f0) RGB(0f0, 1f0, 0f0) RGB(0f0, 0f0, 1f0) RGB(1f0, 0f0, 1f0)]))
                                        )
                                   )
                                  )] 
        renderer = renderer_type(world, BLACK)
    else
        # TODO throw error
    end
    println(io, " done!")
    image_tracer = load_tracer(image_resolution, camera_type, camera_position, camera_orientation, screen_distance, disable_output=disable_output)
    rendering!(image_tracer, renderer, use_threads=use_threads, disable_output=disable_output)
    print(io, "Saving pfm image...")
    input_file = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    save(input_file, permutedims(image_tracer.image.pixel_matrix))
    println(io, " done!")
    tonemapping(input_file, output_file, alpha, gamma, disable_output=disable_output)
end
