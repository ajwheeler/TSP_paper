using FITSIO
using JLD2
using FileIO
using Interpolations
using Statistics: mean

function download_lamost_spectra(obsids::Vector, dir="LAMOST_spectra"; verbose=true)
    fns = readdir(dir)
    downloaded_obsids = Set([parse(Int, split(fn, '?')[1])
                             for fn in fns if fn[end-6:end] == "?token="])
    s = sum([o in downloaded_obsids for o in obsids])
    println("of $(length(obsids)) spectra, $(length(obsids) - s) need to be downloaded")
    for obsid in obsids
        if !(obsid in downloaded_obsids)
            url = "http://dr4.lamost.org/./spectrum/fits/$(obsid)?token="
            if verbose
                run(`wget -P $(dir) $url`)
            else
                run(`wget -q -P $(dir) $url`)
            end
        end
    end
end

function load_lamost_spectrum(obsid::Integer; dir="LAMOST_spectra", 
                              wl_grid=load("wl_grid.jld2")["wl_grid"], L=100)
    hdu = FITS("$(dir)/$(obsid)?token=")[1]
    header = read_header(hdu)
    data = read(hdu)
    wl = data[:, 3] .- data[:, 3].*header["Z"]
    if wl_grid != nothing
        wl_grid = load("wl_grid.jld2")["wl_grid"]
        flux = (LinearInterpolation(wl, data[:, 1])).(wl_grid)
        ivar = (LinearInterpolation(wl, data[:, 2])).(wl_grid)
        wl = wl_grid
    else
        flux = data[:, 1]
        ivar = data[:, 2]
    end
    if L == 0
        continuum = mean(flux)
    else
        continuum = calculate_continuum(wl, flux, ivar, L=L)
    end
    flux ./= continuum
    ivar .*= continuum.^2

    return Float32.(wl), Float32.(flux), Float32.(ivar)
end

function smoothing_kernel(wl, wl0, L) 
    exp(- (((wl-wl0)/L)^2) / 2)
end
function calculate_continuum(wls, fluxes, ivars; L=100, window=3L)
    map(zip(wls, fluxes, ivars)) do triple
        wl, flux, ivar = triple
        indices = wl-window .< wls .< wl+window
        weights = smoothing_kernel.(wls[indices], wl, L) .* ivars[indices]
        sum(weights .* fluxes[indices])/sum(weights)
    end
end
