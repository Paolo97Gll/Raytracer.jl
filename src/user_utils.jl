# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   user_utils.jl
# description:
#   High-level utilities

# TODO write docstrings


function tonemapping(input_file::AbstractString,
                     output_file::AbstractString,
                     alpha::Real,
                     gamma::Real)
    println("\n-> TONE MAPPING PROCESS")
    print("Loading input file '$(input_file)'...")
    image = load(input_file) |> HdrImage
    print(" done!\nApplying tone mapping... ")
    image = normalize_image(image, alpha) |> clamp_image
    image = γ_correction(image, gamma)
    print(" done!\nSaving final image to '$(output_file)'...")
    save(output_file, image.pixel_matrix)
    println(" done!")
end


function demo(output_file::AbstractString,
              image_resolution::Tuple{Integer, Integer},
              camera_type::AbstractString,
              camera_position::Tuple{Real, Real, Real},
              camera_orientation::Tuple{Real, Real, Real},
              screen_distance::Real,
              alpha::Real,
              gamma::Real)
    println("---------------------")
    println("| Raytracer.jl demo |")
    println("---------------------")
    println("\n-> RENDERING")
    print("Loading ambient...")
    world = World(undef, 10)
    for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
        world[i] = Sphere(transformation = translation(coords * 0.5) * scaling(1/10))
    end
    world[end-1:end] = [Sphere(transformation = translation([0, 0, -0.5]) * scaling(1/10)), Sphere(transformation = translation([0, 0.5, 0]) * scaling(1/10))]
    println(" done!")
    print("Loading tracing informations...")
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
    image_tracer = ImageTracer(image, camera)
    println(" done!")
    println("Starting image rendering.")
    fire_all_rays(image_tracer, ray -> any(shape -> ray_intersection(ray, shape) !== nothing, world) ? RGB(1.,1.,1.) : RGB(0.,0.,0.))
    print("Saving pfm image...")
    input_file = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    save(input_file, permutedims(image_tracer.image.pixel_matrix) |> Matrix{RGB{Float32}})
    println(" done!")
    tonemapping(input_file, output_file, alpha, gamma)
end
