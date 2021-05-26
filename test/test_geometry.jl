# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_geometry.jl
# description:
#   Unit tests for geometry.jl


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
        @test -v1 ≈ -sv1

        @test norm(v1) === norm(sv1)
        @test normalize(v1) === Vec(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 === sv1 ⋅ sv2

        @test v1 + v2 === Vec(sv1 + sv2)
        @test v1 - v2 === Vec(sv1 - sv2)
        @test v1 × v2 === Vec(sv1 × sv2)

        @test s * v1 === v1 * s === Vec(s * sv1)

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
        @test norm(v1) === norm(sv1)
        @test normalize(v1) === Normal{eltype(sv1), true}(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 === sv1 ⋅ sv2

        @test v1 + v2 === Normal(sv1 + sv2)
        @test v1 - v2 === Normal(sv1 - sv2)
        @test v1 × v2 === Normal(sv1 × sv2)

        @test s * v1 === v1 * s === Normal(s * sv1)

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


@testset "Transformation (testset 1)" begin
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

        @test prod * v == Vec(prod.m[1:3,1:3] * v)
        @test prod * n == Normal(transpose(prod.invm[1:3,1:3]) * v)
        tmp = prod.m * [p.v..., 1.]
        @test prod * p == Point(@view((tmp/tmp[end])[1:3]))

        @test t1 ≈ t1
    end

    @testset "methods" begin
        t = t1 * t2 
        invt = inv(t)
        @test t.m == invt.invm && t.invm == invt.m

        θ = π/4
        rot_mat = Dict(
            :X => @SMatrix([   1       0      0     0;
                               0     cos(θ) -sin(θ) 0;
                               0     sin(θ)  cos(θ) 0;
                               0       0      0     1]),
            :Y => @SMatrix([ cos(θ)    0    sin(θ) 0;
                               0       1      0    0;
                             -sin(θ)   0    cos(θ) 0;
                               0       0      0    1]),
            :Z => @SMatrix([ cos(θ) -sin(θ)    0    0;
                             sin(θ) cos(θ)     0    0;
                               0      0        1    0;
                               0      0        0    1])
        )

        @test rotationX(θ) ≈ Transformation(rot_mat[:X], transpose(rot_mat[:X]))
        @test rotationY(θ) ≈ Transformation(rot_mat[:Y], transpose(rot_mat[:Y]))
        @test rotationZ(θ) ≈ Transformation(rot_mat[:Z], transpose(rot_mat[:Z]))

        id = Diagonal(ones(eltype(v), 4)) |> MMatrix{4, 4}
        id⁻¹ = copy(id)
        id[1:3, end]   =  v
        id⁻¹[1:3, end] = -v
        @test translation(v)    ≈ Transformation(id, id⁻¹)
        @test translation(v...) ≈ Transformation(id, id⁻¹)

        @test scaling(v) ≈ Transformation(Diagonal([v...,true]), Diagonal(true ./ [v..., true]))
        @test scaling(v...) ≈ Transformation(Diagonal([v...,true]), Diagonal(true ./ [v..., true]))
        @test scaling(5) ≈ Transformation(Diagonal([5,5,5,1]), Diagonal(inv.([5,5,5,1])))
    end
end


@testset "Transformation (testset 2)" begin
    @testset "constructor" begin
        m1 = Transformation([1.0 2.0 3.0 4.0;
                             5.0 6.0 7.0 8.0;
                             9.0 9.0 8.0 7.0;
                             6.0 5.0 4.0 1.0],
                            [-3.75 2.75 -1 0;
                             4.375 -3.875 2.0 -0.5;
                             0.5 0.5 -1.0 1.0;
                             -1.375 0.875 0.0 -0.5])
        @test isconsistent(m1)

        m2 = Transformation(m1.m, m1.invm)
        @test m1 ≈ m2

        @test_throws AssertionError Transformation([1.0 2.0 3.0 4.0;
                                                    5.0 6.0 8.0 8.0;
                                                    9.0 9.0 8.0 7.0;
                                                    6.0 5.0 4.0 1.0],
                                                   [-3.75 2.75 -1 0;
                                                    4.375 -3.875 2.0 -0.5;
                                                    0.5 0.5 -1.0 1.0;
                                                    -1.375 0.875 0.0 -0.5])

        m3 = Transformation([1.0 2.0 3.0 4.0;
                             5.0 6.0 8.0 8.0;
                             9.0 9.0 8.0 7.0;
                             6.0 5.0 4.0 1.0])
        @test !(m1 ≈ m3)
    end

    @testset "multiplication" begin
        m1 = Transformation([1.0 2.0 3.0 4.0;
                             5.0 6.0 7.0 8.0;
                             9.0 9.0 8.0 7.0;
                             6.0 5.0 4.0 1.0],
                            [-3.75 2.75 -1 0;
                             4.375 -3.875 2.0 -0.5;
                             0.5 0.5 -1.0 1.0;
                             -1.375 0.875 0.0 -0.5])
        @test isconsistent(m1)

        m2 = Transformation([3.0 5.0 2.0 4.0;
                             4.0 1.0 0.0 5.0;
                             6.0 3.0 2.0 0.0;
                             1.0 4.0 2.0 1.0],
                            [0.4 -0.2 0.2 -0.6;
                             2.9 -1.7 0.2 -3.1;
                             -5.55 3.15 -0.4 6.45;
                             -0.9 0.7 -0.2 1.1])
        @test isconsistent(m2)

        expected = Transformation([33.0 32.0 16.0 18.0;
                                   89.0 84.0 40.0 58.0;
                                   118.0 106.0 48.0 88.0;
                                   63.0 51.0 22.0 50.0],
                                  [-1.45 1.45 -1.0 0.6;
                                   -13.95 11.95 -6.5 2.6;
                                   25.525 -22.025 12.25 -5.2;
                                   4.825 -4.325 2.5 -1.1])
        @test isconsistent(expected)

        @test expected ≈ (m1 * m2)
    end

    @testset "vec and point multiplication" begin
        m = Transformation([1.0 2.0 3.0 4.0;
                            5.0 6.0 7.0 8.0;
                            9.0 9.0 8.0 7.0;
                            0.0 0.0 0.0 1.0],
                           [-3.75 2.75 -1 0;
                            5.75 -4.75 2.0 1.0;
                            -2.25 2.25 -1.0 -2.0;
                            0.0 0.0 0.0 1.0])
        @test isconsistent(m)

        expected_v = Vec(14.0, 38.0, 51.0)
        @test expected_v ≈ (m * Vec(1.0, 2.0, 3.0))

        expected_p = Point(18.0, 46.0, 58.0)
        @test expected_p ≈ (m * Point(1.0, 2.0, 3.0))

        expected_n = Normal(-8.75, 7.75, -3.0)
        @test expected_n ≈ (m * Normal(3.0, 2.0, 4.0))
    end

    @testset "inv" begin
        m1 = Transformation([1.0 2.0 3.0 4.0;
                             5.0 6.0 7.0 8.0;
                             9.0 9.0 8.0 7.0;
                             6.0 5.0 4.0 1.0],
                            [-3.75 2.75 -1 0;
                             4.375 -3.875 2.0 -0.5;
                             0.5 0.5 -1.0 1.0;
                             -1.375 0.875 0.0 -0.5])

        m2 = inv(m1)
        @test isconsistent(m1)

        prod = m1 * m2
        @test isconsistent(prod)
        @test prod ≈ Transformation{Float64}()
    end

    @testset "translations" begin
        tr1 = translation(Vec(1.0, 2.0, 3.0))
        @test isconsistent(tr1)

        tr1_2 = translation(Vec(1.0, 2.0, 3.0)...)
        @test isconsistent(tr1_2)
        @test tr1 ≈ tr1_2

        tr2 = translation(Vec(4.0, 6.0, 8.0))
        @test isconsistent(tr1)

        prod = tr1 * tr2
        @test isconsistent(prod)

        expected = translation(Vec(5.0, 8.0, 11.0))
        @test prod ≈ expected
    end

    @testset "rotations" begin
        @test isconsistent(rotationX(0.1))
        @test isconsistent(rotationY(0.1))
        @test isconsistent(rotationZ(0.1))

        @test (rotationX(π/2) * VEC_Y) ≈ VEC_Z
        @test (rotationY(π/2) * VEC_Z) ≈ VEC_X
        @test (rotationZ(π/2) * VEC_X) ≈ VEC_Y
    end

    @testset "scalings" begin
        tr1 = scaling(Vec(2.0, 5.0, 10.0))
        @test isconsistent(tr1)

        tr2 = scaling(Vec(3.0, 2.0, 4.0))
        @test isconsistent(tr2)

        expected = scaling(Vec(6.0, 10.0, 40.0))
        @test expected ≈ (tr1 * tr2)
    end
end

@testset "ONB" begin
    pcg = PCG()

    @test begin 
        for _ ∈ 1:1_000_000
            normal = rand(pcg, Float32, 3) |> Normal
            normalize(normal)
            e1, e2, e3 = create_onb_from_z(normal)

            # Verify that the z axis is aligned with the normal
            @assert e3 ≈ normal

            # Verify that the base is orthogonal
            @assert e1 ⋅ e2 ≈ 0
            @assert e2 ⋅ e3 ≈ 0
            @assert e3 ⋅ e1 ≈ 0

            # Verify that each component is normalized
            @assert norm²(e1) ≈ 1
            @assert norm²(e2) ≈ 1
            @assert norm²(e3) ≈ 1
        end
    end
end