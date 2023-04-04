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
