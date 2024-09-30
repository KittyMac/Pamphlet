const { minify: terserMinify } = require("terser");
const jsonminify = require("jsonminify");
const { minify: htmlMinify } = require('html-minifier-terser');

global.toolJS = function(content, callback) {
    let options = {
        format: {
            ascii_only: true
        },
        compress: {
            unused: false
        },
        mangle: {
            reserved: [ "preconfig" ]
        }
    };
        
    terserMinify(content, options).then( function($) {
        callback($.code);
    });
}

global.toolHTML = function(content, callback) {
    let options = {
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

    try {
        htmlMinify(content, options).then( function($) {
            callback($);
        });
    } catch(error) {
        callback(new Minimize().parse(content));
    }
}

global.toolJSON = function(content, callback) {
    callback(jsonminify(content));
}
