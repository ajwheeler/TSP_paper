%.residuals.fits: plumbing/knit_output.jl
	julia plumbing/knit_output.jl $*

%.stackedresiduals.fits: %.residuals.fits plumbing/stack.jl
	julia plumbing/stack.jl $<

%.classified.fits: %.stackedresiduals.fits plumbing/model_comparison.jl model.jl
	julia plumbing/model_comparison.jl $<

%.flagged.csv: %.classified.fits plumbing/match_flagged.jl
	julia plumbing/match_flagged.jl $<

%.classified.tex: %.classified.fits plumbing/make_latex_table.py
	python3 plumbing/make_latex_table.py $< $@

.SECONDARY:
.PHONY: clean
clean:
	rm *.residuals.fits *.stackedresiduals.fits *.classified.fits *flagged.csv *classified.tex
