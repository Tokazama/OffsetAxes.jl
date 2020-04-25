using Test, OffsetAxes


# differences from OffsetArrays
# * indexing preserves the offset so things like:
#!!! note this is different than what OffsetArryas does because offset arrays produced 0:1
# which doesn't make sense given the axis doesn't have a length of 2
#    @test S[0] == 3
#    @test axes(S) == (0:0,)



@testset "OffsetAxis" begin
    function same_value(r1, r2)
        length(r1) == length(r2) || return false
        for (v1, v2) in zip(r1, r2)
            v1 == v2 || return false
        end
        return true
    end
    function check_indexed_by(r, rindx)
        for i in rindx
            r[i]
        end
        @test_throws BoundsError r[minimum(rindx)-1]
        @test_throws BoundsError r[maximum(rindx)+1]
        return nothing
    end

    ro = OffsetAxis(Base.OneTo(3))
    rs = OffsetAxis(-2, 3:5)
    @test typeof(ro) !== typeof(rs)
    @test same_value(ro, 1:3)
    check_indexed_by(ro, 1:3)
    @test same_value(rs, 1:3)
    check_indexed_by(rs, -1:1)
    @test @inferred(typeof(ro)(ro)) === ro
    @test @inferred(OffsetAxis{Int}(ro))   === ro
    @test @inferred(OffsetAxis{Int16}(ro)) === OffsetAxis(Base.OneTo(Int16(3)))
    @test @inferred(OffsetAxis(ro))        === ro
    @test values(ro) === ro.values
    @test values(rs) === rs.values
    # construction/coercion preserves the values, altering the axes if needed
    r2 = @inferred(typeof(rs)(ro))
    @test typeof(r2) === typeof(rs)
    @test same_value(ro, 1:3)
    check_indexed_by(ro, 1:3)
    r2 = @inferred(typeof(ro)(rs))
    @test typeof(r2) === typeof(ro)
    @test same_value(r2, 1:3)
    check_indexed_by(r2, 1:3)
    # check the example in the comments
    r = OffsetAxis{Int,UnitRange{Int}}(3:4)
    @test same_value(r, 3:4)
    check_indexed_by(r, 1:2)
    r = OffsetAxis{Int,Base.OneTo{Int}}(3:4)
    @test same_value(r, 3:4)
    check_indexed_by(r, 3:4)
    r = OffsetAxis{Int,Base.OneTo{Int}}(-2, 3:4)
    @test same_value(r, 1:2)
    check_indexed_by(r, 1:2)

    # conversion preserves both the values and the axes, throwing an error if this is not possible
    @test @inferred(oftype(ro, ro)) === ro
    @test @inferred(convert(OffsetAxis{Int}, ro)) === ro
    @test @inferred(convert(OffsetAxis{Int}, rs)) === rs
    @test @inferred(convert(OffsetAxis{Int16}, ro)) === OffsetAxis(Base.OneTo(Int16(3)))
    r2 = @inferred(oftype(rs, ro))
    @test typeof(r2) === typeof(rs)
    @test same_value(r2, 1:3)
    check_indexed_by(r2, 1:3)
    # These two broken tests can be fixed by uncommenting the `convert` definitions
    # in axes.jl, but unfortunately Julia may not quite be ready for this. (E.g. `reinterpretarray.jl`)
    @test_broken try oftype(ro, rs); false catch err true end  # replace with line below
    # @test_throws ArgumentError oftype(ro, rs)
    @test @inferred(oftype(ro, Base.OneTo(2))) === OffsetAxis(Base.OneTo(2))
    @test @inferred(oftype(ro, 1:2)) === OffsetAxis(Base.OneTo(2))
    @test_broken try oftype(ro, 3:4); false catch err true end
    # @test_throws ArgumentError oftype(ro, 3:4)
end

@testset "Single-entry arrays in dims 0:5" begin
    for n = 0:5
        for z in (offset_view(ones(Int,ntuple(d->1,n)), ntuple(x->x-1,n)),
                  fill!(offset_view(Array{Float64}(undef, ntuple(_ -> 1, n)), ntuple(x->x:x, n)), 1),
                  fill!(offset_view(Array{Float64}(undef, ntuple(_ -> 1, n)), ntuple(x->x:x, n)...), 1),
                  fill!(offset_view(Array{Float64,n}(undef, ntuple(_ -> 1, n)), ntuple(x->x:x, n)), 1),
                  fill!(offset_view(Array{Float64,n}(undef, ntuple(_ -> 1, n)), ntuple(x->x:x, n)...), 1))
            @test length(LinearIndices(z)) == 1
            @test axes(z) == ntuple(x->x:x, n)
            @test z[1] == 1
        end
    end

    a0 = reshape([3])
    a = offset_view(a0)
    @test axes(a) == ()
    @test ndims(a) == 0
    @test a[] == 3
end

@testset "Offset range construction" begin
    r = -2:5
    y = offset_view(r, r)
    @test axes(y) == (r,)
    y = offset_view(r, (r,));
    @test axes(y) == (r,)
end

@testset "Traits" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1,2))                   # IndexLinear
    S = offset_view(view(A0, 1:2, 1:2), (-1,2))   # IndexCartesian
    @test axes(A) == axes(S) == (0:1, 3:4)
    @test size(A) == size(A0)
    @test size(A, 1) == size(A0, 1)
    @test length(A) == length(A0)
    @test A == offset_view(A0, 0:1, 3:4)
end

@testset "Scalar indexing" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1,2));
    S = offset_view(view(A0, 1:2, 1:2), (-1,2));

    @test @inferred(A[0,3]) == @inferred(A[0,3,1]) == @inferred(A[1]) == @inferred(S[0,3]) == @inferred(S[0,3,1]) == @inferred(S[1]) == 1
    @test A[1,3] == A[1,3,1] == A[2] == S[1,3] == S[1,3,1] == S[2] == 2
    @test A[0,4] == A[0,4,1] == A[3] == S[0,4] == S[0,4,1] == S[3] == 3
    @test A[1,4] == A[1,4,1] == A[4] == S[1,4] == S[1,4,1] == S[4] == 4
    @test @inbounds(A[0,3]) == @inbounds(A[0,3,1]) == @inbounds(A[1]) == @inbounds(S[0,3]) == @inbounds(S[0,3,1]) == @inbounds(S[1]) == 1
    @test @inbounds(A[1,3]) == @inbounds(A[1,3,1]) == @inbounds(A[2]) == @inbounds(S[1,3]) == @inbounds(S[1,3,1]) == @inbounds(S[2]) == 2
    @test @inbounds(A[0,4]) == @inbounds(A[0,4,1]) == @inbounds(A[3]) == @inbounds(S[0,4]) == @inbounds(S[0,4,1]) == @inbounds(S[3]) == 3
    @test @inbounds(A[1,4]) == @inbounds(A[1,4,1]) == @inbounds(A[4]) == @inbounds(S[1,4]) == @inbounds(S[1,4,1]) == @inbounds(S[4]) == 4
    @test_throws BoundsError A[1,1]
    @test_throws BoundsError S[1,1]
    @test_throws BoundsError A[0,3,2]
    @test_throws BoundsError A[0,3,0]
    Ac = copy(A)
    Ac[0,3] = 10
    @test Ac[0,3] == 10
    Ac[0,3,1] = 11
    @test Ac[0,3] == 11
    @inbounds Ac[0,3,1] = 12
    @test Ac[0,3] == 12

    ks = -1:1, -7:7, -128:512, -5:5, -1:1, -3:3, -2:2, -1:1
    y = offset_view(Array{Float64}(undef, map(length, ks)), ks...)
    y[-1,-7,-128,-5,-1,-3,-2,-1] = 14
    y[-1,-7,-128,-5,-1,-3,-2,-1] += 5
    @test y[-1,-7,-128,-5,-1,-3,-2,-1] == 19
end

@testset "CartesianAxisCore" begin
    A0 = [1 3; 2 4]
    A = AxisIndicesArray(offset_view(A0, (-1,2)));
    S = AxisIndicesArray(offset_view(view(A0, 1:2, 1:2), (-1,2)));

    @test A[CartesianIndex((0,3))] == S[CartesianIndex((0,3))] == 1
    @test A[CartesianIndex((0,3)),1] == S[CartesianIndex((0,3)),1] == 1
    @test @inbounds(A[CartesianIndex((0,3))]) == @inbounds(S[CartesianIndex((0,3))]) == 1
    @test @inbounds(A[CartesianIndex((0,3)),1]) == @inbounds(S[CartesianIndex((0,3)),1]) == 1
    @test_throws BoundsError A[CartesianIndex(1,1)]
    @test_throws BoundsError A[CartesianIndex(1,1),0]
    @test_throws BoundsError A[CartesianIndex(1,1),2]
    @test_throws BoundsError S[CartesianIndex(1,1)]
    @test_throws BoundsError S[CartesianIndex(1,1),0]
    @test_throws BoundsError S[CartesianIndex(1,1),2]
    @test eachindex(A) == 1:4
    @test eachindex(S) == CartesianIndices(OffsetAxis.((0:1,3:4)))
end

@testset "Vector indexing" begin
    A0 = [1 3; 2 4]
    A_1 = offset_view(A0, (-1,2))
    S_1 = offset_view(view(A0, 1:2, 1:2), (-1,2))

    A = offset_view(A0, (-1,2))
    S = offset_view(view(A0, 1:2, 1:2), (-1,2))

    s = S[:, 3]
    s == S_1[:,3]
    @test A[:, 3] == S[:, 3]
    @test A[:, 4] == S[:, 4]
    @test_throws BoundsError A[:, 1]
    @test_throws BoundsError S[:, 1]
    @test A[0, :] == S[0, :]
    @test A[1, :] == S[1, :]
    @test_throws BoundsError A[2, :]
    @test_throws BoundsError S[2, :]
    @test A[0:1, 3] == S[0:1, 3] == [1,2]
    @test A[[1,0], 3] == S[[1,0], 3] == [2,1]
    @test A[0, 3:4] == S[0, 3:4] == [1,3]
    @test A[1, [4,3]] == S[1, [4,3]] == [4,2]
    @test A[:, :] == S[:, :] == A
end


#=
@testset "Vector indexing with offset ranges" begin
    r = offset_view(8:10, -1:1)
    r1 = r[0:1]
    @test r1 == 9:10
    r1 = (8:10)[AxisIndicesArray(offset_view(1:2, -5:-4))]
    @test axes(r1) == (IdentityUnitRange(-5:-4),)
    @test parent(r1) == 8:9
    r1 = AxisIndicesArray(offset_view(8:10, -1:1))[offset_view(0:1, -5:-4)]
    @test axes(r1) == (IdentityUnitRange(-5:-4),)
    @test parent(r1) == 9:10
end
=#

@testset "view" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1,2))

    S = view(A, :, 3)
    @test S == A[:, 3]
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[2]
    @test axes(S) == (0:1,)
    S = view(A, 0, :)
    @test S == A[0, :]
    @test S[3] == 1
    @test S[4] == 3
    @test_throws BoundsError S[1]
    @test axes(S) == (3:4,)
    S = view(A, 0:0, 4)
    @test S == [3]

    #!!! note this is different than what OffsetArrays does because offset arrays produced 0:1
    # which doesn't make sense given the axis doesn't have a length of 2
    @test S[0] == 3
    #@test_throws BoundsError S[0]
    @test axes(S) == (0:0,)
    S = view(A, 1, 3:4)
    @test S == [2,4]
    @test S[3] == 2
    @test S[4] == 4
    @test axes(S) == (3:4,)
    S = view(A, :, :)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) == (0:1, 3:4)
    S = view(A, axes(A)...)
    @test S == A
    @test S[0,3] == S[1] == 1
    @test S[1,3] == S[2] == 2
    @test S[0,4] == S[3] == 3
    @test S[1,4] == S[4] == 4
    @test_throws BoundsError S[1,1]
    @test axes(S) == OffsetAxis.((0:1, 3:4))
    # issue 100
    S = view(A, axes(A, 1), 3)
    @test S == A[:, 3]
    @test S[0] == 1
    @test S[1] == 2
    @test_throws BoundsError S[length(S)]
    @test axes(S) == (OffsetAxis(0:1), )
    # issue 100
    S = view(A, 1, axes(A, 2))
    @test S == A[1, :]
    @test S[3] == 2
    @test S[4] == 4
    @test_throws BoundsError S[1]
    @test axes(S) == (OffsetAxis(3:4), )

    A0 = collect(reshape(1:24, 2, 3, 4))
    A = offset_view(A0, (-1,2,1))
    S = view(A, axes(A, 1), 3:4, axes(A, 3))
    @test S == A[:, 3:4, :]
    @test S[0, 3, 2] == A[0, 3, 2]
    @test S[0, 4, 2] == A[0, 4, 2]
    @test S[1, 3, 2] == A[1, 3, 2]
    @test axes(S) == (OffsetAxis(0:1), 3:4, OffsetAxis(2:5))
end

#=
@testset "similar" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1, 2))

    B = similar(A, Float32)
    #= TODO
    @test isa(B, AxisIndicesArray(offset_view{Float32,2}))
    @test axes(B) == axes(A)
    B = similar(A, (3,4))
    @test isa(B, Array{Int,2})
    @test size(B) == (3,4)
    @test axes(B) == (Base.OneTo(3), Base.OneTo(4))
    B = similar(A, (-3:3,1:4))
    @test isa(B, offset_view{Int,2})
    @test axes(B) == IdentityUnitRange.((-3:3, 1:4))
    B = similar(parent(A), (-3:3,1:4))
    @test isa(B, offset_view{Int,2})
    =#
end

@testset "reshape" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1,2))

    B = reshape(A0, -10:-9, 9:10)
    @test isa(B, offset_view{Int,2})
    @test parent(B) === A0
    @test axes(B) == IdentityUnitRange.((-10:-9, 9:10))
    B = reshape(A, -10:-9, 9:10)
    @test isa(B, offset_view{Int,2})
    @test pointer(parent(B)) === pointer(A0)
    @test axes(B) == IdentityUnitRange.((-10:-9, 9:10))
    b = reshape(A, -7:-4)
    @test axes(b) == (IdentityUnitRange(-7:-4),)
    @test isa(parent(b), Vector{Int})
    @test pointer(parent(b)) === pointer(parent(A))
    @test parent(b) == A0[:]
    a = offset_view(rand(3,3,3), -1:1, 0:2, 3:5)
    # Offset axes are required for reshape(::offset_view, ::Val) support
    b = reshape(a, Val(2))
    @test isa(b, offset_view{Float64,2})
    @test pointer(parent(b)) === pointer(parent(a))
    @test axes(b) == IdentityUnitRange.((-1:1, 1:9))
    b = reshape(a, Val(4))
    @test isa(b, offset_view{Float64,4})
    @test pointer(parent(b)) === pointer(parent(a))
    @test axes(b) == (axes(a)..., IdentityUnitRange(1:1))

    @test reshape(offset_view(-1:0, -1:0), :, 1) == reshape(-1:0, 2, 1)
    @test reshape(offset_view(-1:2, -1:2), -2:-1, :) == reshape(-1:2, -2:-1, 2)
end
=#

#=
@testset "logical indexing" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1,2))

    @test A[A .> 2] == [3,4]
end

@testset "copyto!" begin
    a = offset_view{Int}(undef, (-3:-1,))
    fill!(a, -1)
    copyto!(a, (1,2))   # non-array iterables
    @test a[-3] == 1
    @test a[-2] == 2
    @test a[-1] == -1
    fill!(a, -1)
    copyto!(a, -2, (1,2))
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2
    @test_throws BoundsError copyto!(a, 1, (1,2))
    fill!(a, -1)
    copyto!(a, -2, (1,2,3), 2)
    @test a[-3] == -1
    @test a[-2] == 2
    @test a[-1] == 3
    @test_throws BoundsError copyto!(a, -2, (1,2,3), 1)
    fill!(a, -1)
    copyto!(a, -2, (1,2,3), 1, 2)
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2

    b = 1:2    # copy between AbstractArrays
    bo = AxisIndicesArray(offset_view(1:2, (-3,)))
    if VERSION < v"1.5-"
        @test_throws BoundsError copyto!(a, b)
        fill!(a, -1)
        copyto!(a, bo)
        @test a[-3] == -1
        @test a[-2] == 1
        @test a[-1] == 2
    else
        # the behavior of copyto! is corrected as the documentation says "first n element"
        # https://github.com/JuliaLang/julia/pull/34049
        fill!(a, -1)
        copyto!(a, bo)
        @test a[-3] == 1
        @test a[-2] == 2
        @test a[-1] == -1
    end
    fill!(a, -1)
    copyto!(a, -2, bo)
    @test a[-3] == -1
    @test a[-2] == 1
    @test a[-1] == 2
    @test_throws BoundsError copyto!(a, -4, bo)
    @test_throws BoundsError copyto!(a, -1, bo)
    fill!(a, -1)
    copyto!(a, -3, b, 2)
    @test a[-3] == 2
    @test a[-2] == a[-1] == -1
    @test_throws BoundsError copyto!(a, -3, b, 1, 4)
    am = offset_view{Int}(undef, (1:1, 7:9))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, b)
    @test am[1] == 1
    @test am[2] == 2
    @test am[3] == -1
    @test am[1,7] == 1
    @test am[1,8] == 2
    @test am[1,9] == -1
end

#=
@testset "map" begin
    am = AxisIndicesArray(offset_view{Int}(undef, (1:1, 7:9)))  # for testing linear indexing
    fill!(am, -1)
    copyto!(am, 1:2)

    dest = similar(am)
    map!(+, dest, am, am)
    @test dest[1,7] == 2
    @test dest[1,8] == 4
    @test dest[1,9] == -2
end

@testset "reductions" begin
    A = AxisIndicesArray(offset_view(rand(4,4), (-3,5)))
    @test maximum(A) == maximum(parent(A))
    @test minimum(A) == minimum(parent(A))
    @test extrema(A) == extrema(parent(A))
    C = similar(A)
    cumsum!(C, A, dims = 1)
    @test parent(C) == cumsum(parent(A), dims = 1)
    @test parent(cumsum(A, dims = 1)) == cumsum(parent(A), dims = 1)
    cumsum!(C, A, dims = 2)
    @test parent(C) == cumsum(parent(A), dims = 2)
    R = similar(A, (1:1, 6:9))
    maximum!(R, A)
    @test parent(R) == maximum(parent(A), dims = 1)
    R = similar(A, (-2:1, 1:1))
    maximum!(R, A)
    @test parent(R) == maximum(parent(A), dims = 2)
    amin, iamin = findmin(A)
    pmin, ipmin = findmin(parent(A))
    @test amin == pmin
    @test A[iamin] == amin
    @test amin == parent(A)[ipmin]
    amax, iamax = findmax(A)
    pmax, ipmax = findmax(parent(A))
    @test amax == pmax
    @test A[iamax] == amax
    @test amax == parent(A)[ipmax]

    amin, amax = extrema(parent(A))
    @test clamp.(A, (amax+amin)/2, amax) == offset_view(clamp.(parent(A), (amax+amin)/2, amax), axes(A))
end

# v  = offset_view([1,1e100,1,-1e100], (-3,))*1000
# v2 = offset_view([1,-1e100,1,1e100], (5,))*1000
# @test isa(v, offset_view)
# cv  = offset_view([1,1e100,1e100,2], (-3,))*1000
# cv2 = offset_view([1,-1e100,-1e100,2], (5,))*1000
# @test isequal(cumsum_kbn(v), cv)
# @test isequal(cumsum_kbn(v2), cv2)
# @test isequal(sum_kbn(v), sum_kbn(parent(v)))

@testset "Collections" begin
    A = offset_view(rand(4,4), (-3,5))

    @test unique(A, dims=1) == offset_view(parent(A), 0, first(axes(A, 2)) - 1)
    @test unique(A, dims=2) == offset_view(parent(A), first(axes(A, 1)) - 1, 0)
    v = offset_view(rand(8), (-2,))
    @test sort(v) == offset_view(sort(parent(v)), v.offsets)
    @test sortslices(A; dims=1) == offset_view(sortslices(parent(A); dims=1), A.offsets)
    @test sortslices(A; dims=2) == offset_view(sortslices(parent(A); dims=2), A.offsets)
    @test sort(A, dims = 1) == offset_view(sort(parent(A), dims = 1), A.offsets)
    @test sort(A, dims = 2) == offset_view(sort(parent(A), dims = 2), A.offsets)

    @test mapslices(v->sort(v), A, dims = 1) == offset_view(mapslices(v->sort(v), parent(A), dims = 1), A.offsets)
    @test mapslices(v->sort(v), A, dims = 2) == offset_view(mapslices(v->sort(v), parent(A), dims = 2), A.offsets)
end

@testset "rot/reverse" begin
    A = offset_view(rand(4,4), (-3,5))

    @test rotl90(A) == offset_view(rotl90(parent(A)), A.offsets[[2,1]])
    @test rotr90(A) == offset_view(rotr90(parent(A)), A.offsets[[2,1]])
    @test reverse(A, dims = 1) == offset_view(reverse(parent(A), dims = 1), A.offsets)
    @test reverse(A, dims = 2) == offset_view(reverse(parent(A), dims = 2), A.offsets)
end

@testset "fill" begin
    B = fill(5, 1:3, -1:1)
    @test axes(B) == (1:3,-1:1)
    @test all(B.==5)
end

@testset "broadcasting" begin
    A = offset_view(rand(4,4), (-3,5))

    @test A.+1 == offset_view(parent(A).+1, A.offsets)
    @test 2*A == offset_view(2*parent(A), A.offsets)
    @test A+A == offset_view(parent(A)+parent(A), A.offsets)
    @test A.*A == offset_view(parent(A).*parent(A), A.offsets)
end

@testset "@inbounds" begin
    a = offset_view(zeros(7), -3:3)
    unsafe_fill!(x) = @inbounds(for i in axes(x,1); x[i] = i; end)
    function unsafe_sum(x)
        s = zero(eltype(x))
        @inbounds for i in axes(x,1)
            s += x[i]
        end
        s
    end
    unsafe_fill!(a)
    for i = -3:3
        @test a[i] == i
    end
    @test unsafe_sum(a) == 0
end

@testset "Resizing OffsetVectors" begin
    local a = OffsetVector(rand(5),-3)
    axes(a,1) == -2:2
    length(a) == 5
    resize!(a,3)
    length(a) == 3
    axes(a,1) == -2:0
    @test_throws ArgumentError resize!(a,-3)
end

####
#### type defined for testing no_offset_view
####

struct NegativeArray{T,N,S <: AbstractArray{T,N}} <: AbstractArray{T,N}
    parent::S
end

# Note: this defines the axes-of-the-axes to be OneTo.
# In general this isn't recommended, because
#    positionof(A, i, j, ...) == map(getindex, axes(A), (i, j, ...))
# is quite desirable, and this requires that the axes be "identity" ranges, i.e.,
# `r[i] == i`.
# Nevertheless it's useful to test this on a "broken" implementation
# to make sure we still get the right answer.
Base.axes(A::NegativeArray) = map(n -> (-n):(-1), size(A.parent))

Base.size(A::NegativeArray) = size(A.parent)

function Base.getindex(A::NegativeArray{T,N}, I::Vararg{Int,N}) where {T,N}
    getindex(A.parent, (I .+ size(A.parent) .+ 1)...)
end

@testset "no offset view" begin
    # offset_view fallback
    A = randn(3, 3)
    O1 = offset_view(A, -1:1, 0:2)
    O2 = offset_view(O1, -2:0, -3:(-1))
    @test no_offset_view(O2) ≡ A

    # generic fallback
    A = collect(reshape(1:12, 3, 4))
    N = NegativeArray(A)
    @test N[-3, -4] == 1
    V = no_offset_view(N)
    @test collect(V) == A

    # bidirectional
    B = BidirectionalVector([1, 2, 3])
    pushfirst!(B, 0)
    OB = offset_views.no_offset_view(B)
    @test axes(OB, 1) == 1:4
    @test collect(OB) == 0:3
end

@testset "no nesting" begin
    A = randn(2, 3)
    x = A[2, 2]
    O1 = AxisIndicesArray(offset_view(A, -1:0, -1:1))
    O2 = AxisIndicesArray(offset_view(O1, 0:1, 0:2))
    @test parent(O1) ≡ parent(O2)
    @test eltype(O1) ≡ eltype(O2)
    O2[1, 1] = x + 1            # just a sanity check
    @test A[2, 2] == x + 1
end

@testset "mutating functions for OffsetVector" begin
    # push!
    o = AxisIndicesArray(OffsetVector(Int[], -1))
    @test push!(o) === o
    @test axes(o, 1) == 0:-1
    @test push!(o, 1) === o
    @test axes(o, 1) == 0:0
    @test o[end] == 1
    @test push!(o, 2, 3) === o
    @test axes(o, 1) == 0:2
    @test o[end-1:end] == [2, 3]
    # pop!
    o = AxisIndicesArray(OffsetVector([1, 2, 3], -1))
    @test pop!(o) == 3
    @test axes(o, 1) == 0:1
    # empty!
    o = AxisIndicesArray(OffsetVector([1, 2, 3], -1))
    @test empty!(o) === o
    @test axes(o, 1) == 0:-1
end

=#

@testset "iteration" begin
    A0 = [1 3; 2 4]
    A = offset_view(A0, (-1, 2))

    let a
        for (a,d) in zip(A, A0)
            @test a == d
        end
    end
end


=#
