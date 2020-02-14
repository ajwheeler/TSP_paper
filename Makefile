%.residuals.fits: #plumbing/knit_output.jl
	julia plumbing/knit_output.jl $*

%.classified.fits: %.residuals.fits #plumbing/model.jl
	julia plumbing/model_check.jl $<

.PHONY: clean
clean:
	rm *.residuals.fits *.classified.fits
