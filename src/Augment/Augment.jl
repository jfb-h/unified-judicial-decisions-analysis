"""
Part of the statistical analysis of BPatG decisions performed in the UNIFIED project.

Augment the extracted metadata and content contained in the files in JSONDIR with manually
cleaned judge names (JUDGESFILE) and CPC subclasses for the patents involved in the trials (PATENTSFILE),
and store the result to AUGMENTDIR.

# API
- `clean_and_augment(dir=JSONDIR, outdir=AUGMENTDIR; judges=JUDGESFILE, patents=PATENTSFILE)`
- `make_manual_check_for_judgenames(dir=JSONDIR, outfile=JUDGESFILE)`
- `init_db(dbpath=DBDIR, csvdir=PATSTATDIR)`
- `make_patentinfo(outfile=PATENTSFILE, db=DBDIR)`


"""
module Augment

using CSV
using JSON3
using SplitApplyCombine
using Dictionaries
using Dates
using SQLite
using DBInterface
using DataFrames

const JUDGESFILE = "data/augment/judges_manual_cleaned.csv"
const PATENTSFILE = "data/augment/patentinfo.csv"

const JSONDIR = "data/processed/json"
const AUGMENTDIR = "data/processed/json_augmented"

const DBDIR = "E:/patstat_applications.db"
const PATSTATDIR = "D:/Databases/PATSTAT/2019/CSV"

include("clean_and_augment.jl")
include("manual_cleaning.jl")
include("patents_cpc.jl")

end#module