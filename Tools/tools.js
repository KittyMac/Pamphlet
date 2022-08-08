const jsonminify = require("jsonminify");
const { minify } = require('html-minifier-terser');

global.toolJS = function(content, callback) {
    var options = {
        removeAttributeQuotes: true,
        collapseWhitespace: true,
        //minifyCSS: true,
        minifyJS: true
    };
        
    minify(content, options).then( function($) {
        callback($);
    });
}

global.toolHTML = function(content, callback) {
    var options = {
        removeAttributeQuotes: true,
        collapseWhitespace: true,
        //minifyCSS: true,
        minifyJS: true
    };
        
    minify(content, options).then( function($) {
        callback($);
    });
}

global.toolJSON = function(content) {
    return jsonminify(content);
}


let sample = `
<html>
<head>
    
</head>
<body>
    <style>
        p {
        	color: red;
        	text-align: center;
        }
    </style>
    <script>
        function helloWorld() {
        	alert("Hello, World")
        }


        
    </script>
</body>
</html>
`;

global.toolHTML(sample, function(result) {
    console.log(result);
})