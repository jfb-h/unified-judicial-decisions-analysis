using Model
using DataFramesMeta
using Dates

function prepdata(decisions)
    df = @chain decisions begin
        DataFrame(technology=subclass.(patent.(_)), date=date.(_))
        flatten(:technology)
        sort(:date)
        groupby(:technology)
        DataFrames.transform(
            :date => minimum => :first,
            :date => maximum => :last,
            groupindices => :gid,
        )
    end
end

function plotdata(df)
    segments = unique(df, [:technology, :first, :last])

    from = [Point(x, y) for (x, y) in zip(datetime2rata.(segments.first), 1:nrow(segments))]
    to   = [Point(x, y) for (x, y) in zip(datetime2rata.(segments.last), 1:nrow(segments))]
    
    xticks = let y = 2000:5:2020
        (datetime2rata.(Date.(y)), string.(y))
    end

    fig = Figure(resolution=(700, 1300))
    ax = Axis(fig[1,1]; xticks, yticksvisible=false, yticklabelsvisible=false)
    linesegments!(ax, [(x, y) for (x, y) in zip(from, to)]; color=:black)
    scatter!(datetime2rata.(df.date), df.gid; marker=:vline, color=:black, markersize=10)
    hideydecorations!(ax)
    
    save("visuals/technology_activity.png", fig)
    fig
end

function main()
    decisions = loaddata("data/processed/json_augmented")
    df = prepdata(decisions)
    plotdata(df)
end

main()