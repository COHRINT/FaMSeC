##########
## instructions for global `.juliarc.jl`
##########

# it is necessary to include the following in the global `.juliarc.jl`
# it makes julia search the current directory for a local `juliarc.jl` file

#  if pwd() != ENV["HOME"]
    #  local_rc = joinpath(pwd(),"juliarc.jl")
    #  if isfile(local_rc)
        #  println("Loading Local juliarc.jl file....")
        #  include(local_rc)
    #  end
#  end

##########
## local `juliarc.jl`
##########

# adds current folder to the julia path so we can load the local modules
push!(LOAD_PATH,pwd())
