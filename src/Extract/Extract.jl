"""
Part of the statistical analysis of BPatG decisions performed in the UNIFIED project.

Parse the content and metadata of all nullity decisions contained in the pdf documents in FILTERDIR
into json format and store the result into JSONDIR.

# API
- `extract(dir=FILTERDIR, outdir=JSONDIR)`

# Extracted metadata

- date
- outcome
- patent id
- board number
- judges
- content
"""
module Extract

using Dictionaries
using Dates
using RCall
using JSON3
using StructTypes
using ProgressMeter

const FILTERDIR = "data/raw/pdf_filtered"
const JSONDIR = "data/processed/json"

Base.@kwdef mutable struct Document
  id::String = ""
  date::Date = Date(9999)
  outcome::String = ""
  patent::String = ""
  board::Int = 0
  judges::Vector{String} = String[]
  pages::Vector{String}
end

Document(x::Vector{String}) = Document(pages=x)
Document(x::String) = Document(pages=[x])

Base.show(io::IO, doc::Document) = print(io, doc.id)

function Base.show(io::IO, ::MIME"text/plain", doc::Document)
  println(io, "Ruling: $(doc.id)")
  println(io, "Date: $(Dates.format(doc.date, "dd.mm.yyyy"))")
  println(io, "Patent: $(doc.patent)")
  println(io, "Outcome: $(doc.outcome)")
  println(io, "BPatG board: $(doc.board)")
  println(io, "Judges: $(join(doc.judges,", "))")
end

StructTypes.StructType(::Type{Document}) = StructTypes.Struct()

casenumber(d::Document) = d.id
date(d::Document) = d.date
outcome(d::Document) = d.outcome
patent(d::Document) = d.patent
board(d::Document) = d.board
judges(d::Document) = d.judges
pages(d::Document) = d.pages
body(d::Document) = join(pages(d), "\n")

readdocument(file) = JSON3.read(read(file), Vector{Document}, jsonlines=true)

_cleanwhitespace(s) = replace(s, r"\s{1,}" => " ")

function parse_pdf(file)
  R"t = suppressMessages(pdftools::pdf_text($file))"
  @rget t
end

function parse_date(filename::AbstractString)
  m = match(r"[0-9]{1,2}(\.|,|\s)[0-9]{1,2}(\.|,|\s)[0-9]{4,}", filename).match
  m = replace(m, r",|\s" => ".")
  Date(m, "dd.mm.yyyy")
end

function get_casenumber(s::AbstractString)
  m = match(r"[0-9]{1,2}\s{0,3}[a-zA-Z]{1,2}\s{0,3}(\(pat\))?\s{0,3}[0-9]{1,3}\/[0-9]{1,2}(\s{0,3}\((EP|EU)\))?", s)
  isnothing(m) && return ""
  m.match
end
get_casenumber(doc::Document) = get_casenumber(first(doc.pages))

isnullity(casenumber::AbstractString) = occursin(r"ni"i, casenumber)
isnullity(doc::Document) = isnullity(get_casenumber(doc))

function get_board(s::AbstractString)
  m = match(r"[0-9]\.*\s*Senat", s)
  isnothing(m) && return 0
  parse(Int, match(r"[0-9]{1,2}", m.match).match)
end
get_board(doc::Document) = get_board(body(doc))

function get_patent(s::AbstractString)
  m = match(r"betreffend\s{0,3}das\s{0,3}(europäische|deutsche)?\s{0,3}Patent\s{0,3}(DE|EP)?([0-9]|\s){6,20}"i, s)
  isnothing(m) && return "unknown"
  id = match(r"((DE|EP)?[0-9|\s]{6,20})", m.match).match
  id = replace(id, r"\s{1,10}" => "")
  if startswith(id, r"EP|DE")
    return id
  elseif m.captures[1] == "europäische"
    return "EP" * id
  elseif m.captures[1] == "deutsche"
    return "DE" * id
  else
    return id
  end
end
get_patent(d::Document) = get_patent(body(d))

const RESULTMATCHES = dictionary([
  r"teilweise für nichtig erklärt"i => "annulled",
  #r"im Umfang der Ansprüche(.*)für nichtig erklärt"i => "annulled",
  r"für nichtig erklärt"i => "partially annulled",
  r"die Klage wird abgewiesen"i => "claim dismissed",
  #r"Die Erinnerung (*.) wir zurückgewiesen" => "other"
])

function get_result(s::AbstractString)
  m = map(keys(RESULTMATCHES)) do m
    !isnothing(match(m, _cleanwhitespace(s)))
  end
  all(m .== false) && return "other"
  RESULTMATCHES[findfirst(m)]
end
get_result(d::Document) = get_result(body(d))


function _clean_titles(s::AbstractString)
  r = r"((Dipl|Dr)\.{0,1}\s{0,2}-{0,1}(Chem|Phys|Ing)\.{0,1})|(P\s{0,1}\s{0,1}h\s{0,1}\.{0,1}D)|(Dr\.)|(Prof\.)|(rer\.\s{0,1}nat.)|Richter|Richterin"
  replace(s, r => "") |> strip
end

function _clean_lastpage_signature(str::AbstractString)
  r = r"[\n|\s]+(\w{2,3}|\w{2,3}\/\w{2,3}|\w{2,3}\/\w{2,3}\/\w{2,3})\s*\n*$"
  replace(str, r => "")
end

function _clean_names(str::AbstractString)
  str = replace(str, r"(?<=\s[A-Z]{1})\.\s(?=[A-Z]+)" => "_")
  str = replace(str, r"(?<=Von|Van|von|van)\s(?=[A-Z]+)" => "_")
end

function get_judges(doc::Document)
  lastpage = last(pages(doc))
  length(lastpage) < 10 && return String[]
  lastpage = _clean_lastpage_signature(lastpage) |> rstrip
  str = split(lastpage, r"\n+") |> last |> strip
  str = _clean_titles(str)
  str = _clean_names(str)
  str = replace(str, r"\s+" => ";")
  string.(split(str, ";"))
end

function update!(d::Document)
  d.id = get_casenumber(d)
  d.outcome = get_result(d)
  d.patent = get_patent(d)
  d.board = get_board(d)
  d.judges = get_judges(d)
  d
end

function extract(dir=FILTERDIR, outdir=JSONDIR)
  isdir(outdir) || mkdir(outdir)

  SUBDIRS = readdir(dir)
  for SUBDIR in SUBDIRS
    FILES = readdir(joinpath(dir, SUBDIR))

    println("Parsing Pdfs for year $SUBDIR...")

    g = Progress(length(FILES))
    docs = map(FILES) do file
      pdf = parse_pdf(joinpath(dir, SUBDIR, file))
      next!(g, showvalues=[(:File, file)])
      doc = Document(pdf)
      doc.date = parse_date(file)
      doc
    end

    g = Progress(length(docs))
    foreach(docs) do n
      update!(n)
      next!(g)
    end

    OUTFILE = joinpath(outdir, "nullity_$SUBDIR.jsonl")

    println("Writing extracted data to $OUTFILE..")

    open(OUTFILE, "w") do io
      foreach(docs) do d
        JSON3.write(io, d)
        write(io, '\n')
      end
    end
  end
end

end # module
