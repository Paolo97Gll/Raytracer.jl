abstract type RaytracerException <: Exception end

struct InvalidRgbStream <: RaytracerException
    message::String
end
Base.showerror(io::IO, e::InvalidRgbStream) = print(io, typeof(e), ": ", e.message)

struct InvalidPfmFileFormat <: RaytracerException
    message::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.message)