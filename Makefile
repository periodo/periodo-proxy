HIGHLIGHT_THEMES := /opt/homebrew/share/highlight/themes/

VOCAB_FILES := $(shell find vocab -name '*.ttl')
SHAPE_FILES := $(shell find shapes -name '*.ttl')

.PHONY: all clean stage publish purge purge-published

all: vocab.html

clean:
	rm -f vocab.ttl vocab.html nginx.conf

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

stage: APP_CONFIG = fly.stage.toml
stage: UPSTREAM_HOST = periodo-server-dev.flycast

publish: APP_CONFIG = fly.publish.toml
publish: UPSTREAM_HOST = periodo-server.flycast

stage publish: clean vocab.html nginx.conf
	fly deploy --config $(APP_CONFIG)

purge: CACHE_PURGER = http://periodo-proxy-dev.internal:8081
purge-published: CACHE_PURGER = http://periodo-proxy.internal:8081

purge purge-published:
	curl -i -X POST \
	-H "Content-Type: application/json" \
	-H "Content-Length: 0" \
	$(CACHE_PURGER)

nginx.conf: nginx.template.conf
	UPSTREAM_HOST=$(UPSTREAM_HOST) \
	envsubst '$$UPSTREAM_HOST' < $< > $@
