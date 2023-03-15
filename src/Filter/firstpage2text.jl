function firstpage2text(pdf, output; pages=2)
    run(`pdftotext -l $pages $pdf $output`)
end

function main()
    PDFDIR = "data/raw/pdf_total"
    TEXTDIR = "data/raw/text_total"
    YEARS = string.(2000:2021)

    isdir(TEXTDIR) || mkdir(TEXTDIR)

    for year in YEARS
        @info "processing year $year"
        yeardir = joinpath(TEXTDIR, year)
        isdir(yeardir) || mkdir(yeardir)

        pdfdir = joinpath(PDFDIR, year)
        for file in readdir(pdfdir)
            fp = joinpath(pdfdir, file)
            txtfile = file[begin:(end-4)] * ".txt"
            firstpage2text(fp, joinpath(yeardir, txtfile))
        end
    end
end
