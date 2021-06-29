# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parser of SceneLang
"""
    ValueLoc

Stores a Julia value and the source location of its declaration.
"""
struct ValueLoc
    value::Any
    loc::SourceLocation
end

function Base.show(io::IO, valueloc::ValueLoc)
    print(io, valueloc.value)
    printstyled(io, " @ ", valueloc.loc, color = :light_black)
end

function Base.show(io::IO, ::MIME"text/plain", valueloc::ValueLoc)
    print(io, valueloc.value)
    printstyled(io, " @ ", valueloc.loc, color = :light_black)
end

"""
    IdTableKey

Alias for `Union{Type{<:TokenValue}, LiteralType}`. Used as the key type for [`IdTable`](@ref).
"""
const IdTableKey = Union{Type{<:TokenValue}, LiteralType}

"""
    IdTable

Alias to `Dict{IdTableKey, Dict{Symbol, ValueLoc}}`.

Dictionary with all the variables set in a SceneLang script.
Keys represent the equivalent [`TokenValue`](@ref) or [`LiteralType`](@ref) type to the Julia type stored in [`ValueLoc`](@ref).
"""
const IdTable = Dict{IdTableKey, Dict{Symbol, ValueLoc}}

function Base.show(io::IO, table::IdTable)
    show(io, MIME("text/plain"), table)
end

function Base.show(io::IO, ::MIME"text/plain", table::IdTable)
    for (key, subdict) ∈ pairs(table)
        printstyled(io, "#### ", key, " ####", color = :blue, bold = true)
        println()
        for (id, value) ∈ pairs(subdict)
            printstyled(io, id, color = :green)
            println(io, " = ", value)
        end
        println(io)
    end
end

"""
    RendererSettings

Struct containing a renderer type and a `NamedTuple` of the named arguments needed for its construction.

Since a [`Renderer`](@ref) type cannot be directly stored into a [`Scene`](@ref) due to it needing at least the [`World`](@ref) argument,
we can use this struct to store everything else, ready to be constructed.
"""
struct RendererSettings
    type::Type{<:Renderer}
    kwargs::NamedTuple
end

"""
    TracerSettings

Struct containing a `NamedTuple` of the named arguments needed to construct an [`ImageTracer`](@ref).

Since a [`ImageTracer`](@ref) type cannot be directly stored into a [`Scene`](@ref) due to it needing at least the [`Camera`](@ref)
and [`HdrImage`](@ref) arguments, we can use this struct to store everything else, ready to be constructed.
"""
struct TracerSettings
    kwargs::NamedTuple
end

"""
    CameraOrNot

Alias for `Union{Camera, Nothing}`.

See also: [`Scene`](@ref)
"""
const CameraOrNot = Union{Camera, Nothing}
"""
    RendererOrNot

Alias for `Union{RendererSettings, Nothing}`.

See also: [`Scene`](@ref)
"""
const RendererOrNot = Union{RendererSettings, Nothing}
"""
    ImageOrNot

Alias for `Union{HdrImage, Nothing}`.

See also: [`Scene`](@ref)
"""
const ImageOrNot = Union{HdrImage, Nothing}
"""
    TracerOrNot

Alias for `Union{TracerSettings, Nothing}`.

See also: [`Scene`](@ref)
"""
const TracerOrNot = Union{TracerSettings, Nothing}

"""
    Scene

A mutable struct containing all the significant elements of a renderable scene and all the declared variables of the SceneLang script.

# Fields

- `variables::`[`IdTable`](@ref): stores all the variables declared in the script
- `world::`[`World`](@ref): stores all the spawned [`Shape`](@ref)s
- `lights::`[`Lights`](@ref): stores all the spawned [`PointLight`](@ref)s
- `image::`[`ImageOrNot`](@ref): stores either the [`HdrImage`](@ref) to impress or `nothing`
- `camera::`[`CameraOrNot`](@ref): stores either the [`Camera`](@ref) or `nothing`
- `renderer::`[`RendererOrNot`](@ref): stores either the [`RendererSettings`](@ref) for the [`Renderer`](@ref) or `nothing`
- `tracer::`[`TracerOrNot`](@ref): strores either the [`TracerSettings`](@ref) for the [`ImageTracer`](@ref) or `nothing`
- `time`: stores the animation time
"""
mutable struct Scene
    variables::IdTable
    world::World
    lights::Lights
    image::ImageOrNot
	camera::CameraOrNot
	renderer::RendererOrNot
    tracer::TracerOrNot
    time
end

"""
    Scene(; variables::IdTable = IdTable(),
            world::World = World(),
            lights::Lights = Lights(),
            image::ImageOrNot = nothing,
            camera::CameraOrNot = nothing,
            renderer::RendererOrNot = nothing,
            tracer::TracerOrNot = nothing,
            time = 0)


Constructor for a [`Scene`](@ref) instance.
"""
function Scene(; variables::IdTable = IdTable(),
                 world::World = World(),
                 lights::Lights = Lights(),
                 image::ImageOrNot = nothing,
                 camera::CameraOrNot = nothing,
                 renderer::RendererOrNot = nothing,
                 tracer::TracerOrNot = nothing,
                 time = 0)
	Scene(variables, world, lights, image, camera, renderer, tracer, time)
end

"""
    Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}};
          world::World = World(),
          lights::Lights = Lights(),
          image::ImageOrNot = nothing,
          camera::CameraOrNot = nothing,
          renderer::RendererOrNot = nothing,
          tracer::TracerOrNot = nothing,
          time = 0)


Constructor for a [`Scene`](@ref) instance.

Slightly more convenient than the default constructor to manually construct in a Julia code.
"""
function Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}};
               world::World = World(), lights::Lights = Lights(),
               image::ImageOrNot = nothing,
               camera::CameraOrNot = nothing,
               renderer::RendererOrNot = nothing,
               tracer::TracerOrNot = nothing,
               time = 0)

	variables =  Dict(zip(first.(variables), (Dict(last(pair)) for pair ∈ variables)))
	Scene(variables, world, lights, image, camera, renderer, tracer, time)
end

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    printstyled(io, ".VARIABLES\n\n", color = :magenta, bold= true)
    show(io, scene.variables)
    println(io)

    printstyled(io, ".WORLD\n\n", color = :magenta, bold= true)
    if !isempty(scene.world)
        for (i, shape) ∈ enumerate(scene.world)
            printstyled(io, i, color = :green)
            println(io, ": ", shape)
        end
        println(io)
    end
    println(io)

    printstyled(io, ".LIGHTS\n\n", color = :magenta, bold= true)
    if !isempty(scene.lights)
        for (i, light) ∈ enumerate(scene.lights)
            printstyled(io, i, color = :green)
            println(io, ": ", light)
        end
        println(io)
    end
    println(io)

    printstyled(io, ".IMAGE\n\n", color = :magenta, bold= true)
    if !isnothing(scene.image)
        printstyled(io, "image", color = :green)
        println(io, " = ", scene.image)
        println(io)
    end
    println(io)

    printstyled(io, ".CAMERA\n\n", color = :magenta, bold= true)
    if !isnothing(scene.camera)
        printstyled(io, "camera", color = :green)
        println(io, " = ", scene.camera)
        println(io)
    end
    println(io)

    printstyled(io, ".RENDERER\n\n", color = :magenta, bold= true)
    if !isnothing(scene.renderer)
        printstyled(io, "type", color = :green)
        println(io, " = ", scene.renderer.type)
        if isempty(scene.renderer.kwargs)
            printstyled(io, "default kwargs\n\n", color=:light_black)
        else
            for (kw, value) ∈ pairs(scene.renderer.kwargs)
                printstyled(io, kw, color = :green)
                println(io, " = ", value)
            end
        end
    end

    printstyled(io, ".TRACER\n\n", color = :magenta, bold= true)
    if !isnothing(scene.tracer)
        if isempty(scene.tracer.kwargs)
            printstyled(io, "default kwargs\n\n", color=:light_black)
        else
            for (kw, value) ∈ pairs(scene.tracer.kwargs)
                printstyled(io, kw, color = :green)
                println(io, " = ", value)
            end
        end
    end

    printstyled(io, ".TIME\n\n", color = :magenta, bold= true)
    printstyled(io, "time", color = :green)
    println(io, " = ", scene.time)
    println(io)

end