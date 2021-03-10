module Raytracer

import ColorTypes.RGB

"""Dispatch of elementwise addition between two RGB type instances"""
Base.:+(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(c1.r+c2.r,c1.g+c2.g,c1.b+c2.b)

"""Dispatch of elementwise subtraction di between two RGB type instances"""
Base.:-(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(c1.r-c2.r,c1.g-c2.g,c1.b-c2.b)

"""Dispatch of scalar multiplication for a RGB type instance"""
Base.:*(scalar::Number, c::RGB{T}) where {T} = RGB{T}((scalar .* (c.r, c.g, c.b))...)

"""Mirrored version of scalar multiplication for a RGB type instance"""
Base.:*(c::RGB{T}, scalar::Number) where {T} = scalar * c

"""Dispatch of elementwise multiplication between two RGB type instances"""
Base.:*(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(((c1.r, c1.g, c1.b) .* (c2.r, c2.g, c2.b))...)

"""Dispatch of elementwise ≈ operator between two RGB type instances"""
Base.:≈(c1::RGB{T}, c2::RGB{T}) where {T} = c1.r ≈ c2.r &&
                                            c1.g ≈ c2.g &&
                                            c1.b ≈ c2.b

end # module