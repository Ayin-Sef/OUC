% =====================================================================
% OUC v2.2 - MATLAB Simulation (128^3)
% Author: Grok + Ayin
% Date: 2025-12-04
% =====================================================================

clear all; close all; clc;

% Load parameters
params = ouc_init_params();

Nx = 128;
Ny = 128;
Nz = 128;

dx = params.dx;
dt = params.dt;

% Fields
C  = params.C0 + 1e-3 * randn(Nx,Ny,Nz);
dC = zeros(Nx,Ny,Nz);

phi = zeros(Nx,Ny,Nz, params.Nphi);
for a = 1:params.Nphi
    phi(:,:,:,a) = 2*pi*rand(Nx,Ny,Nz);
end

% Precompute Fourier grid for Laplacians
[kx,ky,kz] = ndgrid( ...
    fftshift((-Nx/2:Nx/2-1)*(2*pi/(Nx*dx))), ...
    fftshift((-Ny/2:Ny/2-1)*(2*pi/(Ny*dx))), ...
    fftshift((-Nz/2:Nz/2-1)*(2*pi/(Nz*dx))) );

k2 = kx.^2 + ky.^2 + kz.^2;

Nt = params.Nt;
output_interval = params.output_interval;

for t = 1:Nt

    % --- Fourier laplacian of C ---
    Cf = fftn(C);
    lapC = ifftn(-k2 .* Cf);

    % --- Phase gradients contribution ---
    Sphi = 0*C;
    for a = 1:params.Nphi
        gradphi = gradient(phi(:,:,:,a), dx);
        term = params.rho(a)*C.^2 .* divergence(gradphi);
        Sphi = Sphi + term;
    end

    % --- Equation of motion for C ---
    d2C = ( ...
        params.kappa * lapC ...
      - params.Vpp * (C - params.C0) ...
      + Sphi ...
    ) / params.chi;

    % --- Time evolution (leapfrog) ---
    dC = dC + dt * d2C;
    C  = C  + dt * dC;

    % --- Damping (Gamma term) ---
    dC = dC * (1 - params.Gamma * dt);

    % --- Output ---
    if mod(t, output_interval) == 0
        slice = squeeze(C(:,:,floor(Nz/2)));

        imagesc(slice);
        title(['C-field slice at t = ', num2str(t)]);
        colorbar;
        drawnow;

        % Save slice
        outname = sprintf('C_slice_t%06d.png', t);
        imwrite(mat2gray(slice), outname);
    end

end

% Compute P(k)
Cf = fftn(C);
Pk = abs(Cf).^2;
save('Pk.mat','Pk');

disp('Simulation completed.');
