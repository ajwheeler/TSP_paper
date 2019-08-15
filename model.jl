using LinearAlgebra, Optim

"""
- `F` is the (npix x N) flux matrix
- `S` is a (npix x N) matrix containing the uncertainties on F
- `f` is the spectrum under investigation
- `σ` is the vector of uncertainties for `f`
"""
function calculate_weights(F, S, f, σ)
    #work with variables used in paper
    N = size(F, 2) 
    V = Diagonal.(eachrow(S.^2))
    
    #negative log-likelihood up to a linear transformation
    function objective(w)
        r = f - F*w
        Σ = Diagonal([transpose(w)*V[λ]*w + σ[λ]^2 for λ in 1:length(σ)])
        transpose(r)*inv(Σ)*r + logdet(Σ) #n.b. this inversion is trivial since Σ is diagonal
    end
    
    w_init = ones(N) / N
    res = optimize(objective, w_init, Newton(), autodiff=:forward)
    println(res)
    res.minimizer
end