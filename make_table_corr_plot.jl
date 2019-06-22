# use Julia1 for this
using PyPlot
#  using StatPlots
using CSV

type_list = [Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64]
#  table = CSV.read("logs/test_gconvert.csv")
#  table = CSV.read("logs/net_transition_discount_vary_reference_solver_training.csv",types=type_list,weakrefstrings=false,rows=10)
#  table = CSV.read("logs/n_vary_reference_solver_training.csv")
table = CSV.read("logs/mturk_trusted_condition_1.csv")
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
fig.set_size_inches(5,5)
fsize = 15

ax[1].scatter(tbl_ary[:,3],tbl_ary[:,21],c=tbl_ary[:,12])
ax[1].set_title("transition probability vs. reward",size=fsize)
ax[1].set_xlabel("transition probability",size=fsize)

ax[2].scatter(tbl_ary[:,12],tbl_ary[:,21],c=tbl_ary[:,3])
ax[2].set_title("N vs. reward",size=fsize)
ax[2].set_xlabel("N",size=fsize)
#  PyPlot.scatter(tbl_ary[12])
#  cornerplot(tbl_ary[:,col_list],label=names(table)[col_list])
