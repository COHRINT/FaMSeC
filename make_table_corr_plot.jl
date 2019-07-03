# use Julia1 for this
using PyPlot
#  using StatPlots
using Statistics
using CSV

type_list = [Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64]
#  table = CSV.read("logs/test_gconvert.csv")
#  table = CSV.read("logs/net_transition_discount_vary_reference_solver_training.csv",types=type_list,weakrefstrings=false,rows=10)
#  table = CSV.read("logs/n_vary_reference_solver_training.csv")
table = CSV.read("logs/mturk_trusted_condition_1.csv")
#  table = CSV.read("logs/mturk_candidate_condition_4.csv")
#  for c in names(table)
    #  println(typeof(table[c]))
#  end
tbl_ary = convert(Array{Float64},table[:,1:22])
println(typeof(tbl_ary))

# normalize all data
#  for i = 1:size(tbl_ary,2)
    #  tbl_ary[:,i] = tbl_ary[:,i]./maximum(tbl_ary[:,i])
#  end

col_list = []

# detect nearly identical columns and leave them out
#  for i = 1:size(tbl_ary,2)
    #  if sum(isequal.(diff(tbl_ary[:,i]),0.0))/length(tbl_ary[:,i]) > 0.40
        #  # this is an (nearly) identical column
        #  continue
    #  else
        #  push!(col_list,i)
    #  end
#  end

println(col_list)
println(size(tbl_ary))

fig,ax = PyPlot.subplots(2,1)
fig.set_size_inches(8,8)
fsize = 15
#
ax[1].scatter(tbl_ary[:,3],tbl_ary[:,21],marker=".",c=:black,label="Monte-Carlo Results")
#  ax[1].scatter(tbl_ary[:,3],tbl_ary[:,21],c=tbl_ary[:,12])
ax[1].hlines(y=0,xmin=0,xmax=1,colors=:gray,label="rwd=0.0")
ax[1].set_title("transition probability vs. reward",size=fsize)
ax[1].set_xlabel("transition probability",size=fsize)
ax[1].set_ylabel("Reward",size=fsize)
ax[1].legend()

mean_rwd = []
for u in unique(tbl_ary[:,12])
    uniqueN = tbl_ary[:,12].==u

    append!(mean_rwd,mean(tbl_ary[:,21][uniqueN]))
end

mean_sort = sortperm(unique(tbl_ary[:,12]))

ax[2].scatter(tbl_ary[:,12],tbl_ary[:,21],marker=".",c=:black,label="Monte-Carlo Results")
ax[2].plot(unique(tbl_ary[:,12])[mean_sort],mean_rwd[mean_sort],c=:blue,label="Mean Reward")
ax[2].hlines(y=0,xmin=16,xmax=43,colors=:gray,label="rwd=0.0")
ax[2].set_title("N vs. mean reward",size=fsize)
ax[2].set_xlabel("N",size=fsize)
ax[2].set_ylabel("Reward",size=fsize)
ax[2].legend()

fig.tight_layout()

savefig("raw_data.pdf",transparent=true,dpi=300)

#  fig2,ax2 = PyPlot.subplots(1,1)
#  fig.set_size_inches(5,5)
#  fsize = 15
#
#  ax2.scatter(tbl_ary[:,3],tbl_ary[:,12],c=tbl_ary[:,21])
#  ax2.set_title("ptrans vs N",size=fsize)
#  ax2.set_xlabel("ptrans",size=fsize)
#  ax2.set_ylabel("N",size=fsize)
#
#  fig3,ax3 = PyPlot.subplots(1,1)
#  fig3.set_size_inches(5,5)
#  fsize = 15
#
#  mean_rwd = []
#  for u in unique(tbl_ary[:,12])
    #  uniqueN = tbl_ary[:,12].==u
#
    #  append!(mean_rwd,mean(tbl_ary[:,21][uniqueN]))
#  end
#
#  ax3.scatter(mean_rwd,unique(tbl_ary[:,12]))
#  ax3.set_title("mean reward vs N",size=fsize)
#  ax3.set_xlabel("mean reward",size=fsize)
#  ax3.set_ylabel("N",size=fsize)
#
#  fig4,ax4 = PyPlot.subplots(1,1)
#  fig4.set_size_inches(5,5)
#  fsize = 15
