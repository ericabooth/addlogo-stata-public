{smcl}
{* *! version 1.0.2  2026-11-09}{...}
{viewerjumpto "Syntax" "addlogo##syntax"}{...}
{viewerjumpto "Description" "addlogo##description"}{...}
{viewerjumpto "Getting started" "addlogo##quickstart"}{...}
{viewerjumpto "Options" "addlogo##options"}{...}
{viewerjumpto "Engines" "addlogo##engines"}{...}
{viewerjumpto "Stored results" "addlogo##results"}{...}
{viewerjumpto "Examples" "addlogo##examples"}{...}
{viewerjumpto "Remarks" "addlogo##remarks"}{...}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:addlogo} {hline 2}}Stamp a logo onto a Stata graph{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:addlogo} [{cmd:using} {it:imagefile}]{cmd:,}
{cmdab:l:ogo(}{it:file}{cmd:)}
{cmdab:sav:ing(}{it:file}{cmd:)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Required}
{synopt :{cmdab:l:ogo(}{it:file}{cmd:)}}logo image; a PNG with transparency is ideal{p_end}
{synopt :{cmdab:sav:ing(}{it:file}{cmd:)}}output file; the format is taken from its extension{p_end}

{syntab :Placement}
{synopt :{cmdab:pos:ition(}{it:anchor}{cmd:)}}{cmd:nw n ne w c e sw s se}; default {cmd:se}{p_end}
{synopt :{cmdab:sc:ale(}{it:#}{cmd:)}}logo width as a fraction of the graph width; default {cmd:.12}{p_end}
{synopt :{cmd:pad(}{it:#}{cmd:)}}margin from the edge as a fraction of graph width; default {cmd:.02}{p_end}
{synopt :{cmdab:op:acity(}{it:#}{cmd:)}}alpha multiplier {cmd:0}-{cmd:1}; default {cmd:1}{p_end}

{syntab :Source graph}
{synopt :{cmdab:w:idth(}{it:#}{cmd:)}}export width in px for the current/named graph; default {cmd:2400}{p_end}
{synopt :{cmdab:n:ame(}{it:name}{cmd:)}}export a specific named graph in memory{p_end}

{syntab :Engine}
{synopt :{cmdab:eng:ine(}{it:e}{cmd:)}}{cmd:auto}, {cmd:python}, or {cmd:magick}; default {cmd:auto}{p_end}
{synopt :{cmdab:py:exec(}{it:path}{cmd:)}}python interpreter that has Pillow{p_end}
{synopt :{cmdab:magick:exec(}{it:path}{cmd:)}}path to the ImageMagick {cmd:magick} binary{p_end}
{synopt :{cmd:replace}}overwrite {cmd:saving()} if it exists{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:addlogo} adds a logo to a Stata graph.  Stata cannot place a raster image
inside the plot region, so {cmd:addlogo} exports the graph and then composites
the logo onto the exported image.  The logo is sized {it:relative to the graph}
(see {cmd:scale()}), so it keeps the same proportions at whatever export
resolution you choose -- which keeps a set of figures looking consistent.

{pstd}
With no {cmd:using}, the current graph (or the one named in {cmd:name()}) is
exported first.  A {cmd:using} ending in {cmd:.gph} is opened and rendered; any
other {cmd:using} is treated as an already-exported image.  Output may be PNG,
TIF, JPG, or PDF; the format is taken from the {cmd:saving()} extension.


{marker quickstart}{...}
{title:Getting started}

{pstd}
The pattern is always the same -- draw a graph, then hand its name, your logo,
and an output file to {cmd:addlogo}:

{p 8 12 2}{it:(draw a graph)} {cmd:..., name(}{it:mygraph}{cmd:, replace)}{p_end}
{p 8 12 2}{cmd:addlogo, logo(}{it:your_logo.png}{cmd:) saving(}{it:out.png}{cmd:) name(}{it:mygraph}{cmd:) replace}{p_end}

{pstd}
A complete, copy-paste example using Stata's own {cmd:auto} data (any PNG will
do for {cmd:logo()}):

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. scatter price mpg, name(g1, replace)}{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("price_mpg.png") name(g1) replace}{p_end}

{pstd}
That writes {cmd:price_mpg.png} with your logo in the bottom-right corner.  From
there, move it with {cmd:position()}, resize it with {cmd:scale()}, and fade it
to a watermark with {cmd:opacity()}.  See {help addlogo##examples:Examples} for
more.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmdab:l:ogo(}{it:file}{cmd:)} is the logo to stamp.  A PNG with a transparent
background gives the cleanest result; {cmd:opacity()} can fade it further.

{phang}
{cmdab:sav:ing(}{it:file}{cmd:)} is the output file.  Its extension sets the
format ({cmd:.png}, {cmd:.tif}, {cmd:.jpg}, {cmd:.pdf}).  Combine with
{cmd:replace} to overwrite an existing file.  The result is composited into a
temporary file beside {cmd:saving()} and copied into place only on success, so
{cmd:saving()} may name the same image as {cmd:using} (re-branding in place),
and a failed run leaves an existing {cmd:saving()} file untouched.  The folder
named in {cmd:saving()} must already exist (r(603) otherwise).  A leading
{cmd:~} in {cmd:logo()}, {cmd:saving()} or {cmd:using} is expanded from
{cmd:HOME}.

{dlgtab:Placement}

{phang}
{cmdab:pos:ition(}{it:anchor}{cmd:)} chooses one of nine anchors: {cmd:nw n ne}
(top), {cmd:w c e} (middle), {cmd:sw s se} (bottom).  Long forms
({cmd:northwest}, {cmd:north}, {cmd:top-left}, {cmd:top}, {cmd:center},
{cmd:centre}, {cmd:middle}, {cmd:left}, {cmd:right}, {cmd:bottom-right}, ...)
are also accepted by both engines.  Any other value is an error (r(198)).  The
default is {cmd:se} (bottom-right).

{phang}
{cmdab:sc:ale(}{it:#}{cmd:)} sets the logo width as a fraction of the graph
width.  {cmd:scale(.12)} (the default) makes the logo 12% as wide as the graph.
It must be greater than 0 and at most 1.

{phang}
{cmd:pad(}{it:#}{cmd:)} is the margin between the logo and the graph edge, as a
fraction of the graph width (default {cmd:.02}).  It must be at least 0 and less
than .5.

{phang}
{cmdab:op:acity(}{it:#}{cmd:)} multiplies the logo's alpha channel; {cmd:1} is
opaque, {cmd:.85} a light watermark.  A logo without an alpha channel (a JPG, or
a PNG without transparency) is given one first, so both engines fade it the
same way.

{dlgtab:Source graph}

{phang}
{cmdab:w:idth(}{it:#}{cmd:)} is the pixel width at which the current or named
graph is exported before compositing (default {cmd:2400}).

{phang}
{cmdab:n:ame(}{it:name}{cmd:)} exports the named graph in memory instead of the
one currently displayed.

{dlgtab:Engine}

{phang}
{cmdab:eng:ine(}{it:e}{cmd:)} selects the compositor: {cmd:magick} (ImageMagick),
{cmd:python} (Python + Pillow), or {cmd:auto} (the default: ImageMagick if its
binary is found, otherwise Python).

{phang}
{cmdab:py:exec(}{it:path}{cmd:)} and {cmdab:magick:exec(}{it:path}{cmd:)} give
the full path to the interpreter / binary.  Alternatively set the globals
{cmd:$ADDLOGO_PY} and {cmd:$ADDLOGO_MAGICK} once in your {help profile}.
Without them, {cmd:addlogo} probes the usual Homebrew and system locations, and
on Windows the {cmd:ImageMagick-*} folders under {cmd:Program Files}, the
python.org installs under {cmd:%LOCALAPPDATA%/Programs/Python}, and the
{cmd:py} launcher.  If compositing fails, the engine's own messages are shown.


{marker engines}{...}
{title:Engines}

{pstd}
{cmd:addlogo} needs one image compositor:

{p 8 12 2}o  {bf:ImageMagick} -- install with {cmd:brew install imagemagick}
(macOS); it is used with no Python at all.{p_end}
{p 8 12 2}o  {bf:Python + Pillow} -- install with {cmd:pip install Pillow}; the
shipped helper {cmd:addlogo_helper.py} does the compositing.{p_end}

{pstd}
On macOS, a Stata launched from the Dock has a minimal {cmd:PATH} that omits
{cmd:/opt/homebrew/bin}.  Set the engine path once in your {help profile}:

{p 8 12 2}{cmd:global ADDLOGO_MAGICK "/opt/homebrew/bin/magick"}{p_end}
{p 8 12 2}{cmd:global ADDLOGO_PY     "/opt/homebrew/bin/python3"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:addlogo} is {cmd:rclass} and stores in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(file)}}the output file written{p_end}
{synopt:{cmd:r(engine)}}the engine used ({cmd:magick} or {cmd:python}){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Brand the current graph, bottom-right:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. twoway scatter price mpg, name(g1, replace)}{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("fig1.png") name(g1) replace}{p_end}

{pstd}A light watermark, top-left:{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("fig1.png") position(nw) scale(.18) opacity(.85) replace}{p_end}

{pstd}Stamp a graph you saved earlier as {cmd:.gph}:{p_end}
{phang2}{cmd:. addlogo using "fig.gph", logo("logo.png") saving("fig.png") replace}{p_end}

{pstd}Re-brand an already-exported image:{p_end}
{phang2}{cmd:. addlogo using "old.png", logo("logo.png") saving("old_branded.png") replace}{p_end}

{pstd}Re-brand it in place:{p_end}
{phang2}{cmd:. addlogo using "old.png", logo("logo.png") saving("old.png") replace}{p_end}

{pstd}Batch-brand every {cmd:.gph} in a folder (the output folder must exist):{p_end}
{phang2}{cmd:. capture mkdir "branded"}{p_end}
{phang2}{cmd:. local files : dir "graphs" files "*.gph"}{p_end}
{phang2}{cmd:. foreach f of local files {c -(}}{p_end}
{phang2}{cmd:.     local stem = substr("`f'", 1, strrpos("`f'", ".") - 1)}{p_end}
{phang2}{cmd:.     addlogo using "graphs/`f'", logo("logo.png") saving("branded/`stem'.png") replace}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker changes}{...}
{title:Changes}

{phang}1.0.2 (2026-11-09): {cmd:opacity()} now fades a logo without an alpha
channel under ImageMagick too; {cmd:name()} works after an earlier
{cmd:addlogo using} {it:*.gph} in batch mode; {cmd:scale()}, {cmd:pad()} and
{cmd:width()} are validated; a missing {cmd:saving()} folder is a clear error
(r(603)); the engine's messages are shown when compositing fails; on Windows
the engine runs through {cmd:cmd /c} and the usual install folders are
probed.{p_end}

{phang}1.0.1 (2026-11-09): long-form positions ({cmd:northwest}, {cmd:top-left},
{cmd:center}, ...) now work with the ImageMagick engine (they fell back to
{cmd:se}); an unknown position is an error; re-branding in place no longer
deletes the source image; an unreadable logo now fails instead of reusing a
logo resized by an earlier call; temporary files are removed on every exit;
the width probe no longer uses {cmd:/dev/null} on Windows; a leading {cmd:~} is
expanded.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
For a true {it:vector} logo overlay in LaTeX / Beamer, export the graph as
{cmd:.svg} and inject an {cmd:<image>} tag, or overlay the logo at
{cmd:\includegraphics} time with a TikZ node.  {cmd:saving(fig.pdf)} here gives
a raster-in-PDF, which embeds fine for most uses.


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth, Sr Researcher, Texas 2036.
Email {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}.
MIT-licensed.  A companion to {help googlechart}, {help googlesheets}, and
{help webapi}.
