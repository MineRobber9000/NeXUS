# NeXUS API

## Data types

The data types used in describing functions include:

 - `integer`: integer numbers
 - `number`: floating point numbers
 - `string`: strings
 - `color`: colors (one integer, see below)

### Colors

Colors in NeXUS are given in 3-3-2 bit format. With 7 as the most significant bit and 0 as the least significant bit:

```
76543210

Red component: 210
Green component: 543
Blue component: 76
```

For instance, with the color value 160:

```
76543210
10100000

Red component:   000 = 0/7 = 0.00000000
Green component: 100 = 4/7 = 0.57142857
Blue component:   10 = 2/3 = 0.66666667
```

## Graphics

### Side note: graphics pages

Graphics pages are passed into `create_cart.py` as the `--graphics` option, and
are used as space from which you can declare sprites (see `define_spr` below).

The ID assigned to each graphics page is the same as the 0-based index of the
file in the list of files you passed to `create_cart.py`. For instance:

```
You ran:
$ python create_cart.py --graphics primary.png secondary.png -- code.lua out.rom

Your graphics pages are:
[0] = primary.png
[1] = secondary.png
```

### canvas_new

```lua
canvas_new(w: integer, h: integer, [x: integer, y: integer]) -> integer
```

Returns a canvas ID. Canvases are faster at pixel manipulation, at the cost of
lacking certain drawing features. The optional x and y arguments are to
initialize the canvas with pixels from the screen (out-of-range pixels are
filled with black).

### canvas_clear

```lua
canvas_clear(id: integer)
```

Clears the canvas.

### canvas_close

```lua
canvas_close(id: integer)
```

Closes the canvas, freeing all resources connected to it. Any attempt to use a
canvas after closing it will cause an error.

Note that if a new canvas is created, it may be reassigned the same number as a
previously closed canvas.

### canvas_draw

```lua
canvas_draw(id: integer, x: integer, y: integer)
```

Draws the canvas to the screen.

### canvas_pix

```lua
canvas_pix(id: integer, x: integer, y: integer, [color: color]) -> [integer]
```

If the color is not specified, returns the color at (x,y). Otherwise, sets the pixel at (x,y) to `color`.

This function is (or should be) more performant than `pix`, since `pix` has to roundtrip data to the GPU, while `canvas_pix` just has to store to image data on the CPU.

### circ

```lua
circ(x: number, y: number, r: number, color: color)
```

Draws a circle centered on (x,y) of radius `r` and color `color`, filled in.

### circb

```lua
circb(x: number, y: number, r: number, color: color)
```

Draws a circle centered on (x,y) of radius `r` and color `color`, outlined.

### clip

```lua
clip([x: integer, y: integer, w: integer, h: integer])
```

If called with 4 arguments, sets the clipping region to the specified position and size. Drawing operations will not affect pixels outside of this region. If called with no arguments, unsets the clipping region.

### cls

```lua
cls([color: color])
```

Clears the screen to the given color (defaults to 00, black).

### define_spr

```lua
define_spr(id: integer, x: integer, y: integer, w: integer, h: integer, [colorkey: color]) -> integer
```

Defines a sprite based on a w-pixels by h-pixels subset of graphics page id at position (x,y), with optional transparency color colorkey. Returns the ID of the sprite (IDs start at 0 and increment).

### line

```lua
line(x1: number, y1: number, x2: number, y2: number, color: color)
```

Draws a line from (x1,y1) to (x2,y2) in color `color`.

### rect

```lua
rect(x: number, y: number, w: number, h: number, color: color)
```

Draws a rectangle at (x,y) of width w, height h and color `color`, filled in.

### rectb

```lua
rectb(x: number, y: number, w: number, h: number, color: color)
```

Draws a rectangle at (x,y) of width w, height h and color `color`, outlined.

### pix

```lua
pix(x: integer, y: integer, [color: color]) -> [integer]
```

If the color is not specified, returns the color at (x,y). Otherwise, sets the pixel at (x,y) to `color`.

THIS FUNCTION IS VERY HACKY. It is *not* performant, it is *not* something you should be doing often (if at all). Basically, the contents of the screen are cached between successive reads, but any drawing to the screen requires the contents of the screen to be obtained again. Therefore, if you have to do full screen per-pixel effects (most of the time you don't), read all of the pixels you need and THEN manipulate them. Writes are fast, reads are not (unless you do all of the reads in a row).

### print

```lua
print(str: string, [x: number], [y: number], [color: color])
```

Prints string `str` at (x,y) in the color `color`. Defaults to printing at (0,0) in white.

### spr

```lua
spr(id: integer, x: number, y: number, [scale: number, flip: integer, rotate: number])
```

Draws sprite id at (x,y), scaled with a factor of scale, flipped according to the bitmap below, and rotated `rotate` radians.

|Bit|Flip (if set)|
|---|-------------|
|  0|Horizontally |
|  1|Vertically   |

### textwidth

```lua
textwidth(str: string) -> integer
```

Returns the width of the string in pixels as an integer.

### tri

```lua
tri(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, color: color)
```

Draws a triangle with vertices {(x1,y1),(x2,y2),(x3,y3)} and color `color`, filled in.

### trib

```lua
trib(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, color: color)
```

Draws a triangle with vertices {(x1,y1),(x2,y2),(x3,y3)} and color `color`, outlined.

## Sound

### pcm_queue

```lua
pcm_queue(samples: table) -> boolean
```

Queues PCM samples from the given table, and starts playing if the PCM channel was stopped. Samples are 11025Hz 8-bit mono.

The code responsible for loading the samples functions as follows (`arg` being the sample table argument):

```lua
local samples = {}
for i,v in ipairs(arg) do
  -- convert input to 8 bit signed
  v=(v&255)
  if (v&128)>0 then
    v=-128+(v~128)
  end
  -- convert 8 bit signed to float
  v=(v/127)
  if v<-1 then v=-1 end
  if v>1 then v=1 end
  samples[#samples+1]=v
end
-- `samples` now contains the samples to be queued
```

If `pcm_queue` returns false, then the samples could not be queued for whatever reason. It is unlikely that this condition will resolve before the frame is over, so games should reattempt `pcm_queue` on the next frame (or skip the `pcm_queue` invocation altogether).

### pcm_ready

```lua
pcm_ready() -> boolean
```

Returns true if the PCM channel can take more samples.

### pcm_start

```lua
pcm_start()
```

Attempts to start the PCM channel, if there are queued samples to play.

### pcm_stop

```lua
pcm_stop()
```

Stops the PCM channel from playing.

### pcm_clear

```lua
pcm_clear()
```

Clears the PCM channel of queued samples

## Input

### btn

```lua
btn() -> integer
btn(id: integer) -> boolean
```

Gets the current state of the button with ID `id`. If `id` is not provided,
then `btn` will return a bitfield of all of the buttons, with bits as listed below.

|ID|Button|Keyboard mapping|
|--|------|----------------|
| 0|Up    |Up arrow        |
| 1|Down  |Down arrow      |
| 2|Left  |Left arrow      |
| 3|Right |Right arrow     |
| 4|A     |Z               |
| 5|B     |X               |
| 6|Select|Left shift      |
| 7|Start |Enter           |

## Saving/loading

### Side note: file names

NeXUS enforces the POSIX portable file name character set. This character set includes:

 - All uppercase and lowercase Latin letters
 - Numbers 0 to 9
 - The period (.)
 - The hyphen (-)
 - The underscore (_)

Attempting to use a character that is not in this set in a filename will cause an error.

Saves are stored as `name.nxsv` files in the NeXUS save directory. For instance, `load_save("electronico")` will load the data stored in file `electronico.nxsv`.

### delete_save

```lua
delete_save(filename: string)
```

Deletes the save file with name `filename`.

### list_saves

```lua
list_saves([pattern: string]) -> table
```

Returns a table of saves that match the pattern `pattern`. The default pattern is `.+`, which matches any string (in effect, listing all of the saves).

### load_save

```lua
load_save(filename: string) -> string
```

Loads the save file with name `filename`. Returns a string.

### save_exists

```lua
save_exists(filename: string) -> boolean
```

Checks whether or not the save file with the name `filename` exists. Unlike the other saving/loading functions, giving an invalid filename to this function will not error; however, the function will always return false for a filename with illegal characters.

### save_file

```lua
save_file(filename: string, data: string)
```

Saves `data` to save file `filename`.

### valid_save

```lua
valid_save(filename: string) -> boolean
```

Checks whether the filename `filename` is valid.

## Utility functions

### epoch

```lua
epoch() -> number
```

Returns the number of seconds since the Unix epoch.

### get_resource

```lua
get_resource(id: integer) -> string
```

Gets a binary resource. These are defined like graphics pages (see "Side note: graphics pages" above).

### trace

```lua
trace(message: string)
```

Prints a message to the console. Useful for debugging.

### version

```lua
version()
```

Returns the version of NeXUS being used as a string. Currently "Alpha".
