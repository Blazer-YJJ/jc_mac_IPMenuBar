APP       := IPMenuBar
BUNDLE_ID := io.github.blazeryjj.ipmenubar
VERSION   := 1.0.0
BUILD_DIR := build
APP_DIR   := $(BUILD_DIR)/$(APP).app
BIN       := $(BUILD_DIR)/$(APP)
SOURCES   := Sources/main.swift
PLIST     := Resources/Info.plist

.PHONY: all build bundle run install uninstall clean

all: bundle

build:
	@mkdir -p "$(BUILD_DIR)"
	swiftc -O -swift-version 5 -o "$(BIN)" $(SOURCES)

bundle: build
	@rm -rf "$(APP_DIR)"
	@mkdir -p "$(APP_DIR)/Contents/MacOS"
	@cp "$(BIN)" "$(APP_DIR)/Contents/MacOS/$(APP)"
	@sed -e 's/__VERSION__/$(VERSION)/g' "$(PLIST)" > "$(APP_DIR)/Contents/Info.plist"
	@codesign --force --sign - "$(APP_DIR)" 2>/dev/null || echo "warn: codesign skipped"
	@echo "built $(APP_DIR)"

run: bundle
	open "$(APP_DIR)"

install: bundle
	bash scripts/install.sh

uninstall:
	bash scripts/uninstall.sh

clean:
	rm -rf "$(BUILD_DIR)"
