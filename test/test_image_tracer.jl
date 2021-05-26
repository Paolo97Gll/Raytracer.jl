# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_image_tracer.jl
# description:
#   Unit tests for image_tracer.jl


image = HdrImage(4, 2)
camera = PerspectiveCamera(aspect_ratio=2)
tracer = ImageTracer(image, camera)


@testset "uv_sub_mapping" begin
    ray1 = fire_ray(tracer, 1, 1, u_pixel=2.5, v_pixel=1.5)
    ray2 = fire_ray(tracer, 3, 2, u_pixel=0.5, v_pixel=0.5)
    @test ray1 ≈ ray2
end


@testset "image_coverage" begin
    fire_all_rays!(tracer, ray -> RGB(1.0, 2.0, 3.0))
    rangerow, rangecol = axes(tracer.image)
    for row ∈ rangerow, col ∈ rangecol
        @test image[row, col] == RGB(1.0, 2.0, 3.0)
    end
end


@testset "orientation" begin
    # Fire a ray against top-left corner of the screen
    top_left_ray = fire_ray(tracer, 1, 1, u_pixel=0.0, v_pixel=0.0)
    @test Point(0.0, 2.0, 1.0) ≈ top_left_ray(1.0)

    # Fire a ray against bottom-right corner of the screen
    bottom_right_ray = fire_ray(tracer, 4, 2, u_pixel=1.0, v_pixel=1.0)
    @test Point(0.0, -2.0, -1.0) ≈ bottom_right_ray(1.0)
end