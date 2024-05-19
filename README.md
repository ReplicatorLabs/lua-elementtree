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

## Roadmap

Planned:

* [x] Lua 5.4 support.
  * [ ] Unit tests.
  * [ ] Integration tests.
* [ ] LuaRocks package.

Open to consideration:

* [ ] LuaJIT support.
  * [ ] Integration tests.
* [ ] Lua 5.3 support.
  * [ ] Integration tests.
* [ ] Lua 5.2 support.
  * [ ] Integration tests.
* [ ] Lua 5.1 support.
  * [ ] Integration tests.

## XML

You may be able to preprocess XML documents using [Tidy](https://www.html-tidy.org/)
with the provided configuration file in order to parse them with this library:

```bash
tidy -config ./tidy-config --input-xml --output-xml yes -o clean.xml original.xml
```

## SVG

You may be able to preprocess SVG documents using [Tidy](https://www.html-tidy.org/)
with the provided configuration file in order to parse them with this library:

```bash
tidy -config ./tidy-config --input-xml yes --output-xml yes -o clean.svg original.svg
```

## HTML5

You may be able to preprocess HTML5 documents using [Tidy](https://www.html-tidy.org/)
with the provided configuration file in order to parse them with this library:

```bash
tidy -config ./tidy-config --output-html yes -o clean.html original.html
```

## References

* HTML5
  * [Syntax](https://html.spec.whatwg.org/multipage/syntax.html)
* [Tidy](https://www.html-tidy.org/)
