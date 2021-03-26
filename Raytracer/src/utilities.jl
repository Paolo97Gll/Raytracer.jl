"""
    little_endian
Store bool about endianness of host system
"""
const little_endian = ENDIAN_BOM == 0x04030201

# We define a singleton type FE{file encoding symbol} for each file encoding, so
# that Julia's dispatch and overloading mechanisms can be used to
# dispatch read!.

"""
    FE
A type representing a standard file data encoding. "FE" stands for
"File Encoding".
A `FE` object can be passed as the second argument to [`read`](@ref) or [`write`](@ref) to
request the given stream to be decoded or encoded in the given format.
# Examples
```jldoctest
julia> image = HdrImage(RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                                     RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                                     RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)]);

julia> io = IOBuffer();

julia> write(io, FE("pfm"), image) # write to stream in pfm format, return number of bytes written
84

julia> seekstart(io);

julia> fromstream = read(io, FE("pfm")) # read from stream, decode the pfm format, return HdrImage
3x2 HdrImage{RGB{Float32}}
 (10.0 20.0 30.0)  (100.0 200.0 300.0)
 (40.0 50.0 60.0)  (400.0 500.0 600.0)
 (70.0 80.0 90.0)  (700.0 800.0 900.0)

julia> all(fromstream .== image)
true
```
""" 
struct FE{stream_type} end

macro FE_str(s)
    :(FE{$(Expr(:quote, Symbol(s)))})
end

FE(s) = FE{Symbol(s)}()