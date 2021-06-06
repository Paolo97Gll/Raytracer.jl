# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Permuted congruential generator (simple fast space-efficient statistically good algorithms for random number generation)
# TODO write docstrings


mutable struct PCG <: AbstractRNG
    state::UInt64
    inc::UInt64
    
    function PCG(state::UInt64 = UInt64(42), inc::UInt64 = UInt64(54))
        self = new(UInt64(0), (inc << UInt64(1)) | UInt64(1))
        rand(self)
        self.state += state
        rand(self)
        self
    end
end

function Base.rand(r::PCG)
    rand(r, Sampler(r, UInt32, Val(1)))
end

function Base.rand(r::PCG, ::Random.SamplerType{UInt32}) 
    oldstate = r.state
    r.state = UInt64(oldstate * UInt64(6364136223846793005) + r.inc)
    xorshifted = UInt32(((oldstate >> UInt64(18)) ⊻ oldstate) >> UInt64(27) & typemax(UInt32))
    rot = oldstate >> UInt64(59)
    UInt32((xorshifted >> rot) | (xorshifted << ((-rot) & UInt32(31))))
end

function Base.rand(r::PCG, ::Random.SamplerTrivial{Random.CloseOpen01{Float64}, Float64})
    convert(Float64, rand(r)/typemax(UInt32))
end

function Base.rand(r::PCG, ::Random.SamplerType{T}) where {T <: Integer}
    convert(T, rand(r) % typemax(T))
end

function Base.rand(r::PCG, ::Type{T}) where {T <: AbstractFloat}
    convert(T, rand(r, Sampler(r, Float64, Val(1))))
end
