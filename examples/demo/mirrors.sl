# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Path tracer renderer example script

SET
    # Shapes
    sp1_position TRANSLATE(0, 0, -0.8)
    sp1_material Material(.brdf Brdf.Specular(Pigment.Uniform(<0.2, 0.7, 0.8>)))
    sp2_position TRANSLATE(-4, 0, -0.5) * SCALE 0.8
    sp2_material Material(.brdf Brdf.Specular(Pigment.Uniform(<0.6, 0.2, 0.3>)))
    sp3_position TRANSLATE(0, 4, 0)
    sp3_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.2, 0.7, 0.8>)))
    sp4_position TRANSLATE(0, -5, 0.5) * SCALE 1.5
    sp4_material Material(.brdf Brdf.Specular(Pigment.Uniform(<0.6, 0.75, 0.2>)))
    sp5_position TRANSLATE(4, 0, 2) * SCALE 0.6
    sp5_material Material(.brdf Brdf.Specular(Pigment.Uniform(<0.4, 0.6, 0.4>)))

    # Ground
    ground_position TRANSLATE(.Z -1)
    ground_pigment Pigment.Checkered(.N 6, .color_on <0.3, 0.5, 0.1>, .color_off <0.1, 0.2, 0.5>)
    ground_material Material(.brdf Brdf.Diffuse(ground_pigment))

    # Sky
    sky_position SCALE 20
    sky_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0, 0, 0>)),
                          .emitted_radiance Pigment.Uniform(<1, 1, 1>))

SPAWN
    # Spheres
    Shape.Sphere(.transformation sp1_position, .material sp1_material)
    Shape.Sphere(.transformation sp2_position, .material sp2_material)
    Shape.Sphere(.transformation sp3_position, .material sp3_material)
    Shape.Sphere(.transformation sp4_position, .material sp4_material)
    Shape.Sphere(.transformation sp5_position, .material sp5_material)
    # Ground
    Shape.Plane(.transformation ground_position, .material ground_material)
    # Sky
    Shape.Sphere(.transformation sky_position, .material sky_material)

USING
    Camera.Perspective(.aspect_ratio 1.5, .transformation TRANSLATE(.X -3), .screen_distance 1.3)
    Renderer.PathTracer()
    Image(600, 400)
    Tracer()
