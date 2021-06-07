# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for shapes.jl


@testset "OnOffRenderer" begin
    sphere = Sphere(transformation=translation(Vec(2f0, 0f0, 0f0)) * scaling(Vec(0.2f0, 0.2f0, 0.2f0)))
    image = HdrImage(3, 3)
    camera = OrthogonalCamera()
    tracer = ImageTracer(image, camera)
    world = World([sphere])
    renderer = OnOffRenderer(world)
    fire_all_rays!(tracer, renderer, enable_progress_bar=false)
    
    @test image[1, 1] |> iszero
    @test image[2, 1] |> iszero
    @test image[3, 1] |> iszero
    
    @test image[1, 2] |> iszero
    @test image[2, 2] |> isone 
    @test image[3, 2] |> iszero
    
    @test image[1, 3] |> iszero
    @test image[2, 3] |> iszero
    @test image[3, 3] |> iszero
end


@testset "FlatRenderer" begin
    sphere_color = RGB(1.0f0, 2.0f0, 3.0f0)
    sphere = Sphere(transformation=translation(Vec(2f0, 0f0, 0f0)) * scaling(Vec(0.2f0, 0.2f0, 0.2f0)),
                    material=Material(brdf=DiffuseBRDF(pigment=UniformPigment(sphere_color))))
    image = HdrImage(3, 3)
    camera = OrthogonalCamera()
    tracer = ImageTracer(image, camera)
    world = World([sphere])
    renderer = FlatRenderer(world)
    fire_all_rays!(tracer, renderer)

    @test image[1, 1] |> iszero 
    @test image[2, 1] |> iszero 
    @test image[3, 1] |> iszero 

    @test image[1, 2] |> iszero 
    @test image[2, 2] ≈ sphere_color
    @test image[3, 2] |> iszero 

    @test image[1, 3] |> iszero 
    @test image[2, 3] |> iszero 
    @test image[3, 3] |> iszero 
end


@testset "PathTracer" begin
    pcg = PCG()
    
    begin
        # Run the furnace test several times using random values for
        # the emitted radiance and reflectance
        for i in 1:5
            emitted_radiance = rand(pcg, Float32)
            reflectance = rand(pcg, Float32) * 0.9f0  # Avoid numbers that are too close to 1
    
            world = World()
    
            enclosure_material = Material(
                brdf=DiffuseBRDF(pigment=UniformPigment(WHITE * reflectance)),
                emitted_radiance=UniformPigment(WHITE * emitted_radiance),
            )
    
            push!(world, Sphere(material=enclosure_material))
    
            path_tracer = PathTracer(
                world,
                rng=pcg,
                n=1,
                max_depth=100,
                roulette_depth=101,
            )
    
            ray = Ray(Point(0f0, 0f0, 0f0), Vec(1f0, 0f0, 0f0))
            color = path_tracer(ray)
    
            expected = emitted_radiance / (1f0 - reflectance)
            atol = 1f-3
            @test isapprox(color.r, expected, atol = atol)
            @test isapprox(color.g, expected, atol = atol)
            @test isapprox(color.b, expected, atol = atol)
        end
    end
end
