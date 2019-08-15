using FITSIO
import DataFrames

function DataFrames.DataFrame(hdu::TableHDU; cols=nothing) :: DataFrame
    df = DataFrame()
    collist = cols == nothing ? FITSIO.colnames(hdu) : cols
    for col in collist
        c = read(hdu, col)
        if length(size(c)) == 1
            df[!, Symbol(col)] = read(hdu, col)
        end
    end
    df
end
