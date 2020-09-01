using Distributed
@everywhere begin
    using SharedArrays
    include("model.jl")
    include("get_lamost_spectra.jl")
end
include("lines_and_grid.jl")

using CSV, JLD2, FileIO, DataFrames

#CLI args
obsids_fn = ARGS[1]
tr_set_fn = ARGS[2]
datadir   = ARGS[3]
outdir    = ARGS[4]
k         = parse(Int, ARGS[5])
q         = parse(Int, ARGS[6])
jobindex  = parse(Int, ARGS[7])
njobs     = parse(Int, ARGS[8])

println("job $jobindex of $njobs")
println("training set: $tr_set_fn")
println("deploy on: $obsids_fn")
println("k=$k, q=$q")

#load the training data
tr_ids = CSV.read(tr_set_fn)[!, :obsid] #
npix = length(wl_grid)
Ft = SharedArray{Float32}((npix, length(tr_ids))) #F'
for (i,tr_id) in enumerate(tr_ids)
    _, flux, ivar = load_lamost_spectrum(tr_id, dir=datadir, wl_grid=wl_grid)
    Ft[:, i] .= flux
end

#load star_ids to deploy on, determine which are this job's
star_ids = CSV.read(obsids_fn)[!, :obsid] 
jobsize = Int(ceil(length(star_ids)/njobs))
if jobindex == njobs
    row_range = (jobindex-1)*jobsize+1 : length(star_ids)
else
    row_range = (jobindex-1)*jobsize+1 : jobindex*jobsize 
end
println("inferring labels for star_ids in $row_range")

inferred_values = pmap(star_ids[row_range]) do obsid
    try
        _, f, ivar = load_lamost_spectrum(obsid, dir=datadir, wl_grid=wl_grid)
        #pass F as adjoint object (i.e. transpose(Ft)) so that it's in row-major form
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
               ivar          = (r->r[3]).(inferred_values),
               best_fit_chi2 = last.(inferred_values))

mkpath(outdir)
save("$(outdir)/$(jobindex).jld2", "out", df)
