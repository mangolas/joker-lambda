
JOKER_BIN_URL = https://github.com/candid82/joker/releases/download/v0.14.2/joker-0.14.2-linux-amd64.zip

LAYER_LIB_ZIP = target/layer-joker-lib.zip
LAYER_LIB_NAME = joker-lib
LAYER_LIB_ARN = target/lib-version-arn

LAYER_BOOTSTRAP_ZIP = target/layer-joker-bootstrap.zip
LAYER_BOOTSTRAP_NAME = joker-bootstrap
LAYER_BOOTSTRAP_ARN = target/bootstrap-version-arn

LAMBDA_SRC = example/src/hello_world.clj
LAMBDA_NAME = hello-world
LAMBDA_ZIP = target/$(LAMBDA_NAME).zip
LAMBDA_HANDLER = hello_world.clj/handle

# LAMBDA_ROLE value *must* be given for 'create'
LAMBDA_ROLE_IAM = ${LAMBDA_ROLE}

.PHONY: create update layers
create: target/create-function
update: target/update-function
layers: $(LAYER_LIB_ARN) $(LAYER_BOOTSTRAP_ARN)

target/bin/joker:
	mkdir -p target/install target/bin
	curl -L $(JOKER_BIN_URL) -o target/install/joker.zip
	unzip target/install/joker.zip -d target/install
	mv target/install/joker $@

$(LAYER_LIB_ZIP): target/bin/joker
	mkdir -p target
	cd target; zip ../$@ bin/joker

$(LAYER_BOOTSTRAP_ZIP): bootstrap/bootstrap bootstrap/src/bootstrap.clj
	mkdir -p target
	zip -j $@ $^

$(LAYER_LIB_ARN): $(LAYER_LIB_ZIP)
	aws lambda publish-layer-version \
	--layer-name $(LAYER_LIB_NAME) \
	--zip-file fileb://$< | \
	jq -r '.LayerVersionArn' > $@

$(LAYER_BOOTSTRAP_ARN): $(LAYER_BOOTSTRAP_ZIP)
	aws lambda publish-layer-version \
	--layer-name $(LAYER_BOOTSTRAP_NAME) \
	--zip-file fileb://$< | \
	jq -r '.LayerVersionArn' > $@

$(LAMBDA_ZIP): $(LAMBDA_SRC)
	mkdir -p target
	zip -j $@ $^

target/create-function: LAYERS = $(shell cat $(LAYER_LIB_ARN); cat $(LAYER_BOOTSTRAP_ARN))
target/create-function: $(LAMBDA_ZIP) $(LAYER_LIB_ARN) $(LAYER_BOOTSTRAP_ARN)
	aws lambda create-function \
    --function-name $(LAMBDA_NAME) \
    --runtime provided \
    --handler $(LAMBDA_HANDLER) \
    --role $(LAMBDA_ROLE_IAM) \
    --layers $(LAYERS) \
    --zip-file fileb://$(LAMBDA_ZIP)
	touch $@

target/update-function-layers: LAYERS = $(shell cat $(LAYER_LIB_ARN); cat $(LAYER_BOOTSTRAP_ARN))
target/update-function-layers: $(LAYER_LIB_ARN) $(LAYER_BOOTSTRAP_ARN)
	aws lambda update-function-configuration \
    --function-name $(LAMBDA_NAME) \
    --layers $(LAYERS)
	touch $@

target/update-function: $(LAMBDA_ZIP) target/update-function-layers
	aws lambda update-function-code \
    --function-name $(LAMBDA_NAME) \
    --zip-file fileb://$(LAMBDA_ZIP)
	touch $@

delete-function:
	aws lambda delete-function \
	--function-name $(LAMBDA_NAME)
	rm -f target/update-function \
	      target/update-function-layers \
	      target/create-function
.PHONY: delete-function
