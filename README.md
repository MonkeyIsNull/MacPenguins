# MacPenguins — Penguins for Mac

A macOS port of the classic [XPenguins](https://en.wikipedia.org/wiki/XPenguins)
desktop toy. Cartoon penguins fall from the top of your screen, walk
along the tops of windows, and shuffle around at the bottom of your
display in front of the Dock.

> **Status:** early port. Walking and falling work; a skateboarder
> variant zips around faster. Many of the original states (climbing,
> tumbling, floating, dying, idle actions) are not yet implemented —
> see [Roadmap](#roadmap).

## Requirements

- macOS 13 (Ventura) or later
- Swift toolchain (Xcode or `xcode-select --install`)

## Run

```bash
git clone <this-repo>
cd MacPenguins
./run_macpenguins.sh
```

The script just runs `swift run MacPenguins`. The first run will
build (~1–2 seconds on Apple Silicon); subsequent runs are instant.

Hit `Ctrl+C` in the terminal to stop. There is no dock icon — it runs
as a background service drawing into a transparent overlay window
above the Dock.

## What works

- Penguins fall from the top of the screen and walk along the bottom
- Penguins land on the top edge of any open window and walk along it
- Penguins ride windows as you resize them, and fall off if you shrink
  a window past their feet or close it
- Multi-monitor (the screen-bottom ground is per-screen)
- A skateboarder variant (~3/8 of penguins) walks faster

## What's missing

These exist in the original XPenguins but aren't implemented yet:

- Tumblers (cartwheel fall when walking off a window edge)
- Climbers (scaling window sides / screen edges)
- Floaters (balloon-style upward drift)
- Death animations: explosion, splatted, squashed, zapped
- Angel ascent before respawn
- Idle actions (reader, digger)
- Click-to-zap interaction
- Side-mounted Dock awareness

## Project layout

```
Sources/                 Swift sources (build target)
  main.swift             Entry point
  MacPenguinsService     Update loop, spawning, lifecycle
  SimplePenguin          Per-penguin physics + state machine
  SimpleCollision        Window + ground surface tracking
  SimpleWindowManager    CGWindow polling
  BasicRenderer          NSWindow overlay + sprite rendering
sprites/                 Pre-split walker frames + faller/tumbler
MacPenguins/Themes/      Original-style sprite sheets (incl. skateboarder)
```

The repo also has an `MacPenguins.xcodeproj/` for opening in Xcode if
you prefer; the SwiftPM `Package.swift` is the canonical build target.

## Roadmap

Rough order of attack for the missing pieces:

1. Tumblers — when a walker steps off a window's right/left edge
2. Climbers — when a walker hits a vertical obstacle
3. Death animations + angel respawn cycle
4. Idle actions (reader, digger)
5. Click-to-zap
6. Side-Dock and notch handling

## Credits

This is a port of Robin Hogan's **XPenguins** (1999–2001). All sprite
artwork is his, used under GPL v2. See [`CREDITS.md`](CREDITS.md) for
full attribution.

## License

GNU General Public License v2 — see [`LICENSE`](LICENSE).

This port is GPL v2 because the sprite assets are derivatives of
Robin Hogan's GPL v2 XPenguins artwork. The Swift code in `Sources/`
is original work and is also released under GPL v2 to keep the whole
package consistently licensed.
