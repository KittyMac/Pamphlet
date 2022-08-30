SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)
RELEASEVERSION := $(shell git describe)
RELEASENAME := PamphletTool-${RELEASEVERSION}.zip

.PHONY: all build clean xcode

all: build

.PHONY: build
build:
	swift build --triple arm64-apple-macosx $(SWIFT_BUILD_FLAGS) 
	swift build --triple x86_64-apple-macosx $(SWIFT_BUILD_FLAGS)
	-rm .build/${PROJECTNAME}
	lipo -create -output .build/${PROJECTNAME} .build/arm64-apple-macosx/release/${PROJECTNAME} .build/x86_64-apple-macosx/release/${PROJECTNAME}
	cp .build/${PROJECTNAME} ./dist/Pamphlet

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

.PHONY: install
install: clean build
	-rm ./dist/Pamphlet
	cp .build/${PROJECTNAME} ./dist/Pamphlet
	
	-rm /opt/homebrew/dist/Pamphlet
	-cp .build/${PROJECTNAME} /opt/homebrew/dist/Pamphlet
	
	-rm /usr/local/dist/Pamphlet
	-cp .build/${PROJECTNAME} /usr/local/dist/Pamphlet
	

.PHONY: tools
tools: install
	make -C Tools
	./dist/Pamphlet --prefix=Tools --release ./Tools/Pamphlet ./Sources/PamphletFramework/Tools

.PHONY: tools-simple
tools-simple: install
	make -C Tools
	./dist/Pamphlet --prefix=Tools --release --disable-html --disable-js --disable-json ./Tools/Pamphlet ./Sources/PamphletFramework/Tools

.PHONY: release
release: install
	cp ./dist/Pamphlet ./dist/Pamphlet.artifactbundle/Pamphlet-macos/bin/Pamphlet
	rm -f ./dist/Pamphlet.zip
	cd ./dist && zip -r ./Pamphlet.zip ./Pamphlet.artifactbundle

docker:
	-docker buildx create --name local_builder
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name local_builder --platform linux/amd64 --append
	-docker buildx use local_builder
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet .

docker-shell:
	docker pull kittymac/pamphlet
	docker run --rm -it --entrypoint bash kittymac/pamphlet
