using JSON3
using CSV
using DataFrames
using Dates
using Dictionaries
using ThreadsX

const JUDGESFILE = "data/augment/judges_manual_cleaned.csv"
const CPCFILE = "data/augment/patentinfo.csv"
const PDFDIR = "data/raw/pdf_filtered"
const RESFILE = "data/processed/data"

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
get_casenumber(s::AbstractVector) = get_casenumber(join(first(s, 5)))

function get_senate(s::AbstractString)
  m = match(r"[0-9]\.*\s*Senat", s)
  isnothing(m) && return 0
  parse(Int, match(r"[0-9]{1,2}", m.match).match)
end
get_senate(s::AbstractVector) = get_senate(join(first(s, 5)))

function get_patent(s::AbstractString)
  m = match(r"betreffend\s{0,3}das\s{0,3}(europäische|deutsche)?\s{0,3}Patent\s{0,3}(DE|EP)?([0-9]|\s){6,20}"i, s)
  isnothing(m) && return missing
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
get_patent(s::AbstractVector) = get_patent(join(first(s, 5)))

function get_outcome(s::AbstractString)
  _cleanwhitespace(s) = replace(s, r"\s{1,}" => " ")

  RESULTMATCHES = dictionary([
    r"teilweise für nichtig erklärt"i => "partially annulled",
    r"im Umfang (der|seiner) (patent)?ansprüche(.*)für nichtig erklärt"i => "partially annulled",
    r"für nichtig erklärt, soweit" => "partially annulled",
    r"für nichtig erklärt"i => "annulled",
    r"die Klagen? (wird|werden) abgewiesen"i => "claim dismissed",
  ])
  m = map(keys(RESULTMATCHES)) do m
    !isnothing(match(m, _cleanwhitespace(s)))
  end
  all(m .== false) && return missing
  RESULTMATCHES[findfirst(m)] # TODO: Should not just pick first result
end
get_outcome(s::AbstractVector) = get_outcome(join(first(s, 5)))

function extractinfo(docs)
  DataFrame(
    file=docs.file,
    id=get_casenumber.(docs.doc),
    date=parse_date.(docs.file),
    senate=get_senate.(docs.doc),
    patent=get_patent.(docs.doc),
    outcome=get_outcome.(docs.doc),
  )
end

function combine_datasets(extracted, judges, cpcs)
  res = leftjoin(extracted, judges; on=:id, makeunique=true)
  res = leftjoin(res, cpcs; on=:patent => :publn_nr, matchmissing=:notequal)
end

function unflatten_results(df)
  splitm(v) = [ismissing(x) ? x : split(x, ";") for x in v]
  res = copy(df)
  res.judges = splitm(res.judges)
  res.cpc = splitm(res.cpc)
  res
end

function write_csv(out, result::DataFrame)
  CSV.write(out * ".csv", result)
end
function write_json(out, result::DataFrame)
  res = unflatten_results(result)
  open(out * ".jsonl", "w") do io
    for row in Tables.rowtable(res)
      JSON3.write(io, row)
      print(io, "\n")
    end
  end
end

function csv2json(csv, json)
  csv = CSV.read(csv, DataFrame)
  res = unflatten_results(csv)
  open(json, "w") do io
    for row in Tables.rowtable(res)
      JSON3.write(io, row)
      print(io, "\n")
    end
  end
end

function main()
  #files = filepaths(PDFDIR)
  docs = readpdfs(PDFDIR)
  judges = readjudges(JUDGESFILE)
  cpcs = readcpcs(CPCFILE)

  extracted = extractinfo(docs)
  res = combine_datasets(extracted, judges, cpcs)

  write_csv(RESFILE, res)
  #write_json(RESFILE, res)
end

isinteractive() || main()
