

PATH := $(CURDIR)/elixir/bin:$(PATH)


all: elixir/lib/elixir/ebin/elixir.app
	mix local.hex --force
	mix deps.get
	make -C deps/emqttd
	ERL_LIBS=deps mix compile
	-rm -rf $(CURDIR)/elixir/lib/mix/test


elixir/lib/elixir/ebin/elixir.app:
	git clone https://github.com/elixir-lang/elixir.git
	echo "start to build elixir ..."
	make -C elixir -f Makefile

clean:
	rm -rf _build deps

test:
	mix test --cover
