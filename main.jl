#!/usr/bin/env julia

using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer

function main()
    image = open("test/memorial.pfm") do io
        read(io, FE("pfm"))
    end
    image = normalize_image(image, 0.5)
    image = clamp_image(image)
    save("prova.png", image)
    # open("prova_w.png", "w") do io
    #     write(io, FE("PNG"), image)
    # end
end

main()
