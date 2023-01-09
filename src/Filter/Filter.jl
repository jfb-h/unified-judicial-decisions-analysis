"""
Part of the statistical analysis of BPatG decisions performed in the UNIFIED project.

Filter all pdf documents contained in RAWDIR down to those that are decisions (Urteil) 
on nullity cases (Nichtigkeit) and store them with a cleaned name in FILTERDIR.

# API
- `filterpdfs(dir=RAWDIR, newdir=FILTERDIR)`
"""
module Filter

using RCall: @R_str, @rget
using ProgressMeter: @showprogress

const RAWDIR = "data/raw/pdf_total"
const FILTERDIR = "data/raw/pdf_filtered"

function parse_pdf(file)
    R"t = suppressMessages(pdftools::pdf_text($file))"
    @rget t
end

function isnullity(page::String)
    contains(page, r"urteil"i) && contains(page, r"nichtigkeitssache"i)
end
isnullity(doc::Vector{String}) = isnullity(first(doc))


function filterpdfs(dir=RAWDIR, newdir=FILTERDIR)
    isdir(newdir) || mkdir(newdir)
    SUBDIRS = readdir(dir)
    @showprogress "Filtering directory..." for SUBDIR in SUBDIRS
        FILES = joinpath.(RAWDIR, SUBDIR, readdir(joinpath(RAWDIR, SUBDIR)))
        for file in FILES
            pdf = parse_pdf(file)
            if isnullity(pdf)
                newsubdir = joinpath(newdir, SUBDIR)
                isdir(newsubdir) || mkdir(newsubdir)
                run(`cp "./$file" "./$newsubdir"`)
            end
        end
    end
    return nothing
end

end#module