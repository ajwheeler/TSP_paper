using DataFrames, CSV
include("../fitsdf.jl")

df = fitsdf(ARGS[1], 2)
df = df[df.isline .& (df.amplitude .> 0) .& (df.delta_chi2.> 50), :]

lamost = fitsdf("../cats/LAMOST-dr5-v3-stellar.fits.gz", 2)[:, [:designation, :obsid]]
lamostxgaia = fitsdf("../cats/LAMOST-dr5v3-designations-coords-gaia.fits")
df = join(df, lamost, kind=:left, on=:obsid)
df = join(df, lamostxgaia, kind=:left, on=:designation)

CSV.write(prod(vcat(split(ARGS[1], ".")[1:end-2], ".flagged.csv")), df)
