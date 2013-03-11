SRC = $(shell find . -name '*.coffee')
LIB = $(SRC:%.coffee=%.js)

all: lib

lib: $(LIB)

watch:
	watch -n 1 $(MAKE) all

publish:
	git push
	git push --tags
	npm publish

%.js: %.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

clean:
	rm -rf $(LIB)
