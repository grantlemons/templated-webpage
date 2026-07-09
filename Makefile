COMPILER=corral run -- ponyc
COMPILERFLAGS=-Dopenssl_3.0.x
SRCS=src
TARGET=main

# change the order of debug and release to change the default
debug: COMPILERFLAGS+=--debug
debug: release
release: _corral _repos $(TARGET)

$(TARGET): $(SRCS)
	$(COMPILER) $(COMPILERFLAGS) $^ -b $@
	@sudo setcap CAP_NET_BIND_SERVICE=+eip $(TARGET)
	
# ensure dependencies are present
_corral:
	corral fetch
_repos:
	corral fetch

.PHONY: clean all debug release
clean:
	rm -f $(TARGET)
