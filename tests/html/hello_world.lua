local et <const> = require('elementtree')

DOCUMENT = et.Document{
  root=et.Node('html', {lang='en'}, {
    et.Node('head', {}, {
      et.Node('meta', {charset="UTF-8"}),
      et.Node('meta', {name="viewport", content="width=device-width, initial-scale=1.0"}),
      et.Node('title', {}, {"Hello, world!"}),
      et.Comment("link stylesheets here")
    }),
    et.Node('body', {}, {
      et.Node('center', {}, {
        et.Node('h1', {}, {"Hello, world!"})
      }),
      et.Comment("link scripts here")
    })
  })
}

DOCUMENT.root:freeze()
print(et.HTML5.dump_string(DOCUMENT))
