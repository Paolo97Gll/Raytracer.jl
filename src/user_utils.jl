# TODO docstring
# TODO implement tonemapping(input_file, alpha, ...) and recall this function when using tonemapping(options)
function tonemapping(options)
    println("\n-> TONE MAPPING PROCESS")
    print("Loading input file '$(options["input_file"])'...")
    image = load(options["input_file"]) |> HdrImage
    print(" done!\nApplying tone mapping... ")
    image = normalize_image(image, options["alpha"]) |> clamp_image
    image = γ_correction(image, options["gamma"])
    print(" done!\nSaving final image to '$(options["output_file"])'...")
    save(options["output_file"], image.pixel_matrix)
    println(" done!")
end


# TODO docstring
# TODO implement demo(image_resolution, camera_position, ...) and recall this function when using demo(options)
function demo(options)
    println("---------------------")
    println("| Raytracer.jl demo |")
    println("---------------------")
    println("\n-> RENDERING")
    print("Loading ambient...")
    world = World(undef, 10)
    for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
        world[i] = Sphere(translation(coords * 0.5) * scaling(1/10))
    end
    world[end-1:end] = [Sphere(translation([0, 0, -0.5]) * scaling(1/10)), Sphere(translation([0, 0.5, 0]) * scaling(1/10))]
    println(" done!")
    print("Loading tracing informations...")
    img_size = parse.(Int64, split(options["image_resolution"], ":"))
    img = HdrImage{RGB{Float64}}(img_size...)
    camera_position = "["*options["camera_position"]*"]" |> Meta.parse |> eval
    # camera_orientation = "["*options["camera_orientation"]*"]" |> Meta.parse |> eval
    angx, angy, angz = deg2rad.(parse.(Float64, split(options["camera_orientation"], ",")))
    rot = rotationX(angx)*rotationY(angy)*rotationZ(angz)
    if options["camera_type"] == "perspective"
        camera = PerspectiveCamera(//(img_size...), translation(camera_position)*rot, options["screen_distance"])
    else
        camera = OrthogonalCamera(//(img_size...), translation(camera_position)*rot)
    end
    image_tracer = ImageTracer(img, camera)
    println(" done!")
    println("Starting image generation.")
    fire_all_rays(image_tracer, ray -> any(shape -> ray_intersection(ray, shape) !== nothing, world) ? RGB(1.,1.,1.) : RGB(0.,0.,0.))
    print("Saving pfm image...")
    options["input_file"] = join([split(options["output_file"], ".")[begin:end-1]..., "pfm"], ".")
    save(options["input_file"], permutedims(img.pixel_matrix))
    println(" done!")
    tonemapping(options)
end