IMAGE_PREFIX = anaconda-project
BASE_IMAGES := $(basename $(wildcard *.dockerfile))

all: $(BASE_IMAGES)

.PHONY: $(BASE_IMAGES)
$(BASE_IMAGES):
	docker build -t $(IMAGE_PREFIX)-$@ -f $@.dockerfile .

TEST_IMAGES := $(patsubst %,test-%,$(BASE_IMAGES))

.PHONY: $(TEST_IMAGES)
$(TEST_IMAGES):
	docker build -t $(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate -f $(patsubst test-%,%,$@).dockerfile .
	IMAGE_NAME=$(IMAGE_PREFIX)-$(patsubst test-%,%,$@)-candidate test/run
