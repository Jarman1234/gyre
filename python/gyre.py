# Module   : gyre
# Purpose  : process GYRE output
#
# Copyright 2013 Rich Townsend
#
# This file is part of GYRE. GYRE is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, version 3.
#
# GYRE is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Imports

import h5py
import numpy as np

# Read a GYRE eigenvalue file

def read_eigval (filename) :

    # Read the data

    file = h5py.File(filename, 'r')

    n = file.attrs['n']
    l = file.attrs['l']

    freq_units = file.attrs['freq_units']

    freq = file['freq'][:].astype(complex)
    n_p = file['n_p'][:]
    n_g = file['n_g'][:]

    E = file['E'][:]

    file.close()

    # Sort the data by re(omega) (this is because gyre/MPI can produce
    # data out-of-order)

    i = np.argsort(np.real(freq))

    freq = freq[i]
    n_p = n_p[i]
    n_g = n_g[i]

    E = E[i]

    # Return the data

    return {'n'          : n,
            'l'          : np.array([l for i in range(0,freq.size)]),
            'freq'       : freq,
            'freq_units' : freq_units,
            'n_p'        : n_p,
            'n_g'        : n_g,
            'n_cowl'     : n_p-n_g,
            'E'          : E}

#


# Read a GYRE eigenfunction file

def read_eigfunc (filename) :

    # Read the data

    file = h5py.File(filename, 'r')

    n = file.attrs['n']
    n_e = file.attrs['n_e']

    n_p = file.attrs['n_p']
    n_g = file.attrs['n_g']

    lambda_0 = file.attrs['lambda_0']
    l = file.attrs['l']

    freq = file.attrs['freq']
    freq_units = file.attrs['freq_units']
    
    x = file['x'][:]
    y = file['y'][:].astype(complex)

    dE_dx = file['dE_dx'][:]

    file.close()

    # Return the data

    return {'n'          : n,
            'n_e'        : n_e,
            'n_p'        : n_p,
            'n_g'        : n_g,
            'n_cowl'     : n_p-n_g,
            'lambda_0'   : lambda_0,
            'l'          : l,
            'freq'       : freq,
            'freq_units' : freq_units,
            'x'          : x,
            'y'          : y,
            'dE_dx'      : dE_dx}

#
