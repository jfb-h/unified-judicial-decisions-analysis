
"""
    Outcome

Outcome of a judicial decision.

# Fields
- id::Int : Integer representation of the decision outcome, should be contiguous
- label::String : Label of the decision outcome
"""
struct Outcome
  id::Int
  label::String
end

"""
    Board

Board making a judicial decision.

# Fields
- id::Int : Integer index of the board, should be contiguous
- label::String : Name of the board
"""
struct Board
  id::Int
  label::String
end

"""
    Judge

Judge involved in making a judicial decision.

# Fields
- id::Int : Integer representation of the judge, should be contiguous from 1:NJudges
- label::String : Name of the judge
"""
struct Judge
  id::Int
  label::String
end

#"""
#  CPC
#
#CPC technology classification code
#"""
#struct CPC
#  id::Int
#  label::String
#end

"""
    Patent

Patent for which a validity decision is to be made. Contains the patent number issued 
by the respective authority (`auth` and `id`) and a vector of CPC symbols.
"""
struct Patent
  nr::String
  cpc::Vector{String}
end

id(x::Patent) = x.nr
cpc(x::Patent) = x.cpc
subclass(x::Patent) = first.(x.cpc, 4) |> unique
class(x::Patent) = first.(x.cpc, 3) |> unique
section(x::Patent) = first.(x.cpc, 1) |> unique
office(x::Patent) = first(id(x), 2)

"""
Decision

Metadata for a judicial decisions on patent nullity.
    
    # Fields
    - id::Int : Integer id of the decision
    - label::String : Official id as found on the decision document
    - patent::String : id of the patent
    - outcome::Outcome : decision outcome
    - date::Date : date of publication of the decision
    - board::Board : board making the decision
    - judges::Vector{Judge} : panel of judges involved in the decision
"""
struct Decision
  id::Int
  label::String
  patent::Patent
  outcome::Outcome
  date::Date
  board::Board
  judges::Vector{Judge}
end

id(x) = x.id
label(x) = x.label

patentage(d::Decision) = (date(d) - date(patent(d))).value / 365

outcome(x::Decision) = x.outcome
patent(x::Decision) = x.patent
board(x::Decision) = x.board
judges(x::Decision) = x.judges
chairman(x::Decision) = first(judges(x))
date(x::Decision) = x.date

Base.show(io::IO, d::Decision) = print(io, label(d))

function Base.show(io::IO, ::MIME"text/plain", d::Decision)
  println(io, "Ruling $(label(d)) on $(id(patent(d)))")
  println(io, "Date of decision: $(Dates.format(date(d), "d U, Y"))")
  println(io, "Decided by: $(label(board(d))) ($(join(label.(judges(d)), ", ")))")
  println(io, "Outcome: $(label(outcome(d)))")
end
