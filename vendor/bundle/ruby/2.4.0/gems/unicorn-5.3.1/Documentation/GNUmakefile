all::

PANDOC = pandoc
PANDOC_OPTS = -f markdown --email-obfuscation=none
pandoc = $(PANDOC) $(PANDOC_OPTS)
pandoc_html = $(pandoc) --toc -t html --no-wrap

man1 := $(addsuffix .1,unicorn unicorn_rails)
html1 := $(addsuffix .html,$(man1))

all:: html man

html: $(html1)
man: $(man1)

install-html: html
	mkdir -p ../doc/man1
	install -m 644 $(html1) ../doc/man1

install-man: man
	mkdir -p ../man/man1
	install -m 644 $(man1) ../man/man1

%.1: %.1.txt
	$(pandoc) -s -t man < $< > $@+ && mv $@+ $@
%.1.html: %.1.txt
	$(pandoc_html) < $< > $@+ && mv $@+ $@

clean::
	$(RM) $(man1) $(html1)
