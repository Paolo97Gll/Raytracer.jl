# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for transformations.jl


@testset "Transformation (testset 1)" begin
    sI    = SMatrix{4, 4, Float32}(I(4))
    m     = Diagonal([1f0, 2f0, 3f0, 4f0])
    sm    = SMatrix{4, 4, Float32}(m)
    invm  = inv(m)
    sinvm = SMatrix{4, 4, Float32}(invm)

    @testset "constructor" begin
        def_t = Transformation() 
        @test def_t.m == def_t.invm == sI
        @test isconsistent(def_t)

        t1 = Transformation(m)
        @test t1.m == sm && t1.invm == invm
        @test isconsistent(t1)

        t2 = Transformation(sm)
        @test t2.m == m && t2.invm == invm
        @test isconsistent(t2)

        t3 = Transformation(m, invm)
        @test t3.m == m && t3.invm == invm
        @test isconsistent(t3)

        t4 = Transformation(sm, invm)
        @test t4.m == m && t4.invm == invm 
        @test isconsistent(t4)

        t5 = Transformation(m, sinvm)
        @test t5.m == m && t5.invm == invm
        @test isconsistent(t5)

        t6 = Transformation(sm, sinvm)
        @test t6.m == m && t6.invm == invm
        @test isconsistent(t6)

        @test t1 == t2 == t3 == t4 == t5 == t6
    end

    t1 = translation(1f0, 2f0, 3f0)
    t2 = rotationZ(π/4f0)
    vv = [1f0, 2f0, 3f0]
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

        θ = π/4f0
        rot_mat = Dict(
            :X => @SMatrix(Float32[   1       0      0     0;
                                      0     cos(θ) -sin(θ) 0;
                                      0     sin(θ)  cos(θ) 0;
                                      0       0      0     1]),
            :Y => @SMatrix(Float32[ cos(θ)    0    sin(θ)  0;
                                      0       1      0     0;
                                    -sin(θ)   0    cos(θ)  0;
                                      0       0      0     1]),
            :Z => @SMatrix(Float32[ cos(θ) -sin(θ)   0     0;
                                    sin(θ) cos(θ)    0     0;
                                      0      0       1     0;
                                      0      0       0     1])
        )

        @test rotationX(θ) ≈ Transformation(rot_mat[:X], transpose(rot_mat[:X]))
        @test rotationY(θ) ≈ Transformation(rot_mat[:Y], transpose(rot_mat[:Y]))
        @test rotationZ(θ) ≈ Transformation(rot_mat[:Z], transpose(rot_mat[:Z]))

        id = Diagonal(ones(eltype(v), 4)) |> MMatrix{4, 4, Float32}
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
        m1 = Transformation([1f0 2f0 3f0 4f0;
                             5f0 6f0 7f0 8f0;
                             9f0 9f0 8f0 7f0;
                             6f0 5f0 4f0 1f0],
                            [ -3.75f0   2.75f0 -1f0    0f0;
                              4.375f0 -3.875f0  2f0 -0.5f0;
                                0.5f0    0.5f0 -1f0    1f0;
                             -1.375f0  0.875f0  0f0 -0.5f0])
        @test isconsistent(m1)

        m2 = Transformation(m1.m, m1.invm)
        @test m1 ≈ m2

        @test !isconsistent(Transformation([1f0 2f0 3f0 4f0;
                                            5f0 6f0 8f0 8f0;
                                            9f0 9f0 8f0 7f0;
                                            6f0 5f0 4f0 1f0],
                                           [1f0 2f0 3f0 4f0;
                                            5f0 6f0 8f0 8f0;
                                            9f0 9f0 8f0 7f0;
                                            6f0 5f0 4f0 1f0]))

        m3 = Transformation([1f0 2f0 3f0 4f0;
                             5f0 6f0 8f0 8f0;
                             9f0 9f0 8f0 7f0;
                             6f0 5f0 4f0 1f0])
        @test !(m1 ≈ m3)
    end

    @testset "multiplication" begin
        m1 = Transformation([1f0 2f0 3f0 4f0;
                             5f0 6f0 7f0 8f0;
                             9f0 9f0 8f0 7f0;
                             6f0 5f0 4f0 1f0],
                            [ -3.75f0   2.75f0 -1f0    0f0;
                              4.375f0 -3.875f0  2f0 -0.5f0;
                                0.5f0    0.5f0 -1f0    1f0;
                             -1.375f0  0.875f0  0f0 -0.5f0])
        @test isconsistent(m1)

        m2 = Transformation([3f0 5f0 2f0 4f0;
                             4f0 1f0 0f0 5f0;
                             6f0 3f0 2f0 0f0;
                             1f0 4f0 2f0 1f0],
                            [  0.4f0 -0.2f0  0.2f0 -0.6f0;
                               2.9f0 -1.7f0  0.2f0 -3.1f0;
                             -5.55f0 3.15f0 -0.4f0 6.45f0;
                              -0.9f0  0.7f0 -0.2f0  1.1f0])
        @test isconsistent(m2)

        expected = Transformation([ 33f0  32f0 16f0 18f0;
                                    89f0  84f0 40f0 58f0;
                                   118f0 106f0 48f0 88f0;
                                    63f0  51f0 22f0 50f0],
                                  [ -1.45f0    1.45f0  -1.0f0  0.6f0;
                                   -13.95f0   11.95f0  -6.5f0  2.6f0;
                                   25.525f0 -22.025f0 12.25f0 -5.2f0;
                                    4.825f0  -4.325f0   2.5f0 -1.1f0])
        @test isconsistent(expected)

        @test expected ≈ (m1 * m2)
    end

    @testset "vec and point multiplication" begin
        m = Transformation([1f0 2f0 3f0 4f0;
                            5f0 6f0 7f0 8f0;
                            9f0 9f0 8f0 7f0;
                            0f0 0f0 0f0 1f0],
                           [-3.75f0  2.75f0 -1f0  0f0;
                             5.75f0 -4.75f0  2f0  1f0;
                            -2.25f0  2.25f0 -1f0 -2f0;
                                0f0     0f0  0f0  1f0])
        @test isconsistent(m)

        expected_v = Vec(14f0, 38f0, 51f0)
        @test expected_v ≈ (m * Vec(1f0, 2f0, 3f0))

        expected_p = Point(18f0, 46f0, 58f0)
        @test expected_p ≈ (m * Point(1f0, 2f0, 3f0))

        expected_n = Normal(-8.75f0, 7.75f0, -3.0f0)
        @test expected_n ≈ (m * Normal(3.0f0, 2.0f0, 4.0f0))
    end

    @testset "inv" begin
        m1 = Transformation([1f0 2f0 3f0 4f0;
                             5f0 6f0 7f0 8f0;
                             9f0 9f0 8f0 7f0;
                             6f0 5f0 4f0 1f0],
                            [ -3.75f0   2.75f0 -1f0    0f0;
                              4.375f0 -3.875f0  2f0 -0.5f0;
                                0.5f0    0.5f0 -1f0    1f0;
                             -1.375f0  0.875f0  0f0 -0.5f0])

        m2 = inv(m1)
        @test isconsistent(m1)

        prod = m1 * m2
        @test isconsistent(prod)
        @test prod ≈ Transformation()
    end

    @testset "translations" begin
        tr1 = translation(Vec(1f0, 2f0, 3f0))
        @test isconsistent(tr1)

        tr1_2 = translation(Vec(1f0, 2f0, 3f0)...)
        @test isconsistent(tr1_2)
        @test tr1 ≈ tr1_2

        tr2 = translation(Vec(4f0, 6f0, 8f0))
        @test isconsistent(tr1)

        prod = tr1 * tr2
        @test isconsistent(prod)

        expected = translation(Vec(5f0, 8f0, 11f0))
        @test prod ≈ expected
    end

    @testset "rotations" begin
        @test isconsistent(rotationX(0.1f0))
        @test isconsistent(rotationY(0.1f0))
        @test isconsistent(rotationZ(0.1f0))

        @test (rotationZ(π/2) * VEC_X) ≈ VEC_Y
        @test (rotationX(π/2) * VEC_Y) ≈ VEC_Z
        @test (rotationY(π/2) * VEC_Z) ≈ VEC_X
    end

    @testset "scalings" begin
        tr1 = scaling(Vec(2f0, 5f0, 10f0))
        @test isconsistent(tr1)

        tr2 = scaling(Vec(3f0, 2f0, 4f0))
        @test isconsistent(tr2)

        expected = scaling(Vec(6f0, 10f0, 40f0))
        @test expected ≈ (tr1 * tr2)
    end
end
