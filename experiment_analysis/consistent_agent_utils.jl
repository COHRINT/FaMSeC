using TexTables
function merge_dicts(ad::Array{Dict{String,Any},1})
    new_dict = Dict()
    for (i,d) in enumerate(ad)
        for (key,value) in d
            new_dict["$(i)_$key"] = value
        end
    end
    return new_dict
end

function expand_data(xQ::Array{Float64},xP::Array{Float64};order::Int64=2)
    for i = 2:order
        xQ = [xQ xQ.^i]
        xP = [xP xP.^i]
    end
    return [xQ xP]
end

function get_data(data::Dict;return_df::Bool=false,return_params::Bool=true)
    tasks = collect(keys(data))
    task_number = []
    task_order = []
    try
        task_number = parse.(Int64,collect(tasks))
    catch
        task_number = []
    end

    xQ = zeros(length(tasks))
    xP = zeros(length(tasks))
    N = zeros(length(tasks))
    tp = zeros(length(tasks))
    outcome = Array{Bool}(undef,length(tasks))
    for (i,t) in enumerate(tasks)
        xQ[i] = data[t]["xQ"]
        xP[i] = data[t]["xP"]
        #  println("task: $t, xQ: $(xQ[i]), xP: $(xP[i])")
        if return_params
            N[i] = data[t]["num_nodes"]
            tp[i] = data[t]["trans_prob"]
        end
        data[t]["outcome"] == "fail" ? outcome[i] = false : outcome[i] = true
    end

    Xp = [xQ[outcome] xP[outcome]]
    Xn = [xQ[.!outcome] xP[.!outcome]]

    (Xp_m,Xp_c) = mean_and_cov(Xp)
    (Xn_m,Xn_c) = mean_and_cov(Xn)

    if !return_df
        if return_params
            return xQ, xP, outcome, Xp, Xn, Xp_m, Xp_c, Xn_m, Xn_c, N, tp, task_number
        else
            return xQ, xP, outcome, Xp, Xn, Xp_m, Xp_c, Xn_m, Xn_c, task_number
        end
    else
        df = DataFrame(xQ=xQ,xP=xP,outcome=outcome,N=N,tp=tp,task_number=task_number)
        return xQ, xP, df
    end
end

function prop_in_quadrant(xQ,xP)
    num_in_q = Array{Int64,1}()
    for i = 1:4
        if i == 1
            n = sum([q>1.0 && p>0.0 for (q,p) in zip(xQ,xP)])
        elseif i == 2
            n = sum([q<1.0 && p>0.0 for (q,p) in zip(xQ,xP)])
        elseif i == 3
            n = sum([q<1.0 && p<0.0 for (q,p) in zip(xQ,xP)])
        elseif i == 4
            n = sum([q>1.0 && p<0.0 for (q,p) in zip(xQ,xP)])
        end
        push!(num_in_q,n)
    end
    return num_in_q./length(xQ)
end

function num_from_prop(props::Array{Float64},num::Int64;max_num::Int64=-1,min_num::Int64=-1)
    num_float = props.*num

    if max_num != -1
        num_float[num_float.>max_num] .= max_num
    end
    if min_num != -1
        num_float[num_float.<min_num] .= min_num
    end

    return Int.(ceil.(num_float))
end

function choose_equal_portion_set(xQ,xP,outcomes,num::Array{Int64}=[];max_num::Int64=16,min_num::Int64=8)
    if length(num) == 1
        #default to equal examples per quadrant
        props = prop_in_quadrant(xQ,xP)
        num_per_quadrant = num_from_prop(props,num[1],max_num=max_num,min_num=min_num)
        println("Experiment Trial Selection:")
        println("target N: $(sum(num_per_quadrant)), p_num: $num_per_quadrant, props: $props")
    elseif length(num) == 4
        num_per_quadrant = num
    else
        error("need 4 quadrants")
    end
    task_set = Array{Int64,1}()
    q_cnt = Array{Int64,1}()
    s_cnt = Array{Int64,1}()
    sf_ratio = Array{Float64,1}()
    for i = 1:4
        if i == 1
            quad_idx = [q>=1.0 && p>=0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 2
            quad_idx = [q<1.0 && p>=0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 3
            quad_idx = [q<1.0 && p<0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 4
            quad_idx = [q>=1.0 && p<0.0 for (q,p) in zip(xQ,xP)]
        end

        q_outcomes = outcomes[quad_idx]
        q_s_ratio = sum(q_outcomes)/length(q_outcomes)
        q_f_ratio = sum(.!q_outcomes)/length(q_outcomes)
        q_sf_ratio = q_s_ratio/q_f_ratio

        q_subset = collect(1:length(xQ))[quad_idx]

        num_pos = Int(round(num_per_quadrant[i]*q_s_ratio))
        num_neg = Int(round(num_per_quadrant[i]*q_f_ratio))

        println(length(q_outcomes))

        pos_subset = q_subset[q_outcomes][rand(1:sum(q_outcomes),num_pos)]
        neg_subset = q_subset[.!q_outcomes][rand(1:sum(.!q_outcomes),num_neg)]
        println("size pos: $(size(pos_subset)), neg: $(size(neg_subset))")

        subset = [pos_subset; neg_subset]

        println("Q1 subset: $(sort(subset))")

        if length(subset) < num_per_quadrant[i]
            subset = subset
        else
            subset = subset[1:num_per_quadrant[i]]
        end
        #  println("q$i size: $(sum(quad_idx))")
        push!(q_cnt,sum(quad_idx))
        push!(s_cnt,length(subset))
        push!(task_set,subset...)
        push!(sf_ratio,q_sf_ratio)
    end

    println("actual N: $(length(task_set)), p_num_actual: $s_cnt")
    println("sf ratios: $sf_ratio")
    println("total q: $q_cnt")
    println("total q ratio: $(q_cnt./sum(q_cnt))")
    println("total Q12: $(sum(s_cnt[1:2])), total Q14: $(sum(s_cnt[[1,4]]))")
    return task_set
end

function choose_equal_portion_set_lhc(xQ,xP,outcomes,num::Array{Int64}=[];max_num::Int64=16,min_num::Int64=8)
    if length(num) == 1
        #default to equal examples per quadrant
        props = prop_in_quadrant(xQ,xP)
        num_per_quadrant = num_from_prop(props,num[1],max_num=max_num,min_num=min_num)
        println("Experiment Trial Selection:")
        println("target N: $(sum(num_per_quadrant)), p_num: $num_per_quadrant, props: $props")
    elseif length(num) == 4
        num_per_quadrant = num
    else
        error("need 4 quadrants")
    end
    task_set = Array{Int64,1}()
    q_cnt = Array{Int64,1}()
    s_cnt = Array{Int64,1}()
    s_ratio = Array{Float64,1}()
    f_ratio = Array{Float64,1}()
    pos_subset_ary = Array{Any,1}()
    neg_subset_ary = Array{Any,1}()
    q_idx = Array{Any,1}()
    for i = 1:4
        if i == 1
            quad_idx = [q>=1.0 && p>=0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 2
            quad_idx = [q<1.0 && p>=0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 3
            quad_idx = [q<1.0 && p<0.0 for (q,p) in zip(xQ,xP)]
        elseif i == 4
            quad_idx = [q>=1.0 && p<0.0 for (q,p) in zip(xQ,xP)]
        end

        q_outcomes = outcomes[quad_idx]
        q_s_ratio = sum(q_outcomes)/length(q_outcomes)
        q_f_ratio = sum(.!q_outcomes)/length(q_outcomes)
        q_sf_ratio = q_s_ratio/q_f_ratio

        q_subset = collect(1:length(xQ))[quad_idx]

        num_pos = Int(round(num_per_quadrant[i]*q_s_ratio))
        num_neg = Int(round(num_per_quadrant[i]*q_f_ratio))

        #  @info "Q$i" num_pos num_neg
        pos_data = [xQ xP][q_subset[q_outcomes],:]
        neg_data = [xQ xP][q_subset[.!q_outcomes],:]
        pos_subset = q_subset[q_outcomes][bin_sample(pos_data,num_pos)]
        neg_subset = q_subset[.!q_outcomes][bin_sample(neg_data,num_neg)]

        #  @info "Actual Size" size(pos_subset) size(neg_subset)

        subset = [pos_subset; neg_subset]

        println("Q$i subset: $pos_subset, $neg_subset")

        #  println("q$i size: $(sum(quad_idx))")
        push!(q_cnt,sum(quad_idx))
        push!(s_cnt,length(subset))
        push!(task_set,subset...)
        push!(s_ratio,q_s_ratio)
        push!(f_ratio,q_f_ratio)
        push!(pos_subset_ary,pos_subset)
        push!(neg_subset_ary,neg_subset)
        push!(q_idx,quad_idx)
    end

    println("actual N: $(length(task_set)), p_num_actual: $s_cnt")
    println("total q: $q_cnt")
    println("total q: $(q_cnt./sum(q_cnt))")
    println("total Q12: $(sum(s_cnt[1:2])), total Q14: $(sum(s_cnt[[1,4]]))")

    function return_row(row_name,data_ary,first_val,col_prefix::String="Quad.")
        row = TableCol("Total",[row_name],[first_val])
        for i = length(data_ary):-1:1
            row = hcat(TableCol("$col_prefix $i",[row_name],[data_ary[i]]),row)
        end
        return row
    end
    #####
    # save table with the statistics of the data set
    rn_row = return_row("Original N",sum.(q_idx),length(outcomes))
    rn_prop = sum.(q_idx)./length.(q_idx)
    rn_prop_row = return_row("Original N Proportion",rn_prop,sum(rn_prop))

    sf = [sum(outcomes[q])/sum(.!outcomes[q]) for q in q_idx]
    r_sf_ratio = return_row("Original S/F Ratio",sf,sum(outcomes)/length(outcomes))

    n_row = return_row("N",s_cnt,sum(s_cnt))

    p_row = return_row("N Proportion",s_cnt./sum(s_cnt),sum(s_cnt./sum(s_cnt)))

    tot_s = sum(length.(pos_subset_ary))
    s_row = return_row("Successes",length.(pos_subset_ary),tot_s)

    tot_f = sum(length.(neg_subset_ary))
    f_row = return_row("Failures",length.(neg_subset_ary),tot_f)

    sf_ratio = return_row("S/F Ratio",length.(pos_subset_ary)./length.(neg_subset_ary),tot_s/tot_f)

    q_table = vcat(rn_row,rn_prop_row,r_sf_ratio,n_row,p_row,s_row,f_row,sf_ratio)
    display(q_table)
    write_tex("q_table.tex",q_table)
    #####

    return task_set
end
