# Pamphlet

Pamphlet turns text files into Swift code, allowing those text resources to be easily embeddable into your executable. Resource availability is then checked by the compiler, and will error if the resource is removed from the project.

**Example**

Let suppose we were making a simple web server where the contents of the server are compiled in using Pamplet.  So the directory structure might look like this:

www  
├── index.html  
├── style.css  
├── code.js  


And Pamphlet might be called like this:

```bash
pamphlet /path/to/www ./Sources/server/ 
```

When finished, you would access the content in your Swift code like this:

```swift
let html = Pamplet.index_html()
let style = Pamplet.style_css()
let js = Pamplet.code_js()
```

or you can look them up dynamically by their file name like this:

```swift
let html = Pamphlet[dynamicMember: "/index.html"]
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
    static func index_html() -> String {
return ###"""
<html>
  <head>
  </head>
  <body>
    Hello World!
  </body>
</html>
"""###
```

*Pamphlet+style.css.swift*

```swift
// swiftlint:disable all
public extension Pamphlet {
    static func style_css() -> String {
return ###"""
<content of style.css goes here>
"""###
```

*Pamphlet+code.js.swift*

```swift
// swiftlint:disable all
public extension Pamphlet {
    static func code_js() -> String {
return ###"""
<content of code.js goes here>
"""###
```