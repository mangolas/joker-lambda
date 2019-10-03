
LIB = target/layer-joker-lib.zip
BOOTSTRAP = target/layer-joker-bootstrap.zip

PHONY: all
all: target/update-lib target/update-bootstrap

$(LIB): bin/joker
	mkdir -p target
	zip $@ $^

$(BOOTSTRAP): bootstrap bootstrap.clj
	mkdir -p target
	zip $@ $^

target/update-lib: $(LIB)
	aws lambda publish-layer-version \
	--layer-name joker-lib \
	--zip-file fileb://$<
	touch $@

target/update-bootstrap: $(BOOTSTRAP)
	aws lambda publish-layer-version \
	--layer-name joker-bootstrap \
	--zip-file fileb://$<
	touch $@
