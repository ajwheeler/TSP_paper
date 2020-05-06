using LinearAlgebra

#"""error-weighted euclidean distance (between two spectra)"""
#spectral_dist(f1, s1, f2, s2) = sum(@. (f1-f2)^2/(s1^2 + s2^2))

"""
find the k columns of (`F`,`S`) that are clossest to (`flux`, `err`).
Returns an array of k `Int`s, indices into (`F`, `S`).
This function does not mask any spectral features for you.  Do that beforehand.
"""
function find_neighbors(flux, F, k)
        #dists = sum((F .- flux').^2 ./ (err'.^2 .+ S.^2) .+ log.(err'.^2 .+ S.^2), dims=2)[:]
        dists = sum((flux .- F').^2 , dims=1)[:]
        dists[dists .== 0.0] .= Inf #don't let spectra neighbor themselves
        #perm = Vector{Int}(undef, size(dists))
        #partialsortperm!(perm, view(dists, :), 1:k)
        partialsortperm(dists, 1:k)
end

function project_onto_local_manifold(F::AbstractMatrix, f::Vector, 
                                     ivar::Vector, mask, q::Int) 
    μ = mean(F, dims=1)      # center coordinates
    F = (F .- μ)[1:end-1, :] # F :: (k-1 x p), drop one neighboring spectra
                             #   since it's redundant after centering
    f = f - μ[:]             # don't use the .-= opperator, it mutates F

    # eigendecomposition of N x N matrix F F' (not p x p matrix F' F)
    eivals, eivecs = eigen(F * F')       # (k-1) x (k-1)
    eispec = F' * eivecs[:, end-q+1:end] #convert N-eigenvectors to p-eigenvectors (eigenspectra)

    #we could normalize the eigenspectra, but it's not necessary
    #PCnorm = sqrt.(eivals[end-q+1:end]) 
    #eispec = PCs ./ PCnorm' #normalize eigenspectra (p x q)
    
    invΣ = diagm(ivar[.! mask])
    E = eispec[.! mask, :]
    β = (E' * invΣ * E) \ (E' * invΣ * f[.! mask] )
    eispec * β + μ[:]
end

"""
Predict the part of `f` covered by `mask`. 
- `f` is spectrum (a vector) of flux values
- `ivar` is a vector of precision values (1/variance) for `f`
- `F` is the matrix whose rows are the reference spectra
- `P` is the matrix whose rows are the precision-vectors of the reference spectra

For the best performance, pass `F` as a `Transpose` object, e.g. stored in row-major form
"""
function predict_spectral_range(f, ivar, F, P, k, q, mask; whiten=false)
    @assert length(f) == length(ivar) == size(F, 2)

    #masked_data_present = all(P[:, mask] .!= 0, dims=2)
    neighbors = find_neighbors(view(f,.! mask), view(F, :, .!mask), k)

    #goodpix = any(P[neighbors, :] .== 0, dims=1)
    if whiten
        @assert size(F) == size(P)
        error = [mean(col[col .!= 0.0].^(-1/2)) for col in eachcol(P[neighbors, :])] 
        pf = project_onto_local_manifold((F[neighbors, :] .- 1)./error', (f.-1)./error, 
                                         ivar.*error.^2, mask, q) .* error .+ 1
    else
        pf = project_onto_local_manifold(F[neighbors, :], f, ivar, mask, q)
    end
    pf
end

function model_comparison(D, P, masked_wls, line, width)
    #construct model matrix M
    n = length(masked_wls)
    M = zeros(2 + n, n)
    Δλ = (masked_wls[end] - masked_wls[1]) / (length(masked_wls) -1 )
    ϕ(x, μ, σ) = exp(-1/2 * (x-μ)^2/σ^2) / sqrt(2π) / σ #gaussian kernel
    M[1, :] = ϕ.(masked_wls, line, width) ./ Δλ # normalized s.t. EW = 1
    M[2, :] .= 1.0
    for i in 3:(2+n)
        M[i, i-2] = 1.
    end

    #TODO: how does this work?
    l1 = M.^2 * P
    l2 = M * (D .* P)
    loss = @. -l2^2 / l1

    losses = collect(eachcol(loss))
    isline = argmin.(losses) .== 1
    amplitude = first.(collect(eachcol(l2 ./ l1)))
    amplitude[.! isline] .= NaN

    N = length(isline)
    delta_chi2 = Vector(undef, N)
    for i in 1:N
        delta_chi2[i] = isline[i] ? minimum(losses[i][2:end]) - losses[i][1] : NaN
    end
    
    isline, losses, amplitude, delta_chi2
end
