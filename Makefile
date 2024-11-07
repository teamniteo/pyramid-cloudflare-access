# Convenience makefile to build the dev env and run common commands
# Based on https://github.com/teamniteo/Makefile

.PHONY: all
all: tests

# Testing and linting targets
all = false

.PHONY: lint
lint:
	@black --diff .
	@isort --diff --check-only -rc .

.PHONY: types
types:
	@mypy pyramid_cloudflare_access 
	@cat ./typecov/linecount.txt
	@command typecov 90 ./typecov/linecount.txt


# anything, in regex-speak
filter = "."

# additional arguments for pytest
full_suite = "false"
ifeq ($(filter),".")
	full_suite = "true"
endif
ifdef path
	full_suite = "false"
endif
args = ""
pytest_args = -k $(filter) $(args)
ifeq ($(args),"")
	pytest_args = -k $(filter)
endif
verbosity = ""
ifeq ($(full_suite),"false")
	verbosity = -vv
endif
full_suite_args = ""
ifeq ($(full_suite),"true")
	full_suite_args = --cov=pyramid_cloudflare_access --cov-branch --cov-report html --cov-report xml:cov.xml --cov-report term-missing --cov-fail-under=100
endif

.PHONY: unit
unit:
ifndef path
	@pytest pyramid_cloudflare_access $(verbosity) $(full_suite_args) $(pytest_args)
else
	@pytest $(path)
endif

.PHONY: tests
tests: lint unit

fmt: format
black: format
format:
	@poetry run isort -rc --atomic pyramid_cloudflare_access
	@poetry run autoflake --remove-all-unused-imports -i -r pyramid_cloudflare_access
	@poetry run black pyramid_cloudflare_access