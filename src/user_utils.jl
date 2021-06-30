# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# High-level utilities


#####################################################################


"""
    tonemapping(; input_file::String,
                  output_file::String,
                  α::Float32,
                  γ::Float32,
                  luminosity::Union{Float32, Nothing} = nothing,
                  disable_output::Bool = false)

Load a pfm hdr image, apply the tone mapping, and save the generated ldr image.

`input_file` is the path to a valid PFM image. `output_file` is the path in which save the generated image + the name
of the output file. The output format is deduced by the extension of the output file: if the name is `example.jpg`,
the image will be exported in JPEG format. `α` is the normalization coefficient. `γ` is the actor of the γ correction.
Optional parameter `luminosity` can be used for better tuning.

If `disable_output` is `true`, no message is printed.
"""
function tonemapping(; input_file::String,
                       output_file::String,
                       α::Float32 = 0.5f0,
                       γ::Float32 = 1f0,
                       luminosity::Union{Float32, Nothing} = nothing,
                       disable_output::Bool = false)
    @assert typeof(query(input_file))<:File{format"PFM"}
    io = disable_output ? devnull : stdout
    println(io, "\n-> TONE MAPPING PROCESS")
    print(io, "Loading input file '$(input_file)'...")
    image = load(input_file) |> HdrImage
    print(io, " done!\nApplying tone mapping... ")
    image = (isnothing(luminosity) ? normalize(image, α) : normalize(image, α, luminosity=luminosity)) |> clamp
    image = γ_correction(image, γ)
    print(io, " done!\nSaving final image to '$(output_file)'...")
    save(output_file, image.pixel_matrix)
    println(io, " done!")
end

"""
    function tonemapping(input_file::String,
                         output_file::String,
                         ; α::Float32 = 0.5f0,
                           γ::Float32 = 1f0,
                           luminosity::Union{Float32, Nothing} = nothing,
                           disable_output::Bool = false)
"""
function tonemapping(input_file::String,
                     output_file::String,
                     ; α::Float32 = 0.5f0,
                       γ::Float32 = 1f0,
                       luminosity::Union{Float32, Nothing} = nothing,
                       disable_output::Bool = false)
    tonemapping(input_file=input_file, output_file=output_file, α=α, γ=γ, luminosity=luminosity, disable_output=disable_output)
end


#####################################################################


"""
    render(; image_tracer::ImageTracer,
             renderer::Renderer,
             output_file::String
             use_threads::Bool = true,
             disable_output::Bool = false)

Render an image given an [`ImageTracer`](@ref) and a [`Renderer`](@ref), and save the generated hdr image in `output_file`.

If `use_threads` is `true`, use macro `Threads.@threads`. If `disable_output` is `true`, no message is printed.
"""
function render(; image_tracer::ImageTracer,
                  renderer::Renderer,
                  output_file::String = "out.pfm",
                  use_threads::Bool = true,
                  disable_output::Bool = false)
    @assert typeof(query(output_file))<:File{format"PFM"}
    io = disable_output ? devnull : stdout
    println(io, "\n-> RENDERING")
    println(io, "Rendering image...")
    fire_all_rays!(image_tracer, renderer, use_threads=use_threads, enable_progress_bar=!disable_output)
    print(io, "Saving pfm image...")
    save(output_file, permutedims(image_tracer.image.pixel_matrix))
    println(io, " done!")
end


"""
    function render_scene_from_script(input_script::String,
                                      ; output_file::String = "out.jpg",
                                        α::Float32 = 0.75f0,
                                        γ::Float32 = 1f0,
                                        luminosity::Union{Float32, Nothing} = nothing,
                                        use_threads::Bool = true,
                                        disable_output::Bool = false)

Render and image given a SceneLang script, and save the output in `output_file`.
"""
function render_scene_from_script(input_script::String,
                                  ; output_file::String = "out.jpg",
                                    α::Float32 = 0.75f0,
                                    γ::Float32 = 1f0,
                                    luminosity::Union{Float32, Nothing} = nothing,
                                    use_threads::Bool = true,
                                    disable_output::Bool = false)
    # parse scene
    scene = Scene()
    scene = open_stream(input_script) do stream
        try
            parse_scene(stream, scene)
        catch e
            isa(e, InterpreterException) || rethrow(e)
            print_subsequent_lexer_exceptions(stream, e) |> rethrow
        end
    end
    needs_lights = !isnothing(scene.renderer) && scene.renderer.type ∈ (PointLightRenderer,)
    let are_not_defined = (isempty(scene.world)                  => "No shapes have been spawned.",
                           needs_lights && isempty(scene.lights) => "No lights have been spawned",
                           isnothing(scene.camera)               => "No camera is being used.",
                           isnothing(scene.image)                => "No image is being used",
                           isnothing(scene.renderer)             => "No renderer is being used",
                           isnothing(scene.tracer)               => "No tracer is being used")
        if any(first.(are_not_defined))
            throw(UndefinedSetting(SourceLocation(input_script = input_script), """
            One or more necessary settings have not bene set by a USING or SPAWN command in the given SceneLang script.
            in particular:\n\t$(join(last.(filter(first, are_not_defined)), "\n\t"))
            """))
        end
    end

    # extract render informations
    renderer = if needs_lights
        scene.renderer.type(scene.world, scene.lights; scene.renderer.kwargs...)
    else
        scene.renderer.type(scene.world; scene.renderer.kwargs...)
    end
    image_tracer = ImageTracer(scene.image, scene.camera; scene.tracer.kwargs...)

    # render and apply tonemapping
    output_file_hdr = join([split(output_file, ".")[begin:end-1]..., "pfm"], ".")
    output_file_ldr = output_file
    render(image_tracer=image_tracer, renderer=renderer, output_file=output_file_hdr, use_threads=use_threads, disable_output=disable_output)
    tonemapping(input_file=output_file_hdr, output_file=output_file_ldr, α=α, γ=γ, luminosity=luminosity, disable_output=disable_output)
end
