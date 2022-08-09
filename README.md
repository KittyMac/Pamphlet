Pamphlet is a **Swift Package Manager Build Tool** for preprocessing, minifying and storing resource files in generated Swift code. Pamphlet supports Swift development on macOS and Linux.

## Quick Start

To use Pamphlet make sure you are using **Swift 5.6** or later and make the following changes to your Package.swift

Add to your Package:

```swift
dependencies: [
    .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.0"),
]
```

Add to the desired Target:

```swift
.target(
	...
	dependencies: [
		.product(name: "PamphletFramework", package: "Pamphlet")
	],
	plugins: [
		.plugin(name: "PamphletPlugin", package: "Pamphlet")
	]
)
```

Now when you build your Swift package the PamphletPlugin will **convert all files in the Pamphlet directory** of the target you assigned the plugin to.

For example, let's pretend your project directory looks like this:

```
My Swift Project  
├── Package.swift
├── Sources
	├── MyTarget
		├── main.swift
		├── Pamphlet
			├── index.html  
			├── style.css  
			├── script.js  
			├── Images/  
				├── logo.png  
```

When you run ```swift build```, PamphletPlugin will generate a Pamphlet.swift which contains the processed contents of all resources in the Pamphlet directory. This allows you to access those resources elsewhere in your project like this:

```swift
// Direct access
let html: String = Pamphlet.IndexHtml()
let style: String = Pamphlet.StyleCss()
let js: String = Pamphlet.ScriptJs()
let logo: Data = Pamphlet.Images.LogoPng()

// Indirect access
if let html = Pamphlet.get(string: "/index.html") {
    // use html
}
if let gzippedHtml = Pamphlet.get(gzip: "/index.html") {
    // use gzip'd version of index.html
}
if let logo = Pamphlet.get(data: "Images/logo.png") {
    // use logo
}
```


## Preprocessing

Pamphlet will minify several resource types automatically. This processing is done using well-known tools vendored inside Pamphlet for convenience (see Tools/tools.js).

**HTML** -> [HTML Minifier Terser](https://github.com/terser/html-minifier-terser)

**JavaScript** -> [Terser](https://github.com/terser/terser)

**JSON** -> [JSON.minify](https://github.com/fkei/JSON.minify)

**C Preprocessor** -> [mcpp](http://mcpp.sourceforge.net)

### Hot loading when running in debug
When debugging it is often desirable to reprocess the source content on the fly, instead of using the version generated at build time. Pamphlet will do this automatically for debug builds.

## C Preprocessing (for any text file)

Pamphlet includes a forked version of the powerful [mcpp](http://mcpp.sourceforge.net) preprocessor, a C99 compliant C/C++ preprocessor.  This feature instantly adds powerful preprocessing capabilities to any text-based files processed using Pamphlet. To add the C preprocessor to your file, simply start the file with ```#define PAMPHLET_PREPROCESSOR```

**Example**

Before preprocessing:

```
#define PAMPHLET_PREPROCESSOR
#define HELLO(x) <div class="outer"><div class="inner">Hello x!</div><div>

<html>
	<head>
	</head>
	<body>
		HELLO(dog)
		HELLO(cat)
		HELLO(pineapple)
		HELLO(world)
	</body>
</html>
```

After preprocessing:

```
<html>
	<head>
	</head>
	<body>
		<div class="outer"><div class="inner">Hello dog!</div><div>
		<div class="outer"><div class="inner">Hello cat!</div><div>
		<div class="outer"><div class="inner">Hello pineapple!</div><div>
		<div class="outer"><div class="inner">Hello world!</div><div>
	</body>
</html>
```



### Differences from standard C Preprocessor

#### Macros are processed inside of strings
Since pamphlet preprocessing is meant to be used with any text resource (and not just C/C++ source code), the preprocessor has been modified to process all string and character literals. This allows you to put macros in strings and have them processed.

**Example**

```
#define PAMPHLET_PREPROCESSOR
#define HELLO(x) 'Hello x!'
"HELLO(dog)HELLO(cat)HELLO(pineapple)HELLO(world)"
```

Results in:
	
```
"'Hello dog!''Hello cat!''Hello pineapple!''Hello world!'"
```

#### #macro / #endmacro
Multi-line #defines are annoying to use due to the **trailing backslash (\\)** required. Pamphlet adds the #macro and #endmacro pairing to allow for multi-line definitions which do not require such escaping. Note that the lines are collapsed, just as if you had used #define with **trailing backslash (\\)**.

**Example**

```
#define PAMPHLET_PREPROCESSOR
#define MULTILINE_MACRO()            \
Lorem ipsum dolor sit amet,          \
consectetur adipiscing elit,         \
sed do eiusmod tempor incididunt     \
ut labore et dolore magna aliqua.    \
"MULTILINE_MACRO()"

```

```
#define PAMPHLET_PREPROCESSOR
#macro MULTILINE_MACRO()
Lorem ipsum dolor sit amet, 
consectetur adipiscing elit, 
sed do eiusmod tempor incididunt 
ut labore et dolore magna aliqua. 
#endmacro
"MULTILINE_MACRO()"

```

Both result in:

```
"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
```
