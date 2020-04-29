module OffsetAxes

using Reexport
using AxisIndices
using StaticRanges
using AxisIndices: AxisIndicesStyle, IndicesCollection, IndexElement, KeyElement, KeysCollection
using Base: OneTo, @propagate_inbounds, tail

@reexport using AxisIndices

# TODO should OffsetAxis be exported?
export
    OffsetAxis,
    OffsetArray,
    OffsetVector

@static if !isdefined(Base, :IdentityUnitRange)
    const IdentityUnitRange = Base.Slice
else
    using Base: IdentityUnitRange
end

include("abstractoffsetaxis.jl")
include("offsetaxis.jl")
include("offsetarray.jl")
# include("centeredaxis.jl")
# include("identityaxis.jl")

end
