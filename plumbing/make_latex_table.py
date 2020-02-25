import pandas as pd
from astropy.table import Table
from astropy.io import ascii
import sys
import numpy as np
np.set_printoptions(precision=2)

t = Table(Table.read(sys.argv[1], memmap=True)[1:10])
for col in t.columns:
    if col in ['neighbors', 'weights', 'diff', 'err', 'loss']:
        t[col] = [[round(cc, 4) for cc in c] for c in t[col]]
for tup in t.dtype.descr:
    if len(tup) == 2 and tup[1][1] == 'f':
        t[tup[0]] = [round(c, 4) for c in t[tup[0]]]
ascii.write(t, sys.argv[2], format='aastex', overwrite=True,
        formats={})
#for col in t.columns:
#    if col in ['neighbors', 'weights', 'diff', 'err', 'loss']:
#        t[col] = [np.array_str(c, precision=3) for c in t[col]]
#
#df = t.to_pandas()
#with open(sys.argv[2], 'w') as f:
#    f.write(df.to_latex(index=False, na_rep="", 
#            float_format="{:0.2f}".format))
