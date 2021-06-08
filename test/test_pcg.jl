# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for pcg.jl


pcg = PCG()

@test pcg.state == UInt64(1753877967969059832)
@test pcg.inc == UInt64(109)

for expected ∈ [2707161783, 2068313097,
                3122475824, 2211639955,
                3215226955, 3421331566]
    @test expected == rand(pcg, UInt32)
end
