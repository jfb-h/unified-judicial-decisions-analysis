function read_json(file::AbstractString)
    Dict.(JSON3.read(read(file); jsonlines=true))
end

function read_patents(file::AbstractString) 
    csv = CSV.File(file)
    cpc = group(csv.publn_nr, csv.cpc)
    dat = map(minimum, group(csv.publn_nr, csv.date))
    cpc, dat
end

function read_judges(file::AbstractString)
    csv = CSV.File(file)
    id_date = csv.id .* " : " .* csv.date
    dictionary(unique(id_date .=> csv.judges_final))
end

function augment_json!(jsondict, cpc, dates, judges)
    # judge info
    i = jsondict[:id]
    d = Dates.format(Date(jsondict[:date]), "dd.mm.Y")
    id_date = i .* " : " .* d
    
    if haskey(judges, id_date)
        jsondict[:judges] = split(judges[id_date], ";")
    else
        jsondict[:judges] = jsondict[:judges]
    end

    # patent info
    p = jsondict[:patent]
    p = (startswith(p, r"DE|EP") || p == "unknown") ? p : "DE" * p
    
    if !haskey(cpc, p) 
        jsondict[:patent] = Dict(:nr => p, :cpc => missing, :date => missing)
    else
        jsondict[:patent] = Dict(:nr => p, :cpc => cpc[p], :date => dates[p])
    end

    jsondict
end

function clean_and_augment(dir=JSONDIR, outdir=AUGMENTDIR; judges=JUDGESFILE, patents=PATENTSFILE)
    FILES = filter(endswith(".jsonl"), readdir(dir))
    isdir(outdir) || mkdir(outdir)

    cpc, dates = read_patents(patents)
    juds = read_judges(judges)

    for f in FILES
        json = read_json(joinpath(dir, f))
        aug = map(x -> augment_json!(x, cpc, dates, juds), json)
        open(joinpath(outdir, f), "w") do io
            for j in aug
                JSON3.write(io, j)
                write(io, "\n")
            end
        end
    end
end