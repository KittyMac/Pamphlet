SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

.PHONY: build
build:
	swift build --triple arm64-apple-macosx $(SWIFT_BUILD_FLAGS) 
	swift build --triple x86_64-apple-macosx $(SWIFT_BUILD_FLAGS)
	-rm .build/${PROJECTNAME}
	lipo -create -output .build/${PROJECTNAME} .build/arm64-apple-macosx/release/${PROJECTNAME} .build/x86_64-apple-macosx/release/${PROJECTNAME}
	cp .build/${PROJECTNAME} ./bin/pamphlet

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
install: build
	-rm ./bin/pamphlet
	-rm /opt/homebrew/bin/pamphlet
    
	-cp .build/${PROJECTNAME} /opt/homebrew/bin/pamphlet
	
	-rm /usr/local/bin/pamphlet
	-cp .build/${PROJECTNAME} /usr/local/bin/pamphlet
	
	cp .build/${PROJECTNAME} ./bin/pamphlet

.PHONY: install
tools: install
	make -C Tools
	./bin/pamphlet --prefix=Tools --release --collapse-all --disable-html --disable-js --disable-json ./Tools/Pamphlet ./Sources/PamphletFramework/Tools

docker:
	-docker buildx create --name local_builder
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name local_builder --platform linux/amd64 --append
	-docker buildx use local_builder
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet .

docker-shell:
	docker run --rm -it --entrypoint bash kittymac/pamphlet
