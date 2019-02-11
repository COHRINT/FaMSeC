using PyPlot
using LatinHypercubeSampling
using LinearAlgebra
using Random
using Base.Sort

function get_range(ary::Array{Float64,1})
    return minimum(ary), maximum(ary)
end

function get_range(ary::Array{Float64,2})
    ranges = Array{Tuple}(undef,size(ary,2))
    for i = 1:size(ary,2)
        ranges[i] = get_range(ary[:,i])
    end
    return ranges
end

function make_spatial_bins(min::Float64,max::Float64,bins::Int64)
    return collect(range(min,stop=max,length=bins))
end

function make_spatial_bins(ranges::Array{Tuple};bins::Int64=10)
    bin_ary = Array{Array{Float64}}(undef,length(ranges))
    for i = 1:length(bin_ary)
        bin_ary[i] = make_spatial_bins(ranges[i][1],ranges[i][2],bins+1)
    end
    return bin_ary
end

function return_bin_center(bins::Array{Array{Float64}})
    bin_c = Array{Float64}(undef,length(bins[1])-1,length(bins))
    for i = 1:length(bins)
        bin_c[:,i] = diff(bins[i])./2.0 .+ bins[i][1:end-1]
    end
    return bin_c
end

function vnormalize(X::Array;dims::Int64=1)
    minx = minimum(X,dims=dims)
    maxx = maximum(X,dims=dims)

    minx_mat = repeat(minx,size(X,1),size(X,2))
    maxx_mat = repeat(maxx,size(X,1),size(X,2))

    X_scaled = (X.-minx_mat)./(maxx_mat.-minx_mat)

    return X_scaled
end

function vnorm(A::Array;dims::Int64=1,normalize::Bool=false)
    if normalize
        A = vnormalize(A,dims=dims)
    end

    return sqrt.(sum(abs2,A,dims=dims))[:]
end

function set_distance(X::Array{Float64})
    sum_dists = Array{Float64}(undef,0)
    for i = 1:size(X,1)
        not_i = [x for x = 1:size(X,1) if x != i]
        dtr = distance_to_reference(X[i,:],X[not_i,:])
        push!(sum_dists,sum(dtr))
    end
    return sum_dists
end

function distance_to_reference(ref::Array{Float64},X::Array{Float64})
    X_scaled = ones(size(X))*Inf
    ref_scaled = ones(size(ref))*Inf
    for i = 1:size(X,2)
        xci = X[:,i]
        min_xci = minimum(xci)
        max_xci = maximum(xci)

        ref_scaled[i] = (ref[i].-min_xci)./(max_xci-min_xci)
        X_scaled[:,i] = (xci.-min_xci)./(max_xci-min_xci)
    end
    X_norms = vnorm(X_scaled,dims=2)
    return X_norms
end

function find_closest_neighbor(bin_center::Array{Float64},X::Array{Float64};exclude=Array{Float64}=[],deterministic::Bool=true)
    # scale so the two dimensions have equal weight
    X_norms = distance_to_reference(bin_center,X)
    ndist = abs.(X_norms .- vnorm(bin_center))

    if !isempty(exclude)
        idx = collect(1:length(ndist))
        idx_mask = [x for x in idx if x ∉ exclude]
        #  println("exclude: $exclude")
        #  println("idx: $idx")
        #  println("ndist: $ndist")
        #  println("idx_mask: $idx_mask")
        indexed_ndist = [ndist idx]
        sorted_ndist = sortslices(indexed_ndist[idx_mask,:],dims=1)
        if deterministic
            neighbor = sorted_ndist[1,2]
        else
            num_neighbors = Int(round(0.5 * size(sorted_ndist,1)))
            rand_neighbor = randperm(num_neighbors)[1]
            neighbor = sorted_ndist[rand_neighbor,2]
            #  @info num_neighbors rand_neighbor neighbor size(sorted_ndist,1)
            #  readline()
        end
        nn = Int(neighbor)
        #  neighbor = argmin(indexed_ndist[idx_mask,:])[1][1]
        #  nn = Int(indexed_ndist[idx_mask,:][neighbor,2])
        #  @info "closest neighbor info:" bin_center nn ndist[nn] ndist X[nn,:]
        #  readline()
    else
        nn = argmin(ndist)
        #  @info nn
        #  readline()
    end

    return nn
end

function nearest_neighbor_set(X::Array{Float64},lhc_centers::Array{Float64})
    sample_set = []
    for i = 1:size(lhc_centers,1)
        bin_center = lhc_centers[i,:]
        #  @info "lhc info" lhc_centers[i,:] bin_center
        # elements of each dimension in bins indicated by lhc_design
        # if a point doesn't exist there then find closest one
        closest_neighbor = find_closest_neighbor(bin_center,X,exclude=sample_set)
        push!(sample_set,closest_neighbor)
    end
    #  @info sample_set
    return sample_set
end

function random_neighbor_set(X::Array{Float64},lhc_centers::Array{Float64})
    sample_set = []
    for i = 1:size(lhc_centers,1)
        bin_center = lhc_centers[i,:]
        #  @info "lhc info" lhc_centers[i,:] bin_center
        # elements of each dimension in bins indicated by lhc_design
        # if a point doesn't exist there then find closest one
        closest_neighbor = find_closest_neighbor(bin_center,X,exclude=sample_set,deterministic=false)
        push!(sample_set,closest_neighbor)
    end
    #  @info sample_set
    return sample_set
end

function return_lhc_bin_centers(lhc::Array{Int64},bins::Array{Float64})
    lhc_centers = zeros(size(lhc))
    #  @info lhc bins
    for i = 1:size(lhc,1)
        for j = 1:size(lhc,2)
            lhc_bin = lhc[i,j]
            lhc_centers[i,j] = bins[lhc_bin,j]
        end
    end
    return lhc_centers
end

function max_rand_distance(X::Array,n::Int64)
    i = 0
    set_history = Array{Array{Int64}}(undef,0)
    dist_history = []
    dist = 0.0
    while i < 100000
        candidate_set = randperm(size(X,1))[1:n]

        if n == 2
            dists = vnorm(diff(X[candidate_set,:],dims=2),dims=1,normalize=true)
        else
            dists = set_distance(X[candidate_set,:])
            #  dists = distance_to_reference(X[candidate_set[1],:],X[candidate_set[2:end],:])
        end
        #  @info dists sum(dists) dist candidate_set
        #  readline()

        if sum(dists) > dist
            push!(dist_history,sum(dists))
            push!(set_history,candidate_set)
            dist = sum(dists)
        end

        i += 1
    end
    #  @info set_history[end] minimum(dist_history) dist_history[end]
    readline()
    return set_history[end]
end

function bin_sample(X::Array{Float64},n::Int64)
    # select n samples from X spread out 'spatially'
    @assert length(size(X)) == 2
    if size(X,1) <= n
        # need to return everything to have enough
        return X
    end

    # which bins do we want to take data from?
    if n == 1
        return rand(1:size(X,1),1)
    else
        lhc_design = randomLHC(n,size(X,2))
    end
    #  @info "LHC Size" size(lhc_design)

    r = get_range(X)
    b = make_spatial_bins(r,bins=n)
    bc = return_bin_center(b)
    lhc_centers = return_lhc_bin_centers(lhc_design,bc)

    #  sample_set = max_rand_distance(X,n)
    #  sample_set = nearest_neighbor_set(X,lhc_centers)
    sample_set = random_neighbor_set(X,lhc_centers)
    return sample_set
end
