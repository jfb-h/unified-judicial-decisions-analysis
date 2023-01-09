
onehot(x) = (sort(unique(x)) .== permutedims(x)) |> permutedims

function graph_case_judge(docs)
	j = unique(vcat(judges.(docs)...))
	nd = length(docs)
	nj = length(j)
	m = Dict(j .=> nd+1:nd+nj)
	g = SimpleGraph(nd + nj)
	for (i, d) in enumerate(docs)
		for j in judges(d)
			add_edge!(g, i, m[j])
		end
	end
	g
end	

function graph_senate_judge(df)
	d = flatten(select(df, :judges, :senate), :judges) |> unique
	nj = length(unique(d.judges))
	ns = length(unique(d.senate))
	m = Dict(vcat(unique(d.judges), sort(unique(d.senate))) .=> 1:nj+ns)
	g = SimpleGraph(nj + ns)
	for r in eachrow(d)
		add_edge!(g, m[r.judges], m[r.senate])
	end
	g
end	

function incmat(bipartite, n) 
	A = adjacency_matrix(bipartite)
	A[1:n, n+1:size(A,1)]
end

function project(bipartite, n)
	I = incmat(bipartite, n)
	I' * I |> Matrix
end

function main_component(g)
    c = connected_components(g)
    _, i = findmax(length.(c))
    induced_subgraph(g, c[i])
end

function igraph_louvain(m)
	R"""
	g = igraph::graph_from_adjacency_matrix($m, mode="undirected", weighted=TRUE)
	c = igraph::cluster_louvain(g)
	g = igraph::membership(c)
	"""
	convert.(Int, @rget g)
end

function igraph_layout_kamadakawai(g::AbstractGraph; seed=1234)
    adjmat = adjacency_matrix(g)
    mode = is_directed(g) ? "directed" : "undirected"

    R"""
    set.seed($seed)
    g = igraph::graph_from_adjacency_matrix($adjmat, mode=$mode)
    l = igraph::layout_with_kk(g)
    """
    l = @rget l
    return [Point(y, x) for (x, y) in eachrow(l)]
end

function igraph_layout_fruchtermanreingold(g::AbstractGraph; seed=1234)
    adjmat = adjacency_matrix(g)
    mode = is_directed(g) ? "directed" : "undirected"

    R"""
    set.seed($seed)
    g = igraph::graph_from_adjacency_matrix($adjmat, mode=$mode)
    l = igraph::layout_with_fr(g)
    """
    l = @rget l
    return [Point(y, x) for (x, y) in eachrow(l)]
end

label(fig, pos, text) = Label(fig[pos..., TopLeft()], text, font="Arial bold", fontsize=24, color=:grey30, padding=[0, 0, 20, 0])