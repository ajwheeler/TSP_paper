#! /bin/bash
rsync deploy.jl moto:NNspectra
rsync deploy.sh moto:NNspectra
rsync get_lamost_spectra.jl moto:NNspectra
rsync model.jl moto:NNspectra
rsync one_tenth_of_lamost.csv moto:NNspectra
rsync nano_LAMOST.csv moto:NNspectra
rsync top_SNR_DR2.csv moto:NNspectra
rsync random_DR2.csv moto:NNspectra
rsync distributed_DR2.csv moto:NNspectra
rsync wl_grid.jld2 moto:NNspectra
rsync Project.toml moto:NNspectra
