#!/usr/bin/env julia
using Pkg
Pkg.activate("..")

using Raytracer
using FileIO

# TODO try with 4 threads and 8 threads

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
        1)
    rm(filename * ".pfm")
end

function generate_animation()
    curdir = pwd()
    demodir = "demo_imgs"
    isdir(joinpath(curdir,demodir)) || mkdir(demodir)
    cd(demodir)
    Threads.@threads for θ ∈ 0:10:359
        generate_image(θ)
    end
    `ffmpeg -r 6 -pattern_type glob -i 'frame_deg_*.jpg' -c:v libx264 test.mp4` |> run
    cd(curdir)
end

generate_animation()