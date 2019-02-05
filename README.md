# FaMSeC
This is a repository for Factorized Machine Self-Confidence (FaMSeC). FaMSeC is a "self-assessment" *algorithmic assurance* ([1][2]), and is meant to effect the how people interact with an autonomous system. The code here produces data that was used in [this experiment][3]. This code also, produced data for [this paper][4].

<p align="center">
  <img src="repo_imgs/FaMSeC.png" alt="Example Road-Network Delivery Problem" width="750">
</p>

The overall goal is to : 1) generate "road-network" MDPs, and simulate the performance of different solvers on them; 2) calculate two of the FaMSeC metrics---"Solver Quality" ($x_Q$), and "Outcome Assessment" ($x_P$); 3) provide scripts for plotting different data and investigating the different properties of $x_Q$.

## Requirements
This code uses Julia v0.6.3 with the following packages:

* `POMDPs.jl` (`v0.6.9`) and `POMDPToolbox` (`v0.2.8`) --- MDP and POMDP functionality
* `MetaGraphs.jl` (`v0.4.1`) --- for adding metadata to `LightGraphs.jl` graphs
* `JSON.jl` (`v0.17.2`) --- for reading/exporting `.json` files
* `PyPlot.jl` (`v2.6.3`) --- for creating plots with matplotlib (this requires matplotlib to be installed, but PyPlot takes care of this using an anaconda environment)
* `JLD` (`v0.8.3`)/`FileIO` (`v0.9.1`)  --- for binary file storage
* `ProgressMeter` (`v0.5.6`) --- for showing progress bars when running
* `MicroLogging` (`v0.2.0`) --- nice logging utility
* `Distributions` (`v0.15.0`) --- for working with random variables and distributions
* `StatsBase` (`v0.23.1`) --- basic statistics stuff
* `TikzGraphs` (`v0.6.0`)/`TikzPictures` (`v1.2.0`) --- for plotting graphs using Tikz
* `DataStructures` (`v0.8.4`) --- adds data structures (linked lists, queues, etc.)
* `DataFrames` (`v0.11.7`)/`CSV` (`v0.2.5`)--- dealing with reading and writing data in tables

## Process
Add notes about how to create the experimental data.

When creating data "from scratch" this is the process that I followed:

1. run `make_nets_and_data.jl`, after adding the `experiment_name` to the `experiment_utilities.jl` file, and creating a corresponding experiment parameters file in the `experiment_params` folder, and following the format of other files in that folder. I typically did this on Google Cloud Platform using something like a 64 processor machine and a few hundred workers in julia.

2. run `make_experiment_data.jl`. This file can do three things:
    * Create the `.svg` figures for the experiment
    * Calculate xQ for each network, this will produce the SQ model if necessary (which will be necessary if you are starting from scratch)
    * Export data to a `.json` file that can be used in the MTurk experiment

3. run `svg_resize.jl` to "square-up" the `.svg` figures

Other `make_*` files are, or were at some point, self-sufficient but were wrapped into the above two files over time. The `plot_*` files are run to make specialty plots for different papers.

Discuss "farming out" to some cloud service and parallelizing the computations. OR using local computations that could take forever.

## A Note About Notation
We used `X3` and `X4` in code because that was the original self-confidence notation. Later we changed the notation to `xQ` and `xO`, but we haven't replace that in the code yet...hasn't been a priority

## Description of Files

* `calc_xq.jl`---calculates the solver quality `xQ` value, used by `make_experiment_data.jl`
* `experiment_utilities.jl`---some basic utilities used by `make_nets_and_data.jl`
* `hellinger_test.jl`---file for investigating the properties and behavior of the Hellinger metric
* `juliarc.jl`---file that adds the current path to the julia environment so local modules can be loaded with `using` command
* `LICENSE`---MIT license file
* `logistic_tests`---file for investigating the properties of the general logistic function
* `make_experiment_data.jl`---After all networks have been created and simulations run, this code runs to make the data for the MTurk experiment. This means making the figures, calculating xQ (which has to be done after everything because we need to have the surrogate model), filtering out networks that are too dense or where the truck is too close to the exit, and simulating success/failures of deliveries on networks. This data is used for the MTurk experiment.
* `make_nets_and_data.jl`---This file is the main file to produce the simulation data. Here the networks are created and many simulations are run.  I ran this file on Google Cloud Platform so I could utilize many parallel processes. Otherwise this might take a ***really*** long time.
* `make_roadnet_figs.jl`---Called by `make_experiment_data.jl` to produce the `.svg` figures of the different road networks
* `make_SQ_model.jl`---
* `make_table_corr_plot.jl`---file used to make correlation plot of log files (found in `logs` folder). This is to help identify what variables are interacting to try and decide what variable to include in the surrogate model
* `network_library.jl`---file used to create different kinds of networks. The "original" road-network, and a "medium" network are here. Also code to make "random" networks that were used in the final experiments. Also some code to visualize a network. These aren't just "standard" networks, they specify things like exit nodes, and reward structures that are used in the MDP.
* `plot_mcts_depth.jl`---make box plots based on MCTS depth of the different solvers. This made figures in numerical simulations report that is on [ArXiv][1]
* `plot_root_comparison.jl`---Used to plot different fractional exponents when thinking about the $\alpha$ parameter of xQ
* `plot_rwd_dists.jl`---file used in `make_experiment_data.jl` to plot the `surprisesuccess` and `surprisefailure` figures.
* `prepend_preamble.tex`---this file is used by the `TikzGraphs` library in order to add special characters when making the road-network images. This enables the truck and motorcycle icons to be displayed
* `roadnet_MDP.jl`---
* `Roadnet_MDP.jl`---
* `roadnet_pursuer_driver.jl`---
* `roadnet_pursuer_generator_MDP`---
* `road_net_visualize.jl`---make an animation of a simulated run.
* `self_confidence.jl`---code for calculating both `xO` (`X4`) and `xQ` (`X3`)
* `send_mail.jl`---used for sending email when `make_nets_and_data.jl` is done running on Google Cloud Platform.
* `SQ_investigation.jl`---I don't think this file is used, but I haven't taken the time to check....
* `svg_resize.jl`---processes images in the `imgs` folder to make their aspect ratio square, save figures in `imgs/squared` folder
* `test_mxnet.jl`---script to make sure mxnet is working alright
* `test_pomdp_parallel.jl`---script to test parallel pomdps
* `utilities.jl`---some useful functions that I used in places, I don't think all of them are still used though, and some may not be finished. I think I abandoned them in the middle for a different approach (i.e. lhs).
* `visualize_medium_net.jl`---make plots of original and medium roadnets
* `X3_empirical.jl`---code for original development of X3
* `X3_test.jl`---code to produce more numerical simulations of X3 in action. This figure was used in several papers, and shows two GPs that cross over in different locations. The value of X3 is compared at different locations and for different "global reward ranges".

[1]:https://arxiv.org/abs/1810.06519
[2]:http://bisraelsen.site/assurances
[3]:https://github.com/COHRINT/SC_experiment
[4]:http://bisraelsen.site/SQ
