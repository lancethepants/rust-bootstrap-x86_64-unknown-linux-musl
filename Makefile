export DESTARCH=x86_64
export PREFIX=/mmc

export EXTRACFLAGS =
export PATH := $(PATH):/opt/tomatoware/x86_64-musl$(subst /,-,$(PREFIX))/bin/

rust:
	./scripts/rust.sh

clean:
	git clean -fdxq && git reset --hard
