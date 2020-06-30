using DataFrames, CSV, FITSIO, FITSTables

df = FITS(DataFrame ∘ last, ARGS[1])
df = df[df.isline .& (df.EEW .> 0.2) .& (df.EEW_err .< 0.2/3), :]

lamostxgaia = FITS(DataFrame ∘ last, "../cats/LAMOST-dr5v3-designations-coords-gaia.fits")
df = join(df, lamostxgaia, kind=:left, on=:designation)

CSV.write(prod(vcat(split(ARGS[1], ".")[1:end-2], ".flagged.csv")), df)
