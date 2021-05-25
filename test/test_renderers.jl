@testset "OnOffRenderer" begin
    sphere = Sphere(transformation=translation(Vec(2, 0, 0)) * scaling(Vec(0.2, 0.2, 0.2)))
    image = HdrImage{RGB{Float32}}(3, 3)
    camera = OrthogonalCamera()
    tracer = ImageTracer(image, camera)
    world = World([sphere])
    renderer = OnOffRenderer{Float32}(world=world)
    fire_all_rays!(tracer, renderer)
    
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
    sphere_color = RGB(1.0, 2.0, 3.0)
    sphere = Sphere(transformation=translation(Vec(2, 0, 0)) * scaling(Vec(0.2, 0.2, 0.2)),
                    material=Material(brdf=DiffuseBRDF{Float32}(pigment=UniformPigment(sphere_color))))
    image = HdrImage{RGB{Float32}}(3, 3)
    camera = OrthogonalCamera()
    tracer = ImageTracer(image, camera)
    world = World([sphere])
    renderer = FlatRenderer{Float32}(world=world)
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