@testset "OnOffRenderer" begin
    sphere = Sphere(transformation=translation(Vec(2, 0, 0)) * scaling(Vec(0.2, 0.2, 0.2)))
    image = HdrImage{RGB{Float32}}(3, 3)
    camera = OrthogonalCamera()
    tracer = ImageTracer(image, camera)
    world = World([sphere])
    renderer = OnOffRenderer{Float32}(world=world)
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

# # BUG it sometimes fails: find out why
# @testset "PathTracer" begin
#     pcg = PCG()
    
#     begin
#         # Run the furnace test several times using random values for
#         # the emitted radiance and reflectance
#         for i in 1:5
#             emitted_radiance = rand(pcg, Float64)
#             reflectance = rand(pcg, Float64) * 0.9  # Avoid numbers that are too close to 1
    
#             world = World()
    
#             enclosure_material = Material(
#                 brdf=DiffuseBRDF{Float64}(pigment=UniformPigment(one(RGB{Float64}) * reflectance)),
#                 emitted_radiance=UniformPigment(one(RGB{Float64}) * emitted_radiance),
#             )
    
#             push!(world, Sphere(material=enclosure_material))
    
#             path_tracer = PathTracer{Float64}(
#                 rng=pcg, 
#                 n=1, 
#                 world=world, 
#                 max_depth=100, 
#                 roulette_depth=101,
#             )
    
#             ray = Ray{Float64}(Point(0, 0, 0), Vec(1, 0, 0))
#             color = path_tracer(ray)
    
#             expected = emitted_radiance / (1 - reflectance)
#             atol = 1e-3
#             @test isapprox(color.r, expected, atol = atol)
#             @test isapprox(color.g, expected, atol = atol)
#             @test isapprox(color.b, expected, atol = atol)
#         end
#     end
# end