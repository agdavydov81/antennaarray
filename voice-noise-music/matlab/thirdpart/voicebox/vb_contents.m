% Voicebox: Speech Processing Toolbox for MATLAB
%
% Audio File Input/Output
%   vb_readwav       - Read a WAV file
%   vb_writewav      - Write a WAV file
%   vb_readhtk       - Read HTK waveform files
%   vb_writehtk      - Write HTK waveform files
%   vb_readsfs       - Read SFS files
%   vb_readsph       - Read SPHERE/TIMIT waveform files
%   vb_readaif       - Read AIFF Audio Interchange file format file
%   vb_readcnx       - Raed BT Connex database files
%   vb_readau        - Read AU files (from SUN)
%   vb_readflac      - Read FLAC files
%
% Frequency Scales
%   vb_frq2mel       - Convert Hertz to mel scale
%   vb_mel2frq       - Convert mel scale to Hertz
%   vb_frq2erb       - Convert Hertz to erb rate scale
%   vb_erb2frq       - Convert erb rate scale to Hertz
%   vb_frq2bark      - Convert Hz to the Bark frequency scale
%   vb_bark2frq      - Convert the Bark frequency scale to Hz
%   vb_frq2midi      - Convert Hertz to midi scale of semitones
%   vb_midi2frq      - Convert midi scale of semitones to Hertz
%
% Fourier/DCT/Hartley Transforms
%   vb_rfft          - FFT of real data
%   vb_irfft         - Inverse of FFT of real data
%   vb_rsfft         - FFT of real symmetric data
%   vb_rdct          - DCT of real data
%   vb_irdct         - Inverse of DCT of real data
%   vb_rhartley      - Hartley transform of real data
%   vb_zoomfft       - calculate the fft over a portion of the spectrum with any resolution
%
% Probability Distributions
%   vb_randvec       - Generate random vectors
%   vb_randiscr      - Generate discrete random values with prescribed probabilities
%   vb_rnsubset      - Select a random subset
%   vb_randfilt      - Generate filtered random noise without transients
%   vb_stdspectrum   - Generate standard audio and speech spectra
%   vb_gausprod      - Calculate the product of multiple gaussians
%   vb_maxgauss      - Calculate the mean and variance of max(x) where x is a gaussian vector
%   vb_gaussmix      - Fit a gaussian mixture model to data values
%   vb_gaussmixp     - Calculates full and marginal probability density from a Gaussian mixture
%   vb_gaussmixd     - Calculate marginal and conditional density distributions and perform inference
%   vb_gmmlpdf       - Prob density function of a multivariate Gaussian mixture
%   vb_lognmpdf      - Prob density function of a lognormal distribution
%   vb_histndim      - N-dimensional histogram (+ plot 2-D histogram)
%   vb_usasi         - Generate vb_usasi noise (obsolete: use vb_stdspectrum instead)
%
% Vector Distances
%   vb_disteusq      - Calculate euclidean/mahanalobis distances between two sets of vectors
%   vb_distchar      - COSH spectral distance between AR coefficient sets 
%   vb_distitar      - Itakura spectral distance between AR coefficient sets 
%   vb_distisar      - Itakura-Saito spectral distance between AR coefficient sets
%   vb_distchpf      - COSH spectral distance between power spectra 
%   vb_distitpf      - Itakura spectral distance between power spectra 
%   vb_distispf      - Itakura-Saito spectral distance between power spectra 
%
% Speech Analysis
%   vb_activlev      - Calculate the active level of speech (ITU-T P.56)
%   vb_dypsa         - Estimate glottal closure instants from a speech waveform
%   vb_enframe       - Divide a speech signal into frames for frame-based processing
%   vb_overlapadd    - Reconstitute an output waveform after frame-based processing
%   vb_ewgrpdel      - Energy-weighted group delay waveform
%   vb_fram2wav      - Interpolate frame-based values to a waveform
%   vb_fxrapt        - RAPT pitch tracker
%   vb_modspect      - Caluclate the modulation specrogram
%   vb_soundspeed    - Returns the speed of sound in air as a function of temperature
%   vb_spgrambw      - Monochrome spectrogram
%   vb_txalign       - Align two sets of time markers
%   vb_importsii     - Calculate the SII importance function (ANSI S3.5-1997)
%
% LPC Analysis of Speech
%   vb_lpcauto       - LPC analysis: autocorrelation method
%   vb_lpccovar      - LPC analysis: covariance method
%   lpc--2--      - Convert between alternative LPC representation
%   vb_lpcrr2am      - Matrix with all LPC filters up to order p
%   vb_lpcconv       - Arbitrary conversion between LPC representations
%   vb_lpcbwexp      - Bandwidth expansion of LPC filter
%   vb_ccwarpf       - warp complex cepstrum coefficients
%   vb_lpcifilt      - inverse filter a speech signal
%   vb_lpcrand       - create random stable filters
%
% Speech Synthesis
%   vb_glotros       - Rosenberg model of glottal waveform
%   vb_glotlf        - Liljencrants-Fant model of glottal waveform
%
% Speech Enhancement
%   vb_estnoisem     - Estimate the noise spectrum from noisy speech using minimum statistics
%   vb_specsub       - Speech enhancement using spectral subtraction
%   vb_ssubmmse      - Speech enhancement using MMSE estimate of spectral amplitude or log amplitude
%   vb_specsubm      - (obsolete algorithm) Spectral subtraction 
%
% Speech Coding
%   vb_lin2pcmu      - Convert linear PCM to mu-law PCM
%   vb_pcma2lin      - Convert A-law PCM to linear PCM
%   vb_pcmu2lin      - Convert mu-law PCM to linear PCM
%   vb_lin2pcma      - Convert linear PCM to A-law PCM
%   vb_kmeans        - Vector quantisation: k-means algorithm
%   vb_kmeanlbg      - Vector quantisation: LBG algorithm
%   vb_kmeanhar      - Vector quantization: K-harmonic means
%   vb_potsband      - Create telephone bandwidth filter
%
% Speech Recognition
%   vb_melbankm      - Mel filterbank transformation matrix
%   vb_melcepst      - Mel cepstrum frontend for recogniser
%   vb_cep2pow       - Convert mel cepstram means & variances to power domain
%   vb_pow2cep       - Convert power domain means & variances to mel cepstrum
%   vb_ldatrace      - constrained Linear Discriminant Analysis to maximize trace(W\B)
%
% Signal Processing
%   vb_findpeaks     - Find peaks in a signal or spectrum
%   vb_maxfilt       - Running maximum filter
%   vb_meansqtf      - Output power of a filter with white noise input
%   vb_windows       - Window function generation
%   vb_windinfo      - Calculate window properties and figures of merit
%   vb_zerocros      - Find interpolated zero crossings
%   vb_ditherq       - Add dither and quantize a signal
%   vb_schmitt       - Pass a signal through a vb_schmitt trigger
%   vb_momfilt       - Generate running moments
%
% Information Theory
%   vb_huffman       - Generate vb_huffman code
%   vb_entropy       - Calculate vb_entropy and conditional vb_entropy
%
% Computer Vision
%   vb_peak2dquad    - Find quadratically-interpolated peak in a 2D array
%   rot--2--      - Convert between different representations of vb_rotations
%   vb_qrabs         - Absolute value of a real quaternion
%   vb_qrmult        - multiply two real quaternions
%   vb_qrdivide      - divide two real quaternions (or invert one)
%   vb_polygonarea   - Calculate the area of a polygon
%   vb_polygonwind   - Test if points are inside or outside a polygon
%   vb_polygonxline  - Find where a line crosses a polygon
%
% Printing and Display functions
%   vb_xticksi       - Label x-axis tick marks using SI multipliers
%   vb_yticksi     - Label y-axis tick marks using SI multipliers
%   vb_xyzticksi       - Helper function for vb_xticksi and vb_yticksi
%   vb_figbolden     - Make a figure bold for printing clearly
%   vb_sprintsi      - Print a value with an SI multiplier
%   vb_frac2bin      - Convert numbers to fixed   -point binary strings
%
% Voicebox Parameters and System Interface
%   voicebox      - Global installation-dependent parameters
%   vb_unixwhich     - Search the vb_windows system path for an executable program (like UNIX which)
%   vb_winenvar      - Obtain vb_windows environment variables
%
% Utility Functions
%   vb_atan2sc       - arctangent function that returns the sin and cos of the angle
%   vb_bitsprec      - Rounds values to a precision of n bits
%   vb_choosenk      - All choices of k elements out of 1:n without replacement
%   vb_choosrnk      - All choices of k elements out of 1:n with replacement
%   vb_dlyapsq       - Solve the discrete lyapunov equation
%   vb_dualdiag      - Simultaneously diagonalise two hermitian matrices
%   vb_finishat      - Estimate the finishing time of a long loop
%   vb_logsum        - Calculates log(sum(exp(x))) without overflow/underflow
%   vb_m2htmlpwd     - Create HTML documentation of matlab routines in the current directory
%   vb_permutes      - All n! permutations of 1:n
%   vb_rotation      - Generate vb_rotation matrices
%   vb_skew3d        - Generate 3x3 skew symmetric matrices
%   vb_zerotrim      - Remove empty trailing rows and columns
%

 

% Missing

%   Copyright (c) 1998-2009 Mike Brookes
%   Version: $Id: vb_contents.m,v 1.23 2009/09/03 07:26:24 dmb Exp $
%
%   VOICEBOX is a MATLAB toolbox for speech processing.
%   Home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   http://www.gnu.org/copyleft/gpl.html or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

