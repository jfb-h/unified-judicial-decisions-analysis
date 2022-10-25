function make_manual_check_for_judgenames(dir=JSONDIR, outfile=JUDGESFILE)
    check(doc) = length(doc.judges) < 2 || length(doc.judges) > 6
    hasnames(doc) = !endswith(r"\s*Unterschriften\s*"i)(last(doc.pages))
    cleantext(str) = replace(str, r"\s+|,|;" => " ")
    isnullity(doc) = contains(first(doc.pages), "URTEIL") && contains(first(doc.pages), "In der Patentnichtigkeitssache")

    json = mapreduce(vcat, dir) do json
        JSON3.read(read(json), jsonlines=true)
    end
    
    out = map(json) do j
        (
            id=j.id, 
            date=j.date,
            nullity=isnullity(j),
            check=check(j), 
            hasnames=hasnames(j),
            judges=join(j.judges, ";"),
            lastpage=cleantext(last(j.pages)),
        )
    end

    CSV.write(outfile, out)
end