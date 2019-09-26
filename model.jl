using LinearAlgebra, Optim

"""
- `F` is the (npix x K) flux matrix
- `S` is a (npix x K) matrix containing the uncertainties on F
- `f` is the spectrum under investigation
- `σ` is the vector of uncertainties for `f`
"""
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
    invΣ = inv(Diag(σ))
    w_init = (transpose(F) * invΣ * F) \ (transpose(F)  * invΣ * f)

    res = optimize(objective, w_init, Newton(), autodiff=:forward)
    res.minimizer
end
