IMAGE_PREFIX = conda/s2i-anaconda-project
BASE_IMAGES := $(basename $(wildcard *.dockerfile))

all: $(BASE_IMAGES)

.PHONY: $(BASE_IMAGES)
$(BASE_IMAGES):
	docker build -t $(IMAGE_PREFIX)-$@ -f $@.dockerfile .

TEST_IMAGES := $(patsubst %,test-%,$(BASE_IMAGES))
test: $(TEST_IMAGES)

.PHONY: $(TEST_IMAGES)
$(TEST_IMAGES):
	docker build -t $(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate -f $(patsubst test-%,%,$@).dockerfile .
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-default
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run-cmd server
