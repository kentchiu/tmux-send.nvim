TESTS_INIT=scripts/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test test-file test-watch clean format check-format

# Run all tests
test:
	@echo "Running all tests..."
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"

# Run specific test file
# Usage: make test-file FILE=tests/config_spec.lua
test-file:
	@echo "Running test file: $(FILE)"
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedFile $(FILE)"

# Watch mode for development
test-watch:
	@echo "Watching for file changes..."
	@while true; do \
		make test; \
		inotifywait -qre modify ${TESTS_DIR} lua/; \
	done

# Clean up
clean:
	@echo "Cleaning up..."
	@rm -rf tests/*.log

# Format code with stylua
format:
	@echo "Formatting Lua files..."
	@stylua lua/ tests/ --config-path stylua.toml

# Check if code is formatted
check-format:
	@echo "Checking code format..."
	@stylua lua/ tests/ --check --config-path stylua.toml
