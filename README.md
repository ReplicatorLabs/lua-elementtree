# lua-elementtree

Lua element tree serialization library.

* No third-party dependencies.
* Support common hierarchial markup languages:
  * XML
  * SVG
  * HTML5
* Just enough serialization logic for each markup language to express the
  most common patterns (ex: HTML5 web sites, SVG diagrams, etc).
* Just enough deserialization logic to parse markup generated by this
  library.

This library explicitly does not aim to support 100% of the markup language
standards and there is no expectation it can correctly parse or recreate
arbitrary third-party data.

## References

* HTML5
  * [Syntax](https://html.spec.whatwg.org/multipage/syntax.html)
