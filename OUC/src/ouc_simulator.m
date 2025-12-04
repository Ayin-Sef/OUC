% =====================================================================
% OUC v2.2 simple simulator interface
% =====================================================================

function [C,phi] = ouc_simulator(params, steps)

Nx = 64; Ny = 64; Nz = 64;
dx = params.dx; dt = params.dt;

C  = params.C0 + 1e-3 * randn(Nx,Ny,Nz);
dC = zeros(Nx,Ny,Nz);

phi = zeros(Nx,Ny,Nz, params.Nphi);
for a = 1:params.Nphi
    phi(:,:,:,a) = 2*pi*rand(Nx,Ny,Nz);
end

[kx,ky,kz] = ndgrid( ...
    fftshift((-Nx/2:Nx/2-1)*(2*pi/(Nx*dx))), ...
    fftshift((-Ny/2:Ny/2-1)*(2*pi/(Ny*dx))), ...
    fftshift((-Nz/2:Nz/2-1)*(2*pi/(Nz*dx))) );

k2 = kx.^2 + ky.^2 + kz.^2;

for t=1:steps
    Cf = fftn(C);
    lapC = ifftn(-k2 .* Cf);

    d2C = ouc_field_equations(C, phi, params, lapC);

    dC = dC + dt*d2C;
    C  = C  + dt*dC;

    dC = dC * (1 - params.Gamma * dt);
end

end
