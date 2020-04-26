
"""
    CenteredArray
"""
const CenteredArray{T,N,P,A<:Tuple{Vararg{<:CenteredAxis}}} = AxisIndicesArray{T,N,P,A}

"""
    CenteredVector
"""
const CenteredVector{T,P<:AbstractVector{T},Ax1} = CenteredArray{T,1,P,Tuple{Ax1}}

CenteredArray(A::AbstractArray{T,N}) where {T,N} = CenteredArray{T,N}(A)
CenteredArray{T,N}(A) where {T,N} = AxisIndicesArray{T,N}(A, map(OffsetAxis, axes(A)))

