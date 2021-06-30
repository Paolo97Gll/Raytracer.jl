# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Flat renderer example script for comparison between other renderers

SET
    # Shapes
    sp1_position TRANSLATE(0.5, 0.7, 0.1)
    sp1_color <0.2, 0.7, 0.8>
    sp1_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(sp1_color)))
    sp2_position TRANSLATE(-0.2, -0.8, -0.8) * SCALE 0.5
    sp2_color <0.6, 0.2, 0.3>
    sp2_material Material(.brdf Brdf.Specular(Pigment.Uniform(sp2_color)))

    # Ground
    ground_position TRANSLATE(.Z -1)
    ground_pigment Pigment.Checkered(.N 6, .color_on <0.3, 0.5, 0.1>, .color_off <0.1, 0.2, 0.5>)
    ground_material Material(.brdf Brdf.Diffuse(ground_pigment))

    # Sky
    sky_position SCALE 100
    sky_color <0, 0, 0>
    sky_emitted <1, 1, 1>
    sky_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(sky_color)),
                          .emitted_radiance Pigment.Uniform(sky_emitted))

SPAWN
    # Spheres
    Shape.Sphere(.transformation sp1_position, .material sp1_material)
    Shape.Sphere(.transformation sp2_position, .material sp2_material)
    # Ground
    Shape.Plane(.transformation ground_position, .material ground_material)
    # Sky
    Shape.Sphere(.transformation sky_position, .material sky_material)

USING
    Camera.Perspective(.transformation TRANSLATE(.X -3), .screen_distance 2)
    Renderer.Flat()
    Image(500, 500)
    Tracer(.samples_per_side 4)
