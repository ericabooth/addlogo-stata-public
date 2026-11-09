*! addlogo 1.0.1  Eric Booth  09nov2026
*! Stamp a logo onto a Stata graph: export the graph, composite a logo, save it.
*!
*! Syntax:
*!   addlogo [using imagefile] , logo(file) saving(file) [options]
*!
*! With no  using , the CURRENT graph (or the one in name()) is exported first.
*! A  using  ending in .gph is opened and rendered; any other  using  is treated
*! as an already-exported image (png/tif/jpg/...).
*!
*! Options:
*!   logo(file)      logo image, ideally a PNG with transparency          (required)
*!   saving(file)    output file; format inferred from extension          (required)
*!   position(str)   nw n ne w c e sw s se, or long forms such as
*!                   northwest, top-left, center               (default: se)
*!   scale(#)        logo width as a fraction of graph width    (default: .12)
*!   pad(#)          margin from edge as a fraction of width    (default: .02)
*!   opacity(#)      0..1 alpha multiplier for the logo         (default: 1)
*!   width(#)        export width in px for the current graph   (default: 2400)
*!   name(str)       export a specific named graph in memory
*!   engine(str)     auto | python | magick                    (default: auto)
*!   pyexec(str)     python interpreter that has Pillow
*!   magickexec(str) path to the ImageMagick 'magick' binary
*!   replace         overwrite saving() if it exists
*!
*! Set-once defaults (e.g. in profile.do) avoid macOS PATH surprises:
*!   global ADDLOGO_PY     "/opt/homebrew/bin/python3"   // must have Pillow
*!   global ADDLOGO_MAGICK "/opt/homebrew/bin/magick"
*!
*! Changes:
*!   1.0.1  09nov2026  long-form positions work with ImageMagick (they fell
*!                     back to se); unknown positions are an error; in-place
*!                     re-branding (using X, saving(X)) no longer deletes X;
*!                     an unreadable logo fails instead of reusing an older
*!                     resized logo; temporary files are removed on every
*!                     exit; Windows-safe stderr redirect; a leading ~ in
*!                     logo(), saving() or using is expanded.
*!   1.0.0  18jul2026  first public version.

program define addlogo, rclass
    version 16.0

    syntax [using/] ,                       ///
        Logo(string)                        ///
        SAVing(string)                      ///
        [                                   ///
        POSition(string)                    ///
        SCale(real 0.12)                    ///
        PAD(real 0.02)                      ///
        OPacity(real 1.0)                   ///
        Width(integer 2400)                 ///
        Name(string)                        ///
        ENGine(string)                      ///
        PYexec(string)                      ///
        MAGICKexec(string)                  ///
        replace                             ///
        ]

    // ---------- defaults & light validation ----------
    if (`"`engine'"' == "") local engine auto
    local engine = lower("`engine'")
    if (!inlist("`engine'","auto","python","magick")) {
        di as error "addlogo: engine() must be auto, python, or magick"
        exit 198
    }
    if (`opacity' < 0 | `opacity' > 1) {
        di as error "addlogo: opacity() must be between 0 and 1"
        exit 198
    }

    // position(): normalise long forms to the nine short codes
    local position = lower(strtrim(`"`macval(position)'"'))
    if (`"`position'"' == "") local position se
    local pos ""
    if inlist(`"`position'"', "nw", "northwest", "topleft", "top-left")  local pos nw
    if inlist(`"`position'"', "n", "north", "top")                       local pos n
    if inlist(`"`position'"', "ne", "northeast", "topright", "top-right") local pos ne
    if inlist(`"`position'"', "w", "west", "left")                       local pos w
    if inlist(`"`position'"', "c", "center", "centre", "middle")         local pos c
    if inlist(`"`position'"', "e", "east", "right")                      local pos e
    if inlist(`"`position'"', "sw", "southwest", "bottomleft", "bottom-left") local pos sw
    if inlist(`"`position'"', "s", "south", "bottom")                    local pos s
    if inlist(`"`position'"', "se", "southeast", "bottomright", "bottom-right") local pos se
    if ("`pos'" == "") {
        di as error `"addlogo: unknown position(`macval(position)')"'
        di as error "         use one of nw n ne w c e sw s se (or northwest, top-left, center, ...)"
        exit 198
    }
    local position `pos'

    // expand a leading ~ ourselves (external programs do not)
    local home : env HOME
    if (`"`home'"' == "") local home : env USERPROFILE
    foreach f in logo saving using {
        local v `"`macval(`f')'"'
        if (`"`macval(v)'"' == "~" | substr(`"`macval(v)'"', 1, 2) == "~/" | ///
            substr(`"`macval(v)'"', 1, 2) == "~\") {
            if (`"`home'"' == "") {
                di as error "addlogo: cannot expand ~ (HOME is not set)"
                exit 198
            }
            local tail = substr(`"`macval(v)'"', 2, .)
            local `f' `"`home'`macval(tail)'"'
        }
    }

    capture confirm file `"`logo'"'
    if (_rc) {
        di as error `"addlogo: logo file not found: `macval(logo)'"'
        exit 601
    }

    // ---------- overwrite guard ----------
    if ("`replace'" == "") {
        capture confirm file `"`saving'"'
        if (_rc == 0) {
            di as error `"addlogo: `macval(saving)' already exists (specify -replace-)"'
            exit 602
        }
    }

    // ---------- working files ----------
    // All intermediates sit beside saving() with clean names: Stata tempfile
    // names contain a period, which confuses graph export's suffix detection.
    // The composite is written to a temporary output and copied over saving()
    // only when it succeeds, so using X, saving(X) never loses X.
    local sl = max(strrpos(`"`saving'"', "/"), strrpos(`"`saving'"', "\"))
    local dot = strrpos(`"`saving'"', ".")
    if (`dot' > `sl' + 1) {
        local stub = substr(`"`saving'"', 1, `dot' - 1)
        local ext  = substr(`"`saving'"', `dot', .)
    }
    else {
        local stub `"`saving'"'
        local ext ""
    }
    local basepng `"`stub'__addlogo_base.png"'
    local logopng `"`stub'__addlogo_logo.png"'
    local outtmp  `"`stub'__addlogo_out`ext'"'
    local wtmp    `"`stub'__addlogo_w.txt"'
    foreach f in basepng logopng outtmp wtmp {
        capture erase `"``f''"'
    }

    capture noisily {
        // ---------- resolve the base image ----------
        if (`"`using'"' != "") {
            capture confirm file `"`using'"'
            if (_rc) {
                di as error `"addlogo: file not found: `macval(using)'"'
                exit 601
            }
            if (substr(lower(`"`using'"'), -4, 4) == ".gph") {
                graph use `"`using'"'
                graph export `"`basepng'"', width(`width') replace
                local base `"`basepng'"'
            }
            else {
                local base `"`using'"'
            }
        }
        else {
            if ("`name'" != "") local gname name(`name')
            capture noisily graph export `"`basepng'"', width(`width') replace `gname'
            if (_rc) {
                local rc = _rc
                di as error "addlogo: could not export the current graph " ///
                            "(is a graph open, or pass a name()/using?)"
                exit `rc'
            }
            local base `"`basepng'"'
        }

        // ---------- resolve engine executables (survive minimal GUI PATH) ----------
        local magick ""
        if (`"`magickexec'"' != "")            local magick `"`magickexec'"'
        else if (`"$ADDLOGO_MAGICK"' != "")    local magick "$ADDLOGO_MAGICK"
        else {
            foreach c in /opt/homebrew/bin/magick /usr/local/bin/magick {
                if ("`magick'" == "") {
                    capture confirm file "`c'"
                    if (_rc == 0) local magick "`c'"
                }
            }
        }

        local py ""
        if (`"`pyexec'"' != "")          local py `"`pyexec'"'
        else if (`"$ADDLOGO_PY"' != "")  local py "$ADDLOGO_PY"
        else {
            foreach c in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3 {
                if ("`py'" == "") {
                    capture confirm file "`c'"
                    if (_rc == 0) local py "`c'"
                }
            }
        }
        if ("`py'" == "") local py "python3"

        if ("`engine'" == "auto") {
            if ("`magick'" != "") local engine magick
            else                  local engine python
        }
        if ("`engine'" == "magick" & "`magick'" == "") local magick "magick"

        // stderr sink for the width probe (cmd.exe has no /dev/null)
        if ("`c(os)'" == "Windows") local nullerr "2>NUL"
        else                        local nullerr "2>/dev/null"

        // ---------- composite ----------
        if ("`engine'" == "python") {
            capture findfile addlogo_helper.py
            if (_rc) {
                di as error "addlogo: cannot find addlogo_helper.py on the adopath " ///
                            "(reinstall the package; keep it beside addlogo.ado)"
                exit 601
            }
            local pyscript "`r(fn)'"
            shell "`py'" "`pyscript'" --base "`base'" --logo "`logo'" ///
                  --out "`outtmp'" --position "`position'" ///
                  --scale `scale' --pad `pad' --opacity `opacity'
        }
        else {   // magick
            // base width, to size the logo & pad relative to the graph
            shell "`magick'" identify -format "%w" "`base'" > "`wtmp'" `nullerr'
            local _wline ""
            capture confirm file `"`wtmp'"'
            if (_rc == 0) {
                tempname fh
                file open `fh' using `"`wtmp'"', read text
                file read `fh' _wline
                file close `fh'
            }
            local bw = real(trim(`"`_wline'"'))
            if (`bw' >= . | `bw' <= 0) {
                di as error "addlogo: could not read base width via ImageMagick"
                exit 459
            }
            local lw = round(`scale' * `bw')
            if (`lw' < 1) local lw 1
            local padpx = round(`pad' * `bw')

            // gravity + offsets from the chosen anchor
            if ("`position'" == "nw") local grav NorthWest
            if ("`position'" == "n")  local grav North
            if ("`position'" == "ne") local grav NorthEast
            if ("`position'" == "w")  local grav West
            if ("`position'" == "c")  local grav Center
            if ("`position'" == "e")  local grav East
            if ("`position'" == "sw") local grav SouthWest
            if ("`position'" == "s")  local grav South
            if ("`position'" == "se") local grav SouthEast
            local dx `padpx'
            local dy `padpx'
            if (inlist("`position'","n","c","s")) local dx 0
            if (inlist("`position'","w","c","e")) local dy 0

            // resize + apply opacity, then composite
            shell "`magick'" "`logo'" -resize `lw'x ///
                  -channel A -evaluate multiply `opacity' +channel "`logopng'"
            capture confirm file `"`logopng'"'
            if (_rc) {
                di as error `"addlogo: ImageMagick could not read or resize the logo: `macval(logo)'"'
                exit 459
            }
            shell "`magick'" "`base'" "`logopng'" ///
                  -gravity `grav' -geometry +`dx'+`dy' -composite "`outtmp'"
        }

        // ---------- confirm, then move into place ----------
        capture confirm file `"`outtmp'"'
        if (_rc) {
            di as error "addlogo: compositing failed (engine=`engine'); see messages above."
            exit 459
        }
        copy `"`outtmp'"' `"`saving'"', replace
    }
    local rc = _rc
    foreach f in basepng logopng outtmp wtmp {
        capture erase `"``f''"'
    }
    if (`rc') exit `rc'

    di as text "addlogo: wrote " as result `""`saving'""' ///
       as text "  [engine=`engine', pos=`position', scale=`scale', opacity=`opacity']"

    return local engine "`engine'"
    return local file `"`saving'"'
end
