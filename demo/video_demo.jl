#!/usr/bin/env julia

@warn "DEPRECATED: USE `raytracer_cli.jl demo animation` INSTEAD"
sleep(10)

using Pkg
Pkg.activate("..")

using Raytracer
using FileIO
using ProgressMeter

function generate_image(θ::Number)
    # num = lpad(repr(θ), 3, '0')
    filename = "frame_deg_$(lpad(repr(θ), 3, '0'))"
    demo(filename * ".jpg",
        (512,512),
        "perspective",
        (-1,0,0),
        (0,0, θ),
        1,
        FlatRenderer,
        1,
        1,
        disable_output=true)
    rm(filename * ".pfm")
end

function generate_animation()
    curdir = pwd()
    demodir = "demo_imgs"
    isdir(joinpath(curdir,demodir)) || mkdir(demodir)
    cd(demodir)
    θ_list = 0:10:359
    p = Progress(length(θ_list), dt=1)
    Threads.@threads for θ ∈ θ_list
        generate_image(θ)
        next!(p)
    end
    `ffmpeg -r 6 -pattern_type glob -i 'frame_deg_*.jpg' -c:v libx264 test.mp4` |> run
    cd(curdir)
end

println("-------------------------------")
println("| Raytracer.jl animation demo |")
println("-------------------------------")
return
generate_animation()