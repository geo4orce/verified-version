PORT ?= 8000

.PHONY: lint serve
lint:
	npx --yes html-validate@11.7.0 index.html 404.html

serve:
	node tools/serve.mjs $(PORT)
