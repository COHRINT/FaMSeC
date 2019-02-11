using JSON
using PyPlot
using StatsBase
using DataFrames, CSV
using Random
include("consistent_agent_utils.jl")
include("spread_sample.jl")

json_fldr = "test_data/"

# load the files that will be used, this will vary based on the experiment that you ran in `make_nets_and_data.jl`
data1 = JSON.parsefile("$(json_fldr)experiment_data_mturk_1_Ntprob_solver.json")
data2 = JSON.parsefile("$(json_fldr)experiment_data_mturk_2_Ntprob_solver.json")
data3 = JSON.parsefile("$(json_fldr)experiment_data_mturk_3_Ntprob_solver.json")
data4 = JSON.parsefile("$(json_fldr)experiment_data_mturk_4_Ntprob_solver.json")
data5 = JSON.parsefile("$(json_fldr)experiment_data_mturk_5_Ntprob_solver.json")

data = merge_dicts([data1,data2,data3,data4,data5]) # don't include data1 for training because it is 'trusted' sovler
exp_data = data4 # `candidate` data that will be used in the experiment

pygui(false)

xQ, xP, outcome, Xp, Xn, Xp_m, Xp_c, Xn_m, Xn_c, N_c, tp_c = get_data(data)

xQe, xPe, outcomee, Xpe, Xne, Xp_me, Xp_ce, Xn_me, Xn_ce, N_e, tp_e, tn_e = get_data(exp_data)

####################
### plot full data set
####################
fig_individual, ax_individual = PyPlot.subplots(1,1)
fig_individual[:set_size_inches](5,5)
ax_individual[:scatter](xQ[outcome],xP[outcome],label="success",alpha=0.5)
ax_individual[:scatter](xQ[.!outcome],xP[.!outcome],label="failure",alpha=0.5)
ax_individual[:legend]()
ax_individual[:set_title](L"$x_Q/x_O$ Plane---All Data",size=15)
ax_individual[:set_xlabel](L"x_Q",size=15)
ax_individual[:set_ylabel](L"x_O",size=15)
ax_individual[:set_xlim]((0.0,2.0))
ax_individual[:set_ylim]((-1.0,1.0))
ax_individual[:axvline](1.0,c=:gray)
ax_individual[:axhline](0.0,c=:gray)
fig_individual[:tight_layout]()
fig_individual[:savefig]("plots/xQxO_Plane.pdf",dpi=300,tranparent=true)
#####################

#####################
### Here is where the experiment task subset is selected, may need to change nubmers for other experiments
### this code depends on having `enough` data to be able to select successes and failures from each quadrant
### see the above plot `xQxO_Plane.pdf` to visualize your data before proceeding and expecting it to work
### there will be errors if there isn't enough data to do this. As set up now using the `experiment_data_mturk_fast_NN_Ntprob_solver.json` files there is not enough data
#####################
exp_trial_set = choose_equal_portion_set_lhc(xQe,xPe,outcomee,[12,8,15,8],max_num=16,min_num=8)

#  exp_trial_set = collect(1:length(xQe)) # use this for testing *all* of the examples
#####################
### end experiment task subset selection
#####################

####################
### plot experiment data set
####################
exp_success = sum(outcomee[exp_trial_set])
exp_failure = sum(.!outcomee[exp_trial_set])
fig_individual, ax_individual = PyPlot.subplots(1,1)
fig_individual[:set_size_inches](5,5)
ax_individual[:scatter](xQe[exp_trial_set][outcomee[exp_trial_set]],xPe[exp_trial_set][outcomee[exp_trial_set]],label="successes: $exp_success",alpha=0.5)
ax_individual[:scatter](xQe[exp_trial_set][.!outcomee[exp_trial_set]],xPe[exp_trial_set][.!outcomee[exp_trial_set]],label="failures: $exp_failure",alpha=0.5)
ax_individual[:set_title](L"$x_Q/x_O$ Plane---Experiment Task Set",size=15)
ax_individual[:set_xlabel](L"x_Q",size=15)
ax_individual[:set_ylabel](L"x_O",size=15)
ax_individual[:axvline](1.0,c=:gray)
ax_individual[:axhline](0.0,c=:gray)
ax_individual[:set_xlim]((0.0,2.0))
ax_individual[:set_ylim]((-1.0,1.0))
ax_individual[:legend]()
fig_individual[:tight_layout]()
fig_individual[:savefig]("plots/xQxO_plane_experiment_set.pdf")
#####################

# need to export file for the list of networks to be used in experiment, the indices
# are different because in this file we have only cared about the array, but we need
# to associate the array indices with the network numbers before exporting
psiturk_trial_set = tn_e[exp_trial_set]
open("experiment_trial_set.json","w") do f
    dat = JSON.json(psiturk_trial_set,4)
    write(f,dat)
end

copy_file_to_experiment = false
if copy_file_to_experiment
    # this is useful if you're updating the files, and don't want to forget to get the most updated version in the experiment folder
    expt_fldr = "../SC_experiment/"
    run(`cp experiment_trial_set.json $(expt_fldr)templates/json/`)
    run(`cp json/experiment_data_mturk_4_Ntprob_solver.json $(expt_fldr)templates/json/v2_support.json`)
end
