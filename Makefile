DEST ?= /usr/local/bin/vapor
MANDEST_DIR ?= /usr/local/share/man/man1
SUDO ?= true

_USE_SUDO := $(shell test $(shell id -u) -ne 0 -a "$(SUDO)" = "true" && echo "sudo" || echo "")

init-git:
	@if [ ! -d .git ]; then \
		git init; \
		git commit --allow-empty -m "first commit"; \
	fi
generate-manual:
	swift package generate-manual
build: init-git generate-manual
	swift run BuildToolbox
install: build
	$(_USE_SUDO) mv .build/release/vapor ${DEST}
	$(_USE_SUDO) chmod 755 ${DEST}
# Install manpage
	$(_USE_SUDO) mkdir -p $(MANDEST_DIR)
	$(_USE_SUDO) cp .build/plugins/GenerateManual/outputs/vapor/vapor.1 $(MANDEST_DIR)/vapor.1
uninstall:
	$(_USE_SUDO) rm ${DEST}
# Remove manpage
	$(_USE_SUDO) rm $(MANDEST_DIR)/vapor.1
clean:
	rm -rf .build
