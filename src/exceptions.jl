abstract type RaytracerException <: Exception end

struct InvalidRgbStream <: RaytracerException
    msg::AbstractString
end
showerror(io::IO, e::InvalidRgbStream) = println(io, e.msg)