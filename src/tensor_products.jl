# dcontract, dot, tdot, otimes, cross
"""
    dcontract(::SecondOrderTensor, ::SecondOrderTensor)
    dcontract(::SecondOrderTensor, ::FourthOrderTensor)
    dcontract(::FourthOrderTensor, ::SecondOrderTensor)
    dcontract(::FourthOrderTensor, ::FourthOrderTensor)

Compute the double contraction between two tensors.
The symbol `⊡`, written `\\boxdot`, is overloaded for double contraction.
The reason `:` is not used is because it does not have the same precedence as multiplication.

# Examples
```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> dcontract(A,B)
1.9732018397544984

julia> A ⊡ B
1.9732018397544984
```
"""
@generated function dcontract(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    ex1 = Expr[:(get_data(S1)[$(idxS1(i, j))]) for i in 1:dim, j in 1:dim][:]
    ex2 = Expr[:(get_data(S2)[$(idxS2(i, j))]) for i in 1:dim, j in 1:dim][:]
    exp = reducer(ex1, ex2)
    return quote
        $(Expr(:meta, :inline))
        @inbounds return $exp
    end
end

@generated function dcontract(S1::SecondOrderTensor{dim}, S2::FourthOrderTensor{dim}) where {dim}
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j, k, l) = compute_index(get_base(S2), i, j, k, l)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, j))])       for i in 1:dim, j in 1:dim][:]
        ex2 = Expr[:(get_data(S2)[$(idxS2(i, j, k, l))]) for i in 1:dim, j in 1:dim][:]
        push!(exps.args, reducer(ex1, ex2, true))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

@generated function dcontract(S1::FourthOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j, k, l) = compute_index(get_base(S1), i, j, k, l)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for j in 1:dim, i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, j, k, l))]) for k in 1:dim, l in 1:dim][:]
        ex2 = Expr[:(get_data(S2)[$(idxS2(k, l))])       for k in 1:dim, l in 1:dim][:]
        push!(exps.args, reducer(ex1, ex2, true))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

@generated function dcontract(S1::FourthOrderTensor{dim}, S2::FourthOrderTensor{dim}) where {dim}
    TensorType = getreturntype(dcontract, get_base(S1), get_base(S2))
    idxS1(i, j, k, l) = compute_index(get_base(S1), i, j, k, l)
    idxS2(i, j, k, l) = compute_index(get_base(S2), i, j, k, l)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim, j in 1:dim, i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, j, m, n))]) for m in 1:dim, n in 1:dim][:]
        ex2 = Expr[:(get_data(S2)[$(idxS2(m, n, k, l))]) for m in 1:dim, n in 1:dim][:]
        push!(exps.args, reducer(ex1, ex2, true))
    end
    expr = remove_duplicates(TensorType, exps)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $TensorType($expr)
    end
end

const ⊡ = dcontract

"""
    otimes(::Vec, ::Vec)
    otimes(::SecondOrderTensor, ::SecondOrderTensor)

Compute the open product between two tensors.
The symbol `⊗`, written `\\otimes`, is overloaded for tensor products.

# Examples
```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> A ⊗ B
2×2×2×2 SymmetricTensor{4, 2, Float64, 9}:
[:, :, 1, 1] =
 0.271839  0.352792
 0.352792  0.260518

[:, :, 2, 1] =
 0.469146  0.608857
 0.608857  0.449607

[:, :, 1, 2] =
 0.469146  0.608857
 0.608857  0.449607

[:, :, 2, 2] =
 0.504668  0.654957
 0.654957  0.48365
```
"""
@inline function otimes(S1::Vec{dim}, S2::Vec{dim}) where {dim}
    return Tensor{2, dim}(@inline function(i,j) @inbounds S1[i] * S2[j]; end)
end

@inline function otimes(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    TensorType = getreturntype(otimes, get_base(typeof(S1)), get_base(typeof(S2)))
    TensorType(@inline function(i,j,k,l) @inbounds S1[i,j] * S2[k,l]; end)
end

@inline otimes(S1::Number, S2::Number) = S1*S2
@inline otimes(S1::AbstractTensor, S2::Number) = S1*S2
@inline otimes(S1::Number, S2::AbstractTensor) = S1*S2

const ⊗ = otimes

"""
    otimes(::Vec)

Compute the open product of a vector with itself.
Return a `SymmetricTensor`.

# Examples
```jldoctest
julia> A = rand(Vec{2})
2-element Vec{2, Float64}:
 0.5908446386657102
 0.7667970365022592

julia> otimes(A)
2×2 SymmetricTensor{2, 2, Float64, 3}:
 0.349097  0.453058
 0.453058  0.587978
```
"""
@inline function otimes(S::Vec{dim}) where {dim}
    return SymmetricTensor{2, dim}(@inline function(i,j) @inbounds S[i] * S[j]; end)
end

"""
    otimesu(::SecondOrderTensor, ::SecondOrderTensor)

Compute the "upper" open product between two tensors.

# Examples
```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> otimesu(A, B)
2×2×2×2 Tensor{4, 2, Float64, 16}:
[:, :, 1, 1] =
 0.271839  0.469146
 0.352792  0.608857

[:, :, 2, 1] =
 0.352792  0.608857
 0.260518  0.449607

[:, :, 1, 2] =
 0.469146  0.504668
 0.608857  0.654957

[:, :, 2, 2] =
 0.608857  0.654957
 0.449607  0.48365
```
"""
@inline function otimesu(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    S1_ = convert(Tensor, S1) # Convert to full tensor if symmetric to make 10x faster... (see Tensors.jl#164)
    S2_ = convert(Tensor, S2)
    return Tensor{4, dim}((i,j,k,l) -> S1_[i,k] * S2_[j,l])
end

"""
    otimesl(::SecondOrderTensor, ::SecondOrderTensor)

Compute the "lower" open product between two tensors.

# Examples
```jldoctest
julia> A = rand(SymmetricTensor{2, 2});

julia> B = rand(SymmetricTensor{2, 2});

julia> otimesl(A, B)
2×2×2×2 Tensor{4, 2, Float64, 16}:
[:, :, 1, 1] =
 0.271839  0.469146
 0.352792  0.608857

[:, :, 2, 1] =
 0.469146  0.504668
 0.608857  0.654957

[:, :, 1, 2] =
 0.352792  0.608857
 0.260518  0.449607

[:, :, 2, 2] =
 0.608857  0.654957
 0.449607  0.48365
```
"""
@inline function otimesl(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    S1_ = convert(Tensor, S1) # Convert to full tensor if symmetric to make 10x faster... (see Tensors.jl#164)
    S2_ = convert(Tensor, S2)
    return Tensor{4, dim}((i,j,k,l) -> S1_[i,l] * S2_[j,k])
end

"""
    dot(::Vec, ::Vec)
    dot(::Vec, ::SecondOrderTensor)
    dot(::SecondOrderTensor, ::Vec)
    dot(::SecondOrderTensor, ::SecondOrderTensor)

Computes the dot product (single contraction) between two tensors.
The symbol `⋅`, written `\\cdot`, is overloaded for single contraction.

# Examples
```jldoctest
julia> A = rand(Tensor{2, 2})
2×2 Tensor{2, 2, Float64, 4}:
 0.590845  0.566237
 0.766797  0.460085

julia> B = rand(Tensor{1, 2})
2-element Vec{2, Float64}:
 0.7940257103317943
 0.8541465903790502

julia> dot(A, B)
2-element Vec{2, Float64}:
 0.9527955925660736
 1.0018368881367576

julia> A ⋅ B
2-element Vec{2, Float64}:
 0.9527955925660736
 1.0018368881367576
```
"""
@generated function LinearAlgebra.dot(S1::Vec{dim}, S2::Vec{dim}) where {dim}
    ex1 = Expr[:(get_data(S1)[$i]) for i in 1:dim]
    ex2 = Expr[:(get_data(S2)[$i]) for i in 1:dim]
    exp = reducer(ex1, ex2)
    quote
        $(Expr(:meta, :inline))
        @inbounds return $exp
    end
end

@generated function LinearAlgebra.dot(S1::SecondOrderTensor{dim}, S2::Vec{dim}) where {dim}
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    exps = Expr(:tuple)
    for i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, j))]) for j in 1:dim]
        ex2 = Expr[:(get_data(S2)[$j])             for j in 1:dim]
        push!(exps.args, reducer(ex1, ex2))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Vec{dim}($exps)
    end
end

@generated function LinearAlgebra.dot(S1::Vec{dim}, S2::SecondOrderTensor{dim}) where {dim}
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for j in 1:dim
        ex1 = Expr[:(get_data(S1)[$i])             for i in 1:dim]
        ex2 = Expr[:(get_data(S2)[$(idxS2(i, j))]) for i in 1:dim]
        push!(exps.args, reducer(ex1, ex2))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Vec{dim}($exps)
    end
end

@generated function LinearAlgebra.dot(S1::SecondOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for j in 1:dim, i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, k))]) for k in 1:dim]
        ex2 = Expr[:(get_data(S2)[$(idxS2(k, j))]) for k in 1:dim]
        push!(exps.args, reducer(ex1, ex2))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Tensor{2, dim}($exps)
    end
end

@generated function LinearAlgebra.dot(S1::FourthOrderTensor{dim}, S2::SecondOrderTensor{dim}) where {dim}
    idxS1(i, j, k, l) = compute_index(get_base(S1), i, j, k, l)
    idxS2(i, j) = compute_index(get_base(S2), i, j)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim, j in 1:dim, i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, j, k, m))]) for m in 1:dim]
        ex2 = Expr[:(get_data(S2)[$(idxS2(m, l))]) for m in 1:dim]
        push!(exps.args, reducer(ex1, ex2))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Tensor{4, dim}($exps)
    end
end

@generated function LinearAlgebra.dot(S1::SecondOrderTensor{dim}, S2::FourthOrderTensor{dim}) where {dim}
    idxS1(i, j) = compute_index(get_base(S1), i, j)
    idxS2(i, j, k, l) = compute_index(get_base(S2), i, j, k, l)
    exps = Expr(:tuple)
    for l in 1:dim, k in 1:dim, j in 1:dim, i in 1:dim
        ex1 = Expr[:(get_data(S1)[$(idxS1(i, m))]) for m in 1:dim]
        ex2 = Expr[:(get_data(S2)[$(idxS2(m, j, k, l))]) for m in 1:dim]
        push!(exps.args, reducer(ex1, ex2))
    end
    quote
        $(Expr(:meta, :inline))
        @inbounds return Tensor{4, dim}($exps)
    end
end

"""
    dot(::SymmetricTensor{2})

Compute the dot product of a symmetric second order tensor with itself.
Return a `SymmetricTensor`.

See also [`tdot`](@ref) and [`dott`](@ref).

# Examples
```jldoctest
julia> A = rand(SymmetricTensor{2,3})
3×3 SymmetricTensor{2, 3, Float64, 6}:
 0.590845  0.766797  0.566237
 0.766797  0.460085  0.794026
 0.566237  0.794026  0.854147

julia> dot(A)
3×3 SymmetricTensor{2, 3, Float64, 6}:
 1.2577   1.25546  1.42706
 1.25546  1.43013  1.47772
 1.42706  1.47772  1.68067
```
"""
@inline LinearAlgebra.dot(S::SymmetricTensor{2}) = tdot(S)

"""
    tdot(A::SecondOrderTensor)

Compute the transpose-dot product of `A` with itself, i.e. `dot(A', A)`.
Return a `SymmetricTensor`.

# Examples
```jldoctest
julia> A = rand(Tensor{2,3})
3×3 Tensor{2, 3, Float64, 9}:
 0.590845  0.460085  0.200586
 0.766797  0.794026  0.298614
 0.566237  0.854147  0.246837

julia> tdot(A)
3×3 SymmetricTensor{2, 3, Float64, 6}:
 1.2577   1.36435   0.48726
 1.36435  1.57172   0.540229
 0.48726  0.540229  0.190334
```
"""
@inline tdot(S::SecondOrderTensor) = unsafe_symmetric(S' ⋅ S)

"""
    dott(A::SecondOrderTensor)

Compute the dot-transpose product of `A` with itself, i.e. `dot(A, A')`.
Return a `SymmetricTensor`.

# Examples
```jldoctest
julia> A = rand(Tensor{2,3})
3×3 Tensor{2, 3, Float64, 9}:
 0.590845  0.460085  0.200586
 0.766797  0.794026  0.298614
 0.566237  0.854147  0.246837

julia> dott(A)
3×3 SymmetricTensor{2, 3, Float64, 6}:
 0.601011  0.878275  0.777051
 0.878275  1.30763   1.18611
 0.777051  1.18611   1.11112
```
"""
@inline dott(S::SecondOrderTensor) = unsafe_symmetric(S ⋅ S')

"""
    cross(::Vec, ::Vec)

Computes the cross product between two `Vec` vectors, returns a `Vec{3}`. For dimensions 1 and 2 the `Vec`'s
are expanded to 3D first. The infix operator `×` (written `\\times`) can also be used.

# Examples
```jldoctest
julia> a = rand(Vec{3})
3-element Vec{3, Float64}:
 0.5908446386657102
 0.7667970365022592
 0.5662374165061859

julia> b = rand(Vec{3})
3-element Vec{3, Float64}:
 0.4600853424625171
 0.7940257103317943
 0.8541465903790502

julia> a × b
3-element Vec{3, Float64}:
  0.20535000738340053
 -0.24415039787171888
  0.11635375677388776
```
"""
@inline LinearAlgebra.cross(u::Vec{3}, v::Vec{3}) = @inbounds Vec{3}((u[2]*v[3] - u[3]*v[2], u[3]*v[1] - u[1]*v[3], u[1]*v[2] - u[2]*v[1]))
@inline LinearAlgebra.cross(u::Vec{2,T1}, v::Vec{2,T2}) where {T1,T2} = @inbounds Vec{3}((zero(T1)*zero(T2), zero(T1)*zero(T2), u[1]*v[2] - u[2]*v[1]))
@inline LinearAlgebra.cross( ::Vec{1,T1}, ::Vec{1,T2}) where {T1,T2} = @inbounds zero(Vec{3,promote_type(T1,T2)})
