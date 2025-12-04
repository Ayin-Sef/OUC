# OUC — Our Universe Coherence Theory (v2.2)

This repository contains:
- Full paper in LaTeX: paper/OUC_v2.2.tex  
- Figures: paper/figs/  
- MATLAB simulations (128³): simulations/matlab/  
- Python scripts for Planck comparison: simulations/python/  
- Core OUC field equations: src/  

## How to compile paper:
cd paper
pdflatex OUC_v2.2.tex
pdflatex OUC_v2.2.tex

## MATLAB simulation:
cd simulations/matlab
run('matlab_sim_128.m')

## Planck protocol:
cd simulations/python
python planck_protocol.py

## Folder structure:
paper/
   OUC_v2.2.tex
   figs/
src/
   ouc_field_equations.m
   ouc_simulator.m
simulations/
   matlab/
   python/
