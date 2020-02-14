readable_name = Dict([:teff => L"$T_\mathrm{eff}$ [K]",
                      :snrz => L"(S/N)_z",
                      :logg => L"\log g",
                      :vmic => L"v_\mathrm{mic}",
                      :A_V => L"A_V",
                      :logA_V => L"\log_{10} A_V",
                      :JR => L"$J_R$ [km s$^{-1}$ kpc]", 
                      :logJR => L"$\log_{10}J_R$ [km s$^{-1}$ kpc]",
                      :Jphi => L"$J_\phi$ [km s$^{-1}$ kpc]",
                      :Jz => L"$J_z$ [km s$^{-1}$ kpc]",
                      :logJz => L"$\log_{10} J_z$ [km s$^{-1}$ kpc]",
                      :feh => "[Fe/H]",
                      :fe_h => "[Fe/H]", 
                      :li_fe => "[Li/Fe]",
                      :o_fe => "[O/Fe]",
                      :eu_fe => "[Eu/Fe]",
                      :alpha_fe => L"[$\alpha$/Fe]",
                      :sc_fe => "[Sc/Fe]",
                      :sprocess_fe => L"[$s$-process/Fe]",
                      :mg_fe => "[Mg/Fe]",
                      :al_fe => "[Al/Fe]",
                      :mn_fe => "[Mn/Fe]",
                      :ba_eu => "[Ba/Eu]",
                      :eu_ba => "[Eu/Ba]",
                      :ba_fe => "[Ba/Fe]", 
                      :vT => L"$V_\phi$ [km s$^{-1}$]",
                      :R => L"$R$ [kpc]",
                      :X => L"$X$ [kpc]",
                      :Y => L"$Y$ [kpc]",
                      :z => L"$z$ [kpc]"])
function hrname(l::Symbol) 
    s = String(l)
    if length(s) > 5 && s[1:5] == "chi2_"
        sublabel = Symbol(join(split(s, '_')[2:end], '_'))
        LaTeXString("\$\\chi^2_\\mathrm{$(hrname(sublabel))}\$")
    else
        readable_name[l] 
    end
end

