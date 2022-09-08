# NeXUS File Formats

## NeXUS ROM

A NeXUS ROM is a collection of code and images for the purposes of running a game. NeXUS ROMs are formatted as RIFF files with a form FourCC of `NXSR` (for **N**e**X**U**S** **R**OM).

### Code chunks (FourCC: `CODE`)

Contains Lua code as plain text.

### Graphics chunks (FourCC: `GRPH`)

Contains graphics data in a special format, for data starting at `n`:

|Start|Length|What|
|-|-|-|
|n+0|4|ID (u32)|
|n+4|4|Width (u32)|
|n+8|4|Height (u32)|
|n+C|Width * Height|Graphics (using 332 color format as described in the API doc)|

The ID is used in the API to describe which graphics chunk data is being pulled from.

### Binary chunks (FourCC: `BIN `)

Contains read-only binary data to be used during the game. For data starting at `n`:

|Start|Length|What|
|-|-|-|
|n|4|ID (u32)|
|n+4|...|Binary data|

## NeXUS Save

The NeXUS save format is used to save data of arbitrary size.

|Start|Length|What|
|-|-|-|
|0|3|"NSV" literal|
|3|1|Save file format version (currently 0)|
|4|...|Save data|

The save file format version is currently 0; increased save file format versions may include additional information in the header, but no other versions are defined at this time.
