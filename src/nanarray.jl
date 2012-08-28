
# Assumes nf.jl has been loaded

# Should probably restrict this to type
type NAFilter{T<:Float} <: AbstractArray{T} 
    x::Array{T}
end

naFilter{T<:Float}(x::StridedArray{T}) = NAFilter(x)

function sum{T<:Float}(A::NAFilter{T})
    A = A.x
    s = zero(T)
    c = zero(T)
    for x in A
        if ~isnan(x)
            t = s + x
            if abs(s) >= abs(x)
                c += ((s-t) + x)
            else
              c += ((x-t) + s)
            end
        end
        s = t
    end
    s + c
end


# Versions of functions that act on whole Array with no parameters.
function sum{T<:Float}(A::StridedArray{T}, skipna::Bool)
    n = length(A)
    if (n == 0)
        return zero(T)
    end
    s = A[1]
    c = zero(T)
    for i in 2:n
        Ai = A[i]
        if skipna && isnan(Ai)
            continue
        end
        t = s + Ai
        if abs(s) >= abs(Ai)
            c += ((s-t) + Ai)
        else
            c += ((Ai-t) + s)
        end
        s = t
    end
    s + c
end

nansum{T<:Float}(A::StridedArray{T}) = sum(A, true)

function sum{T<:Float}(A::StridedArray{T}, opts::Options)
    @defaults opts skipna = false
    return sum(A, skipna)
end

function prod{T<:Float}(A::StridedArray{T}, skipna::Bool)
    if isempty(A)
        return one(T)
    end
    v = A[1]
    for i=2:numel(A)
        Ai = A[i]
        if skipna && !isnan(Ai)
            v *= Ai
        end
    end
    v
end

function prod{T<:Float}(A::StridedArray{T}, opts::Options)
    @defaults opts skipna = false
    return prod(A, skipna)
end

nanprod{T<:Float}(A::StridedArray{T}) = prod(A, true)

function min{T<:Float}(A::StridedArray{T}, skipna::Bool)
    v = typemax(T)
    for i=1:numel(A)
        Ai = A[i]
        if skipna && isnan(Ai)
            continue
        end
        if x < v
            v = x
        end
    end
    v
end

function min{T<:Float}(A::StridedArray{T}, opts::Options)
    @defaults opts skipna = false
    return min(A, skipna)
end

nanmin{T<:Float}(A::StridedArray{T}) = min(A, true)

function max{T<:Float}(A::StridedArray{T}, skipna::Bool)
    v = typemin(T)
    for i=1:numel(A)
        Ai = A[i]
        if skipna && isnan(Ai)
            continue
        end
        if x > v
            v = x
        end
    end
    v
end

function max{T<:Float}(A::StridedArray{T}, opts::Options)
    @defaults opts skipna = false
    return max(A, skipna)
end

nanmax{T<:Float}(A::StridedArray{T}) = max(A, true)

# Operations that ignore NaN for Floats.  Used for versions of array functions
# that use areduce.
_nanplus{T<:Float}(x::T, y::T) = ((isnan(x) ? zero(T) : x) 
                                  + (isnan(y) ? zero(T) : y))
_nanprod{T<:Float}(x::T, y::T) = ((isnan(x) ? one(T) : x)
                                  * (isnan(y) ? one(T) : y))
_nanmin{T<:Float}(x::T, y::T) = min(isnan(x) ? typemax(T) : x,
                                   isnan(y) ? typemax(T) : y)
_nanmax{T<:Float}(x::T, y::T) = max(isnan(x) ? typemin(T) : x,
                                   isnan(y) ? typemin(T) : y)

# Array functions that allow ignoring NaNs in terms of a reduce.
function sum{T<:Float}(A::StridedArray{T}, region::Dimspec, skipna::Bool)
    if skipna
        areduce(_nanplus, A, region, zero(T))
    else
        sum(A, region)
    end
end

function sum{T<:Float}(A::NAFilter{T}, region::Dimspec)
    areduce(_nanplus, A.x, region, zero(T))
end

function sum{T<:Float}(A::StridedArray{T}, region::Dimspec, opts::Options)
    @defaults opts skipna = false
    return sum(A, region, skipna)
end

nansum{T<:Float}(A::StridedArray{T}, region::Dimspec) = sum(A, region, true)

function prod{T<:Float}(A::StridedArray{T}, region::Dimspec, skipna::Bool)
    if skipna
        areduce(_nanprod, A, region, zero(T))
    else
        prod(A, region)
    end
end

function prod{T<:Float}(A::StridedArray{T}, region::Dimspec, opts::Options)
    @defaults opts skipna = false
    return prod(A, region, skipna)
end

nanprod{T<:Float}(A::StridedArray{T}, region::Dimspec) = prod(A, region, true)

function min{T<:Float}(A::StridedArray{T}, region::Dimspec, skipna::Bool)
  if skipna
      areduce(_nanmin, A, region, typemax(T), T)
  else
      min(A, region)
  end
end

function min{T<:Float}(A::StridedArray{T}, region::Dimspec, opts::Options)
    @defaults opts skipna = false
    return min(A, region, skipna)
end

nanmin{T<:Float}(A::StridedArray{T}, region::Dimspec) = min(A, region, true)

function max{T<:Float}(A::StridedArray{T}, region::Dimspec, skipna::Bool)
  if skipna
      areduce(_nanmax, A, region, typemin(T), T)
  else
      max(A, region)
  end
end

function max{T<:Float}(A::StridedArray{T}, region::Dimspec, opts::Options)
    @defaults opts skipna = false
    return max(A, region, skipna)
end

nanmax{T<:Float}(A::StridedArray{T}, region::Dimspec) = max(A, region, true)
