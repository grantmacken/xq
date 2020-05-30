SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
###################################
include .env .version.env .gce.env
include .inc/common.mk
###################################
# note: ghToken should be defined on gihub actions
ifeq ($(origin ghToken),undefined)
  ghToken := $(shell cat ../.github-access-token)
endif

.PHONY: help
help:
	@cat << EOF
	ok
	EOF

.PHONY: test
test:
	@pushd tests/proxy &>/dev/null
	@make -silent
	@popd &>/dev/null

.PHONY: up
up: clean-xq-run xq-up code proxy-up

.PHONY: down
down: proxy-down xqerl-down

.PHONY: proxy-up
proxy-up:
	@$(MAKE) -f .inc/ngxContainer.mk ngx-up

.PHONY: proxy-down
proxy-down:
	@$(MAKE) -f .inc/ngxContainer.mk ngx-down

.PHONY: gc-init
gc-init:
	@pushd gcloud &>/dev/null
	@$(if $(GITHUB_ACTIONS),$(MAKE) $@,echo ' NOTE: target can only be run on githb actions')
	@popd &>/dev/null

.PHONY: certs-into-vol
certs-into-vol:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: certs-check
certs-check:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: certs-clean
certs-clean:
	@pushd gcloud &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: ngx
ngx:
	@pushd proxy &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: nxg-clean
ngx-clean:
	@pushd proxy &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: ngx-reload
ngx-reload:
	@$(MAKE) -f .inc/ngxContainer.mk $@

.PHONY: proxy-tests
proxy-tests:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent
	@popd &>/dev/null

.PHONY: proxy-info
proxy-info:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent info
	@popd &>/dev/null

.PHONY: xq-up
xq-up:
	@$(MAKE) -f .inc/xqContainer.mk

.PHONY: clean-xq-run
clean-xq-run:
	@# in case of unclean shutdowm
	@$(MAKE) -f .inc/xqContainer.mk clean-xq-run

.PHONY: xq-down
xq-down:
	@$(MAKE) -f .inc/xqContainer.mk $@

.PHONY: xq-info
xq-info:
	@$(MAKE) -f .inc/xqContainer.mk $@

.PHONY: xq-info-more
xq-info-more:
	@$(MAKE) -f .inc/xqContainer.mk $@


.PHONY: xq-build
xq-build:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE)
	@popd &>/dev/null

.PHONY: xq-clean
xq-clean:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) clean
	@popd &>/dev/null

.PHONY: check-xq-routes
check-xq-routes:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: check-xq-routes-more
check-xq-routes-more:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

## will error if error
.PHONY: watch
watch:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true; do $(MAKE) || true;  \
 inotifywait -qre close_write .  &>/dev/null; done
	@popd &>/dev/null

.PHONY: watch-content
watch-content:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true; do $(MAKE) content || true;  \
 inotifywait -qre close_write .  &>/dev/null; done
	@popd &>/dev/null


.PHONY: code
code:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: content
content:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-code
clean-code:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: assets
assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: clean-assets
clean-assets:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: db-tar-deploy
db-tar-deploy:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) $@
	@popd &>/dev/null

.PHONY: pull-pkgs
pull-pkgs:
	@echo $(ghToken) | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin
	@docker pull $(XQERL_DOCKER_IMAGE):$(XQ_VER)
	@docker pull $(PROXY_DOCKER_IMAGE):$(NGX_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-scour/scour:$(SCOUR_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:$(ZOPFLI_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:$(CSSNANO_VER)