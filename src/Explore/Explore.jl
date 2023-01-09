module Explore

using JSON3
using StructTypes
using Dates
using DataFrames
using DataFramesMeta
using CairoMakie
using Graphs
using GraphMakie
using LinearAlgebra
using RCall

include("exploration_helpers.jl")

const PAL = CairoMakie.Makie.ColorSchemes.colorschemes[:tableau_10]

const THEME = Theme(
    Axis = (
        backgroundcolor = :gray97,
        leftspinevisible = false,
        rightspinevisible = false,
        bottomspinevisible = false,
        topspinevisible = false,
        #xgridvisible = false,
        xgridcolor = :white,
        ygridcolor = :white,
		cycle = [:color, :marker],
        palette = (color=PAL, )
    )
)

set_theme!(THEME)


function plot_judge_activity(fig = Figure())
	d = @chain df begin
		select([:judges, :date])
		flatten(:judges)
		groupby(:judges)
		@transform :count = length(:judges)
		@rsubset :count >= 30
	end
	
	u = unique(d.judges)
	
	ax = Axis(fig[1,1], yticks=(1:length(u), u), yticklabelsize=9, 
		title="Activity by judge", titlesize=20, titlefont="Arial bold",
		titlecolor="grey40")

	for (i, j) in enumerate(u)
		vs = Dates.datetime2rata.(d.date[d.date .> Date(1990) .&& d.judges .== j])
		xs = repeat(vs, inner=2)
		ys = i .+ repeat([-.3, .3], outer=length(vs))
		linesegments!(ax, xs, ys)
	end

	ax.xticks = Dates.datetime2rata.(Date.(2000:5:2020))
	ax.xtickformat = xs -> [Dates.format(Dates.rata2datetime(x), "yyyy") for x in xs]
	
	xlims!(Dates.datetime2rata.(Date.([1999, 2022]))...)
	ylims!(0, length(u) + 1)
	
	fig
end

function plot_senate_time(fig = Figure())
	u = sort(unique(df.senate))
	l = [i == 0 ? "missing" : string(i) * ". Senate" for i in u]
	
	ax = Axis(fig[1,1], yticks=(1:length(u), l), title="Decisions by senate", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")

	for (i, s) in enumerate(u)
		vs = Dates.datetime2rata.(df.date[df.date .> Date(1990) .&& df.senate .== s])
		xs = repeat(vs, inner=2)
		ys = i .+ repeat([-.3, .3], outer=length(vs))
		linesegments!(ax, xs, ys)
	end

	ax.xticks = Dates.datetime2rata.(Date.(2000:5:2020))
	ax.xtickformat = xs -> [Dates.format(Dates.rata2datetime(x), "yyyy") for x in xs]
	xlims!(Dates.datetime2rata.(Date.([1999, 2022]))...)
	fig
end

function plot_timeseries(fig=Figure())
	d = @chain df begin
		@rtransform :year = year(:date)
		groupby(:year)
		@combine :count = length(:year)
		@rsubset :year <= 2021 && :year >= 2000
		sort(:year)
	end
	
	ax = Axis(fig[1,1], title= "Decision count over time", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")
	lines!(ax, d.year, d.count)
	scatter!(ax, d.year, d.count)
	ylims!(ax, 0, 150)
	xlims!(1999, 2022)
	
	fig
end

function plot_judge_outcomes(fig=Figure())
	options = [
		"annulled",
		"partially annulled",
		"claim dismissed",
		#"other",
	]

	thresh = 10
	k = length(options)
	optsdict = Dict(options .=> 1:k)
	
	d = @chain df begin
		select([:outcome, :judges])
		@rsubset :outcome in options
		flatten(:judges)
		groupby([:judges, :outcome])
		@combine :count = length(:judges)
		groupby(:judges)
		@transform :total = sum(:count)
		@rtransform :share = :count / :total
		@transform :outcome_int = [optsdict[o] for o in :outcome]
		@rsubset :total > thresh
		sort(:judges)
	end

	u = unique(d.judges)
	judgedict = Dict(u .=> 1:length(u))
	@transform! d :judge_int = [judgedict[j] for j in :judges]

	ax = Axis(fig[1,1], title="Share of outcomes by judge (with ≥ $thresh cases)", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40",
		xticks=(1:length(u), u), xticklabelrotation=π/2, xticklabelsize=8)
	
	barplot!(ax, d.judge_int, d.share, stack=d.outcome_int, color=PAL[d.outcome_int])

	xlims!(-4, length(u) + 4)
	
	# m = [MarkerElement(color=PAL[i], marker=:rect, strokecolor=:black) for i in 1:k]
	# Legend(fig[2,1], m, options, orientation=:horizontal)
	
	fig
end

function plot_senate_outcomes(fig=Figure())
	options = [
		"annulled",
		"partially annulled",
		"claim dismissed",
		#"other",
	]

	k = length(options)

	optsdict = Dict(options .=> 1:k)
	
	d = @chain df begin
		@rsubset :outcome in options
		groupby([:senate, :outcome])
		@combine :count = length(:senate)
		groupby(:senate)
		@transform :total = sum(:count)
		@rtransform :share = :count / :total
		@transform :outcome_int = [optsdict[o] for o in :outcome]
		sort(:senate)
	end

	n = unique(select(d, [:total, :senate])).total
	u = sort(unique(df.senate))
	l = [i == 0 ? "missing" : string(i) * ". Sen." for i in u]

	ax = Axis(fig[1,1], title="Share of outcomes by senate", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40",
		xticks=(u .+ 1, l))
	
	barplot!(ax, d.senate .+1, d.share, stack=d.outcome_int, color=PAL[d.outcome_int])
	
	text!(string.(n), position= Point.(1:length(n), 1.04), 
		align=(:center, :center), color=:black, fontsize=16, font="Arial bold")
	
	# m = [MarkerElement(color=PAL[i], marker=:rect, strokecolor=:black) for i in 1:k]
	# Legend(fig[2,1], m, options, orientation=:horizontal)
	
	fig
end

function plot_outcomeshare(fig=Figure())
	options = [
		"annulled",
		"partially annulled",
		"claim dismissed",
		#"other",
	]

	k = length(options)

	optsdict = Dict(options .=> 1:k)
	
	d = @chain df begin
		@rtransform :year = year(:date)
		@rsubset :outcome in options
		groupby([:year, :outcome])
		@combine :count = length(:year)
		groupby(:year)
		@transform :total = sum(:count)
		@rtransform :share = :count / :total
		@transform :outcome_int = [optsdict[o] for o in :outcome]
		@rsubset :year <= 2021 && :year >= 2000
		sort(:year)
	end

	ax = Axis(fig[1,1], title="Share of outcomes by year", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")
	barplot!(ax, d.year, d.share, stack=d.outcome_int, color=PAL[d.outcome_int])

	xlims!(1999, 2022)
	
	m = [MarkerElement(color=PAL[i], marker=:rect, strokecolor=:black) for i in 1:k]
	Legend(fig[2,1], m, options, orientation=:horizontal)
	
	fig
end

function plot_network_senate(fig=Figure())
	g = graph_senate_judge(df)
	u = sort(unique(df.senate))
	l = [i == 0 ? "missing" : string(i) * ". Senate" for i in u]
	c = vcat(repeat([:grey20], nv(g)-length(u)), PAL[u .+ 1])
	s = vcat(repeat([5], nv(g)-length(u)), repeat([25], length(u)))
	m = vcat(repeat([:circle], nv(g)-length(u)), repeat([:rect], length(u)))
	
	ax = Axis(fig[1,1], title="Judge-senate affiliation network", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")
	graphplot!(ax, g, node_color=c, node_size=s, node_marker=m, edge_color=:grey70)
	hidedecorations!(ax)
	fig
end

function plot_network_judge(fig=Figure())
	m = project(graph_case_judge(docs), length(docs))
	m[diagind(m)] .= 0
	c = igraph_louvain(m)
	m = m .>= 10
	g = SimpleGraph(m)
	g, i = main_component(g)

	ax = Axis(fig[1,1], 
		title="Judge-judge co-decisions (thresh ≥ 10)", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")
	
	graphplot!(ax, g, layout=igraph_layout_fruchtermanreingold,
		node_color=PAL[c[i]], edge_color=:grey70)
	
	hidedecorations!(ax)

	text!("Colors represent communities\nobtained by the Louvain method",
		position=(-11, -9), fontsize=12, color=:grey20)
	fig
end

function plot_matrix(fig=Figure())
	m = project(graph_case_judge(docs), length(docs))
	m[diagind(m)] .= 0
	c = igraph_louvain(m)
	i = sortperm(c)
	l = cumsum([sum(c .== u) for u in unique(c[i])])
	m = m[i,i]
	#m = m .> 0
	
	ax = Axis(fig[1,1], aspect=1, 
		title="Judge-judge co-decisions (Louvain clusters)", 
		titlesize=20, titlefont="Arial bold", titlecolor="grey40")
	
	heatmap!(ax, m, colormap=Reverse(:grays))
	vlines!(ax, l, color=(:black, .5))
	hlines!(ax, l, color=(:black, .5))

	hidedecorations!(ax)
	
	fig
end

function plot_composite()
	fig = Figure(resolution=(3000, 1900))

	plot_timeseries(fig[1,1])
	plot_outcomeshare(fig[2,1])
	plot_judge_outcomes(fig[3,1])
	plot_senate_time(fig[4,1])

	for (p,t) in zip(1:4, 'A':'D') label(fig, (p,1), string(t)) end

	rightcol = fig[:,2]
	
	plot_network_judge(rightcol[1,1])
	plot_matrix(rightcol[2,1])
	plot_senate_outcomes(rightcol[3,1])
	
	for (p,t) in zip(1:3, 'E':'G') label(rightcol, (p,1), string(t)) end

	plot_judge_activity(fig[:,3])

	label(fig, (1,3), "H")

	colsize!(fig.layout, 1, Relative(.45))
	colgap!(fig.layout, 1, 70)
	
	rowsize!(fig.layout, 1, Relative(.15))
	
	Label(fig[0,:], "Nullity Decisions by the German Federal Patent Court (BPatG)", 
		fontsize=40, color=:grey40, font="Arial bold")
	
	fig
end

function explore()
    docs = Model.readfiles("data/json")
    df = DataFrame(
        id=casenumber.(docs),
        date=date.(docs),
        patent=patent.(docs),
        outcome=outcome.(docs),
        senate=senate.(docs),
        judges=judges.(docs),
    );

    plot_composite()
end

end # module