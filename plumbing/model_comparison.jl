using DataFrames, FITSIO, FileIO
include("../model.jl")
include("../fitsdf.jl")
include("../air_vacuum.jl")

df = fitsdf(ARGS[1], 2)
D = reduce(hcat, df.diff) 
P = reduce(hcat, df.ivar)

include("../lines_and_grid.jl")

println("doing matched filtering...")
@time df.isline, df.loss, df.EEW, df.EEW_err = model_comparison(D, P, wl_grid[line_mask], li_vac, li_vac/3600)

df.enriched = df.isline .& (df.EEW .> 0.15) .& (df.EEW_err .< 0.05)

outfn = prod(vcat(split(ARGS[1], ".")[1:end-2], ".classified.fits"))
println("writing to $outfn")
write_to_fits(outfn, df)
