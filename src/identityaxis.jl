
"""
    IdentityAxis{V,Vs}

Instead of being reconstructed with the original offset when indexing, a `IdentityAxis`
propagates the indices it was indexed with (e.g., IdentityAxis(1:10)[3:4] == IdentityAxis(3:4))
"""
struct IdentityAxis{V,Vs} <: AbstractOffsetAxis{V,Vs}
    offset::V
    values::Vs
end

function IdentityAxis(ks::AbstractUnitRange, vs::AbstractUnitRange)
    return IdentityAxis{eltype(vs),typeof(vs)}(ks, vs)
end
function IdentityAxis{V,Vs}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return IdentityAxis{V,Vs}(compute_offset(vs, ks), vs)
end

offset(axis::IdentityAxis) = getfield(axis, :offset)

Base.values(axis::IdentityAxis) = getfield(axis, :values)

function StaticRanges.similar_type(
    ::IdentityAxis{V,Vs},
    vs_type::Type=Vs
   ) where {V,Vs}
    return IdentityAxis{eltype(vs_type),vs_type}
end

struct IdentityStyle{S} <: AbstractOffsetStyle{S} end

IdentityStyle(S::AxisIndicesStyle) = IdentityStyle{S}()
IdentityStyle(S::IndicesCollection) =  IdentityStyle{KeysCollection()}()
IdentityStyle(S::IndexElement) = IdentityStyle{KeyElement()}()

function AxisIndices.AxisIndicesStyle(::Type{<:IdentityAxis}, ::Type{T}) where {T}
    return IdentityStyle(AxisIndices.AxisIndicesStyle(T))
end

