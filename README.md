# Pamphlet

Pamphlet turns resource files into Swift code, allowing those resources to be easily embedded into your executable. Resource availability is then checked by the compiler, and will error if the resource is removed from the project.

For **DEBUG** builds, Pamphet will load the content from disk and not use the embedded content. This is particularly useful when you want resource reloading during development, but embedded resources during release.


**Example**

Let suppose we were making a simple web server where the contents of the server are compiled in using Pamphlet.  Our directory structure might look like this:

www  
├── index.html  
├── style.css  
├── code.js  
├── logo.png  


And Pamphlet could be called like this:

```bash
pamphlet /path/to/www ./Sources/server/ 
```

When finished, you would access the content in your Swift code like this:

```swift
let html: String = Pamphlet.index_html()
let style: String = Pamphlet.style_css()
let js: String = Pamphlet.code_js()
let logo: Data = Pamphlet.logo_png()
```

or you can look them up dynamically by their file name like this:

```swift
if let html: String = Pamphlet[dynamicMember: "/index.html"] {
    // use html
}
```


The files that Pamphlet generates will look like these:

*Pamphlet.swift*

```swift
// swiftlint:disable all
@dynamicMemberLookup
public enum Pamphlet {
    static subscript(dynamicMember member: String) -> String? {
        switch member {
        case "index.html": return index_html()
        case "style.css": return style_css()
        case "code.js": return code_js()
        default: break
        }
        return nil
    }
}
```

*Pamphlet+index.html.swift*

```swift
// swiftlint:disable all
public extension Pamphlet {
#if DEBUG
if let contents = try? String(contentsOfFile:"/www/index.html") {
    return contents
}
return "file not found"
#else
    static func index_html() -> String {
return ###"""
<html>
  <head>
  </head>
  <body>
    Hello World!
  </body>
</html>
#endif
"""###
```
