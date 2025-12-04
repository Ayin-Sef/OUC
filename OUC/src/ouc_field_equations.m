% =====================================================================
% Field equations for OUC v2.2
% =====================================================================

function d2C = ouc_field_equations(C, phi, params, lapC)
% Returns second time derivative of C-field

Nx = size(C,1);
Ny = size(C,2);
Nz = size(C,3);

Sphi = zeros(Nx,Ny,Nz);

for a = 1:params.Nphi
    gradphi = gradient(phi(:,:,:,a), params.dx);
    term = params.rho(a)*C.^2 .* divergence(gradphi);
    Sphi = Sphi + term;
end

d2C = ( ...
    params.kappa * lapC ...
  - params.Vpp * (C - params.C0) ...
  + Sphi ...
) / params.chi;

end
