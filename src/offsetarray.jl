
offsets(A) = map(offset, axes(A))

"""
    OffsetArray
"""
const OffsetArray{T,N,P,A<:Tuple{Vararg{<:OffsetAxis}}} = AxisIndicesArray{T,N,P,A}

"""
    OffsetVector
"""
const OffsetVector{T,P<:AbstractVector{T},Ax1} = OffsetArray{T,1,P,Tuple{Ax1}}

compute_offset(parent_inds::AbstractUnitRange, offset::AbstractUnitRange) = first(offset) - first(parent_inds)
compute_offset(parent_inds::AbstractUnitRange, offset::Integer) = 1 - first(parent_inds)

OffsetArray(A::AbstractArray{T,N}, inds::Vararg) where {T,N} = OffsetArray(A, inds)

OffsetArray(A::AbstractArray{T,N}, inds::Tuple) where {T,N} = OffsetArray{T,N}(A, inds)

function OffsetArray(A::AbstractArray{T,0}, ::Tuple{}) where {T}
    return AxisIndicesArray(A)
end
OffsetArray(A) = OffsetArray(A, offsets(A))

# OffsetVector constructors
OffsetVector(A, arg) = OffsetArray(A, arg)
OffsetVector{T}(A, arg) where {T} = OffsetArray{T}(A, arg)

OffsetArray{T}(A, inds::Tuple) where {T} = OffsetArray{T,length(inds)}(A, inds)
OffsetArray{T}(A, inds::Vararg) where {T} = OffsetArray{T,length(inds)}(A, inds)

function OffsetArray{T,N}(init::Union{UndefInitializer, Missing, Nothing}, inds::Tuple=()) where {T,N}
    return OffsetArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end

OffsetArray{T,N}(A, inds::Vararg) where {T,N} = OffsetArray{T,N}(A, inds)

function OffsetArray{T,N}(A::AbstractArray, inds::Tuple) where {T,N}
    axs = ntuple(Val(N)) do i
        index = getfield(inds, i)
        axis = axes(A, i)
        if index isa Integer
            OffsetAxis(index, axis)
        else
            if length(index) == length(axis)
                OffsetAxis(first(index) - first(axis), axis)
            else
                throw(DimensionMismatch("supplied axes do not agree with the size of the array (got size $(length(axis)) for the array and $(length(index)) for the indices"))
            end
        end
    end
    return AxisIndicesArray{T,N}(A, axs)
end

function OffsetArray{T,N}(A::AbstractAxisIndices, inds::Tuple) where {T,N}
    axs = ntuple(Val(N)) do i
        index = getfield(inds, i)
        axis = axes(A, i)
        if index isa Integer
            OffsetAxis(index + offset(axis), values(axis))
        else
            if length(index) == length(axis)
                OffsetAxis(first(index) - first(axis), axis)
            else
                throw(DimensionMismatch("supplied axes do not agree with the size of the array (got size $(length(axis)) for the array and $(length(index)) for the indices"))
            end
        end
    end
    return AxisIndicesArray{T,N}(parent(A), axs)
end
