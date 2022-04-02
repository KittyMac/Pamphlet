SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

.PHONY: build
build:
	swift build $(SWIFT_BUILD_FLAGS) --triple arm64-apple-macosx
	swift build $(SWIFT_BUILD_FLAGS) --triple x86_64-apple-macosx
	lipo -create -output .build/release/${PROJECTNAME} .build/arm64-apple-macosx/release/${PROJECTNAME} .build/x86_64-apple-macosx/release/${PROJECTNAME}
	cp .build/release/pamphlet ./bin/pamphlet

.PHONY: clean
clean:
	rm -rf .build

.PHONY: update
update:
	swift package update

.PHONY: run
run:
	swift run $(SWIFT_BUILD_FLAGS)
	
.PHONY: test
test:
	swift test --configuration debug

.PHONY: xcode
xcode:
	swift package generate-xcodeproj

.PHONY: install
install: build
	-rm /opt/homebrew/bin/pamphlet
	-cp .build/release/pamphlet /opt/homebrew/bin/pamphlet
	
	-rm /usr/local/bin/pamphlet
	-cp .build/release/pamphlet /usr/local/bin/pamphlet
	
	cp .build/release/pamphlet ./bin/pamphlet
