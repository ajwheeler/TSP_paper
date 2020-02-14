using FITSIO
import DataFrames
using PyCall
Table = pyimport("astropy.table").Table

function fitsdf(fn::String, hdu::Int=2; cols=nothing)
    FITS(fn) do hdus
        DataFrame(hdus[hdu], cols=cols)
    end
end
function DataFrames.DataFrame(hdu::TableHDU; cols=nothing) :: DataFrame
    df = DataFrame()
    collist = cols == nothing ? FITSIO.colnames(hdu) : cols
    for col in collist
        c = read(hdu, col)
        #println(size(collect(eachcol(c))))
        #df[!, Symbol(col)] = collect(eachcol(c))
        if length(size(c)) == 1
            df[!, Symbol(col)] = c
        else
            df[!, Symbol(col)] = collect(eachcol(c))
        end
    end
    df
end

function write_to_fits(fn::String, df::DataFrame)
    t = Table([df[!, name] for name in names(df)], names=names(df))
    t.write(fn, overwrite=true)
end
