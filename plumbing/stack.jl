using DataFrames, FITSIO, FITSTables

fn = ARGS[1]

df = FITS(DataFrame ∘ last, fn)
lamost = FITS(DataFrame ∘ last, "../cats/LAMOST-dr5-v3-stellar.fits.gz")[:, [:obsid, :designation]]
df = join(df, lamost, on=:obsid, kind=:left)

rename!(df, :err=>:ivar)

function stack(group)
    avDiff = sum([p.*r for (p,r) in zip(group.ivar, group.diff)]) ./ sum(group.ivar)
    avPrec = sum(group.ivar)
    (diff=[avDiff], ivar=[avPrec])
end
sdf = by([:diff, :ivar] => stack, df, :designation)


include("../fitsdf.jl")
write_to_fits(fn[1:end-length(".residuals.fits")] * ".stackedresiduals.fits", sdf)
