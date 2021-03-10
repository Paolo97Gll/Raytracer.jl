#!/usr/bin/env julia

using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer

function main()
    hello_world.greet()
end

main()