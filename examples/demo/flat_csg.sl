# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Flat renderer example script

SET
    # Shapes

    s1 Shape.Cylinder(
        .transformation SCALE(1, 2.5, 2),
        .material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.2, 1, 0.2>)))
    )
    s2 Shape.Sphere(
        .material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.2, 0.2, 1>)))
    )
    s3 Shape.Cube(
        .transformation ROTATE(.X 45) * SCALE(2,0.75,0.75),
        .material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<1, 0.2, 0.2>)))
    )

    # Ground
    ground_position TRANSLATE(.Z -1)
    ground_pigment Pigment.Checkered(.N 4, .color_on <1, 0, 0>, .color_off <1, 1, 0>)
    ground_material Material(.brdf Brdf.Diffuse(ground_pigment))

    # Sky
    sky_position SCALE 20
    sky_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<1, 1, 1>)))

SPAWN
    # Spheres
    DIFF(INTERSECT(s1,s2),s3)
    # Ground
    Shape.Plane(.transformation ground_position, .material ground_material)
    # Sky
    Shape.Sphere(.transformation sky_position, .material sky_material)

USING
    Camera.Perspective(.transformation ROTATE(.X 5 * .Y 10 * .Z 20 * .Y 10) * TRANSLATE(.X -3, .Z 0.5), .screen_distance 2)
    Renderer.Flat()
    Image(500, 500)
    Tracer(.samples_per_side 4)
