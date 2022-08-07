import { minify } from "terser";

function terser(content) {
    
    var options = {
        format: {
            ascii_only: true
        },
        compress: {},
        mangle: true
    };

    var result = "";
    return minify(content, { sourceMap: false }).then( function($) {
        result = $.code;
    });
    
    return result;
    
}