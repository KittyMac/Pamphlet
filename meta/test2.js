#define PAMPHLET_PREPROCESSOR

#define SIZE(W,H) width:W##em;height:H##em;

var x = 5
`SIZE(${x},${x})`
