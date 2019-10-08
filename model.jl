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
