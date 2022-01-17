# Convenience makefile to build the dev env and run common commands
# Based on https://github.com/teamniteo/Makefile

.PHONY: all
all: tests

# Testing and linting targets
all = false

.PHONY: lint
lint: types
# 1. get all unstaged modified files
# 2. get all staged modified files
# 3. get all untracked files
# 4. run pre-commit checks on them
ifeq ($(all),true)
	@pre-commit run --hook-stage push --all-files
else
	@{ git diff --name-only ./; git diff --name-only --staged ./;git ls-files --other --exclude-standard; } \
			| sort | uniq | sed 's|backend/||' \
			| xargs pre-commit run --hook-stage push --files
endif

.PHONY: types
types:
	@mypy src/pareto
	@cat ./typecov/linecount.txt
	@command typecov 100 ./typecov/linecount.txt


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
pytest_args = -k $(filter) $(args) --ignore=src/pareto/tests/browser
ifeq ($(args),"")
	pytest_args = -k $(filter) --ignore=src/pareto/tests/browser
endif
verbosity = ""
ifeq ($(full_suite),"false")
	verbosity = -vv
endif
full_suite_args = ""
ifeq ($(full_suite),"true")
	full_suite_args = --durations 10 --cov=pareto --cov-branch --cov-report html --cov-report xml:cov.xml --cov-report term-missing --cov-fail-under=100
endif

.PHONY: unit
unit:
ifeq ($(full_suite),"true")
	@python -m pareto.scripts.drop_tables -c etc/test.ini
endif
ifndef path
	@pytest src/pareto $(verbosity) $(full_suite_args) $(pytest_args)
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