# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# OnOff renderer example script

SET scaling_factor SCALE 0.22
SET
    coord0 TRANSLATE(-1, -1, -1) * scaling_factor
    coord1 TRANSLATE( 1, -1, -1) * scaling_factor
    coord2 TRANSLATE(-1,  1, -1) * scaling_factor
    coord3 TRANSLATE( 1,  1, -1) * scaling_factor
    coord4 TRANSLATE(-1, -1,  1) * scaling_factor
    coord5 TRANSLATE( 1, -1,  1) * scaling_factor
    coord6 TRANSLATE(-1,  1,  1) * scaling_factor
    coord7 TRANSLATE( 1,  1,  1) * scaling_factor
    coord8 TRANSLATE( 0,  0, -1) * scaling_factor
    coord9 TRANSLATE( 0,  1,  0) * scaling_factor

SPAWN
    Shape.Sphere(.transformation coord0)
    Shape.Sphere(.transformation coord1)
    Shape.Sphere(.transformation coord2)
    Shape.Sphere(.transformation coord3)
    Shape.Sphere(.transformation coord4)
    Shape.Sphere(.transformation coord5)
    Shape.Sphere(.transformation coord6)
    Shape.Sphere(.transformation coord7)
    Shape.Sphere(.transformation coord8)
    Shape.Sphere(.transformation coord9)

SET camera_position ROTATE(.Z TIME) * TRANSLATE(.X -3)

USING
    Camera.Perspective(.transformation camera_position, .screen_distance 2)
    Renderer.OnOff()
    Image(500, 500)
    Tracer()
