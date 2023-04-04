using Model
using DataFramesMeta
using Dates

function prepdata(decisions)
    df = DataFrame(
        board=board.(decisions),
        judge=judges.(decisions),
        technology=section.(patent.(decisions))
    )
        
    @chain df begin
        flatten(:judge)
        flatten(:technology)
        sort(:technology)
        groupby([:judge, :technology, :board])
        combine(nrow => :count)
        unstack(:technology, :count; fill=0)
    end
end 

function df2matrix(df; k=10)
    d = Matrix(df[:,3:end])
    s = sum(d; dims=2)
    i = findall(>=(k), vec(s))
    d = d ./ s
    d[i,:]    
end

function plotdata2(decisions)
    sen = sort!(unique(map(board, decisions)); by=id)
    ind = CartesianIndices((4,2))
    
    df = prepdata(decisions)
    
    fig = Figure(resolution=(800, 1000))
    for (i, s) in enumerate(sen)
        d = @rsubset df :board == s
        tec = names(d)[3:end]
        mat = df2matrix(d; k=3)
        
        ax = Axis(fig[Tuple(ind[i])...]; xticks=(1:length(tec), tec), title=label(s))
        heatmap!(ax, permutedims(mat); colormap=:viridis)
        hideydecorations!(ax)
    end
    fig
    save("visuals/judge_technology_specialization.png", fig)
end
        
       
     
