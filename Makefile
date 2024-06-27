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
	-rm .build/PamphletTool
	lipo -create -output .build/PamphletTool .build/arm64-apple-macosx/release/PamphletTool .build/x86_64-apple-macosx/release/PamphletTool
	cp .build/PamphletTool ./dist/PamphletTool
	cp .build/PamphletTool ./dist/Pamphlet
	
build-windows:
	swift build --configuration release
	cp .build/release/PamphletTool.exe ./dist/PamphletTool-windows.artifactbundle/PamphletTool-amd64/bin/PamphletTool.exe
	rm ./dist/PamphletTool-windows.zip
	Compress-Archive -Path ./dist/PamphletTool-windows.artifactbundle -DestinationPath ./dist/PamphletTool-windows.zip

.PHONY: clean
clean:
	rm -rf .build
	
.PHONY: clean-repo
clean-repo:
	rm -rf /tmp/clean-repo/
	mkdir -p /tmp/clean-repo/
	cd /tmp/clean-repo/ && git clone https://github.com/KittyMac/Pamphlet.git/
	cd /tmp/clean-repo/Pamphlet && cp -r dist ../dist.tmp && cp .git/config ../config
	cd /tmp/clean-repo/Pamphlet && git filter-repo --invert-paths --path dist
	cd /tmp/clean-repo/Pamphlet && mv ../dist.tmp dist && mv ../config .git/config
	cd /tmp/clean-repo/Pamphlet && git add dist
	cd /tmp/clean-repo/Pamphlet && git commit -a -m "clean-repo"
	open /tmp/clean-repo/Pamphlet
	# clean complete; manual push required
	# git push origin --force --all
	# git push origin --force --tags
	
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
	cp .build/PamphletTool ./dist/Pamphlet
	
	-rm /opt/homebrew/bin/pamphlet
	-cp .build/PamphletTool /opt/homebrew/bin/pamphlet
	
	-rm /usr/local/bin/pamphlet
	-cp .build/PamphletTool /usr/local/bin/pamphlet
	

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

docker: docker
	-docker buildx create --name cluster_builder203
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login
	
	docker buildx build --file Dockerfile-focal --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet-focal .

docker-shell:
	docker pull kittymac/pamphlet
	docker run --platform linux/arm64 --rm -it --entrypoint bash kittymac/pamphlet
