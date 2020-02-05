using LinearAlgebra, Optim

spectral_dist(f1, s1, f2, s2) = sum(@. (f1-f2)^2/(s1^2 + s2^2))

"""
- `F` is the (npix x K) flux matrix
- `S` is a (npix x K) matrix containing the uncertainties on F.
   If it is not supplied F is assumed to be exact.
- `f` is the spectrum under investigation
- `σ` is the vector of uncertainties for `f`
"""
function calculate_weights(F::Matrix{Fl}, f::Vector{Fl}, 
                           σ::Vector{Fl}) where Fl <: AbstractFloat
    invΣ = inv(Diagonal(σ))
    (transpose(F) * invΣ * F) \ (transpose(F)  * invΣ * f)
end
function calculate_weights(F::Matrix{Fl}, S::Matrix{Fl}, 
                           f::Vector{Fl}, σ::Vector{Fl}) where Fl <: AbstractFloat
    @assert (npix = length(f)) == length(σ) == size(F, 1) == size(S, 1)

    #work with variables used in paper
    V = Diagonal.(eachrow(S.^2))
    
    #negative log-likelihood, up to positive linear transformation
    function objective(w)
        r = f - F*w
        Σ = Diagonal([transpose(w)*V[λ]*w + σ[λ]^2 for λ in 1:length(σ)])
        #n.b. this inversion is trivial since Σ is diagonal
        transpose(r)*inv(Σ)*r + logdet(Σ) 
    end

    #start optimizer at weights you get if F has no error
    w_init = calculate_weights(F, f, σ)
    res = optimize(objective, w_init, Newton(), autodiff=:forward)
    res.minimizer
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
