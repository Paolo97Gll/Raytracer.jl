#!/usr/bin/env julia
using Pkg
Pkg.activate("..")

using Raytracer
using FileIO

curdir = pwd()
demodir = "demo_imgs"
isdir(joinpath(curdir,demodir)) || mkdir(demodir)
cd(demodir)
Threads.@threads for θ ∈ 0:5:359
    num = lpad(repr(θ), 3, '0')
    filename = "frame_deg_$(lpad(repr(θ), 3, '0'))"
    demo(filename * ".jpg",
         (512,512),
         "perspective",
         (-1,0,0),
         (0,0, θ),
         1,
         1,
         1)
    rm(filename * ".pfm")
end
cd(curdir)

`ffmpeg `