using DataFrames, JLD2, FileIO, FITSIO
include("../fitsdf.jl")

dir = ARGS[1]

files = [f for f in readdir(dir) if endswith(f, ".jld2")]
dfs = map(files) do f
    df = load(dir*"/"*f)["out"]
end
df = reduce(vcat,dfs)

write_to_fits(dir * ".residuals.fits", df)
