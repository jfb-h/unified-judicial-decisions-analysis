using Model
using DataFramesMeta
using SplitApplyCombine
using Dates
using LinearAlgebra
using StatsBase

function incidence_matrix(decisions)
    adj = map(decisions) do d
        map(id, judges(d))        
    end
    n, m = length(adj), maximum(map(maximum, adj))
    inc = zeros(Int, n, m)
    for (i, d) in enumerate(adj)
        for j in d
            inc[i, j] += 1
        end
    end
    inc
end

adjacency_matrix(decisions) = (inc = incidence_matrix(decisions); inc' * inc)

function judge_senate_affil(decisions)
    res = [Int[] for _ in 1:200]
    for d in decisions
        js = id.(judges(d))
        for j in js
            push!(res[j], id(senate(d)))
        end
    end
    unique!.(res)
end

function mode(x)
    c = StatsBase.countmap(x)
    k = collect(keys(c))
    v = collect(values(c))
    k[first(findmax(v))]    
end

function adjacency_matrix_permuted(decisions)
    adj = adjacency_matrix(decisions)
    sen = mode.(judge_senate_affil(decisions))
    idx = sort(1:200; by=x->sen[x])
    per = float.(adj[idx, idx])
    per[diagind(per)] .= NaN
    per
end

function plotdata(decisions)
    adj = adjacency_matrix_permuted(decisions)
    fap = heatmap(adj; axis=(;aspect=1))
    save("visuals/codecisions.png", fap)
end