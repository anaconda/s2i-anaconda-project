IMAGE_PREFIX = conda/s2i-anaconda-project
BASE_IMAGES := $(basename $(wildcard *.dockerfile))
PLATFORM ?= local
TAG ?= latest
_comma = ,

ifeq ($(PLATFORM), local)
	DOCKER_BUILD=docker build
else
	DOCKER_BUILD=docker buildx build --platform $(PLATFORM) --push
endif

all: $(BASE_IMAGES)

.PHONY: $(BASE_IMAGES)
$(BASE_IMAGES):
	$(DOCKER_BUILD) $(foreach tag, $(subst $(_comma), ,$(TAG)), -t $(IMAGE_PREFIX)-$@:$(tag)) -f $@.dockerfile .

TEST_IMAGES := $(patsubst %,test-%,$(BASE_IMAGES))
test: $(TEST_IMAGES)

.PHONY: $(TEST_IMAGES)
$(TEST_IMAGES):
	docker build -t $(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate -f $(patsubst test-%,%,$@).dockerfile .
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-default
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-cmd server
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-multi-env default py38
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-multi-env py38 py38
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-multi-env py39 py39
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-env-vars "" "CMD_VAR=cmd_value\nPROJECT_VAR=project_value\n"
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-env-vars "env" "PROJECT_VAR=project_value"
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-lambda-py
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-lambda-api
