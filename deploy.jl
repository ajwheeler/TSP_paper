using Pkg; Pkg.activate("."); Pkg.resolve(); Pkg.instantiate()
using Distributed
@everywhere begin
    using Pkg
    Pkg.activate(".")
    include("model.jl")
    include("get_lamost_spectra.jl")
    using SharedArrays
end
using CSV, JLD2, FileIO, DataFrames

#CLI args
obsids_fn = ARGS[1]
tr_set_fn = ARGS[2]
datadir   = ARGS[3]
outdir    = ARGS[4]
k         = parse(Int, ARGS[5])
jobindex  = parse(Int, ARGS[6])
njobs     = parse(Int, ARGS[7])

println("job $jobindex of $njobs")
println("training set: $tr_set_fn")
println("deploy set: $obsids_fn")
println("$k nearest neighbors")

#load the training data
tr_ids = CSV.read(tr_set_fn)[!, :obsid] #
wls = Float32.(load("wl_grid.jld2")["wl_grid"])
P = length(wls)
wl_grid = SharedArray{Float32}(P)
wl_grid .= wls
F = SharedArray{Float32}((P, length(tr_ids)))
S = SharedArray{Float32}((P, length(tr_ids)))
for (i,tr_id) in enumerate(tr_ids)
    _, flux, ivar = load_lamost_spectrum(tr_id, dir=datadir, wl_grid=wl_grid)
    F[:, i] .= flux
    S[:, i] .= ivar.^(-1/2)
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


#now get to work calculating scaled equivalent widths
inferred_values = pmap(star_ids[row_range]) do obsid
    #choose mask. TODO set this from command line and don't repeat this for every spectrum
    Δλ = 7 
    li_air = 6707.85
    line_mask = li_air - Δλ .< wl_grid .< li_air + Δλ
    try
        _, flux, ivar = load_lamost_spectrum(obsid, dir=datadir, wl_grid=wl_grid)
        err = ivar.^(-5f-1) #make sure err is made of Float32's
        #calculate spectral distances
        dists = map(1:length(tr_ids)) do j
            spectral_dist(flux[.! line_mask], err[.! line_mask], F[.! line_mask, j], S[.! line_mask, j])
        end
        neighbors = partialsortperm(dists, 1:k)
        w = calculate_weights(F[.! line_mask, neighbors], flux[.! line_mask], err[.! line_mask])
        best_fit_chi2 = sum(((F[.! line_mask, neighbors]*w - flux[.! line_mask]) ./ err[.! line_mask]).^2)
        obsid, (F[line_mask, neighbors] * w - flux[line_mask]), err[line_mask], neighbors, w, best_fit_chi2
    catch err
        println(err)
        println("\nskipping obsid $(obsid)")
        missing
    end
end

inferred_values = inferred_values[.! ismissing.(inferred_values)]

df = DataFrame(obsid         = first.(inferred_values),
               diff          = (r->r[2]).(inferred_values),
               err           = (r->r[3]).(inferred_values),
               neighbors     = (row -> tr_ids[row[4]]).(inferred_values),
               weights       = (r->r[5]).(inferred_values),
               best_fit_chi2 = last.(inferred_values))

#CSV.write("$outdir/$(jobindex).csv", df)
save("$(outdir)/$(jobindex).jld2", "out", df)
