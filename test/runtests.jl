using Raytracer
using Test, Documenter
import Raytracer: _clamp, luminosity, average_luminosity, _γ_correction

DocMeta.setdocmeta!(Raytracer, :DocTestSetup, :(using Raytracer); recursive=true)

@testset "Color" begin
    include("test_color.jl")
end

@testset "HDR Image" begin
    include("test_hdr_image.jl")
end

@testset "doctest" begin
    doctest(Raytracer, manual = false)
end