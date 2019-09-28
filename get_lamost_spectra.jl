using FITSIO
using JLD2
using FileIO
using Interpolations


function download_spectra(obsids::Vector, dir="downloaded_spectra")
    fns = readdir(dir)
    downloaded_obsids = Set([parse(Int, split(fn, '?')[1])
                             for fn in fns if fn[end-6:end] == "?token="])
    s = sum([o in downloaded_obsids for o in obsids])
    println("of $(length(obsids)) spectra, $(length(obsids) - s) need to be downloaded")

    for obsid in obsids
        if !(obsid in downloaded_obsids)
            url = "http://dr4.lamost.org/./spectrum/fits/$(obsid)?token="
            run(`wget -P $(dir) $url`)
        end
    end
end

function load_spectrum(obsid::Integer; dir="downloaded_spectra", interpolate=true, normalize=true)
    hdu = FITS("$(dir)/$(obsid)?token=")[1]
    header = read_header(hdu)
    data = read(hdu)
    wl = data[:, 3] .- data[:, 3].*header["Z"]
    if interpolate
        wl_grid = load("wl_grid.jld2")["wl_grid"]
        flux = (LinearInterpolation(wl, data[:, 1])).(wl_grid)
        ivar = (LinearInterpolation(wl, data[:, 2])).(wl_grid)
        wl = wl_grid
    else
        flux = data[:, 1]
        ivar = data[:, 2]
    end
    if !normalize
        return wl, flux, ivar
    end

    continuum = calculate_continuum(wl, flux, ivar)
    flux ./= continuum
    ivar .*= continuum.^2

    return wl, flux, ivar
end
