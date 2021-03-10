module Raytracer

import ColorTypes.RGB
import Base.:+, Base.:*, Base.:≈

Base.:+(c1::RGB{T}, c2::RGB{T}) where {T} = RGB(c1.r+c2.r,c1.g+c2.g,c1.b+c2.b)
Base.:-(c1::RGB{T}, c2::RGB{T}) where {T} = RGB(c1.r-c2.r,c1.g-c2.g,c1.b-c2.b)

end # module