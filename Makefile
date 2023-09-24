HIGHLIGHT_THEMES := /opt/homebrew/share/highlight/themes/

VOCAB_FILES := $(shell find vocab -name '*.ttl')
SHAPE_FILES := $(shell find shapes -name '*.ttl')
SERVER_VERSION := $(shell git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)

.PHONY: all clean stage publish

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

nginx.conf: nginx.template.conf
	UPSTREAM_HOST=$(UPSTREAM_HOST) \
	SERVER_VERSION=$(SERVER_VERSION) \
	envsubst '$$UPSTREAM_HOST $$SERVER_VERSION' < $< > $@
