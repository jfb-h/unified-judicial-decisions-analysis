function filepaths(dir)
  join_and_read(dir) = joinpath.(dir, readdir(dir))
  mapreduce(join_and_read, vcat, join_and_read(dir))
end

function readjudges(file)
  df = CSV.read(file, DataFrame)
  fivejudges(x) = length(split(x, ";")) == 5
  rename!(df, :judges_final => :judges)
  df = subset(df, :judges => ByRow(fivejudges))
  unique(df, :id) #TODO entries are unique by ID and date
end

function readcpcs(file)
  df = CSV.read(file, DataFrame)
  combine(groupby(df, :publn_nr), :cpc => (x -> join(x, ";")) => :cpc)
end

function pdf2text(file)
  @info "reading file $file"
  p = `pdftotext -q $file -`
  io = open(p, "r", stdout)
  str = String(read(io))
  split(str, r"\f")
end

function readpdfs(dir)
  ThreadsX.map(filepaths(dir)) do f
    (; file=f, doc=pdf2text(f))
  end |> DataFrame
end

function write_csv(out, result::DataFrame)
  CSV.write(out * ".csv", result)
end

#function write_json(out, result::DataFrame)
#  res = unflatten_results(result)
#  open(out * ".jsonl", "w") do io
#    for row in Tables.rowtable(res)
#      JSON3.write(io, row)
#      print(io, "\n")
#    end
#  end
#end

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
