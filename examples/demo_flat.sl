# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Flat renderer example script

SET
    red    <1, 0, 0>
    green  <0, 1, 0>
    cyan   <0, 1, 1>
    yellow <1, 1, 0>
    white  <1, 1, 1>


# Shpere
SET scaling_factor SCALE 0.22
SET
    sphere_coord0 TRANSLATE(-1, -1, -1) * scaling_factor
    sphere_coord1 TRANSLATE( 1, -1, -1) * scaling_factor
    sphere_coord2 TRANSLATE(-1,  1, -1) * scaling_factor
    sphere_coord3 TRANSLATE( 1,  1, -1) * scaling_factor
    sphere_coord4 TRANSLATE(-1, -1,  1) * scaling_factor
    sphere_coord5 TRANSLATE( 1, -1,  1) * scaling_factor
    sphere_coord6 TRANSLATE(-1,  1,  1) * scaling_factor
    sphere_coord7 TRANSLATE( 1,  1,  1) * scaling_factor
    sphere_diffuse1 Material(.brdf Brdf.Diffuse(Pigment.Uniform(cyan)))
    

    
    sphere_coord8 TRANSLATE( 0,  0, -1) * scaling_factor
    sphere_coord9 TRANSLATE( 0,  1,  0) * scaling_factor
# Ground
SET
    ground_position TRANSLATE(.Z -2)
    ground_material Material(.brdf Brdf.Diffuse(Pigment.Checkered(.N 4)))

# Sky
SET
    sky_position SCALE 100
    sky_material Material(.brdf Brdf.Diffuse(Pigment.Uniform(white)))


SET
    diffuse1        Material(.brdf Brdf.Diffuse(Pigment.Uniform(cyan)))
    diffuse2        Material(.brdf Brdf.Diffuse(Pigment.Uniform(yellow)))
    checkered1      Material(.brdf Brdf.Diffuse(Pigment.Checkered(.color_on red, .color_off green, .N 8)))
    ground_material Material(.brdf Brdf.Diffuse(Pigment.Checkered(.N 4)))
    sky_material    Material(.brdf Brdf.Diffuse(Pigment.Uniform(white)))

SPAWN
    # Spheres
    Shape.Sphere(.transformation sphere_coord0, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord1, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord2, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord3, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord4, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord5, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord6, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord7, .material diffuse1)
    Shape.Sphere(.transformation sphere_coord8, .material checkered1)
    Shape.Sphere(.transformation sphere_coord9, .material diffuse2)
    # Ground
    Shape.Plane(.transformation ground_position, .material ground_material)
    # Sky
    Shape.Sphere(.transformation sky_position, .material sky_material)

USING
    Camera.Perspective(.transformation TRANSLATE(.X -3), .screen_distance 2)
    Renderer.Flat()
    Image(1000, 1000)
    Tracer()
