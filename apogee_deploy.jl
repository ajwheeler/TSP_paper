#using Pkg; Pkg.activate("."); Pkg.resolve(); Pkg.instantiate()
using Distributed
@everywhere begin
    #using Pkg
    #Pkg.activate(".")
    include("model.jl")
    include("get_lamost_spectra.jl")
    using SharedArrays
end
using CSV, JLD2, FileIO, DataFrames, Serialization

#CLI args
input_fn  = ARGS[1]
tr_set_fn = ARGS[2]
datadir   = ARGS[3]
outdir    = ARGS[4]
k         = parse(Int, ARGS[5])
q         = parse(Int, ARGS[6])
jobindex  = parse(Int, ARGS[7])
njobs     = parse(Int, ARGS[8])

println("job $jobindex of $njobs")
println("training set: $tr_set_fn")
println("deploy set: $input_fn")
println("$k nearest neighbors, q=$q")

#load the training data
tr_cat = CSV.read(tr_set_fn)[!, :obsid] #
wls = Float32.(deserialize("wl_grid_apogee.jdb"))
wlmask = 15900 .< wls .< 16400
npix = sum(wlmask)
wl_grid = SharedArray{Float32}(npix)
wl_grid .= wls
Ft = SharedArray{Float32}((npix, length(tr_ids))) #F'
for row in eachrow(tr_cat)
    flux, ivar = load_apogee_spectrum(row)
    Ft[:, i] .= flux
end

incat = FITS(f->DataFrame(f[2]), input_fn)
jobsize = Int(ceil(size(incat, 1)/njobs))
if jobindex == njobs
    row_range = (jobindex-1)*jobsize+1 : size(incat, 1)
else
    row_range = (jobindex-1)*jobsize+1 : jobindex*jobsize 
end
println("inferring labels for rows in $row_range")

Δλ = 7 
li_air = 6707.85
line_mask = li_air - Δλ .< wl_grid .< li_air + Δλ

inferred_values = pmap(star_ids[row_range]) do obsid
    try
        _, f, ivar = load_lamost_spectrum(obsid, dir=datadir, wl_grid=wl_grid)
        #pass F as adjoint object (e.g. transpose(Ft)) so that it's in row-major form
        pf = predict_spectral_range(f, ivar, Ft', nothing, k, q, line_mask; whiten=false)
        best_fit_chi2 = sum((pf[.! line_mask] - f[.! line_mask]).^2 .* ivar[.! line_mask])
        obsid, (pf[line_mask] - f[line_mask]), ivar[line_mask], best_fit_chi2
    catch err
        println(err)
        println("\nskipping obsid $(obsid)")
        missing
    end
end

inferred_values = inferred_values[.! ismissing.(inferred_values)]

df = DataFrame(obsid         = first.(inferred_values),
               diff          = (r->r[2]).(inferred_values),
               ivar           = (r->r[3]).(inferred_values),
               best_fit_chi2 = last.(inferred_values))

save("$(outdir)/$(jobindex).jld2", "out", df)
