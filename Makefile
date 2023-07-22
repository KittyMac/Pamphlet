DIST:=$(shell cd dist && pwd)
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
	-rm .build/PamphletTool-focal
	lipo -create -output .build/PamphletTool-focal .build/arm64-apple-macosx/release/PamphletTool-focal .build/x86_64-apple-macosx/release/PamphletTool-focal
	cp .build/PamphletTool-focal ./dist/PamphletTool
	cp .build/PamphletTool-focal ./dist/Pamphlet

.PHONY: clean
clean:
	rm -rf .build
	
.PHONY: clean-repo
clean-repo:
	mv dist /tmp/dist
	git filter-repo --invert-paths \
		--path dist/pamphlet \
		--path dist/Pamphlet \
		--path dist/PamphletTool \
		--path dist/PamphletTool-amazonlinux2.zip \
		--path dist/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-amd64/bin/PamphletTool \
		--path dist/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-arm64/bin/PamphletTool \
		--path dist/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-macos/bin/PamphletTool \
		--path dist/PamphletTool-fedora.zip \
		--path dist/PamphletTool-fedora.artifactbundle/PamphletTool-amd64/bin/PamphletTool \
		--path dist/PamphletTool-fedora.artifactbundle/PamphletTool-arm64/bin/PamphletTool \
		--path dist/PamphletTool-fedora.artifactbundle/PamphletTool-macos/bin/PamphletTool \
		--path dist/PamphletTool-fedora38.zip \
		--path dist/PamphletTool-fedora38.artifactbundle/PamphletTool-amd64/bin/PamphletTool \
		--path dist/PamphletTool-fedora38.artifactbundle/PamphletTool-arm64/bin/PamphletTool \
		--path dist/PamphletTool-fedora38.artifactbundle/PamphletTool-macos/bin/PamphletTool \
		--path dist/PamphletTool-focal.zip \
		--path dist/PamphletTool-focal.artifactbundle/PamphletTool-amd64/bin/PamphletTool \
		--path dist/PamphletTool-focal.artifactbundle/PamphletTool-arm64/bin/PamphletTool \
		--path dist/PamphletTool-focal.artifactbundle/PamphletTool-macos/bin/PamphletTool
	mv /tmp/dist dist
	
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
	cp .build/PamphletTool-focal ./dist/Pamphlet
	
	-rm /opt/homebrew/bin/pamphlet
	-cp .build/PamphletTool-focal /opt/homebrew/bin/pamphlet
	
	-rm /usr/local/bin/pamphlet
	-cp .build/PamphletTool-focal /usr/local/bin/pamphlet
	

.PHONY: tools
tools: install
	make -C Tools
	./dist/Pamphlet --prefix=Tools --release ./Tools/Pamphlet ./Sources/PamphletFramework/Tools

.PHONY: tools-simple
tools-simple: install
	make -C Tools
	./dist/Pamphlet --prefix=Tools --release --disable-html --disable-js --disable-json ./Tools/Pamphlet ./Sources/PamphletFramework/Tools

.PHONY: release
release: install docker
	
	# Getting plugin for focal
	docker pull kittymac/pamphlet-focal:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/pamphlet-focal /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-focal.artifactbundle/PamphletTool-arm64/bin/PamphletTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/pamphlet-focal /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-focal.artifactbundle/PamphletTool-amd64/bin/PamphletTool'
	mkdir -p ./dist/PamphletTool-focal.artifactbundle/PamphletTool-macos/bin/
	cp ./dist/PamphletTool ./dist/PamphletTool-focal.artifactbundle/PamphletTool-macos/bin/PamphletTool
	
	rm -f ./dist/PamphletTool-focal.zip
	cd ./dist && zip -r ./PamphletTool-focal.zip ./PamphletTool-focal.artifactbundle
	
	# Getting plugin for amazonlinux2
	docker pull kittymac/pamphlet-amazonlinux2:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/pamphlet-amazonlinux2 /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-arm64/bin/PamphletTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/pamphlet-amazonlinux2 /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-amd64/bin/PamphletTool'
	mkdir -p ./dist/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-macos/bin/
	cp ./dist/PamphletTool ./dist/PamphletTool-amazonlinux2.artifactbundle/PamphletTool-macos/bin/PamphletTool
	
	rm -f ./dist/PamphletTool-amazonlinux2.zip
	cd ./dist && zip -r ./PamphletTool-amazonlinux2.zip ./PamphletTool-amazonlinux2.artifactbundle
	
	# Getting plugin for fedora
	docker pull kittymac/pamphlet-fedora:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/pamphlet-fedora /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-fedora.artifactbundle/PamphletTool-arm64/bin/PamphletTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/pamphlet-fedora /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-fedora.artifactbundle/PamphletTool-amd64/bin/PamphletTool'
	mkdir -p ./dist/PamphletTool-fedora.artifactbundle/PamphletTool-macos/bin/
	cp ./dist/PamphletTool ./dist/PamphletTool-fedora.artifactbundle/PamphletTool-macos/bin/PamphletTool
	
	rm -f ./dist/PamphletTool-fedora.zip
	cd ./dist && zip -r ./PamphletTool-fedora.zip ./PamphletTool-fedora.artifactbundle
	
	# Getting plugin for fedora38
	docker pull kittymac/pamphlet-fedora38:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/pamphlet-fedora38 /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-fedora38.artifactbundle/PamphletTool-arm64/bin/PamphletTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/pamphlet-fedora38 /bin/bash -lc 'cp PamphletTool-focal /outTemp/PamphletTool-fedora38.artifactbundle/PamphletTool-amd64/bin/PamphletTool'
	mkdir -p ./dist/PamphletTool-fedora38.artifactbundle/PamphletTool-macos/bin/
	cp ./dist/PamphletTool ./dist/PamphletTool-fedora38.artifactbundle/PamphletTool-macos/bin/PamphletTool
	
	rm -f ./dist/PamphletTool-fedora38.zip
	cd ./dist && zip -r ./PamphletTool-fedora38.zip ./PamphletTool-fedora38.artifactbundle
	

docker:
	-docker buildx create --name cluster_builder203
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --file Dockerfile-focal --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet-focal .
	docker buildx build --file Dockerfile-amazonlinux2 --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet-amazonlinux2 .
	docker buildx build --file Dockerfile-fedora --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet-fedora .
	docker buildx build --file Dockerfile-fedora38 --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet-fedora38 .


docker-shell:
	docker pull kittymac/pamphlet
	docker run --platform linux/arm64 --rm -it --entrypoint bash kittymac/pamphlet
