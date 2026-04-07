SHELL := /bin/zsh

MISE := mise exec --
TUIST := $(MISE) tuist
DERIVED_DATA := $(CURDIR)/build/DofficeDerivedData
APP_DEBUG := $(DERIVED_DATA)/Build/Products/Debug/Doffice.app
APP_RELEASE := $(DERIVED_DATA)/Build/Products/Release/Doffice.app
SYMLINK := $(CURDIR)/build/Release/Doffice.app

.PHONY: dofi clean-tuist generate build-app build-release open-app link

dofi: clean-tuist generate build-release link open-app

clean-tuist:
	@echo "==> Cleaning Tuist artifacts"
	@$(TUIST) clean
	@rm -rf "$(DERIVED_DATA)"

generate:
	@echo "==> Generating project with Tuist $$( $(TUIST) version )"
	@$(TUIST) generate --no-open

build-app:
	@echo "==> Building Doffice (Debug)"
	@xcodebuild build \
		-workspace Doffice.xcworkspace \
		-scheme Doffice \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)"
	@$(MAKE) link

build-release:
	@echo "==> Building Doffice (Release)"
	@xcodebuild build \
		-workspace Doffice.xcworkspace \
		-scheme Doffice \
		-configuration Release \
		-destination 'platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)"

link:
	@mkdir -p "$(CURDIR)/build/Release"
	@rm -rf "$(SYMLINK)"
	@if [ -d "$(APP_RELEASE)" ]; then \
		ln -s "$(APP_RELEASE)" "$(SYMLINK)"; \
	elif [ -d "$(APP_DEBUG)" ]; then \
		ln -s "$(APP_DEBUG)" "$(SYMLINK)"; \
	fi
	@echo "==> Linked build/Release/Doffice.app"

open-app:
	@echo "==> Opening built app"
	@if [ -d "$(APP_RELEASE)" ]; then \
		open -n "$(APP_RELEASE)"; \
	elif [ -d "$(APP_DEBUG)" ]; then \
		open -n "$(APP_DEBUG)"; \
	elif [ -L "$(SYMLINK)" ]; then \
		open -n "$(SYMLINK)"; \
	else \
		echo "No built app found" >&2; exit 1; \
	fi
	@for _ in {1..20}; do \
		if pgrep -x Doffice >/dev/null; then \
			echo "==> Doffice is running"; \
			exit 0; \
		fi; \
		sleep 1; \
	done; \
	echo "Doffice did not start as expected" >&2; \
	exit 1
