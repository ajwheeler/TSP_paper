import numpy as np
import pandas as pd
import os
import astropy.io.fits as pyfits
import matplotlib.pyplot as plt
import pickle

# Adjust directory you want to work in
data_directory = 'GALAH_spectra'

# You can activate a number of lines that will be plotted in the spectra
important_lines = np.array([
    [4861.35, 'H' , 'red'],
    [6562.79, 'H' , 'red'],
    [6708.  , 'Li', 'orange'],
    ])

def read_spectra(sobject_id, ccds=[1,2,3,4]):
    """
    This function reads in the 4 individual spectra from the subdirectory working_directory/SPECTRA
    
    INPUT:
    sobject_id = identifier of spectra by date (6digits), plate (4digits), combination (2digits) and pivot number (3digits)
    iraf_dr = reduction which shall be used, current version: dr5.3
    SPECTRA = string to indicate sub directory where spectra are saved
    
    OUTPUT
    spectrum = dictionary
    """
    
    spectrum = dict(sobject_id = sobject_id)
    
    # Assess if spectrum is stacked
    if str(sobject_id)[11] == '1':
        # Single observations are saved in 'com'
        com='com'
    else:
        # Stacked observations are saved in 'com2'
        com='com'   
    
    # Iterate through all 4 CCDs
    for each_ccd in ccds:
        fn = data_directory+'/'+str(sobject_id)[0:6]+'/'+str(sobject_id)+str(each_ccd)+'.fits'
        fits = pyfits.open(fn)

        # Extension 0: Reduced spectrum
        # Extension 1: Relative error spectrum
        # Extension 4: Normalised spectrum, NB: cut for CCD4
        
        # Extract wavelength grid for the reduced spectrum
        start_wavelength = fits[0].header["CRVAL1"]
        dispersion       = fits[0].header["CDELT1"]
        nr_pixels        = fits[0].header["NAXIS1"]
        reference_pixel  = fits[0].header["CRPIX1"]
        if reference_pixel == 0:
            reference_pixel = 1
        spectrum['wave_red_'+str(each_ccd)] = np.array([(x-reference_pixel+1)*dispersion+start_wavelength for x in range(0, nr_pixels)])

        # Extract wavelength grid for the normalised spectrum
        start_wavelength = fits[4].header["CRVAL1"]
        dispersion       = fits[4].header["CDELT1"]
        nr_pixels        = fits[4].header["NAXIS1"]
        reference_pixel  = fits[4].header["CRPIX1"]
        if reference_pixel == 0:
            reference_pixel=1
        spectrum['wave_norm_'+str(each_ccd)] = np.array([(x-reference_pixel+1)*dispersion+start_wavelength for x in range(0, nr_pixels)])
        
        # Extract flux and flux error of reduced spectrum
        spectrum['sob_red_'+str(each_ccd)]  = np.array(fits[0].data)
        spectrum['uob_red_'+str(each_ccd)]  = np.array(fits[0].data * fits[1].data)

        # Extract flux and flux error of reduced spectrum
        spectrum['sob_norm_'+str(each_ccd)] = np.array(fits[4].data)
        if each_ccd != 4:
            spectrum['uob_norm_'+str(each_ccd)] = np.array(fits[4].data * fits[1].data)
        else:
            # for normalised error of CCD4, only used appropriate parts of error spectrum
            spectrum['uob_norm_4'] = np.array(fits[4].data * (fits[1].data)[-len(spectrum['sob_norm_4']):])
            
        fits.close()
        
    return spectrum

def interpolate_spectrum_onto_cannon_wavelength(spectrum, ccds=[1,2,3,4]):
    """
    This function interpolates the spectrum 
    onto the wavelength grid of The Cannon as used for GALAH DR2
    
    INPUT:
    spectrum dictionary
    
    OUTPUT:
    interpolated spectrum dictionary
    
    """
    # Initialise interpolated spectrum from input spectrum
    interpolated_spectrum = dict()
    for each_key in spectrum.keys():
        interpolated_spectrum[each_key] = spectrum[each_key]
    
    # The Cannon wavelength grid as used for GALAH DR2
    wave_cannon = dict()
    wave_cannon['ccd1'] = np.arange(4715.94,4896.00,0.046) # ab lines 4716.3 - 4892.3
    wave_cannon['ccd2'] = np.arange(5650.06,5868.25,0.055) # ab lines 5646.0 - 5867.8
    wave_cannon['ccd3'] = np.arange(6480.52,6733.92,0.064) # ab lines 6481.6 - 6733.4
    wave_cannon['ccd4'] = np.arange(7693.50,7875.55,0.074) # ab lines 7691.2 - 7838.5
    
    for each_ccd in ccds:
        
        # exchange wavelength
        interpolated_spectrum['wave_red_'+str(each_ccd)]  = wave_cannon['ccd'+str(each_ccd)]
        interpolated_spectrum['wave_norm_'+str(each_ccd)] = wave_cannon['ccd'+str(each_ccd)]

        # interpolate and exchange flux
        interpolated_spectrum['sob_red_'+str(each_ccd)]  = np.interp(
            x=wave_cannon['ccd'+str(each_ccd)],
            xp=spectrum['wave_red_'+str(each_ccd)],
            fp=spectrum['sob_red_'+str(each_ccd)],
            )
        interpolated_spectrum['sob_norm_'+str(each_ccd)]  = np.interp(
            wave_cannon['ccd'+str(each_ccd)],
            spectrum['wave_norm_'+str(each_ccd)],
            spectrum['sob_norm_'+str(each_ccd)],
            )

        # interpolate and exchange flux error
        interpolated_spectrum['uob_red_'+str(each_ccd)]  = np.interp(
            wave_cannon['ccd'+str(each_ccd)],
            spectrum['wave_red_'+str(each_ccd)],
            spectrum['uob_red_'+str(each_ccd)],
            )
        interpolated_spectrum['uob_norm_'+str(each_ccd)]  = np.interp(
            wave_cannon['ccd'+str(each_ccd)],
            spectrum['wave_norm_'+str(each_ccd)],
            spectrum['uob_norm_'+str(each_ccd)],
            )

    return interpolated_spectrum

def plot_spectrum(spectrum, normalisation = True, lines_to_indicate = None, save_as_png = False, ccds=[1,2,3,4]):
    """
    This function plots the spectrum in 4 subplots for each arm of the HERMES spectrograph
    
    INPUT:
    spectrum = dictionary created by read_spectra()
    normalisation = True or False (either normalised or un-normalised spectra are plotted)
    save_as_png = Save figure as png if True
    
    OUTPUT:
    Plot that spectrum!
    
    """
    
    f, axes = plt.subplots(4, 1, figsize = (15,20))
    
    kwargs_sob = dict(c = 'k', label='Flux', rasterized=True)
    kwargs_error_spectrum = dict(color = 'grey', label='Flux error', rasterized=True)

    # Adjust keyword used for dictionaries and plot labels
    if normalisation==True:
        red_norm = 'norm'
    else:
        red_norm = 'red'
    
    for each_ccd in ccds:
        axes[each_ccd-1].fill_between(
            spectrum['wave_'+red_norm+'_'+str(each_ccd)],
            spectrum['sob_'+red_norm+'_'+str(each_ccd)] - spectrum['uob_'+red_norm+'_'+str(each_ccd)],
            spectrum['sob_'+red_norm+'_'+str(each_ccd)] + spectrum['uob_'+red_norm+'_'+str(each_ccd)],
            **kwargs_error_spectrum
            )
        
        # Overplot observed spectrum a bit thicker
        axes[each_ccd-1].plot(
            spectrum['wave_'+red_norm+'_'+str(each_ccd)],
            spectrum['sob_'+red_norm+'_'+str(each_ccd)],
            **kwargs_sob
            )
        
        # Plot important lines if committed
        for each_line in lines_to_indicate:
            if (float(each_line[0]) >= spectrum['wave_'+red_norm+'_'+str(each_ccd)][0]) & (float(each_line[0]) <= spectrum['wave_'+red_norm+'_'+str(each_ccd)][-1]):
                axes[each_ccd-1].axvline(float(each_line[0]), color = each_line[2], ls='dashed')
                if red_norm=='norm':
                    axes[each_ccd-1].text(float(each_line[0]), 1.25, each_line[1], color = each_line[2], ha='left', va='top')
            
        # Plot layout
        if red_norm == 'norm':
            axes[each_ccd-1].set_ylim(-0.1,1.3)
        axes[each_ccd-1].set_xlabel(r'Wavelength CCD '+str(each_ccd)+' [$\mathrm{\AA}$]')
        axes[each_ccd-1].set_ylabel(r'Flux ('+red_norm+') [a.u.]')
        if each_ccd == 1:
            axes[each_ccd-1].legend(loc='lower left')
    plt.tight_layout()
    
    if save_as_png == True:
        plt.savefig(str(spectrum['sobject_id'])+'_'+red_norm+'.png', dpi=200)

    return f

def model_spectrum(l, coeffs):
    lp = np.zeros(36)
    lp[0] = 1.
    lp[1:8] = l
    k = 8
    for i in range(7):
        for j in range(i, 7):
            lp[k] = l[i] * l[j]
            k += 1
    npix = coeffs.shape[0]
    F = np.zeros(npix)
    for i in range(npix):
        F[i] = np.sum(lp * coeffs[i, :])
    return F
