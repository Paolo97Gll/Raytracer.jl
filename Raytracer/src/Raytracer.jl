module Raytracer

import ColorTypes
import Base.:+, Base.:*, Base.:≈

# To make this work, first define the product "scalar * color"
Base.:*(c::ColorTypes.RGB{T}, scalar) where {T} = scalar * c

end # module