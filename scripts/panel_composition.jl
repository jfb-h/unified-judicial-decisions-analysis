using Model
using Dictionaries, SplitApplyCombine
using Dates

decisions = loaddata("data/processed/json_augmented")

js = Set.(judges.(decisions))

comps = unique(js)

filter(>=(5), map(length, group(js)))

overlaps = [intersect(c1, c2) |> length  for c1 in comps, c2 in comps]

using Clustering