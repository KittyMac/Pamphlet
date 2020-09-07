# Pamphlet

Pamphlet turns resource files into Swift code, allowing those resources to be easily embedded into your executable. Resource availability is then checked by the compiler, and will error if the resource is removed from the project.

Pamphlet also includes a built-in C/C++ preprocessor, which can be used for ANY text files processed by pamphlet. This is incredibly powerful, as it allows you to use the power of the preprocessor anywhere.  See the Preprocessor section for more details.

For **DEBUG** builds, Pamphet will load the content from disk and not use the embedded content. This is particularly useful when you want resource reloading during development, but embedded resources during release.


**Example**

Let suppose we were making a simple web server where the contents of the server are compiled in using Pamphlet.  Our directory structure might look like this:

```
www  
├── index.html  
├── style.css  
├── script.js  
├── Images/  
     ├── logo.png  
```


And Pamphlet could be called like this:

```bash
pamphlet generate /path/to/www ./Sources/server/ 
```

When finished, you would access the content in your Swift code like this:

```swift
let html: String = Pamphlet.IndexHtml()
let style: String = Pamphlet.StyleCss()
let js: String = Pamphlet.ScriptJs()
let logo: Data = Pamphlet.Images.LogoPng()
```

or you can look them up dynamically by their file name like this:

```swift
if let html: String = Pamphlet[dynamicMember: "/index.html"] {
    // use html
}
if let logo: Data = Pamphlet[dynamicMember: "Images/logo.png"] {
    // use logo
}
```


The files that Pamphlet generates will look like these:

*Pamphlet.swift*

```swift
import Foundation

// swiftlint:disable all

@dynamicMemberLookup
public enum Pamphlet {
    static subscript(dynamicMember member: String) -> String? {
        switch member {
        case "/index.html": return Pamphlet.IndexHtml()
        case "/script.js": return Pamphlet.ScriptJs()
        case "/style.css": return Pamphlet.StyleCss()
        default: break
        }
        return nil
    }
    static subscript(dynamicMember member: String) -> Data? {
        switch member {
        case "/Images/logo.png": return Pamphlet.Images.LogoPng()
        default: break
        }
        return nil
    }
}
extension Pamphlet { public enum Images { } }
```

*Pamphlet+index.html.swift*

```swift
import Foundation

// swiftlint:disable all

public extension Pamphlet {
    static func IndexHtml() -> String {
#if DEBUG
if let contents = try? String(contentsOfFile:"/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test/index.html") {
    return contents
}
return "file not found"
#else
return ###"""
<html>
  <head>
  </head>
  <body>
    Hello World!
  </body>
</html>

"""###
#endif
}
}
"""###
```

## Preprocessing

Pamphlet includes a version of the powerful [mcpp](http://mcpp.sourceforge.net) preprocessor, a C99 compliant C/C++ preprocessor.  While this may seem perplexing, it instantly adds powerful template programming to any text-based files processed using Pamphlet.

**Example**

Only files which start with ```#define PAMPHLET_PREPROCESSOR``` will be preprocessed, so there is no concern that the preprocessor might interfere with normal pamplet operation.

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

Would result in this preprocessed output:

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

The preprocessed file is then stored in the generated Swift code.

For **DEBUG** builds, Pamphet dynamically loaded content relies on the pamphlet existing on the development system at ```/usr/local/bin/pamphlet```.  When the resource is requested, its contents will be preprocessed using the CLI tool like this ```pamphlet preprocess /path/to/index.html```.