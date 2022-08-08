const jsonminify = require("jsonminify");
const { minify } = require('html-minifier-terser');

let terserOptions = {
    removeAttributeQuotes: true,
    collapseWhitespace: true,
    //minifyCSS: true,
    minifyJS: {
        format: {
            ascii_only: true
        },
        compress: {},
        mangle: {}
    }
};

global.toolJS = function(content, callback) {
    minify(content, terserOptions).then( function($) {
        callback($);
    });
}

global.toolHTML = function(content, callback) {
    minify(content, terserOptions).then( function($) {
        callback($);
    });
}

global.toolJSON = function(content) {
    return jsonminify(content);
}
