# OffsetAxes.jl

Until I write better docs you can think of this package as an extension of AxisIndices's `AbstractAxis` to support offset based indexing.
The only unique types created in this package are subtypes of `AbstractAxis`.
The exported `OffsetArray` is just an alias for `AxisIndicesArray` with all axes being an `OffsetAxis`.

## But why?

Yes this package is redundant with OffsetArrays.jl.
However, it utilizes the traits in AxisIndices.jl to facilitate indexing instead of a combination of custom ranges and array types.
This means that auto-centered arrays are also going to soon be available with minimal code soon.
It also means that if a bug is fixed in AxisIndices.jl that the array should work here too.
In other words, it should result in less code to maintain in the long run and relying on a consistent dependency that will get more attention for bug fixes.
