# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Path tracer renderer example script

# Ground
SET ground_position TRANSLATE(.Z -1)
# Sky
SET sky_position SCALE 100

USING
    Camera.Perspective(.transformation TRANSLATE(.X -3), .screen_distance 2)
    Renderer.PathTracer()
    Image(1000, 1000)
    Tracer()
