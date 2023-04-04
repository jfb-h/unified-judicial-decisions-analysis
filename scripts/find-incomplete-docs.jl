using JSON3

RAWDIR = "data/raw/pdf_filtered"
SRCDIR = "data/processed/json_augmented"
DSTDIR = "data/augment/manualextract"

function filepaths(dir)
  join_and_read(dir) = joinpath.(dir, readdir(dir))
  mapreduce(join_and_read, vcat, join_and_read(dir))
end

iscomplete(doc) =
  hasjudges(doc) &&
  hascpc(doc) &&
  hasoutcome(doc)

hasoutcome(doc) = doc.outcome != "other"
hasjudges(doc) = length(filter(!isnothing, doc.judges)) == 5
hascpc(doc) = !isnothing(doc.patent.cpc) && length(doc.patent.cpc) > 0

function readdocs(dir)
  mapreduce(vcat, joinpath.(dir, readdir(dir))) do file
    JSON3.read(read(file), jsonlines=true)
  end
end

function file_from_doc(doc, files)
  findall(contains(doc.id), files)
end

function copyfile(doc, file, todir)
  filename = last(splitpath(file))
  run(`mv $filename $(joinpath(todir, filename))`)
end

function main()
  files = filepaths(SRCDIR)
  docs = readdocs(SRCDIR)
  idxs = findall(iscomplete, docs)
  copyfiles(files[idxs], DSTDIR)
end

