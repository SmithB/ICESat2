#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Apr 26 14:58:17 2018

Credits: Johan Nilsson, with contribution from Fernando Paolo.

"""

import re
import sys
import os
import warnings
import argparse
warnings.filterwarnings('ignore')
import h5py
import numpy as np
import matplotlib.pyplot as plt
from astropy.time import Time

def gps2dyr(time):
    """ Converte from GPS time to decimal years. """
    time = Time(time, format='gps')
    time = Time(time, format='decimalyear').value

    return time

def list_files(path, endswith='.h5'):
    """ List files in dir recursively."""
    return [os.path.join(dpath, f)
            for dpath, dnames, fnames in os.walk(path)
            for f in fnames if f.endswith(endswith)]


def track_type(time, lat, tmax=1):
    """
        Determines ascending and descending tracks.
        Defines unique tracks as segments with time breaks > tmax,
        and tests whether lat increases or decreases w/time.
    """
    
    # Generate track segment
    tracks = np.zeros(lat.shape)
    
    # Set values for segment
    tracks[0:np.argmax(np.abs(lat))] = 1
    
    # Output index array
    i_asc = np.zeros(tracks.shape, dtype=bool)
    
    # Loop trough individual tracks
    for track in np.unique(tracks):
        
        # Get all points from an individual track
        i_track, = np.where(track == tracks)
        
        # Test tracks length
        if len(i_track) < 2:
            continue
        
        # Test if lat increases (asc) or decreases (des) w/time
        i_min = time[i_track].argmin()
        i_max = time[i_track].argmax()
        lat_diff = lat[i_track][i_max] - lat[i_track][i_min]
        
        # Determine track type
        if lat_diff > 0:
            i_asc[i_track] = True

    # Output index vector's
    return i_asc, np.invert(i_asc)


# Output description of solution
description = ('Program for reading ICESat ATL06 data.')

# Define command-line arguments
parser = argparse.ArgumentParser(description=description)

parser.add_argument(
        'ifiles', metavar='ifile', type=str, nargs='+',
        help='path for ifile(s) to read (.h5).')

parser.add_argument(
        'ofiles', metavar='ofile', type=str, nargs='+',
        help='path for ofile(s) to save (.h5).')

parser.add_argument(
        '-b', metavar=('w','e','s','n'), dest='bbox', type=float, nargs=4,
        help=('bounding box for geographical region (deg)'),
        default=[None],)

parser.add_argument(
        '-n', metavar=('njobs'), dest='njobs', type=int, nargs=1,
        help="number of cores to use for parallel processing",
        default=[1],)

# Parser argument to variable
args = parser.parse_args()

# Read input from terminal
ipath = args.ifiles[0]
opath = args.ofiles[0]
bbox  = args.bbox
njobs = args.njobs[0]

# Get filelist of data to process
ifiles = list_files(ipath,endswith='.h5')

# Beam namnes
group = ['./gt1l','./gt1r','./gt2l','./gt2r','./gt3l','./gt3r']

# Beam indicies
beams = [1, 2, 3, 4, 5, 6]

# Loop trough and open files
def main(ifile, n=''):
    
    # Check if we already processed the file
    if ifile.endswith('_A.h5') or ifile.endswith('_D.h5'):
        return
    
    # Create beam index container
    beam_id = np.empty((0,))
    
    # Beam flag error
    flg_read_err = False

    # Loop trough beams
    for k in xrange(len(group)):
    
        # Load full data into memory (only once)
        with h5py.File(ifile, 'r') as fi:
            
            # Try to read vars
            try:
                
                # Read in varibales of interest (more can be added!)
                lat  = fi[group[k]+'/land_ice_segments/latitude'][:]
                lon  = fi[group[k]+'/land_ice_segments/longitude'][:]
                h_li = fi[group[k]+'/land_ice_segments/h_li'][:]
                t_dt = fi[group[k]+'/land_ice_segments/delta_time'][:]
                flag = fi[group[k]+'/land_ice_segments/atl06_quality_summary'][:]
                tref = fi['/ancillary_data/atlas_sdp_gps_epoch'][:]

            except:
                
                # Set error flag
                flg_read_err = True
                pass
    
        # Continue to next beam
        if flg_read_err: return

        # Save beam id for each surface height
        beam_id = np.hstack((beam_id, np.ones(lat.shape) * beams[k]))
        
        # Apply bounding box
        if bbox[0]:
        
            # Extract bounding box
            (lonmin, lonmax, latmin, latmax) = bbox
        
            # Select data inside bounding box
            ibox = (lon >= lonmin) & (lon <= lonmax) & (lat >= latmin) & (lat <= latmax)
        
        else:
            
            # Select all boolean
            ibox = np.ones(lat.shape,dtype=bool)

        # Quality flag, only keep good data and data inside box
        flag = (flag == 0) & ibox & (np.abs(h_li) < 10e3)
        
        # Only keep good data
        lat, lon, h_li, t_dt = lat[flag], lon[flag], h_li[flag], t_dt[flag]
        
        # Test for no data
        if len(h_li) == 0: return
        
        # Time in decimal years
        t_li = gps2dyr(t_dt + tref)
        
        # Time in GPS seconds
        t_gps = t_dt + tref
        
        # Determine track type
        (i_asc, i_des) = track_type(t_gps, lat)
        
        # Construct output name and path
        name, ext = os.path.splitext(os.path.basename(ifile))
        ofile = os.path.join(opath, name + ext)

        # Save track as ascending
        if len(lat[i_asc]) > 1:
            
            with h5py.File(ofile.replace('.h5', '_A.h5'), 'w') as fa:
            
                fa['lon']  = lat[i_asc]
                fa['lat']  = lon[i_asc]
                fa['h_li'] = h_li[i_asc]
                fa['t_yr'] = t_li[i_asc]
                        # Save track as desending
        if len(lat[i_des]) > 1:
            
            with h5py.File(ofile.replace('.h5', '_D.h5'), 'w') as fa:
                
                fa['lon']  = lat[i_des]
                fa['lat']  = lon[i_des]
                fa['h_li'] = h_li[i_des]
                fa['t_yr'] = t_li[i_des]
                # Do some updates
                
        print ofile

# Run main program
if njobs == 1:
    
    print 'running sequential code ...'
    [main(f) for f in ifiles]

else:
    
    print 'running parallel code (%d jobs) ...' % njobs
    from joblib import Parallel, delayed
    Parallel(n_jobs=njobs, verbose=5)(delayed(main)(f, n) for n, f in enumerate(ifiles))
