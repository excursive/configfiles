" lightline theme to match the two-firewatch vim theme, with some color inspiration
" from the original powerline theme

" two-firewatch background color:
let s:bg = '#282c34'
" two-firewatch foreground color:
let s:fg = '#abb2bf'

" two-firewatch colors:
let s:red = '#e06c75'
let s:orange = '#dd672c'
let s:tan = '#c8ae9d'


" line background color (increasing values):
let s:lbg = '#303641'
let s:lbg2 = '#3e4552'
let s:lbg3 = '#545a65'
let s:lbgl = '#a8aaaf'

" mode indicator background colors:
let s:nmodebg = '#88be35'
let s:imodebg = '#f8f8f8'
let s:vmodebg = '#d37a22'
let s:rmodebg = '#b12121'

" insert mode line background color (increasing values):
let s:ilbg = '#234d6d'
let s:ilbg2 = '#2b678a'
let s:ilbgl2 = '#7ba4c1'
let s:ilbgl = '#9fc6e0'

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

let s:p.inactive.left = [ [s:lbg3, s:lbg], [s:lbg3, s:lbg] ]
let s:p.inactive.right = [ [s:lbg3, s:lbg], [s:lbg3, s:lbg] ]
let s:p.inactive.middle = [ [s:lbg3, s:lbg] ]
let s:p.normal.left = [ [s:bg, s:nmodebg, 'bold'], [s:fg, s:lbg2] ]
let s:p.normal.right = [ [s:bg, s:lbgl], [s:fg, s:lbg2] ]
let s:p.normal.middle = [ [s:fg, s:lbg] ]
let s:p.insert.left = [ [s:bg, s:imodebg, 'bold'], [s:imodebg, s:ilbg2] ]
let s:p.insert.right = [ [s:bg, s:ilbgl], [s:ilbgl, s:ilbg2] ]
let s:p.insert.middle = [ [s:ilbgl2, s:ilbg] ]
let s:p.visual.left = [ [s:bg, s:vmodebg, 'bold'], [s:fg, s:lbg2] ]
let s:p.visual.right = s:p.normal.right
let s:p.visual.middle = s:p.normal.middle
let s:p.replace.left = [ [s:imodebg, s:rmodebg, 'bold'], [s:fg, s:lbg2] ]
let s:p.replace.right = s:p.normal.right
let s:p.replace.middle = s:p.normal.middle
let s:p.tabline.left = s:p.normal.middle
let s:p.tabline.tabsel = [ [s:bg, s:tan, 'bold'] ]
let s:p.tabline.middle = s:p.normal.middle
let s:p.tabline.right = [ [s:bg, s:red] ]
let s:p.normal.error = [ [s:bg, s:red] ]
let s:p.normal.warning = [ [s:bg, s:orange] ]

let g:lightline#colorscheme#powerline_two_firewatch#palette = lightline#colorscheme#fill(s:p)
