function init_db(dbpath=DBDIR, csvdir=PATSTATDIR)
    isfile(dbpath) && error("DB at $dbpath already exists.") 
    con = SQLite.DB(dbpath)

    # create tables

    pfk = "PRAGMA foreign_keys = ON;"

    app = "CREATE TABLE IF NOT EXISTS applications (
        appln_id INTEGER NOT NULL UNIQUE PRIMARY KEY,
        appln_filing_date TEXT,
        appln_auth TEXT NOT NULL,
        appln_nr TEXT,
        appln_kind TEXT
    );"

    cpc = "CREATE TABLE IF NOT EXISTS cpc (
        appln_id INTEGER NOT NULL REFERENCES applications(appln_id),
        cpc_class_symbol TEXT NOT NULL
    );"

    pub = "CREATE TABLE IF NOT EXISTS publications (
        pat_publn_id INTEGER NOT NULL UNIQUE PRIMARY KEY,
        publn_date TEXT,
        publn_auth TEXT NOT NULL,
        publn_nr TEXT,
        appln_id INTEGER NOT NULL REFERENCES applications(appln_Id)
    );"

    foreach(stmt -> DBInterface.execute(con, stmt), [pfk, app, cpc, pub])

    # load data from csv

    appfiles = ["tls201_part01.csv", "tls201_part02.csv", "tls201_part03.csv"]
    cpcfiles = ["tls224_part01.csv", "tls224_part02.csv"]
    pubfiles = ["tls211_part01.csv"]

    appcols = ["appln_id", "appln_filing_date", "appln_auth", "appln_nr", "appln_kind"]
    cpccols = ["appln_id", "cpc_class_symbol"]
    pubcols = ["pat_publn_id", "publn_date", "publn_auth", "publn_nr", "appln_id"]

    for file in appfiles
        @info "loading $file from csv"
        @time csv = CSV.File(joinpath(csvdir, file); select=appcols, types=Dict("appln_nr" => String)) 
        @info "loading $file into DB"
        @time SQLite.load!(csv, con, "applications")
    end

    for file in cpcfiles
        @info "loading csv file $file"
        @time csv = CSV.File(joinpath(csvdir, file); select=cpccols)
        @info "loading $file into DB"
        @time SQLite.load!(csv, con, "cpc")
    end

    for file in pubfiles
        @info "loading csv file $file"
        @time csv = CSV.File(joinpath(csvdir, file); select=pubcols, types=Dict("publn_nr" => String))
        @info "loading $file into DB"
        @time SQLite.load!(csv, con, "publications")
    end

    # create indexes

    idxs = [
        "CREATE INDEX IF NOT EXISTS applications_appln_id_idx ON applications(appln_id);",
        "CREATE INDEX IF NOT EXISTS applications_appln_auth_nr_idx ON applications(appln_auth, appln_nr);",  
        "CREATE INDEX IF NOT EXISTS cpc_appln_id_idx ON cpc(appln_id);",
        "CREATE INDEX IF NOT EXISTS publications_publn_auth_nr_idx ON publications(publn_auth, publn_nr);",
        "CREATE INDEX IF NOT EXISTS publications_appln_id_idx ON publications(appln_id);",
    ]

    for idx in idxs
        @info idx
        DBInterface.execute(con, idx)
    end
    
    con
end

# function get_cpc_from_application(con, appnr::AbstractString)
#     auth = first(appnr, 2)
#     nr = appnr[3:end]

#     stmt = """
#     SELECT appln_auth, appln_nr, cpc_class_symbol FROM applications
#     LEFT JOIN cpc ON  applications.appln_id = cpc.appln_id
#     WHERE appln_auth = ? AND appln_nr = ?
#     """

#     res = DBInterface.execute(con, stmt, (auth, nr))
#     df = DataFrame(res)
#     select(df, [:appln_auth, :appln_nr] => ByRow(*) => :appln_nr, :cpc_class_symbol => :cpc)
# end

function get_cpc_from_publication(con, pubnr::AbstractString)
    auth = first(pubnr, 2)
    nr = pubnr[3:end]

    stmt = """
    SELECT DISTINCT publn_auth, publn_nr, publn_date, cpc_class_symbol FROM publications
    LEFT JOIN cpc ON publications.appln_id = cpc.appln_id
    WHERE publn_auth = ? AND publn_nr = ?
    """

    res = DBInterface.execute(con, stmt, (auth, nr)).df
    #df = DataFrame(res)
    select(res, [:publn_auth, :publn_nr] => ByRow(*) => :publn_nr, :cpc_class_symbol => :cpc)
end

function make_patentinfo(outfile=PATENTSFILE, db=DBDIR)
    # con = SQLite.DB(db)
    con = DBInterface.connect(DuckDB.DB, db)

    cleanfun(p) = startswith(p, r"DE|EP") ? p : "DE" * p
    patnrs = CSV.read("data/patent_nr.csv", DataFrame)
    patnrs = subset!(patnrs, :patnr => ByRow(!ismissing))
    patnrs = transform!(patnrs, :patnr => ByRow(cleanfun) => :patnr_cleaned)
    
    patnrs = patnrs.patnr_cleaned

    res = mapreduce(vcat, enumerate(patnrs)) do (i, patnr)
        println(i, " ", patnr)
        get_cpc_from_publication(con, patnr)
    end

    CSV.write(outfile, res)
end
