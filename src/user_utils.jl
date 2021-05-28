# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   user_utils.jl
# description:
#   High-level utilities

# TODO write docstrings
# TODO implement flag for disable print


function tonemapping(input_file::AbstractString,
                     output_file::AbstractString,
                     alpha::Real,
                     gamma::Real;
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

function load_tracer(image_resolution::Tuple{Integer, Integer}, 
                     camera_type::AbstractString, 
                     camera_position::Tuple{Real, Real, Real}, 
                     camera_orientation::Tuple{Real, Real, Real},
                     screen_distance::Real;
                     disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    print(io, "Loading tracing informations...")
    image = HdrImage{RGB{Float64}}(image_resolution...)
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

function rendering!(image_tracer::ImageTracer, renderer::Renderer; disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "Rendering image...")
    fire_all_rays!(image_tracer, renderer, enable_progress_bar=!disable_output)
end

function demo(output_file::AbstractString,
              image_resolution::Tuple{Integer, Integer},
              camera_type::AbstractString,
              camera_position::Tuple{Real, Real, Real},
              camera_orientation::Tuple{Real, Real, Real},
              screen_distance::Real,
              renderer_type::Type{<:Renderer},
              alpha::Real,
              gamma::Real;
              disable_output::Bool = false)
    io = disable_output ? devnull : stdout
    println(io, "\n---------------------")
    println(io, "| Raytracer.jl demo |")
    println(io, "---------------------")
    println(io, "\n-> RENDERING")
    print(io, "Loading scene...")
    if renderer_type <: OnOffRenderer
        world = World(undef, 10)
        for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
            world[i] = Sphere(transformation = translation(coords * 0.5) * scaling(1/10))
        end
        world[end-1:end] = [Sphere(transformation = translation([0, 0, -0.5]) * scaling(1/10)), Sphere(transformation = translation([0, 0.5, 0]) * scaling(1/10))]
        renderer = renderer_type(world, one(RGB{Float64}), zero(RGB{Float64}))
    elseif renderer_type <: FlatRenderer
        world = World(undef, 11)
        for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
            world[i] = Sphere(transformation = translation(coords * 0.5) * scaling(1/10), 
                              material = Material(brdf = 
                                DiffuseBRDF{Float64}(pigment = 
                                    UniformPigment(RGB(0., 1., 0.))
                                )
                              )
                             )
        end
        world[end-2] = Plane(transformation = translation([0,0,-1]), material = Material(brdf = DiffuseBRDF{Float64}(pigment = CheckeredPigment{4, RGB{Float64}}())))
        world[end-1:end] = [Sphere(transformation = translation([0, 0, -0.5]) * scaling(1/10),
                                   material = Material(brdf = 
                                        DiffuseBRDF{Float64}(pigment = 
                                            CheckeredPigment{4}(color_on  = RGB(1., 0., 0.), 
                                                                color_off = RGB(0., 1., 0.)
                                                               )
                                        )
                                   )
                                  ), 
                            Sphere(transformation = translation([0, 0.5, 0]) * scaling(1/10),
                                   material = Material(brdf = 
                                        DiffuseBRDF{Float64}(pigment = 
                                            ImagePigment(HdrImage([RGB(1., 0., 0.) RGB(0., 1., 0.) RGB(0., 0., 1.) RGB(1., 0., 1.)]))
                                        )
                                   )
                                  )] 
        renderer = renderer_type(world, zero(RGB{Float64}))
    else
        # TODO throw error
    end
    println(io, " done!")
    image_tracer = load_tracer(image_resolution, camera_type, camera_position, camera_orientation, screen_distance, disable_output=disable_output)
    rendering!(image_tracer, renderer, disable_output=disable_output)
    print(io, "Saving pfm image...")
    input_file = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    save(input_file, permutedims(image_tracer.image.pixel_matrix) |> Matrix{RGB{Float32}})
    println(io, " done!")
    tonemapping(input_file, output_file, alpha, gamma, disable_output=disable_output)
end
