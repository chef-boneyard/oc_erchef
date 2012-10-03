DEPS=$(CURDIR)/deps
XCHECK_APPS=chef_authn chef_authz chef_certgen chef_db chef_index chef_objects chef_wm \
	    oc_chef_wm sqerl

# The release branch should have a file named USE_REBAR_LOCKED
use_locked_config = $(wildcard USE_REBAR_LOCKED)
ifeq ($(use_locked_config),USE_REBAR_LOCKED)
  rebar_config = rebar.config.lock
else
  rebar_config = rebar.config
endif
REBAR = rebar -C $(rebar_config)

all: compile

# Jenkins build target
ci: compile xcheck

compile: $(DEPS)
	@$(REBAR) compile

compile_skip:
	@$(REBAR) compile skip_deps=true

xcheck:
	@scripts/xcheck $(XCHECK_APPS)
clean:
	@$(REBAR) clean

# clean and allclean do the same thing now. Leaving allclean for now
# in case there are scripts that depend on it.
allclean:
	@$(REBAR) clean

update: compile
	@cd rel/oc_erchef;bin/oc_erchef restart

distclean: relclean
	@rm -rf deps
	@$(REBAR) clean

test: eunit

eunit:
	@$(REBAR) eunit app=chef_common,chef_rest

test-common:
	@$(REBAR) eunit app=chef_common

test-rest:
	@$(REBAR) eunit app=chef_rest

tags:
	find deps -name "*.[he]rl" -print | etags -

## KAS: Temporarily disabling dialyzer target until project structure is sorted
#dialyze: dialyzer

#dialyzer:
#	dialyzer -Wrace_conditions -Wspecdiffs apps/*/ebin

update_locked_config:
	@./lock_deps deps meck

rel: rel/oc_erchef

devrel: rel
	@/bin/echo -n Symlinking deps and apps into release
	@$(foreach dep,$(wildcard deps/*), /bin/echo -n .;rm -rf rel/oc_erchef/lib/$(shell basename $(dep))-* \
	   && ln -sf $(abspath $(dep)) rel/oc_erchef/lib;)
	@/bin/echo done.
	@/bin/echo  Run \'make update\' to pick up changes in a running VM.

rel/oc_erchef: compile
	@/bin/echo 'building OTP release package for'
	@/bin/echo '                _          _  '
	@/bin/echo '               | |        | | '
	@/bin/echo ' _   ,_    __  | |     _  | | '
	@/bin/echo '|/  /  |  /    |/ \   |/  |/  '
	@/bin/echo '|__/   |_/\___/|   |_/|__/|__/'
	@/bin/echo '                          |\  '
	@/bin/echo '                          |/  '
	@/bin/echo
	@/bin/echo "using rebar as: $(REBAR)"
	@$(REBAR) generate overlay_vars=db_vars.config

relclean:
	@rm -rf rel/oc_erchef

$(DEPS):
	@echo "Fetching deps as: $(REBAR)"
	@$(REBAR) get-deps
