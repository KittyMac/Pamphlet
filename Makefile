SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

build:
	swift build $(SWIFT_BUILD_FLAGS) --triple arm64-apple-macosx
	swift build $(SWIFT_BUILD_FLAGS) --triple x86_64-apple-macosx
	lipo -create -output .build/release/${PROJECTNAME} .build/arm64-apple-macosx/release/${PROJECTNAME} .build/x86_64-apple-macosx/release/${PROJECTNAME}

clean:
	rm -rf .build

update:
	swift package update

run:
	swift run $(SWIFT_BUILD_FLAGS)
	
test:
	swift test --configuration debug

xcode:
	swift package generate-xcodeproj

release: build
	cp .build/release/pamphlet ./bin/pamphlet

install: build
	-cp .build/release/pamphlet /opt/homebrew/bin/pamphlet
	-cp .build/release/pamphlet /usr/local/bin/pamphlet
	cp .build/release/pamphlet ./bin/pamphlet