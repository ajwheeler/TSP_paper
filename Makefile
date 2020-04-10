%.residuals.fits: #plumbing/knit_output.jl
	julia plumbing/knit_output.jl $*

%.classified.fits: %.residuals.fits #plumbing/model.jl
	julia plumbing/model_check.jl $<

%.flagged.csv: %.classified.fits plumbing/match_flagged.jl
	julia plumbing/match_flagged.jl $<

%.classified.tex: %.classified.fits plumbing/make_latex_table.py
	python3 plumbing/make_latex_table.py $< $@

.PHONY: clean
clean:
	rm *.residuals.fits *.classified.fits
