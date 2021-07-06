# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Cornell box

SET
    cage_p SCALE(6, 7, 6)
    cage_m Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.5,0.5,0.3>)))

    light_p TRANSLATE(.Z 3.499) * SCALE(.X 0.5)
    light_m Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0,0,0>)),
                     .emitted_radiance Pigment.Uniform(<5, 5, 5>))

    cube1_p TRANSLATE(.Y 1.1, .Z -1.6) * ROTATE(.Z -45) * SCALE(0.8, 1.7, 3)
    cube2_p TRANSLATE(.Y -1.1, .Z -1.6) * ROTATE(.Z 45) * SCALE(0.8, 1.7, 3)
    cube_m Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.5,0.5,0.3>)))

    p1_p TRANSLATE(.Y -3) * ROTATE(.X 90)
    p1_m Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0.5,0,0>)))
    p2_p TRANSLATE(.Y 3) * ROTATE(.X 90)
    p2_m Material(.brdf Brdf.Diffuse(Pigment.Uniform(<0,0.5,0>)))

SPAWN
    Shape.Cube(.transformation cage_p, .material cage_m)
    Shape.Cube(.transformation light_p, .material light_m)
    Shape.Cube(.transformation cube1_p, .material cube_m)
    Shape.Cube(.transformation cube2_p, .material cube_m)
    Shape.Plane(.transformation p1_p, .material p1_m)
    Shape.Plane(.transformation p2_p, .material p2_m)

    # Light(.color <1,1,1>, .position {0, 0, 2.9}, .linear_radius 0.5)
    # Light(.color <1,1,1>, .position {-1, -1.5, 2.9}, .linear_radius 0.5)
    # Light(.color <1,1,1>, .position {-1, 1.5, 2.9}, .linear_radius 0.5)

USING
    Camera.Perspective(.transformation TRANSLATE(.X -2.9), .screen_distance 1)
    Renderer.PathTracer(.max_depth 4)
    Image(200,200)
    Tracer(.samples_per_side 10)
