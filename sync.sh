#! /bin/bash
rsync deploy.jl deploy.sh get_lamost_spectra.jl model.jl one_tenth_of_lamost_dr5.csv random_30000.csv wl_grid.jld2 Project.toml moto:NNspectra
