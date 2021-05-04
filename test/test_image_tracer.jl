image = HdrImage(4, 2)
camera = PerspectiveCamera(aspect_ratio=2)
tracer = ImageTracer(image, camera)

ray1 = fire_ray(tracer, 0, 0, u_pixel=2.5, v_pixel=1.5)
ray2 = fire_ray(tracer, 2, 1, u_pixel=0.5, v_pixel=0.5)

@test ray1 ≈ ray2

fire_all_rays(tracer, ray -> RGB(1.0, 2.0, 3.0))
rangerow, rangecol = axes(tracer.image)
for row ∈ rangerow, col ∈ rangecol
    @test image[row, col] == RGB(1.0, 2.0, 3.0)
end