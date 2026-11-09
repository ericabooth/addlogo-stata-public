# addlogo — stamp a logo onto your Stata graphs

**Brand any Stata graph with a logo in one command: export the graph, composite the logo, done.**

```stata
twoway (scatter price mpg) (lfit price mpg), name(fig1, replace)
addlogo, logo("mylogo.png") saving("fig1.png") name(fig1) replace
```

Stata has no way to place a raster image inside the plot region, so `addlogo` exports the current (or named) graph and composites a logo onto it. The logo is sized *relative to the graph*, so it looks the same whether you export at 1200px or 4800px — the key to a consistent look across a report or a slide deck. It works on the current graph, a named graph, a saved `.gph`, or an already-exported image, at nine positions, with adjustable opacity, to PNG / TIF / JPG / PDF.

The compositing is done by **ImageMagick** or by a small **Python + Pillow** helper — whichever you have installed. `engine(auto)` (the default) picks one for you.

## Install

**1. Install one image engine** (either is fine; ImageMagick needs no Python):

```bash
brew install imagemagick        # engine(magick)  — self-contained
# --- or ---
pip3 install Pillow             # engine(python)
```

**2. Install the package in Stata:**

```stata
net install addlogo, from("https://raw.githubusercontent.com/ericabooth/addlogo-stata-public/main/") replace force
help addlogo
```

**3. macOS only — point Stata at the engine.** When Stata is launched from the Dock its `PATH` does not include `/opt/homebrew/bin`, so set the full path once in your `profile.do`. (`addlogo` also probes the usual Homebrew/system locations automatically, so this is belt-and-suspenders.)

```stata
global ADDLOGO_MAGICK "/opt/homebrew/bin/magick"      // if you use ImageMagick
global ADDLOGO_PY     "/opt/homebrew/bin/python3"      // the python3 that has Pillow
```

## What it does

| option | default | meaning |
|--------|---------|---------|
| `logo(file)`      | —      | logo image, ideally a **PNG with transparency** *(required)* |
| `saving(file)`    | —      | output; format from extension (`png` `tif` `jpg` `pdf`) *(required)* |
| `position(str)`   | `se`   | `nw n ne w c e sw s se` (long forms + `top-left` etc. ok with both engines; anything else is an error) |
| `scale(#)`        | `.12`  | logo **width as a fraction of the graph width** |
| `pad(#)`          | `.02`  | margin from the edge, as a fraction of graph width |
| `opacity(#)`      | `1`    | `0`–`1` alpha multiplier (e.g. `.85` for a subtle watermark) |
| `width(#)`        | `2400` | export width in px when stamping the current/named graph |
| `name(str)`       | —      | export a specific named graph in memory |
| `engine(str)`     | `auto` | `auto` \| `python` \| `magick` |
| `pyexec(str)`     | —      | python interpreter that has Pillow |
| `magickexec(str)` | —      | path to the `magick` binary |
| `replace`         | —      | overwrite `saving()` (written only after the composite succeeds, so `saving()` may equal `using`) |

`addlogo` is `rclass`: it returns `r(file)` (the output written) and `r(engine)`.

## Examples

**One line per figure** — set the logo once, then brand every graph you export:

```stata
global LOGO "path/to/brand.png"

twoway …, name(fig1, replace)
addlogo, logo("$LOGO") saving("figures/fig1.png") name(fig1) replace
```

**A light watermark, top-left:**

```stata
addlogo, logo("$LOGO") saving("fig1.png") position(nw) scale(.18) opacity(.85) replace
```

**Batch-brand a whole folder of saved `.gph` files:**

```stata
local files : dir "graphs" files "*.gph"
foreach f of local files {
    local stem = substr("`f'", 1, strrpos("`f'", ".") - 1)
    addlogo using "graphs/`f'", logo("$LOGO") saving("branded/`stem'.png") replace
}
```

**Re-brand PNGs you already exported** (no Stata graph needed):

```stata
addlogo using "old_figure.png", logo("$LOGO") saving("old_figure_branded.png") replace
addlogo using "old_figure.png", logo("$LOGO") saving("old_figure.png") replace   // in place
```

The helper also runs straight from a shell / Makefile, bypassing Stata:

```bash
python addlogo_helper.py --base fig.png --logo logo.png --out fig.png --position se --scale .12
```

## Notes

- **Transparency.** Use a PNG logo with an alpha channel; `opacity()` fades it further for watermarks.
- **PDF / vector.** `saving(fig.pdf)` gives a raster-in-PDF that embeds fine in Beamer. For a *true vector* overlay, export the graph as `.svg` and inject an `<image>` tag, or overlay the logo at `\includegraphics` time with a TikZ node.
- **Why not inside `twoway`?** Stata can't place a raster in the plot region, and rebuilding a logo from markers doesn't scale. Compositing after export is the robust, format-agnostic route.
- **Try it:** `example_addlogo.do` in this repo brands `sysuse auto` with the shipped placeholder `testlogo.png`.

## Author and license

Eric A. Booth, Sr Researcher, Texas 2036 (eric.a.booth@gmail.com), 2026. MIT-licensed. Part of a Stata suite alongside [`googlechart`](https://github.com/ericabooth/googlechart-stata-public), [`googlesheets`](https://github.com/ericabooth/googlesheets-stata-public), and [`webapi`](https://github.com/ericabooth/webapi-stata-public).

## Changes

- **1.0.1 (2026-11-09):** long-form positions (`northwest`, `top-left`, `center`, ...) now work with the ImageMagick engine (they silently fell back to `se`), and an unknown position is an error (r(198)). Re-branding in place (`using X ... saving(X) replace`) no longer deletes `X`: the composite goes to a temporary file and is copied over `saving()` only on success. An unreadable logo now fails instead of reusing a logo resized by an earlier call, and temporary files are removed on every exit. The width probe no longer redirects to `/dev/null` on Windows. A leading `~` in `logo()`, `saving()` or `using` is expanded from `HOME`.
