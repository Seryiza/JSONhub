SHELL := /usr/bin/env bash
MAKEFLAGS += --no-print-directory

.PHONY: shell run-via-playwright test-via-playwright

shell:
	nix develop

run-via-playwright:
	# `make run-via-playwright foo` treats `foo` as another goal; filter it back into a script name.
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make run-via-playwright <script-name>"; \
		exit 1; \
	fi
	@./nix/scripts/run-via-playwright.sh $(filter-out $@,$(MAKECMDGOALS))

test-via-playwright:
	# `make test-via-playwright foo` treats `foo` as another goal; filter it back into a script name.
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make test-via-playwright <script-name>"; \
		exit 1; \
	fi
	@./nix/scripts/check-via-playwright.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
