using LinearAlgebra, Optim

"""error-weighted euclidean distance (between two spectra)"""
spectral_dist(f1, s1, f2, s2) = sum(@. (f1-f2)^2/(s1^2 + s2^2))

"""
find the k columns of (`F`,`S`) that are clossest to (`flux`, `err`).
Returns an array of k `Int`s, indices into (`F`, `S`).
This function does not mask any spectral features for you.  Do that beforehand.
"""
function find_neighbors(flux, err, F, S, k)
        dists = map(1:size(F, 2)) do j
            d = spectral_dist(flux, err, F[:, j], S[:, j])
            d == 0.0 ? Inf : d #don't let spectra neighbor themselves
        end
        partialsortperm(dists, 1:k)
end

function project_onto_local_manifold(F::Matrix, f::Vector, 
                                     ivar::Vector, mask, q::Int) 
    μ = mean(F, dims=1)      # center coordinates
    F = (F .- μ)[1:end-1, :] # F :: (k-1 x p), drop one neighboring spectra
                             #   since it's redundant after centering
    f = f - μ[:]             # don't use the .-= opperator, it mutates F

    # eigendecomposition of N x N matrix F F' (not p x p matrix F' F)
    println(size(F * F'))
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

#"""
#- `F` is the (npix x K) flux matrix
#- `S` is a (npix x K) matrix containing the uncertainties on F.
#   If it is not supplied F is assumed to be exact.
#- `f` is the spectrum under investigation
#- `σ` is the vector of uncertainties for `f`
#"""
#function calculate_weights(F::Matrix{Fl}, f::Vector{Fl}, 
#                           σ::Vector{Fl}) where Fl <: AbstractFloat
#    @assert (npix = length(f)) == length(σ) == size(F, 1)
#    invΣ = inv(Diagonal(σ.^2))
#    (transpose(F) * invΣ * F) \ (transpose(F)  * invΣ * f)
#end
#function calculate_weights(F::Matrix{Fl}, S::Matrix{Fl}, 
#                           f::Vector{Fl}, σ::Vector{Fl}) where Fl <: AbstractFloat
#    @assert (npix = length(f)) == length(σ) == size(F, 1) == size(S, 1)
#
#    #work with variables used in paper
#    V = Diagonal.(eachrow(S.^2))
#    
#    #negative log-likelihood, up to positive linear transformation
#    function objective(w)
#        r = f - F*w
#        Σ = Diagonal([transpose(w)*V[λ]*w + σ[λ]^2 for λ in 1:length(σ)])
#        #n.b. this inversion is trivial since Σ is diagonal
#        transpose(r)*inv(Σ)*r + logdet(Σ) 
#    end
#
#    #start optimizer at weights you get if F has no error
#    w_init = calculate_weights(F, f, σ)
#    res = optimize(objective, w_init, Newton(), autodiff=:forward)
#    res.minimizer
#end

"convenience function"
function predict_spectral_range(f, ivar, F, S, k, q, mask; whiten=true)
    @assert length(f) == length(ivar) == size(F, 2) == size(S, 2)
    @assert size(F) == size(S)

    σ = ivar.^(-1/2)
    σ[σ .== Inf] .= 1.
    imputed_S = copy(S)
    imputed_S[S .== Inf] .= 1.
    neighbors = find_neighbors(f[.! mask], σ[.! mask], F[:, .! mask]',
                               zeros(size(S[:, .! mask]')), k)#imputed_S[:, .! mask]', k)

    if whiten
        error = [mean(col[col .!= 0.0].^(-1/2)) for col in eachcol(rf_ivar[neighbors, :])] 
        pf = project_onto_local_manifold((F[neighbors, :] .- 1)./error', (f.-1)./error, 
                                         ivar.*error.^2, mask, q) .* error .+ 1
    else
        pf = project_onto_local_manifold(F[neighbors, :], f, ivar, mask, q)
    end

    pf
end

function model_comparison(D, E, masked_wls, line, width)
    #construct model matrix M
    ϕ(x, μ, σ) = exp(-1/2 * (x-μ)^2/σ^2) #gaussian kernel
    n = length(masked_wls)
    M = zeros(2 + n, n)
    M[1, :] = ϕ.(masked_wls, line, width)
    M[1, :] ./= sqrt(sum(M[1, :].^2))
    M[2, :] .= sqrt(1/n)
    for i in 3:(2+n)
        M[i, i-2] = 1.
    end

    #TODO: how does this work?
    l1 = M.^2 * (1 ./ E)
    l2 = M * (D./E)
    loss = @. -l2^2 / l1

    losses = collect(eachcol(loss))
    isline = argmin.(losses) .== 1
    amplitude = first.(collect(eachcol(l2 ./ l1)))

    N = length(isline)
    delta_chi2 = Vector(undef, N)
    for i in 1:N
        delta_chi2[i] = isline[i] ? minimum(losses[i][2:end]) - losses[i][1] : NaN
    end
    
    isline, losses, amplitude, delta_chi2
end
