%.residuals.fits: plumbing/knit_output.jl
	julia plumbing/knit_output.jl $*

%.classified.fits: %.residuals.fits plumbing/model.jl
	julia plumbing/model_check.jl $<

%.classified.tex: %.classified.fits plumbing/make_latex_table.py
	python3 plumbing/make_latex_table.py $< $@

.PHONY: clean
clean:
	rm *.residuals.fits *.classified.fits
