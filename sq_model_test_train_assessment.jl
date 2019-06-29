using Flux, Flux.Tracker
using Flux.@epochs
using PyPlot
using CSV

pygui(false)

debugging = false
raw_data = CSV.read("logs/mturk_trusted_condition_1_mod.csv")

# set random seed for repeatability
#  srand(12345)
# 4 is good
# 21 is good
# 39 is beter, with 0.3 dropout and 10 hidden nodes
srand_num = 39
srand(srand_num)

rand_order = randperm(size(raw_data,1))
x1 = [float(q) for q in raw_data[:tprob][rand_order]]
x2 = [float(q) for q in raw_data[:N][rand_order]]
y = [float(q) for q in raw_data[:X3_1][rand_order]]

nx = length(x1)
train_pct = 0.90
train_limit = convert(Int,round(nx*train_pct))
train_set = 1:train_limit

valid_pct = 1.00
valid_limit = convert(Int,round(nx*valid_pct))
valid_set = train_limit+1:valid_limit

#  test_set = valid_limit+1:length(x1)

x1_train = x1[train_set]
x2_train = x2[train_set]
y_train = y[train_set]'

x_train = [x1_train x2_train]'
#  x_train = x1_train'

data = zip(x_train,y_train)

x1_valid = x1[valid_set]
x2_valid = x2[valid_set]
y_valid = y[valid_set]'

x_valid = [x1_valid x2_valid]'
#  x_valid = x1_valid'

#  x1_test = x1[test_set]
#  x2_test = x2[test_set]
#  y_test = y[test_set]'
#
#  x_test = [x1_test x2_test]'

num_hidden = 10
dropout_rate = 0.30

net = Chain(
            Dense(size(x_train,1),num_hidden,relu),
            Dropout(dropout_rate),
            Dense(num_hidden,num_hidden,relu),
            Dropout(dropout_rate),
            Dense(num_hidden,1)
           )

display(params(net))

loss(x,y) = Flux.mse(net(x),y)

opt = ADAM(params(net) , 0.001; β1 = 0.9, β2 = 0.999, ϵ = 1e-08, decay = 0)

evalcb() = @show(loss(tx,ty))

# array to store the validation error per batch
res = []
tr = []
tst = []

function check_err(x,y,ary)
    Flux.testmode!(net)
    append!(ary,loss(x,y).data)
    Flux.testmode!(net,false)
end

function valid_cb()
    # validate data
    check_err(x_valid,y_valid,res)
end
function train_cb()
    # validate data
    check_err(x_train,y_train,tr)
end
function test_cb()
    # validate data
    check_err(x_test,y_test,tst)
end

function cb_fun()
    valid_cb()
    train_cb()
    #  test_cb()
end

num_epocs = 50

@epochs num_epocs Flux.train!(loss,data,opt,cb = cb_fun)
#  Flux.train!(loss,data,opt,cb = Flux.throttle(evalcb(),3))
#  Flux.train!(loss,data,opt,cb = ()=>println("test"))

fig,ax = PyPlot.subplots(1,1)
fig[:set_size_inches](6,4)

epoc_mark = collect(0+1/length(y_train):1/length(y_train):num_epocs)
#  println(length(res))
#  println(length(epoc_mark))
#  display(epoc_mark)
#  readline()

ax[:plot](epoc_mark,res,color=:black,label="validation (N=$(length(y_valid)))")
ax[:plot](epoc_mark,tr,color=:blue,label="training (N=$(length(y_train)))")
#  ax[:plot](epoc_mark,tst,color=:orange,label="test (N=$(length(y_test)))")
if debugging
    ax[:set_title]("Num Hidden: $num_hidden, its: $num_epocs, srand: $srand_num, dropout: $dropout_rate")
else
    ax[:set_title]("Loss vs Epoch")
end

ax[:set_xlabel]("epoc")
ax[:set_ylabel]("loss (MSE)")
ax[:ticklabel_format](axis="y",style="sci",scilimits=(0,1),useOffset=false)
ax[:legend]()

#  Flux.testmode!(net)
#  test_err = loss(x_test,y_test)
#  Flux.testmode!(net,false)

#  ax[:axhline](y=test_err.data,color=:red)

output_fldr = "sqmodel_convergence"

savefig("$(output_fldr)/$(num_epocs)_$(num_hidden)_$(srand_num).pdf")
savefig("$(output_fldr)/current_fit.pdf")
