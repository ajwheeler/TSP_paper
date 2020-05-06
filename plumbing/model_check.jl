using DataFrames, FITSIO, FileIO
include("../model.jl")
include("../fitsdf.jl")
include("../air_vacuum.jl")

df = fitsdf(ARGS[1], 2)
D = reduce(hcat, df.diff) 
P = reduce(hcat, df.ivar)

wl_grid = load("wl_grid.jld2")["wl_grid"]
Δλ = 7                                                                                    
li_air = 6707.85
li_vac = air_to_vac(li_air)
line_mask = li_air - Δλ .< wl_grid .< li_air + Δλ
;

println("doing model comparison...")
@time df.isline, df.loss, df.EEW, df.delta_chi2 = model_comparison(D, P, wl_grid[line_mask], li_vac, li_air/3600)

write_to_fits(prod(vcat(split(ARGS[1], ".")[1:end-2], ".classified.fits")), df)
