all:
	node_modules/.bin/rollup tools.js --banner "let global = {};" --no-treeshake -f iife -o ./Pamphlet/tools.js -p @rollup/plugin-node-resolve
    
	

install:
	-brew install node
    
	npm i terser
	npm i rollup @rollup/plugin-node-resolve
	
	npm update