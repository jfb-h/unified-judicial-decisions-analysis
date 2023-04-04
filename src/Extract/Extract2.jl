module Extract

using JSON3
using CSV
using DataFrames
using Dates
using Dictionaries
using ThreadsX

include("utils.jl")
include("io.jl")
include("regex.jl")

# TODO: Simplify initial extract for judge cleaning (get rid of Document)

const JUDGESFILE = "data/augment/judges_manual_cleaned.csv"
const CPCFILE = "data/augment/patentinfo.csv"
const PDFDIR = "data/raw/pdf_filtered"
const MANFILE = "data/processed/data"

function extractinfo(docs)
  DataFrame(
    file=docs.file,
    id=get_casenumber.(docs.doc),
    date=parse_date.(docs.file),
    board=get_board.(docs.doc),
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

function csv_for_manual_cleaning()
  #files = filepaths(PDFDIR)
  docs = readpdfs(PDFDIR)
  judges = readjudges(JUDGESFILE)
  cpcs = readcpcs(CPCFILE)

  extracted = extractinfo(docs)
  res = combine_datasets(extracted, judges, cpcs)

  write_csv(MANFILE, res)
  #write_json(MANFILE, res)
end

end
