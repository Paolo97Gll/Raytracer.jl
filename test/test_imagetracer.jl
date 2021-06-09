# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for imagetracer.jl


image = HdrImage(4, 2)
camera = PerspectiveCamera(aspect_ratio=2f0)
tracer = ImageTracer(image, camera)

struct LambdaRenderer <: Renderer
    f::Function
end

function (lr::LambdaRenderer)(ray::Ray)
    lr.f(ray)
end

@testset "uv_sub_mapping" begin
    ray1 = fire_ray(tracer, 1, 1, u_pixel=2.5f0, v_pixel=1.5f0)
    ray2 = fire_ray(tracer, 3, 2, u_pixel=0.5f0, v_pixel=0.5f0)
    @test ray1 ≈ ray2
end


@testset "image_coverage" begin
    fire_all_rays!(tracer, LambdaRenderer(ray -> RGB(1f0, 2f0, 3f0)))
    rangerow, rangecol = axes(tracer.image)
    for row ∈ rangerow, col ∈ rangecol
        @test image[row, col] == RGB(1f0, 2f0, 3f0)
    end
end


@testset "orientation" begin
    # Fire a ray against top-left corner of the screen
    top_left_ray = fire_ray(tracer, 1, 1, u_pixel=0f0, v_pixel=0f0)
    @test Point(0f0, 2f0, 1f0) ≈ top_left_ray(1f0)

    # Fire a ray against bottom-right corner of the screen
    bottom_right_ray = fire_ray(tracer, 4, 2, u_pixel=1f0, v_pixel=1f0)
    @test Point(0f0, -2f0, -1f0) ≈ bottom_right_ray(1f0)
end
