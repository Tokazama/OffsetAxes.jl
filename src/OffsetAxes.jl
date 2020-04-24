module OffsetAxes

using Reexport
using AxisIndices
using StaticRanges
using Base: OneTo, @propagate_inbounds
using AxisIndices: AxisIndicesStyle, IndicesCollection, IndexElement, KeyElement

@reexport using AxisIndices

# TODO should OffsetAxis be exported?
export OffsetAxis, offset_view

#=
    OffsetAxis

The keys act as the indices for an OffsetAxis. So the `values(::OffsetAxis)` have
the indices `keys(::OffsetAxis)`
=#
struct OffsetAxis{V,Vs} <: AbstractAxis{V,V,UnitRange{V},Vs}
    offset::V
    values::Vs

    function OffsetAxis{V,Vs}(offset::V, r::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        return new{V,Vs}(offset, r)
    end
end

OffsetAxis(vs::AbstractUnitRange) = OffsetAxis(0, vs)
OffsetAxis{V}(vs::AbstractUnitRange) where {V} = OffsetAxis{V}(zero(V), vs)
OffsetAxis{V,Vs}(vs::AbstractUnitRange) where {V,Vs} = OffsetAxis{V,Vs}(zero(V), vs)

function OffsetAxis{V,Vs}(offset::Integer, r::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    o, rc = offset_coerce(Vs, r)
    return OffsetAxis{V,Vs}(convert(V, o + offset), rc)
end

function OffsetAxis{V}(offset::Integer, r::AbstractUnitRange) where V<:Integer
    rc = convert(AbstractUnitRange{V}, r)::AbstractUnitRange{V}
    return OffsetAxis{V,typeof(rc)}(convert(V, offset), rc)
end

function OffsetAxis(offset::Integer, r::AbstractUnitRange{V}) where V<:Integer
    return OffsetAxis{V,typeof(r)}(convert(V, offset), r)
end

# Coercion from other OffsetAxiss
OffsetAxis{V,Vs}(r::OffsetAxis{V,Vs}) where {V<:Integer,Vs<:AbstractUnitRange{V}} = r
function OffsetAxis{V,Vs}(r::OffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    offset, rc = offset_coerce(Vs, values(r))
    return OffsetAxis{V,Vs}(get_offset(r) + offset, rc)
end
function OffsetAxis{V}(r::OffsetAxis) where V<:Integer
    return OffsetAxis(get_offset(r), convert(AbstractUnitRange{V}, values(r)))
end
OffsetAxis(r::OffsetAxis) = r

function offset_coerce(::Type{Base.OneTo{V}}, r::Base.OneTo) where V<:Integer
    return 0, convert(Base.OneTo{V}, r)
end

function offset_coerce(::Type{Base.OneTo{V}}, r::AbstractUnitRange) where V<:Integer
    o = first(r) - 1
    return o, Base.OneTo{V}(last(r) - o)
end
# function offset_coerce(::Type{Base.OneTo{T}}, r::OffsetAxis) where T<:Integer
#     rc, o = offset_coerce(Base.OneTo{T}, r.parent)

# Fallback, specialze this method if `convert(I, r)` doesn't do what you need
function offset_coerce(::Type{Vs}, r::AbstractUnitRange) where Vs<:AbstractUnitRange{V} where V
    return 0, convert(Vs, r)
end

# TODO: uncomment these when Julia is ready
# # Conversion preserves both the values and the indexes, throwing an InexactError if this
# # is not possible.
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis{V,Vs}) where {V<:Integer,Vs<:AbstractUnitRange{V}} = r
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r.parent), r.offset)
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r), 0)

Base.values(axis::OffsetAxis) = getfield(axis, :values)

get_offset(axis::OffsetAxis) = getfield(axis, :offset)

Base.firstindex(axis::OffsetAxis) = first(values(axis)) + get_offset(axis)

Base.lastindex(axis::OffsetAxis) = last(axis) + get_offset(axis)

Base.keys(axis::OffsetAxis) = firstindex(axis):lastindex(axis)

function StaticRanges.similar_type(
    ::Type{A},
    vs_type::Type=values_type(A)
   ) where {A<:OffsetAxis}
    return OffsetAxis{eltype(vs_type),vs_type}
end

function unsafe_reconstruct(a::OffsetAxis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs)
end

@inline function AxisIndices.AxisIndicesStyle(::Type{<:OffsetAxis}, ::Type{T}) where {T}
    force_keys(AxisIndices.AxisIndicesStyle(T))
end

force_keys(S::AxisIndicesStyle) = S
force_keys(S::IndicesCollection) = KeysCollection()
force_keys(S::IndexElement) = KeyElement()

@inline function Base.compute_offset1(parent, stride1::Integer, dims::Tuple{Int}, inds::Tuple{OffsetAxis}, I::Tuple)
    return Base.compute_linindex(parent, I) - stride1*first(axes(parent, dims[1]))
end
@inline Base.axes(axis::OffsetAxis) = (Base.axes1(axis),)
@inline Base.axes1(axis::OffsetAxis) = OffsetAxis(get_offset(axis), Base.axes1(values(axis)))
@inline Base.unsafe_indices(axis::OffsetAxis) = (axis,)

@inline function Base.iterate(axis::OffsetAxis)
    ret = iterate(values(axis))
    ret === nothing && return nothing
    return (ret[1] + axis.offset, ret[2])
end

@inline function Base.iterate(axis::OffsetAxis, i)
    ret = iterate(values(axis), i)
    ret === nothing && return nothing
    return (ret[1] + axis.offset, ret[2])
end

Base.eachindex(axis::OffsetAxis) = keys(axis)

Base.collect(axis::OffsetAxis) = collect(keys(axis))

@propagate_inbounds function Base.getindex(axis::OffsetAxis, i::Integer)
    return values(axis)[i - get_offset(axis)] + get_offset(axis)
end
@propagate_inbounds function Base.getindex(axis::OffsetAxis, s::AbstractUnitRange{<:Integer})
    return values(axis)[s .- get_offset(axis)] .+ get_offset(axis)
end
@propagate_inbounds function Base.getindex(axis::OffsetAxis, s::OffsetAxis)
    return OffsetAxis(get_offset(axis), values(axis)[s .- get_offset(axis)])
end

function Base.checkindex(::Type{Bool}, axis::OffsetAxis, i::Integer)
    return checkindex(Bool, values(axis), values(axis) - get_offset(axis))
end

function Base.checkindex(::Type{Bool}, axis::OffsetAxis, i::AbstractUnitRange{<:Integer})
    return checkindex(Bool, values(axis), values(axis) .- get_offset(axis))
end

function make_offset_axes(offsets, axs)
    return map((f, axis) -> OffsetAxis(first(axis) + f, axis), offsets, axs)
end

"""
    offset_view()
"""
offset_view(A::AbstractArray, offsets::Int...) = offset_view(A, offsets)

function offset_view(A::AbstractArray{T,N}, offsets::Tuple{Vararg{<:Integer,N}}) where {T,N}
    return AxisIndicesArray(A, make_offset_axes(offsets, axes(A)))
end


end
