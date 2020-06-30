using JLD2, FileIO

Δλ = 7 
subordinate_line_vac = 6105.7
li_vac = 6709.702
wls = Float32.(load("wl_grid.jld2")["wl_grid"])[.! subordinate_line_mask]
subordinate_line_mask = subordinate_line_vac - Δλ .< wl_grid .< subordinate_line_vac + Δλ
npix = sum(.! subordinate_line_mask)
wl_grid = SharedArray{Float32}(npix)
wl_grid .= wls[.! subordinate_line_mask]
line_mask = li_vac - Δλ .< wl_grid .< li_vac + Δλ
