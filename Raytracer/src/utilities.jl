"""
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
A `FE` object can be passed as the second argument to [`read`](@ref) to
request the given stream to be decoded from the given encoding.
# Examples
```jldoctest

```
""" # TODO insert example here
struct FE{stream_type} end

macro FE_str(s)
    :(FE{$(Expr(:quote, Symbol(s)))})
end

FE(s) = FE{Symbol(s)}()