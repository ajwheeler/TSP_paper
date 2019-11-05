#! /bin/bash
rsync deploy.jl moto:NNspectra
rsync deploy.sh moto:NNspectra
rsync get_lamost_spectra.jl moto:NNspectra
rsync model.jl moto:NNspectra
rsync one_tenth_of_lamost.csv moto:NNspectra
rsync nano_LAMOST.csv moto:NNspectra
rsync LAMOST_top_100_snr.csv moto:NNspectra
rsync LAMOST_top_300_snr.csv moto:NNspectra
rsync LAMOST_top_1000_snr.csv moto:NNspectra
rsync wl_grid.jld2 moto:NNspectra
rsync Project.toml moto:NNspectra
