
# Assumes nf.jl has been loaded

# Should probably restrict this to type
type NAFilter{T<:Float,N}
    x::Array{T,N}
end
show(io, naf::NAFilter) = show(naf.x)

naFilter{T<:Float,N}(x::AbstractArray{T,N}) = NAFilter(x)

function sum{T<:Float}(A::NAFilter{T})
    A = A.x
    s = zero(T)
    c = zero(T)
    for x in A
        if !isnan(x)
            t = s + x
            if abs(s) >= abs(x)
                c += ((s-t) + x)
            else
                c += ((x-t) + s)
            end
            s = t
        end
    end
    s + c
end

function prod{T<:Float}(A::NAFilter{T})
    A = A.x
    if isempty(A)
        return one(T)
    end
    v = one(T)
    for x in A
        if !isnan(x)
            v *= x
        end
    end
    v
end

function min{T<:Float}(A::NAFilter{T})
    A = A.x
    v = typemax(T)
    for x in A
        if !isnan(x) && x < v
            v = x
        end
    end
    v
end

function max{T<:Float}(A::NAFilter{T})
    A = A.x
    v = typemin(T)
    for x in A
        if !isnan(x) && x > v
            v = x
        end
    end
    v
end

function nancount{T<:Float}(A::AbstractArray{T})
    nn = 0
    for x in A
        if isnan(x)
            nn += 1
        end
    end
    nn
end

# Operations that ignore NaN for Floats.  Used for versions of array functions
# that use areduce.
#_nanplus{T<:Float}(x::T, y::T) = (x + (isnan(y) ? zero(T) : y))
#_nanprod{T<:Float}(x::T, y::T) = (x * (isnan(y) ? one(T) : y))
#_nanmin{T<:Float}(x::T, y::T) = min(x, isnan(y) ? typemax(T) : y)
#_nanmax{T<:Float}(x::T, y::T) = max(x, isnan(y) ? typemin(T) : y)
#_nanaccum{T<:Int,S<:Float}(x::T, y::S) = (x + (isnan(y) ? one(T) : zero(T)))
_nanplus{T<:Float}(x::T, y::T) = (x + ((y != y) ? zero(T) : y))
_nanprod{T<:Float}(x::T, y::T) = (x * ((y != y) ? one(T) : y))
_nanmin{T<:Float}(x::T, y::T) = min(x, (y != y) ? typemax(T) : y)
_nanmax{T<:Float}(x::T, y::T) = max(x, (y != y) ? typemin(T) : y)
_nanaccum{T<:Int,S<:Float}(x::T, y::S) = (x + ((y != y) ? one(T) : zero(T)))

# Tried with AbstractArray also
function nancount{T<:Float}(A::AbstractArray{T}, region::Dimspec)
    areduce(_nanaccum, A, region, zero(Int64), Int64)
end

# Array functions that allow ignoring NaNs in terms of a reduce.
function sum{T<:Float}(A::NAFilter{T}, region::Dimspec)
    areduce(_nanplus, A.x, region, zero(T), T)
end

function prod{T<:Float}(A::NAFilter{T}, region::Dimspec)
    areduce(_nanprod, A.x, region, one(T), T)
end

function min{T<:Float}(A::NAFilter{T}, region::Dimspec)
    #areduce(_nanmin, A.x, region, typemax(T), T)
    areduce(_nanmin, A.x, region, typemax(T), T)
end

function max{T<:Float}(A::NAFilter{T}, region::Dimspec)
    #areduce(_nanmax, A, region, typemin(T), T)
    areduce(_nanmax, A, region, typemin(T), T)
end
