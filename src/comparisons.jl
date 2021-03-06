# This file is inspired from Polyhedra.jl

const ABSZTOL(N::Type{<:AbstractFloat}) = N(10) * sqrt(eps(N))
const ABSZTOL(N::Type{Rational{INNER}}) where {INNER} = zero(N)

"""
    _leq(x::N, y::N; [kwargs...]) where {N<:Real}

Determine if `x` is smaller than or equal to `y`.

### Input

- `x`      -- number
- `y`      -- another number (of the same numeric type as `x`)
- `kwargs` -- not used

### Output

A boolean that is `true` iff `x <= y`.

### Algorithm

This is a fallback implementation for numbers of type `Real`. If the arguments
are floating point numbers, see `_leq(x::AbstractFloat, y::AbstractFloat)`.
"""
_leq(x::N, y::N; kwargs...) where {N<:Real} = x <= y

"""
    _leq(x::N, y::M; [kwargs...]) where {N<:Real, M<:Real}

Determine if `x` is smaller than or equal to `y`.

### Input

- `x`      -- number
- `y`      -- another number (of possibly different numeric type than `x`)
- `kwargs` -- optional arguments; see `?_leq` for the available options 

### Output

A boolean that is `true` iff `x <= y`.

### Algorithm

This implementation calls Julia's `promote(x, y)` function, which converts all
arguments to a common numeric type, returning them as a tuple. The conversion
is such that the common type to which the values are converted can represent
them as faithfully as possible.
"""
_leq(x::N, y::M; kwargs...) where {N<:Real, M<:Real} =
    _leq(promote(x, y)...; kwargs...)

"""
    _geq(x::Real, y::Real; [kwargs...])

Determine if `x` is greater than or equal to `y`.

### Input

- `x` -- number
- `y` -- another number (of possibly different numeric type than `x`)

### Output

A boolean that is `true` iff `x >= y`.

### Algorithm

This function falls back to `_leq(y, x)`, with type promotion if needed. See the
documentation of `_leq` for further details.
"""
_geq(x::Real, y::Real; kwargs...) = _leq(y, x; kwargs...)

"""
    isapproxzero(x::N; ztol::Real=ABSZTOL(N)) where {N<:Real}

Determine if `x` is approximately zero.

### Input

- `x`    -- number
- `ztol` -- (optional, default: `ABSZTOL`) tolerance against zero

### Output

A boolean that is `true` iff `x ≈ 0`.

### Algorithm

It is considered that `x ≈ 0` whenever `x` (in absolute value) is smaller than
the tolerance for zero, `ztol`.
"""
function isapproxzero(x::N; ztol::Real=ABSZTOL(N)) where {N<:Real}
    return abs(x) <= ztol
end

"""
    _isapprox(x::N, y::N;
              rtol::Real=Base.rtoldefault(N),
              ztol::Real=ABSZTOL(N),
              atol::Real=zero(N)) where {N<:Real}

Determine if `x` is approximately equal to `y`.

### Input

- `x`    -- number
- `y`    -- another number (of the same numeric type as `x`)
- `rtol` -- (optional, default: `Base.rtoldefault(N)`) relative tolerance
- `ztol` -- (optional, default: `ABSZTOL(N)`) absolute tolerance for comparison
            against zero
- `atol` -- (optional, default: `zero(N)`) absolute tolerance

### Output

A boolean that is `true` iff `x ≈ y`.

### Algorithm

We first check if `x` and `y` are both approximately zero, using
`isapproxzero(x, y)`.
If that fails, we check if `x ≈ y`, using Julia's `isapprox(x, y)`.
In the latter check we use `atol` absolute tolerance and `rtol` relative
tolerance.

Comparing to zero with default tolerances is a special case in Julia's
`isapprox`, see the last paragraph in `?isapprox`. This function tries to
combine `isapprox` with its default values and a branch for `x ≈ y ≈ 0` which
includes `x == y == 0` but also admits a tolerance `ztol`.

Note that if `x = ztol` and `y = -ztol`, then `|x-y| = 2*ztol` and still
`_isapprox` returns `true`.
"""
function _isapprox(x::N, y::N;
                   rtol::Real=Base.rtoldefault(N),
                   ztol::Real=ABSZTOL(N),
                   atol::Real=zero(N)) where {N<:Real}
    if isapproxzero(x, ztol=ztol) && isapproxzero(y, ztol=ztol)
        return true
    else
        return isapprox(x, y, rtol=rtol, atol=atol)
    end
end

"""
    _leq(x::N, y::N;
         rtol::Real=Base.rtoldefault(N),
         ztol::Real=ABSZTOL(N),
         atol::Real=zero(N)) where {N<:AbstractFloat}

Determine if `x` is smaller than or equal to `y`.

### Input

- `x`    -- number
- `y`    -- another number (of the same numeric type as `x`)
- `rtol` -- (optional, default: `Base.rtoldefault(N)`) relative tolerance
- `ztol` -- (optional, default: `ABSZTOL(N)`) absolute tolerance for comparison
            against zero
- `atol` -- absolute tolerance

### Output

A boolean that is `true` iff `x <= y`.

### Algorithm

The `x <= y` comparison is split into `x < y` or `x ≈ y`; the latter is
implemented by extending Juila's built-in `isapprox(x, y)` with an absolute
tolerance that is used to compare against zero.
"""
function _leq(x::N, y::N;
              rtol::Real=Base.rtoldefault(N),
              ztol::Real=ABSZTOL(N),
              atol::Real=zero(N)) where {N<:AbstractFloat}
    return x <= y || _isapprox(x, y, rtol=rtol, ztol=ztol, atol=atol)
end
