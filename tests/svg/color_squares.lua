local et <const> = require('elementtree')

DOCUMENT = et.Document{
  root=et.Node('svg', {
    xmlns='http://www.w3.org/2000/svg',
    width='1000',
    height='1000'
  }, {
    et.Comment("top left square"),
    et.Node('rect', {
      x='150',
      y='150',
      width='500',
      height='500',
      rx='20',
      fill='#ff0000',
      stroke='#000000',
      ['stroke-width']='2'
    }),

    et.Comment("bottom right square"),
    et.Node('rect', {
      x='350',
      y='350',
      width='500',
      height='500',
      rx='20',
      fill='#0000ff',
      ['fill-opacity']='0.7',
      stroke='#000000',
      ['stroke-width']='2'
    }),
  })
}

print(et.SVG.dump_string(DOCUMENT))
