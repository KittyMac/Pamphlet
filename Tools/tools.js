import { minify } from "terser";

global.toolTerser = function(content, callback) {
    var options = {
        format: {
            ascii_only: true
        },
        compress: {},
        mangle: true
    };

    minify(content, { sourceMap: false }).then( function($) {
        callback($.code);
    });
}