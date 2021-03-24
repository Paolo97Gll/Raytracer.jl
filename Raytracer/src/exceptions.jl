struct InvalidPfmFileFormat <: Exception
    message::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, e.message)