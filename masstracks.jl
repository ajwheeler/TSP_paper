using PyCall
py"""
import sys
sys.path.insert(0, ".")
"""
rmm = pyimport("read_mist_models")
eeps = []
cols = ["phase", "Gaia_G_DR2Rev", "Gaia_BP_DR2Rev", "Gaia_RP_DR2Rev", "log_Teff", "log_g", "star_age", "Z_surf"]

for M in [0.5, 0.8, 1, 1.5, 2], feh in ["p0.00"]#["m0.50", "p0.00", "p0.50"]
    Mstr = lpad(Int(M*10000), 7, '0')
    eep = rmm.EEPCMD("../cats/MIST/MIST_v1.2_feh_$(feh)_afe_p0.0_vvcrit0.4_CMDEEPS/$(Mstr)M.track.eep.cmd")
    edf = DataFrame([Symbol(c)=>get(eep.eepcmds, c) for c in cols]...)
    edf.BP_RP = edf.Gaia_BP_DR2Rev .- edf.Gaia_RP_DR2Rev
    rename!(edf, :Gaia_G_DR2Rev=>:G)
    push!(eeps, (M, feh, edf))
end

function overplot_eep(eeps, xcol, ycol; c="gray", label=true, lw=nothing, alpha=0.6)
    ls = Dict("m0.50"=>":", "p0.00"=>"-", "p0.50"=>"--")
    for (M, feh, eep) in eeps
        mask = 0 .<= eep.phase .< 4
        xs = eep[mask, xcol]
        ys = eep[mask, ycol]
        plot(xs, ys, ls = ls[feh], c=c, lw=lw, alpha=alpha)
        if label
            text(xs[1], ys[1]+0.2, LaTeXString("\$$(M) M_\\odot\$"), va="top", ha="center", color="k", size=10)
        end
    end
end
