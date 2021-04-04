#!/usr/bin/env julia

using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer
using ImageIO

function main()
    image = load("test/memorial.pfm") |> HdrImage
    image = normalize_image(image, 0.5) |> clamp_image
    save("test/savetest.png", image)
end

main()
