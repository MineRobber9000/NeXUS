# NeXUS

A work in progress fantasy console. API documentation is in `API.md` (not that
it's really in a state for you to make games with it yet but if you're really
raring to go, I guess it's there for you...)

The system font is [Matchup Pro][] by [Eeve Somepx][], used with attribution
because holy cow it's a really good font go support Eeve you won't regret it.

## To run

Download a shared library for Lua 5.4 from [LuaBinaries][] (or build one
yourself) and place it somewhere where your system will know to look for it
(on Windows, the directory next to your LOVE executable is a good bet). Name it
something like `lua54.dll` (Windows) or `liblua54.so` (Mac/Linux) so NeXUS can
find it.

In its current state, the easiest way to get coding with NeXUS is to change the
ROM that the game loads for the "no game loaded" screen. Write your code, then run
it through `create_cart.py` to get a ROM. Replace `src/nogameloaded.rom` with your
new ROM, and enjoy!

[Matchup Pro]: https://somepx.itch.io/humble-fonts-free "links to the Humble Fonts Free collection which contains Matchup Pro"
[Eeve Somepx]: https://twitter.com/somepx
[LuaBinaries]: http://luabinaries.sourceforge.net/download.html
