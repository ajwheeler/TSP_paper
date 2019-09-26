using PyCall
py"""
import sys
sys.path.insert(0, ".")
"""
sg = pyimport("svens_galah_fns")
np = pyimport("numpy")
sg.data_directory = "GALAH_spectra"

function load_spectrum(sobject_id::Int)
    s = sg.read_spectra(sobject_id)
    sg.interpolate_spectrum_onto_cannon_wavelength(s)
    wls  = np.concatenate([s["wave_norm_1"], s["wave_norm_2"], s["wave_norm_3"], s["wave_norm_4"]])
    fs   = np.concatenate([s["sob_norm_1"],  s["sob_norm_2"],  s["sob_norm_3"],  s["sob_norm_4"]])
    errs = np.concatenate([s["uob_norm_1"],  s["uob_norm_2"],  s["uob_norm_3"],  s["uob_norm_4"]])
    wls, fs, errs
end
