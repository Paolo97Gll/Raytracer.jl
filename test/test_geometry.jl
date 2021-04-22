# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_geometry.jl
# description:
#   Unit test for geometry.jl


s = 3

vv1 = [1., 2., 3.]
vv2 = [1.5, 3., 4.5]
vv3 = [10., 20., 30.]

sv1 = SVector{size(vv1)...}(vv1)
sv2 = SVector{size(vv2)...}(vv2)
sv3 = SVector{size(vv3)...}(vv3)

@testset "Vec" begin
    v1, v2, v3 = (sv1, vv2, vv3) .|> Vec

    @testset "constructor" begin
        @test v1 == sv1
        @test v2 == sv2
        @test Vec(vv1...) == sv1
    end

    @testset "operations" begin
        @test norm(v1) == norm(sv1)
        @test normalize(v1) == Vec(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 == sv1 ⋅ sv2

        @test v1 + v2 == Vec(sv1 + sv2)
        @test v1 - v2 == Vec(sv1 - sv2)
        @test v1 × v2 == Vec(sv1 × sv2)

        @test s * v1 == v1 * s == Vec(s * sv1)

        @test Vec([15, 30, 45]) ≈ v2 * 10
    end
end

@testset "Normal" begin
    v1, v2, v3 = (sv1, vv2, vv3) .|> Normal 
    
    @testset "constructor" begin
        @test v1 == sv1
        @test v2 == sv2
        @test Normal(vv1...) == sv1
    end

    @testset "operations" begin
        @test norm(v1) == norm(sv1)
        @test normalize(v1) == Normal(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 == sv1 ⋅ sv2

        @test v1 + v2 == Normal(sv1 + sv2)
        @test v1 - v2 == Normal(sv1 - sv2)
        @test v1 × v2 == Normal(sv1 × sv2)

        @test s * v1 == v1 * s == Normal(s * sv1)

        @test Normal([15, 30, 45]) ≈ v2 * 10
    end
end


@testset "Point" begin
    p1, p2 = (sv1, vv2) .|> Point
    v = Vec(vv3)

    @testset "constructor" begin
        @test p1.v == sv1
        @test p2.v == sv2
        @test_throws ArgumentError Point(ones(4))
    end

    @testset "operations" begin
        @test p1 ≈ Point(vv3 ./ 10)  

        @test p1 - p2 == Vec(sv1 - sv2)

        @test p1 + v == Point(sv1 + sv3)
        @test p1 - v == Point(sv1 - sv3)

        @test Point([15, 30, 45]) ≈ p2 * 10
    end
end

@testset "Transformation" begin
    m     = Diagonal([1,2,3,4]) |> Matrix
    sm    = SMatrix{4,4}(m)
    invm  = inv(m)
    sinvm = SMatrix{4,4}(invm)

    @testset "constructor" begin
        T = Float64
        def_t = Transformation{T}() 
        @test def_t.m == def_t.invm == Diagonal(ones(T, 4)) 
        @test eltype(def_t) <: T

        t1 = Transformation(m)
        @test t1.m == m && t1.invm == invm
        @test isconsistent(def_t)

        t1 = Transformation(sm)
        @test t1.m == m && t1.invm == invm
        @test typeof(t1.m) <: SMatrix{4, 4} && typeof(t1.invm) <: SMatrix{4, 4} 
        @test isconsistent(t1)

        t2 = Transformation(m, invm)
        @test t1.m == m && t1.invm == invm
        @test isconsistent(t2)

        t2 = Transformation(sm, invm)
        @test t1.m == m && t1.invm == invm
        @test typeof(t1.m) <: SMatrix{4, 4} 
        @test isconsistent(t2)

        t2 = Transformation(m, sinvm)
        @test t1.m == m && t1.invm == invm
        @test typeof(t1.invm) <: SMatrix{4, 4} 
        @test isconsistent(t2)

        t2 = Transformation(sm, sinvm)
        @test t1.m == m && t1.invm == invm
        @test typeof(t1.m) <: SMatrix{4, 4} && typeof(t1.invm) <: SMatrix{4, 4} 
        @test isconsistent(t2)
    end

    t1 = translation(1, 2, 3)
    t2 = rotationZ(π/4)
    vv = [1., 2., 3.]
    v = Vec(vv...)
    n = Normal(vv...)
    p = Point(vv...)

    @testset "operations" begin
        prod = t1 * t2

        @test isconsistent(prod) 
        
        @test prod.m    == t1.m * t2.m
        @test prod.invm == t2.invm * t1.invm

        @test prod * v == prod.m[1:3,1:3] * v
        @test prod * n == transpose(prod.invm[1:3,1:3]) * v
        @test prod * p == prod.m * [v..., 1.]
    end

    @testset "methods" begin
        t = t1 * t2 
        invt = inverse(t)
        @test t.m == invt.invm && t.invm == invt.m

        θ = π/4
        rot_mat = Dict(
            :X => @SMatrix([   1       0      0    0;
                               0     cos(θ) sin(θ) 0;
                               0    -sin(θ) cos(θ) 0;
                               0       0      0    1]),
            :Y => @SMatrix([ cos(θ)    0   -sin(θ) 0;
                               0       1      0    0;
                           sin(θ)    0    cos(θ) 0;
                               0       0      0    1]),
            :Z => @SMatrix([ cos(θ) sin(θ)    0    0;
                           -sin(θ) cos(θ)    0    0;
                               0      0       1    0;
                               0      0       0    1])
        )

        @test rotationX(θ) ≈ Transformation(rot_mat[:X], transpose(rot_mat[:X]))
        @test rotationY(θ) ≈ Transformation(rot_mat[:Y], transpose(rot_mat[:Y]))
        @test rotationZ(θ) ≈ Transformation(rot_mat[:Z], transpose(rot_mat[:Z]))

        id = Diagonal(ones(eltype(v), 4)) |> MMatrix{4, 4}
        id⁻¹ = copy(id)
        id[end, 1:3]   =  v
        id⁻¹[end, 1:3] = -v
        @test translation(v)    ≈ Transformation(id, id⁻¹)
        @test translation(v...) ≈ Transformation(id, id⁻¹)

        @test scaling(v) ≈ Transformation(Diagonal([v...,true]), Diagonal(true ./ [v..., true]))
        @test scaling(v...) ≈ Transformation(Diagonal([v...,true]), Diagonal(true ./ [v..., true]))
        @test scaling(5) ≈ Transformation(Diagonal([5,5,5,1]), Diagonal(inv.([5,5,5,1])))
    end
end