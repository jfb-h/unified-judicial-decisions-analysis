function _makepool(json, idx::Symbol)
  u = unique(filter!(!isnothing, mapreduce(j -> getindex(j, idx), vcat, json)))
  Dictionary(sort(u), 1:length(u))
end

"""
    loaddata(file)

Load data from jsonlines (`.sjonl`) file `file` and construct a `Vector{Decision}`.
"""
function loaddata(file::AbstractString)
    json = JSON3.read(read(file), jsonlines=true)

    OUTCOMEPOOL = dictionary(["partially annulled" => 1, "annulled" => 2, "claim dismissed" => 3]) 
    JUDGEPOOL = Model._makepool(json, :judges)
    BOARDPOOL = Model._makepool(json, :board)
    CPCPOOL = Model._makepool(json, :cpc)

    map(enumerate(json)) do (i, j)
        outcome = Outcome(OUTCOMEPOOL[j.outcome], j.outcome)
        board   = Board(BOARDPOOL[j.board], "$(j.board). Board")
        judges  = isnothing(j.judges) ? Judge[] : map(j -> Judge(JUDGEPOOL[j], j), j.judges)
        patent  = Patent(j.patent, j.cpc)
        date    = Date(j.date, dateformat"m/dd/yyyy")

        Decision(i, j.id, patent, outcome, date, board, judges)
    end
end

"""
    cpc2int(decisions, levelfun)

Return (1) an array of arrays containing, for each decision in `decisions`, 
a vector with the integer positions of its associated cpc symbols with respect
to (2) a sorted list of all cpc classes contained in decisions, as aggregated
via `levelfun`. 
"""
function cpc2int(decisions, levelfun)
	ts = (levelfun ∘ patent).(decisions)
    tref = sort(unique(reduce(vcat, ts)))
    ts_int = map(t -> map(i -> findfirst(==(i), tref), t), ts)
    ts_int = convert(Vector{Vector{Int}}, ts_int)
	ts_int, tref
end	

_filterjudges(problem, predicate) = begin 
    j = reduce(vcat, problem.js)
    c = countmap(j) |> Dictionary
    filter!(predicate, c) |> keys |> collect
end

