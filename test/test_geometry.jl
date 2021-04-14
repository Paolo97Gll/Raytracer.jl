# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_geometry.jl
# description:
#   Unit test for geometry.jl

s = 3 
vv = [1.5, 3., 4.5]

sv1 = @SVector [1., 2., 3.]
sv2 = SVector{size(vv)...}(vv)

v1, v2 = (sv1, vv) .|> Vec

@test v1.v == sv1
@test v2.v == sv2
@test norm(v1) == norm(sv1)
@test normalize(v1).v == normalize(sv1)
@test norm²(v1) ≈ norm(sv1) ^ 2

@test v1 ⋅ v2 == sv1 ⋅ sv2

for op ∈ (:+, :-, :×)
    quote
        @test $op(v1, v2).v == $op(sv1, sv2)
    end |> eval
end

@test (s * v1).v == s * sv1
@test (v1 * s).v == s * sv1

@test Vec([15, 30, 45]) ≈ v2 * 10