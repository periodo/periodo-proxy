HIGHLIGHT_THEMES := /opt/homebrew/share/highlight/themes/

VOCAB_FILES := $(shell find vocab -name *.ttl)
SHAPE_FILES := $(shell find shapes -name *.ttl)

.PHONY: all clean

all: vocab.html

clean:
	rm -f vocab.ttl vocab.html

vocab.ttl: $(VOCAB_FILES) $(SHAPE_FILES)
	./bin/ttlcat $^ > $@

vocab.html: vocab.ttl
	cp -f periodo.theme $(HIGHLIGHT_THEMES)
	highlight \
	--input=$< \
	--style=periodo.theme \
	--line-numbers \
	--anchors \
	--anchor-prefix='replaceme' \
	--doc-title='PeriodO vocabulary and shapes' \
	--inline-css \
	--font-size=12 \
	| sed 's/replaceme_/line-/' > $@
