"""Plot reference photon height along a ground track.

Stephen Holland, ICESat-2 Science Computing Facility, 208-03-04.

E-Mail from Tom Neumann, Apr 2, 2018 at 4:40 pm.

    To that end, could you send me a couple of lines that would open
    an ATL03, and plot (let's say) reference photon height against
    distance along track?  I picked this one since it would also
    illustrate how to use the reference photon index parameter to
    extract the heights from the /gtx/heights/ group.

"""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import argparse
import posixpath
import os
import sys

import h5py
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.pyplot as plt
import numpy as np


def photon_heights(infile, track, outroot, confidence, plot=False,
                   overwrite=False, verbose=False):
    """Return distance and reference photon height along a ground track.

    Parameters
    ----------
    infile : str
        Name of ATL03 file to read.
    track : str
        Name of ground track to read.  Value is one of gt1l, gt1r,
        gt2l, gt2r, gt3l, or gt3r.
    outroot : str
        Root name of output files.
    confidence : int
        Minimum signal confidence for plotting photons.
    plot : bool, optional
        Turn on plotting.
    overwrite : bool, optional
        Allow function to overwrite existing files if True.
    verbose : bool, optional
        Turn on additional output.

    Returns
    -------
    status : int
        Non-zero indicates an error.

    """
    if confidence is None:
        confidence = 4  # High confidence.

    # Open the input ATL03 file.
    try:
        f_in = h5py.File(infile, "r")
    except (IOError, RuntimeError) as err:
        print("{0}: error: {1}".format(__file__, err), file=sys.stderr)
        return 1

    # Test the requested ground track.  The posixpath trick prevents a
    # double initial slash.
    track = posixpath.normpath(posixpath.join("/", track))
    if track not in f_in:
        message = "ground track ", track + " not found in " + infile
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return 1

    # Read along-track distance.
    x_name = '/'.join([track, "heights/dist_ph_along"])
    if x_name not in f_in:
        message = x_name + " not found in " + infile
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return 1
    dist_ph_along = f_in[x_name][...]
    print("TEST: len(dist_ph_along) =", len(dist_ph_along))

    # Determine distance from equator for each photon.
    distance = total_along_track_distance(f_in, track, dist_ph_along)
    if distance is None:
        return 1

    # Read photon height.
    y_name = '/'.join([track, "heights/h_ph"])
    if y_name not in f_in:
        message = y_name + " not found in " + infile
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return 1
    height = f_in[y_name][...]  # Ellipses extract data into a NumPy array.

    if verbose:
        print("read", len(distance), "photons from", track, "in", infile)

    # Apply the signal confidence mask.
    take = make_signal_conf_mask(f_in, track, confidence)
    print("TEST: start masking data...")
    distance = distance[take]
    height = height[take]
    print("TEST: done masking data")
    if verbose:
        print(len(distance), "photons with confidence >=", confidence)
        print(len(height), "photons with confidence >=", confidence)

    outfile = outroot + ".txt"
    try:
        write_data(outfile, distance, height, overwrite=overwrite,
                   verbose=verbose)
    except (IOError, RuntimeError) as err:
        print("{0}: error: {1}".format(__file__, err), file=sys.stderr)
        return 1

    if plot:
        """
        # Generate signal confidence mask.
        take = make_signal_conf_mask(f_in, track, confidence)
        """

        title = f_in.filename.rpartition("/")[2]
        x_label = (f_in[x_name].attrs.get("long_name") + " (" +
                   f_in[x_name].attrs.get("units") + ")")
        y_label = (f_in[y_name].attrs.get("long_name") + " (" +
                   f_in[y_name].attrs.get("units") + ")")

        pdffile = outroot + ".pdf"
        plot_data(distance, height, mask=None,
                  title=title, x_label=x_label, y_label=y_label,
                  pdffile=pdffile, verbose=verbose)

    f_in.close()

    return 0


def total_along_track_distance(f_in, track, dist_ph_along):
    """Compute total along track distance from equator.

    Parameters
    ----------
    f_in : file
        Open ATL03 file handle.
    track : str
        Name of ground track to read.  Value is one of gt1l, gt1r,
        gt2l, gt2r, gt3l, or gt3r.
    dist_ph_along : list or NumPy array
        ATL03 /gtXN/heights/dist_ph_along data.

    Returns
    -------
    distance : NumPy array or None
        Total along track distance from equator.  None indicates an
        error occurred.

    """
    name = '/'.join([track, "geolocation/ph_index_beg"])
    if name not in f_in:
        message = name + " not found in " + f_in.filename
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return None
    ph_index_beg = f_in[name][...]

    name = '/'.join([track, "geolocation/segment_ph_cnt"])
    if name not in f_in:
        message = name + " not found in " + f_in.filename
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return None
    segment_ph_cnt = f_in[name][...]

    name = '/'.join(["", track, "geolocation/segment_dist_x"])
    if name not in f_in:
        message = name + " not found in " + f_in.filename
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        return None
    segment_dist_x = f_in[name][...]

    distance = np.zeros(len(dist_ph_along))
    j = -1
    for i, start in enumerate(ph_index_beg):
        # The index values in ph_index_bg are 1-based.
        start -= 1  # Index of first photon in geosegment.
        stop = start + segment_ph_cnt[i]
        segment_start = segment_dist_x[i]
        for dist in dist_ph_along[start:stop]:
            j += 1
            distance[j] = segment_start + dist

    return distance


def make_signal_conf_mask(f_hdf5, track, confidence):
    """Create mask based on minimum signal confidence.

    Parameters
    ----------
    f_hdf5 : file
        Open ATL03 file handle.
    track : str
        Name of ground track to read.  Value is one of gt1l, gt1r,
        gt2l, gt2r, gt3l, or gt3r.
    confidence : int
        Minimum signal confidence for plotting photons.

    Returns
    -------
    mask : NumPy array or None
        True if /track/heights/signal_conf_ph is True for at least one
        surface type.  None indicates an error occurred.

    """
    # Read signal confidence dataset.
    name = '/'.join([track, "heights/signal_conf_ph"])
    if name in f_hdf5:
        signal_conf_ph = f_hdf5[name][...]
        mask = np.array([np.any(row >= confidence) for row in signal_conf_ph])
    else:
        message = name + " not found in " + f_hdf5.filename
        print("{0}: error: {1}".format(__file__, message), file=sys.stderr)
        mask = None

    return mask


def plot_data(x, y, mask=None, title=None, x_label=None, y_label=None,
              pdffile=None, verbose=False):
    """Plot one dataset against another with an optional mask.

    Parameters
    ----------
    x : list or NumPy array
        Data for X axis.
    y : list or NumPy array
        Data for Y axis.
    mask : list or np.array, optional
        Only plot data points where mask is True.
    title : str, optional
        Plot title
    x_label : str, optional
        Label for X axis
    y_label : str, optional
        Label for Y axis
    verbose : bool, optional
        Turn on additional output.

    Returns
    -------
    This function does not return anything.

    """
    if mask is None:
        mask = np.array(len(x) * [True])
    else:
        mask = np.array(mask)
    if len(mask) != len(x):
        message = "mask and data have different lengths, unable to plot"
        print("{0}: warning: {1}".format(__file__, message), file=sys.stderr)
        print("TEST: len(mask), len(x) =", len(mask), len(x))
        return

    # Filter the data.
    x = x[mask]
    y = y[mask]

    if verbose:
        print("plotting", len(x), "data points")

    # Plot the data.
    plt.plot(x, y, "r.")
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(title)
    plt.show()

    # Save the plot to a file.
    if pdffile:
        if verbose:
            print("saving plot to", pdffile)
        pdf = PdfPages(pdffile)
        pdf.savefig()
        pdf.close()

    return


def write_data(outfile, distance, height, overwrite=False, verbose=False):
    """Write height along track data to output file.

    Parameters
    ----------
    outfile : str
        Name of output file.
    distance : list
        Distance along track.
    height : list
        Photon height.
    infile : str
        Name of input data file.
    track : str
        Ground track for data.
    overwrite : bool, optional
        Allow function to overwrite existing files if True.
    verbose : bool, optional
        Turn on additional output.

    Returns
    -------
    This function does not return anything.

    Raises
    ------
    IOError
        Error opening output file.
    RuntimeError
        Unauthorized attempt to overwrite an existing file.

    """
    if os.path.isfile(outfile) and not overwrite:
        message = outfile + " already exists and overwrite set to False"
        raise RuntimeError(message)

    try:
        f_out = open(outfile, mode="w")
    except IOError:
        raise

    print("#  Distance (m)     Height (m)", file=f_out)
    for i, _ in enumerate(distance):
        print("{0:15.3f}{1:15.3f}".format(distance[i], height[i]), file=f_out)
    f_out.close()
    if verbose:
        print("wrote", len(distance), "photons to", outfile)
    return


def cl_args(description):
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("infile", type=str,
                        help="nput ATL03 file")
    parser.add_argument("track", type=str,
                        help="ground track: gt1l,gt1r,gt2l,gt2r,gt3l,gt3r,")
    parser.add_argument("outroot", type=str,
                        help="output file root name")
    parser.add_argument("-c", type=int, default=2,
                        help="minimum signal confidence to plot (0-4)"
                             "default is 4 (high)")
    parser.add_argument("-f", action="store_true",
                        help="force overwriting output data file")
    parser.add_argument("-p", action="store_true",
                        help="plot photon heights")
    parser.add_argument("-v", action="store_true",
                        help="increase the output verbosity")
    return parser.parse_args()


def main(argv=None):
    """Plot reference photon height along a ground track."""
    if argv is None:
        argv = sys.argv
    args = cl_args(__doc__)  # Parse command line arguments.

    infile = args.infile
    track = args.track
    outroot = args.outroot
    confidence_min = args.c
    overwrite = args.f
    plot = args.p
    verbose = args.v

    if verbose:
        print()
        print("          input ATLAS granule:", infile)
        print("                 ground track:", track)
        print("                 plot results:", plot)
        if plot:
            print("    minimum signal confidence:", confidence_min)
        print("             output file root:", outroot)
        print("     overwrite existing files:", overwrite)
        print("                 verbose mode:", verbose)
        print()

    try:
        status = photon_heights(infile, track, outroot,
                                confidence_min, plot=plot,
                                overwrite=overwrite, verbose=verbose)
    except (IOError, RuntimeError) as err:
        print("{0}: error: {1}".format(__file__, err), file=sys.stderr)
        status = 1

    return status


if __name__ == "__main__":
    global_status = main(None)
    sys.exit(global_status)
