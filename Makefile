PROJECT = murmerl3



TEST_DEPS=proper

BUILD_DEPS = elvis_mk
dep_elvis_mk = git https://github.com/inaka/elvis.mk.git master

DEP_PLUGINS = elvis_mk

DIALYZER_OPTS += --src -r test

include erlang.mk
