#!/usr/bin/env julia

using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer

function main()
    image = load(ARGS[1]) |> HdrImage
    image = normalize_image(image, parse(Float64, ARGS[3])) |> clamp_image
    image = γ_correction(image, parse(Float64, ARGS[4]))
    save(ARGS[2], image.pixel_matrix)
end

main()
