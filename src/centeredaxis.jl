
struct CenteredAxis{V,Vs} <: AbstractOffsetAxis{V,Vs}
    offset::V
    values::Vs

    function CenteredAxis{V,Vs}(index::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        return new{V,Vs}(-div(length(index), 2), index)
    end
end

function CenteredAxis{V,Vs}(index) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return CenteredAxis{V,Vs}(Vs(index))
end

function CenteredAxis{V}(index::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return CenteredAxis{V,Vs}(Vs(index))
end

function CenteredAxis{V}(index::Vs) where {V<:Integer,V2,Vs<:AbstractUnitRange{V2}}
    return CenteredAxis{V}(convert(AbstractUnitRange{V}, index))
end


offset(axis::CenteredAxis) = getfield(axis, :offset)

Base.values(axis::CenteredAxis) = getfield(axis, :values)

function StaticRanges.similar_type(
    ::CenteredAxis,
    vs_type::Type=values_type(A)
   ) where {A<:OffsetAxis}
    return CenteredAxis{eltype(vs_type),vs_type}
end
