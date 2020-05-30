
####################
### XQERL UP DOWN ##
####################

define xqRun
 docker run --rm  \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountBin) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_IMAGE)
endef

.PHONY: clean-xq-run
clean-xq-run:
	rm -f $(T)/xq-run/*

.PHONY: xq-up
xq-up: $(T)/xq-run/network.check $(T)/xq-run/volumes.check $(T)/xq-run/xqerl-up.check

.PHONY: xq-down
xq-down: clean-xq-run
	@$(if $(call containerRunning,$(XQ)),echo -n ' - stopping container: ' && docker stop $(XQ),)

$(T)/xq-run/xqerl-up.check:
	@mkdir -p $(dir $@)
	@docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	@if ! grep -oP '^Up(.+)$$' $@ &>/dev/null ; then 
	$(xqRun) && sleep 2 && docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	fi
	@$(if $(call containerRunning,$(XQ)),\
 $(call Tick, - xqerl: [ $$(tail -1 $@) ]),\
 $(call Cross,- xqerl: [ down ]))
	echo

$(T)/xq-run/network.check:
	@mkdir -p $(dir $@)
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)
	@$(call Tick, - network: [ $(NETWORK) ]) 
	@echo

$(T)/xq-run/volumes.check:
	@mkdir -p $(dir $@)
	@# might as well check proxy volumes as well
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,xqerl-compiled-code)
	@$(call MustHaveVolume,xqerl-database)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,letsencrypt)
	@$(call Tick, - volumes OK!)
	@echo

.PHONY: xq-info
xq-info:
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: '
	@docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
	@echo;printf %60s | tr ' ' '-' && echo

xq-info-more:
	@echo -n '- working dir: '
	@$(EVAL) '{ok,CWD}=file:get_cwd(),list_to_atom(CWD).'
	@echo -n '-        node: '
	@$(EVAL) 'erlang:node().'
	@#$(EVAL) 'erlang:nodes().'
	@echo -n '-      cookie: '
	@$(EVAL) 'erlang:get_cookie().'
	@echo -n '-        host: '
	@$(EVAL) '{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME).'
	@echo;printf %60s | tr ' ' '-' && echo
	@#$(EVAL) $(compiledLibs)
