setlims(extent...) = setlims(extent)
function setlims(extent)
    plt.xlim(extent[1:2]...)
    plt.ylim(extent[3:4]...)
end

setlabs(sx::Symbol, sy::Symbol) = setlabs(hrname(sx), hrname(sy))
setlabs(sx::Symbol, sy::AbstractString) = setlabs(hrname(sx), sy)
setlabs(sx::AbstractString, sy::Symbol) = setlabs(sx, hrname(sy))
function setlabs(sx::AbstractString, sy::AbstractString)
    plt.xlabel(sx)
    plt.ylabel(sy)
end
