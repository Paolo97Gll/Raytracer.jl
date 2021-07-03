# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Animation example script

SET
    # Shapes
    cyl_position TRANSLATE(0.5, 0.7, 0.1) * SCALE 1.5
    cyl_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.2, 0.7, 0.8>)))
    sp_position TRANSLATE(-0.2, -0.8, -0.8) * SCALE 0.5
    sp_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.6, 0.2, 0.3>)))

    # Ground
    ground_position TRANSLATE(.Z -1)
    ground_pigment Pigment.Checkered(.N 6, .color_on <0.3, 0.5, 0.1>, .color_off <0.1, 0.2, 0.5>)
    ground_material Material(.brdf Brdf.Diffuse(ground_pigment))

    # Sky
    sky_position SCALE 100
    sky_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(.color <0.01, 0.01, 0.01>)))

    # Light
    light_position {1, 5, 10}
    light_color <1, 1, 1>

SPAWN
    # Spheres
    Shape.Cylinder(.transformation cyl_position, .material cyl_material)
    Shape.Sphere(.transformation sp_position, .material sp_material)
    # Ground
    Shape.Plane(.transformation ground_position, .material ground_material)
    # Sky
    Shape.Sphere(.transformation sky_position, .material sky_material)
    # Light
    Light(.position light_position, .color light_color)

USING
    # Note the usage of TIME
    Camera.Perspective(.transformation ROTATE(.Z TIME) * TRANSLATE(.X -3), .screen_distance 2)
    Renderer.PointLight()
    Image(500, 500)
    Tracer()
