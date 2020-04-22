TESTS = $(patsubst %,%/success,$(shell find tests -mindepth 1 -maxdepth 1 -type d))
DURT_SRC = $(shell find durt -type f)

all: $(TESTS)
	@echo "-----------------------------"
	@echo "--- All tests successful! ---"
	@echo "-----------------------------"

tests/%/success: tests/%/expected_output tests/%/actual_output
	diff $^
	touch $@

tests/%/actual_output: tests/%/bin/main.dart \
	tests/%/bin/bindings.dart \
	target/debug/lib%.so \
	tests/%/pubspec.lock
	LD_LIBRARY_PATH=target/debug dart $(word 1,$^) | tee $@

# TODO: this will also generate tests/%/.packages and tests/%/.dart_tool
tests/%/pubspec.lock: tests/%/pubspec.yaml
	cd $(patsubst %,tests/%/pubspec.yaml,$(word 1,$^)); pub get

tests/%/bin/bindings.dart: tests/%/src/lib.rs tests/%/Cargo.toml $(DURT_SRC)
	cargo run --package durt > $@

# TODO: something's off here: if updating ffishim library, those tests won't be
# re-ran as ffishim sources are not part of the dependency. how to fix?
target/debug/lib%.so: tests/%/src/lib.rs tests/%/Cargo.toml
	cargo build --package $(patsubst target/debug/lib%.so,%,$@)

clean:
	# Anything that needs cleaning can be listed in the
	# .gitignore file. The `git clean -fdX` call removes all
	# files listed in the .gitignore.
	git clean -fdX
