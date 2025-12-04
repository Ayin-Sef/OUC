function params = ouc_init_params()
% Default parameters for OUC v2.2 MATLAB simulation

params.Nphi = 3;

params.dx = 1/32;
params.dt = 0.002;

params.Nt = 2000;
params.output_interval = 50;

params.C0 = 1.0;
params.kappa = 1.0;
params.chi   = 1.0;

params.Vpp = 0.1; % second derivative of potential at C0

params.Gamma = 0.01;

params.rho = [0.8, 0.5, 1.2]; % phase stiffness for 3 layers

end
