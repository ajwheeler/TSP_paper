using FITSIO
using JLD2
using FileIO
using Interpolations

function gen_filename(res, apid)
    filename = "aspcapStar-r8-$res-$apid.fits"
end

function download_spectra(df::DataFrame; dir="downloaded_spectra") 
    download_spectra(df.aspcap_version, df.results_version, df.location_id, 
                     df.apogee_id, dir=dir)
end
function download_spectra(aspcap_versions::Vector{String}, results_versions::Vector{String},
                          locids::Vector{I}, apids::Vector{String};
                          dir="downloaded_spectra") where I <: Integer
    @assert (nspectra = length(aspcap_versions)) == length(results_versions) == 
            length(locids) == length(apids)
    downloaded = Set(readdir(dir))

    s = sum([fn in downloaded for fn in gen_filename.(results_versions, apids)])
    println("of $nspectra spectra, $(nspectra - s) need to be downloaded")

    for (asp, res, loc, apid) in zip(aspcap_versions, results_versions, locids, apids)
        if !(gen_filename(res, apid) in downloaded)
            filename = "aspcapStar-r8-$res-$apid.fits"
            url = "https://data.sdss.org/sas/dr14/apogee/spectro/redux/r8/" *
                   "stars/$asp/$res/$loc/$filename"
            run(`wget -nv -P $(dir) $url`) 
        end
    end
end

function load_spectrum(row::DataFrameRow; dir="downloaded_spectra") 
    load_spectrum(row.results_version, row.apogee_id, dir=dir)
end
function load_spectrum(res, apid; dir="downloaded_spectra")
    FITS("$dir/$(gen_filename(res, apid))") do hdus
        flux = read(hdus[2])[:, 1] #"pixel-based" weighting
        err = read(hdus[3])[:, 1]
        return flux, err
    end
end
