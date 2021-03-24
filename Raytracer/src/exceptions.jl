abstract type RaytracerException <: Exception end


struct InvalidPfmFileFormat <: RaytracerException
    message::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.message)