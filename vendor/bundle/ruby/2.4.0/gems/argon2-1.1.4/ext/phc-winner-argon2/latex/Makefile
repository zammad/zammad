TEX = pdflatex
BIB = bibtex

PROJECT = argon2-specs

.PHONY: all clean update

all:
	$(TEX) $(PROJECT).tex
	$(BIB) $(PROJECT).aux
	$(TEX) $(PROJECT).tex
	$(TEX) $(PROJECT).tex

clean:
	rm -rf *.aux *.bbl *.blg *.log *.out *.pdf *.toc *~

update:
	mv $(PROJECT).pdf ./../$(PROJECT).pdf
