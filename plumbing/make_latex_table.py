import pandas as pd
from astropy.table import Table
from astropy.io import ascii
import sys
import numpy as np
np.set_printoptions(precision=2)

t = Table(Table.read(sys.argv[1], memmap=True)[1:10])
todel = []
for col in t.columns:
    if col in ['neighbors']:
        t[col] = [[round(cc, 4) for cc in c] for c in t[col]]
    if col in ['diff', 'err', 'loss']:
        todel.append(col)
for col in todel:
    del(t[col])

ncols = 0
for tup in t.dtype.descr:
    ncols += 1
    if len(tup) == 2 and tup[1][1] == 'f':
        t[tup[0]] = [round(c, 4) for c in t[tup[0]]]
ascii.write(t, sys.argv[2], names=[r"\texttt{{{}}}".format(n.replace("_", r"\_")) for n in t.columns],
        format='aastex', overwrite=True,
        formats={}, col_align="l"*ncols)

#for col in t.columns:
#    if col in ['neighbors', 'weights', 'diff', 'err', 'loss']:
#        t[col] = [np.array_str(c, precision=3) for c in t[col]]
#
#df = t.to_pandas()
#with open(sys.argv[2], 'w') as f:
#    f.write(df.to_latex(index=False, na_rep="", 
#            float_format="{:0.2f}".format))
