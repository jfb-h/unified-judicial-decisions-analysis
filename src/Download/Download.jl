"""
Part of the statistical analysis of BPatG decisions performed in the UNIFIED project.

Download all pdf documents from the official [BPatG repository](http://juris.bundespatentgericht.de) and 
store them in yearly subdirectories in RAWDIR.

# API
- `download(dir=RAWDIR)`
"""
module Download

using HTTP
using ProgressMeter

const RAWDIR = "data/raw/pdf_total"
const YEARS = 2000:2021
const URL_BASE = "http://juris.bundespatentgericht.de/cgi-bin/rechtsprechung/document.py?"

function getfile(dir, year, pos)
    url = URL_BASE * "Gericht=bpatg&Art=en&Datum=$year&Sort=3&pos=$pos&anz=437&Blank=1.pdf"
    HTTP.download(url, dir; update_period=Inf)
end

function getanz(year)
    resp = HTTP.get("http://juris.bundespatentgericht.de/cgi-bin/rechtsprechung/list.py?Gericht=bpatg&Art=en&Datum=$year&Sort=3&Seite=0")
    html = String(resp)
    m = match(r"anz=[0-9]{1,5}", html)
    parse(Int, replace(m.match, "anz=" => ""))
end

function download(dir=RAWDIR)
    isdir(dir) || mkdir(dir)
    foreach(YEARS) do y
        ydir = mkdir(joinpath(dir, string(y)))
        anz = getanz(y)
        g = Progress(anz)
        for pos in 0:(anz-1)
            # File with name containing ".." results in error due to traversal attack; downloaded manually
            (y == 2017 && pos == 0) && continue
            getfile(ydir, y, pos)
            next!(g, showvalues = [(:File, "File $pos for year $y")])
        end
    end
end

end # module