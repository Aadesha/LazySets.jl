import Base.LinAlg:norm,
       Base.∈

export Hyperrectangle,
       vertices_list,
       norm,
       radius,
       diameter,
       low,
       high,
       ∈

"""
    Hyperrectangle{N<:Real} <: LazySet

Type that represents a hyperrectangle.

A [hyperrectangle](https://en.wikipedia.org/wiki/Hyperrectangle) is the
Cartesian product of one-dimensional intervals.

### Fields

- `center` -- center of the hyperrectangle as a real vector
- `radius` -- radius of the ball as a real vector, i.e., half of its width along
              each coordinate direction
"""
struct Hyperrectangle{N<:Real} <: LazySet
    center::Vector{N}
    radius::Vector{N}

    # default constructor with length comparison
    Hyperrectangle{N}(center::Vector{N}, radius::Vector{N}) where {N<:Real} =
        (length(center) != length(radius)
            ? throw(DimensionMismatch)
            : new(center, radius))
end
# type-less convenience constructor
Hyperrectangle(center::Vector{N}, radius::Vector{N}) where {N<:Real} =
    Hyperrectangle{N}(center, radius)

"""
    Hyperrectangle(;kwargs...)

Construct a hyperrectangle from keyword arguments.

### Input

- `kwargs` -- keyword arguments; two combinations are allowed:
  1. `center`, `radius` -- vectors
  2. `high`, `low`      -- vectors (if both `center` and `radius` are also
                           defined, those are chosen instead)

### Output

A hyperrectangle.

### Examples

The following three constructions are equivalent:

```jldoctest
julia> c = ones(2);

julia> r = [0.1, 0.2];

julia> l = [0.9, 0.8];

julia> h = [1.1, 1.2];

julia> H1 = Hyperrectangle(c, r)
LazySets.Hyperrectangle{Float64}([1.0, 1.0], [0.1, 0.2])
julia> H2 = Hyperrectangle(center=c, radius=r)
LazySets.Hyperrectangle{Float64}([1.0, 1.0], [0.1, 0.2])
julia> H3 = Hyperrectangle(low=l, high=h)
LazySets.Hyperrectangle{Float64}([1.0, 1.0], [0.1, 0.2])
```
"""
function Hyperrectangle(;kwargs...)
    dict = Dict{Symbol, Any}(kwargs)
    if haskey(dict, :center) && haskey(dict, :radius)
        return Hyperrectangle{eltype(dict[:center])}(dict[:center],
                                                     dict[:radius])
    elseif haskey(dict, :high) && haskey(dict, :low)
        # compute center and radius from high and low vectors
        center = (dict[:high] .+ dict[:low]) ./ 2
        radius = abs.(dict[:high] .- center)
        return Hyperrectangle{eltype(center)}(center, radius)
    end
    throw(ArgumentError("invalid arguments for Hyperrectangle: Use either " *
        "'center' and 'radius' or 'high' and 'low'."))
end

"""
    dim(H::Hyperrectangle)::Int

Return the dimension of a hyperrectangle.

### Input

- `H` -- hyperrectangle

### Output

The ambient dimension of the hyperrectangle.
"""
function dim(H::Hyperrectangle)::Int
    return length(H.center)
end

"""
    σ(d::AbstractVector{<:Real}, H::Hyperrectangle)::AbstractVector{<:Real}

Return the support vector of a hyperrectangle in a given direction.

### Input

- `d` -- direction
- `H` -- hyperrectangle

### Output

The support vector in the given direction.
If the direction has norm zero, the vertex with biggest values is returned.
"""
function σ(d::AbstractVector{<:Real}, H::Hyperrectangle)::AbstractVector{<:Real}
    return @. H.center + sign_cadlag(d) * H.radius
end

"""
    vertices_list(H::Hyperrectangle{N})::Vector{Vector{N}} where {N<:Real}

Return the vertices of a hyperrectangle.

### Input

- `H` -- hyperrectangle

### Output

A list of vertices.

### Notes

For high dimensions, it is preferable to develop a `vertex_iterator` approach.
"""
function vertices_list(H::Hyperrectangle{N})::Vector{Vector{N}} where {N<:Real}
    return [H.center .+ si .* H.radius
        for si in IterTools.product([[1, -1] for i = 1:dim(H)]...)]
end

"""
    norm(H::Hyperrectangle, [p]::Real=Inf)::Real

Return the norm of a hyperrectangle.

### Input

- `H` -- hyperrectangle
- `p` -- (optional, default: `Inf`) norm

### Output

A real number representing the norm.

### Notes

The norm of a hyperrectangle is defined as the norm of the enclosing ball, of
the given ``p``-norm, of minimal volume.
"""
function norm(H::Hyperrectangle, p::Real=Inf)::Real
    return maximum(map(x -> norm(x, p), vertices_list(H)))
end

"""
    radius(H::Hyperrectangle, [p]::Real=Inf)::Real

Return the radius of a hyperrectangle.

### Input

- `H` -- hyperrectangle
- `p` -- (optional, default: `Inf`) norm

### Output

A real number representing the radius.

### Notes

The radius is defined as the radius of the enclosing ball of the given
``p``-norm of minimal volume with the same center.
"""
function radius(H::Hyperrectangle, p::Real=Inf)::Real
    # the radius is the same for all corners of the hyperrectangle
    return norm(H.radius, p)
end

"""
    diameter(H::Hyperrectangle, [p]::Real=Inf)::Real

Return the diameter of a hyperrectangle.

### Input

- `H` -- hyperrectangle
- `p` -- (optional, default: `Inf`) norm

### Output

A real number representing the diameter.

### Notes

The diameter is defined as the maximum distance in the given ``p``-norm between
any two elements of the set.
Equivalently, it is the diameter of the enclosing ball of the given ``p``-norm
of minimal volume with the same center.
"""
function diameter(H::Hyperrectangle, p::Real=Inf)::Real
    return radius(H, p) * 2
end

"""
    high(H::Hyperrectangle{N})::Vector{N} where {N<:Real}

Return the higher coordinates of a hyperrectangle.

### Input

- `H` -- hyperrectangle

### Output

A vector with the higher coordinates of the hyperrectangle, one entry per
dimension.
"""
function high(H::Hyperrectangle{N})::Vector{N} where {N<:Real}
    return H.center .+ H.radius
end

"""
    low(H::Hyperrectangle{N})::Vector{N} where {N<:Real}

Return the lower coordinates of a hyperrectangle.

### Input

- `H` -- hyperrectangle

### Output

A vector with the lower coordinates of the hyperrectangle, one entry per
dimension.
"""
function low(H::Hyperrectangle{N})::Vector{N} where {N<:Real}
    return H.center .- H.radius
end

"""
    ∈(x::AbstractVector{N}, H::Hyperrectangle{N})::Bool where {N<:Real}

Check whether a given point is contained in a hyperrectangle.

### Input

- `x` -- point/vector
- `H` -- hyperrectangle

### Output

`true` iff ``x ∈ H``.

### Algorithm

Let ``H`` be an ``n``-dimensional hyperrectangle, ``c_i`` and ``r_i`` be
the ball's center and radius and ``x_i`` be the vector ``x`` in dimension ``i``,
respectively.
Then ``x ∈ H`` iff ``|c_i - x_i| ≤ r_i`` for all ``i=1,…,n``.

### Examples

```jldoctest
julia> H = Hyperrectangle([1.0, 1.0], [2.0, 3.0]);

julia> ∈([-1.1, 4.1], H)
false
julia> ∈([-1.0, 4.0], H)
true
```
"""
function ∈(x::AbstractVector{N}, H::Hyperrectangle{N})::Bool where {N<:Real}
    @assert length(x) == dim(H)
    for i in eachindex(x)
        if abs(H.center[i] - x[i]) > H.radius[i]
            return false
        end
    end
    return true
end