const { minify } = require('terser');
const Minimize = require('minimize');

const minifyHTML = new Minimize();

global.toolTerserJS = function(content, callback) {
        
    var options = {
        format: {
            ascii_only: true
        },
        compress: {},
        mangle: true
    };
        
    minify(content, options).then( function($) {
        callback($.code);
    });
}

global.toolTerserHTML = function(content) {
    return minifyHTML.parse(content);
}