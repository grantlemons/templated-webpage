COMPILER=corral run -- ponyc
COMPILERFLAGS=-Dopenssl_3.0.x
SRCS=src
TARGET=main

debug: COMPILERFLAGS+=--debug
debug: release

$(TARGET): $(SRCS)
	$(COMPILER) $(COMPILERFLAGS) $^ -b $@
	@sudo setcap CAP_NET_BIND_SERVICE=+eip $(TARGET)
	
# ensure dependencies are present
_corral:
	corral fetch
_repos:
	corral fetch

release: _corral _repos $(TARGET)

.PHONY: clean all debug release
clean:
	rm -f $(TARGET)
