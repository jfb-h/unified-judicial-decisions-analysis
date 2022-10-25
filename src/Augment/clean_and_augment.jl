function read_json(file::AbstractString)
    Dict.(JSON3.read(read(file); jsonlines=true))
end

function read_patents(file::AbstractString) 
    csv = CSV.File(file)
    group(csv.publn_nr, csv.cpc)
end

function read_judges(file::AbstractString)
    csv = CSV.File(file)
    id_date = csv.id .* " : " .* csv.date
    dictionary(unique(id_date .=> csv.judges_final))
end

function augment_json!(jsondict, patents, judges)
    p = jsondict[:patent]
    p = (startswith(p, r"DE|EP") || p == "unknown") ? p : "DE" * p
    i = jsondict[:id]
    d = Dates.format(Date(jsondict[:date]), "dd.mm.Y")
    id_date = i .* " : " .* d
    
    if haskey(judges, id_date)
        jsondict[:judges] = split(judges[id_date], ";")
    else
        jsondict[:judges] = jsondict[:judges]
    end
    
    if !haskey(patents, p) 
        jsondict[:patent] = Dict(:nr => p, :cpc => missing)
    else
        jsondict[:patent] = Dict(:nr => p, :cpc => patents[p])
    end

    jsondict
end

function clean_and_augment(dir=JSONDIR, outdir=AUGMENTDIR; judges=JUDGESFILE, patents=PATENTSFILE)
    FILES = filter(endswith(".jsonl"), readdir(dir))
    isdir(outdir) || mkdir(outdir)

    pats = read_patents(patents)
    juds = read_judges(judges)

    for f in FILES
        json = read_json(joinpath(dir, f))
        aug = map(x -> augment_json!(x, pats, juds), json)
        open(joinpath(outdir, f), "w") do io
            for j in aug
                JSON3.write(io, j)
                write(io, "\n")
            end
        end
    end
end