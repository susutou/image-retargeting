run: preview
	
preview: produce
	
produce: intermediate
	cp template.tex slides.tex
	sed -i.bakup '/insert point/r slides_temp.tex' slides.tex
	xelatex slides.tex

	# clean-up
	rm slides_temp.tex
	rm slides.tex
	rm *.aux
	rm *.nav
	rm *.log
	rm *.out
	rm *.snm
	rm *.toc
	rm *.bakup
	rm *.vrb
	
intermediate:
	pandoc -t beamer slides.md -o slides_temp.tex