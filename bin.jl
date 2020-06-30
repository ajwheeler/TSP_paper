struct Bins
    boundaries::Vector{StepRangeLen}
    counts::Array
end

function Bins(boundaries)
    @assert all([reduce(<, b) for b in boundaries])
    dim = length(boundaries)
    Bins(boundaries, zeros(Int, [length(b)-1 for b in boundaries]...))
end

#why doesn't this work?
function Base.show(b::Bins)
    print("Bins(")
    for b in b.boundaries[1:end-1]
        show(b)
        print(", ")
    end
    show(b.bins[end])
    print(")")
end

function whichbin(b::Bins, v)
    map(zip(b.boundaries, v)) do (bounds, el)
        Int(floor((el - first(bounds)) / (last(bounds) - first(bounds)) * (length(bounds) - 1) + 1))
    end
end

function Base.getindex(b::Bins, v)
    bin = whichbin(b, v)
    if all(1 .<= collect(bin) .< length.(b.boundaries))
        getindex(b.counts, whichbin(b, v)...)
    else
        NaN
    end
end
Base.getindex(b::Bins, v...) = b[v]

function Base.setindex!(b::Bins, val, v)
    bin = whichbin(b, v)
    if all(1 .<= collect(bin) .< length.(b.boundaries))
        setindex!(b.counts, val, whichbin(b, v)...)
        true
    end
    false
end
Base.setindex!(b::Bins, val, v...) = Base.setindex!(b, val, v)

function histogram(boundaries, data)
    b = Bins(boundaries)
    for row in eachrow(data)
        b[row] += 1
    end
    b
end

