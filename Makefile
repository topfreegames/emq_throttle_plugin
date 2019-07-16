

PATH := $(CURDIR)/elixir/bin:$(PATH)

.PHONY: test

all: elixir/lib/elixir/ebin/elixir.app
	mix local.hex --force
	mix deps.get
	mix compile
	-rm -rf $(CURDIR)/elixir/lib/mix/test


elixir/lib/elixir/ebin/elixir.app:
	git clone -b v1.6.0-rc.0 https://github.com/elixir-lang/elixir.git
	echo "start to build elixir ..."
	make -C elixir -f Makefile

clean:
	rm -rf _build deps

test:
	mix test --cover
