#!/bin/csh

# Data Assimilation Research Testbed -- DART
# Copyright 2004-2006, Data Assimilation Research Section
# University Corporation for Atmospheric Research
# Licensed under the GPL -- www.gpl.org/licenses/gpl.html
#
# <next three lines automatically updated by CVS, do not edit>
# $Id$
# $Source$
# $Name$

#----------------------------------------------------------------------
# Script to manage the compilation of all components for this model;
# executes a known "perfect model" experiment using an existing
# observation sequence file (obs_seq.in) and initial conditions appropriate 
# for both 'perfect_model_obs' (perfect_ics) and 'filter' (filter_ics).
# There are enough initial conditions for 80 ensemble members in filter.
# Use ens_size = 81 and it WILL bomb. Guaranteed.
# The 'input.nml' file controls all facets of this execution.
#
# 'create_obs_sequence' and 'create_fixed_network_sequence' were used to
# create the observation sequence file 'obs_seq.in' - this defines 
# what/where/when we want observations. This script does not run these 
# programs - intentionally. 
#
# 'perfect_model_obs' results in a True_State.nc file that contains 
# the true state, and obs_seq.out - a file that contains the "observations"
# that will be assimilated by 'filter'.
#
# 'filter' results in three files (at least): Prior_Diag.nc - the state 
# of all ensemble members prior to the assimilation (i.e. the forecast), 
# Posterior_Diag.nc - the state of all ensemble members after the 
# assimilation (i.e. the analysis), and obs_seq.final - the ensemble 
# members' estimate of what the observations should have been.
#
# Once 'perfect_model_obs' has advanced the model and harvested the 
# observations for the assimilation experiment, 'filter' may be run 
# over and over by simply changing the namelist parameters in input.nml.
#
# The result of each assimilation can be explored in model-space with
# matlab scripts that directly read the netCDF output, or in observation-space.
# 'obs_diag' is a program that will create observation-space diagnostics
# for any result of 'filter' and results in a couple data files that can
# be explored with yet more matlab scripts.
#
#----------------------------------------------------------------------
# 'preprocess' is a program that culls the appropriate sections of the
# observation module for the observations types in 'input.nml'; the 
# resulting source file is used by all the remaining programs, 
# so this MUST be run first.
#----------------------------------------------------------------------

\rm -f preprocess create_obs_sequence create_fixed_network_seq
\rm -f perfect_model_obs filter obs_diag integrate_model
\rm -f merge_obs_seq smoother
\rm -f *.o *.mod

echo mkmf_preprocess
csh mkmf_preprocess
make         || exit 1

\rm -f ../../../obs_def/obs_def_mod.f90
\rm -f ../../../obs_kind/obs_kind_mod.f90
./preprocess || exit 2

#----------------------------------------------------------------------

echo mkmf_create_obs_sequence
csh mkmf_create_obs_sequence
make         || exit 3

echo mkmf_create_fixed_network_seq
csh mkmf_create_fixed_network_seq
make         || exit 4

echo mkmf_perfect_model_obs
csh mkmf_perfect_model_obs
make         || exit 5

# this one needs to be compiled with MPI.
echo mkmf_filter
csh mkmf_filter
echo updating Makefile for MPI
\cp -f Makefile Makefile.back
sed -e 's/(LD)/(MPILD)/' -e 's/(FC)/(MPIFC)/' Makefile.back >! Makefile
\rm -f Makefile.back
echo remove all existing obj files and rebuild with MPI compile wrapper
\rm -f *.o *.mod
make         || exit 6
echo remove all existing obj files and start clean
\rm -f *.o *.mod

echo mkmf_obs_diag
csh mkmf_obs_diag
make         || exit 7

echo mkmf_integrate_model
csh mkmf_integrate_model
make         || exit 9

echo mkmf_merge_obs_seq
csh mkmf_merge_obs_seq
make         || exit 10

echo skipping mkmf_smoother
#csh mkmf_smoother
#make         || exit 11


./perfect_model_obs || exit 20

echo " "
echo time to run filter here:
echo ' for lsf run "bsub < runme_filter"'
echo ' for pbs run "qsub runme_filter"'
echo ' for lam-mpi run "lamboot" once, then "runme_filter"'

#\rm -f go_end_filter
