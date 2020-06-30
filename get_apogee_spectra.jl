using FITSIO
using JLD2
using FileIO
using Interpolations


function readdir_recursively(dir)
    allfiles = String[]
    for (root, dirs, files) in walkdir(dir)
        # global contents # if in REPL
        [push!(allfiles, f) for f in files]
    end
    allfiles
end

genfn(id, APRED_VERS) = "aspcapStar-$APRED_VERS-$id.fits"
genpath(scope, field, id, APRED_VERS) = joinpath(scope, field, genfn(id, APRED_VERS))

download_apogee_spectra(df::DataFrame; kwargs...) = download_apogee_spectra(df.TELESCOPE, df.FIELD, df.APOGEE_ID; kwargs...)
function download_apogee_spectra(scopes, fields, ids;
                          dir="APOGEE_spectra", APRED_VERS="r12"
                         ) where I <: Integer
    @assert (nspectra = length(scopes)) == length(fields) == length(ids)
    downloaded = Set(readdir_recursively(dir))

    mask = [!(fn in downloaded) for fn in genfn.(ids, APRED_VERS)]
    s = sum(.! mask)
    println("of $nspectra spectra, $(nspectra - s) need to be downloaded")


    downloaded = map(zip(scopes[mask], fields[mask], ids[mask])) do (scope, field, id)
        url = "https://data.sdss.org/sas/dr16/apogee/spectro/aspcap/$APRED_VERS/l33/" * 
                genpath(scope, field, id, APRED_VERS)
        try
            run(`wget -nv -r -nH --cut-dirs=9 -P $dir $url`)
            true
        catch
            false
        end
    end
    mask[mask] .&= .! downloaded
    .! mask
end

load_apogee_spectrum(row::DataFrameRow; kwargs...) = load_apogee_spectrum(row.TELESCOPE, row.FIELD, row.APOGEE_ID; kwargs...)
load_apogee_spectrum(id; kwargs...) = load_apogee_spectrum(nothing, nothing, id; kwargs...)
function load_apogee_spectrum(scope, field, id; dir="APOGEE_spectra", APRED_VERS="r12", 
                              nested=false)
    if nested
        path = joinpath(dir, genpath(scope, field, id, APRES_VERS))
    else
        path = joinpath(dir, genfn(id, APRED_VERS))
    end
    FITS(path) do hdus
        flux = read(hdus[2]) #"pixel-based" weighting
        err = read(hdus[3])
        return flux, err
    end
end
