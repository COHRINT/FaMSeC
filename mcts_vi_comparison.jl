@everywhere using Roadnet_MDP
@everywhere importall POMDPs, POMDPToolbox
@everywhere using MCTS
@everywhere using DiscreteValueIteration
@everywhere include("roadnet_pursuer_MDP.jl")
# for parallel policy search, use julia -p 2 (for two threads)
using JLD
using PyPlot

include("network_library.jl")

ext_rwd = 2000.
cgt_rwd = -2000.
sen_rwd = -100.
go = original_roadnet(exit_rwd=ext_rwd,caught_rwd=cgt_rwd,sensor_rwd=sen_rwd)
gm = medium_roadnet(exit_rwd=ext_rwd,caught_rwd=cgt_rwd,sensor_rwd=sen_rwd)

fold = "mcts_vi_comparison_data/" #folder for data/images to go

display_network(go,evader_locs=[1],pursuer_locs=[4],scale=1.0,fname="$(fold)go_net",ftype=:svg)
display_network(gm,evader_locs=[1],pursuer_locs=[4],scale=1.0,fname="$(fold)gm_net",ftype=:svg)

t = 0.80
d = 0.95

mdp_go = roadnet_with_pursuer(go,tp=t,d=d)
mdp_gm = roadnet_with_pursuer(gm,tp=t,d=d)

pygui(false)

function plot_results()
    results_set = jldopen("$(fold)mcts_vi_comparison_results_set.jld","r") do file
	read(file,"results_set")
	end

    fig, ax = PyPlot.subplots(2,1)
    i = 1
    for (net,res) in results_set
        #  display(res)
        ax[i][:violinplot](res,widths=0.5,points=500,showmedians=true)
        i+=1
    end
    PyPlot.savefig("$(fold)mcts_vi_comparison_plot.pdf",transparent=true)
     # the :gm plot isn't working very well, and I don't think I need it, I can just use the :go graph as an example

    figgo,axgo = PyPlot.subplots(1,1)
    figgo[:set_size_inches](10,6)
    fsize = 15

    solve_set = [1,2,3,4,7]
    solve_labels = ["MCTS\nd=1","MCTS\nd=3","MCTS\nd=6","MCTS\nd=10","MCTS\nd=15","MCTS\nd=30","Value\nIteration"]
    s_ticks = collect(1:length(solve_set))
    axgo[:violinplot](results_set[:go][:,solve_set],widths=0.5,points=500,showmedians=true)
    axgo[:set_xlabel]("Solver",fontsize=fsize)
    axgo[:set_ylabel]("Expected Rewards",fontsize=fsize)
    axgo[:set_title]("Comparison of MCTS policies to Value Iteration policy",fontsize=fsize)
    axgo[:set_xticks](s_ticks)
    axgo[:xaxis][:set_ticklabels](solve_labels[solve_set])
    fig[:tight_layout]()
    PyPlot.savefig("$(fold)mcts_vi_comparison_plot_orig_net.pdf",transparent=true)
end

function get_results(mdp_go,mdp_gm;num_repeats=5,display_matrix=false)
    vi_policies = jldopen("$(fold)mcts_vi_comparison_valueiteration.jld","r") do file
	read(file,"solns")
	end
    vi_solvers = jldopen("$(fold)mcts_vi_comparison_valueiteration.jld","r") do file
	read(file,"solvers")
	end

    mcts_policies = jldopen("$(fold)mcts_vi_comparison_mcts.jld","r") do file
	read(file,"solns")
	end
    mcts_solvers = jldopen("$(fold)mcts_vi_comparison_mcts.jld","r") do file
	read(file,"solvers")
	end

    policy_set = Dict(:vi=>vi_policies,:mcts=>mcts_policies)
    sovler_set = Dict(:vi=>vi_solvers,:mcts=>mcts_solvers)
    mdp_set = Dict(:go=>mdp_go,:gm=>mdp_gm)

    num_vi_policies = length(vi_policies[:go])
    num_mcts_policies = length(mcts_policies[:go])
    num_po = num_vi_policies+num_mcts_policies
    results_set = Dict(:go=>zeros(num_repeats,num_po),:gm=>zeros(num_repeats,num_po))

    for (solver_type,mdp_policies) in policy_set
        println(solver_type)
        for (mdp_type,policies) in mdp_policies
            println(mdp_type)
            for (pnum,p) in enumerate(policies)
                println("Running policy $pnum of $solver_type/$mdp_type")
                # simulate performance of policies on the appropraite mdp
                max_steps = 100

                PT = repmat([p],1,num_repeats)
                initial_state = roadnet_pursuer_state(1,4)

                q = []
                for pol in PT
                    value = Sim(mdp_go,pol,initial_state,max_steps=max_steps)
                    push!(q,value)
                end
                sim_results = run_parallel(q) do sim,hist
                    #  display(discounted_reward(hist))
                    return [:steps=>n_steps(hist), :reward=>undiscounted_reward(hist)]
                end

                rewards = [float(x) for x in sim_results[:reward]] #need to convert to float, because sim_results[:reward] is a union of floats and missing values, even though there aren't any missing values...
                if solver_type == :mcts
                    results_set[mdp_type][:,pnum] = rewards
                else
                    results_set[mdp_type][:,end] = rewards
                end

                if display_matrix
                    println(size(results_set[mdp_type]))
                    display(results_set[mdp_type])
                end
            end
        end
    end

    jldopen("$(fold)mcts_vi_comparison_results_set.jld","w") do file
        write(file,"results_set",results_set)
    end

    return results_set
end

function get_policies(mdp_go,mdp_gm;solve_vi=false)
	its = 2000
	exp_const = 2000.0

	println("Initializing Sovlers")

	# mcts
	s_mcts_30 = MCTSSolver(n_iterations=its,depth=30,exploration_constant=exp_const,enable_tree_vis=true)
	s_mcts_15 = MCTSSolver(n_iterations=its,depth=15,exploration_constant=exp_const,enable_tree_vis=true)
	s_mcts_10 = MCTSSolver(n_iterations=its,depth=10,exploration_constant=exp_const,enable_tree_vis=true)
	s_mcts_6 = MCTSSolver(n_iterations=its,depth=6,exploration_constant=exp_const,enable_tree_vis=true)
	s_mcts_3 = MCTSSolver(n_iterations=its,depth=3,exploration_constant=exp_const,enable_tree_vis=true)
	s_mcts_1 = MCTSSolver(n_iterations=its,depth=1,exploration_constant=exp_const,enable_tree_vis=true)
    mcts_solvers = Dict(:mcts=>[s_mcts_10,s_mcts_6,s_mcts_3,s_mcts_1])

	# value iteration
	s_vi = ValueIterationSolver(max_iterations=150,belres=1e-6)
    vi_solvers = Dict(:vi=>[s_vi])

	if solve_vi
		# Value iteration takes FOREVER. Don't do this everytime
		println("Running ValueIterationSolver on original roadnet")
		vi_orig_soln = solve(s_vi,mdp_go)
		println("Running ValueIterationSolver on medium roadnet")
		vi_med_soln = solve(s_vi,mdp_gm)

        solns = Dict(:gm=>[vi_med_soln],:go=>[vi_orig_soln])

        jldopen("$(fold)mcts_vi_comparison_valueiteration.jld","w") do file
			addrequire(file,DiscreteValueIteration)
			write(file,"solns",solns)
            write(file,"solvers",vi_solvers)
		end
	end

	println("Running MCTS")
	mcts_orig_30_soln = solve(s_mcts_30,mdp_go)
	mcts_med_30_soln = solve(s_mcts_30,mdp_gm)

	mcts_orig_15_soln = solve(s_mcts_15,mdp_go)
	mcts_med_15_soln = solve(s_mcts_15,mdp_gm)

	mcts_orig_10_soln = solve(s_mcts_10,mdp_go)
	mcts_med_10_soln = solve(s_mcts_10,mdp_gm)

	mcts_orig_6_soln = solve(s_mcts_6,mdp_go)
	mcts_med_6_soln = solve(s_mcts_6,mdp_gm)

	mcts_orig_3_soln = solve(s_mcts_3,mdp_go)
	mcts_med_3_soln = solve(s_mcts_3,mdp_gm)

	mcts_orig_1_soln = solve(s_mcts_1,mdp_go)
	mcts_med_1_soln = solve(s_mcts_1,mdp_gm)

    mcts_solns = Dict(:gm=>[mcts_med_1_soln,mcts_med_3_soln,mcts_med_6_soln,mcts_med_10_soln,mcts_med_15_soln,mcts_med_30_soln],:go=>[mcts_orig_1_soln,mcts_orig_3_soln,mcts_orig_6_soln,mcts_orig_10_soln,mcts_orig_15_soln,mcts_orig_30_soln])

	# write the policies to a file
    jldopen("$(fold)mcts_vi_comparison_mcts.jld","w") do file
		addrequire(file,DiscreteValueIteration)
		write(file,"solns",mcts_solns)
        write(file,"solvers",mcts_solvers)
	end
end
