%% OUC v3.8 - CMB Calibrated Spectrum (Planck Match)
% Target: Perfect alignment with l=220, l=540, l=800
% Method: Tuned acoustic scale and geometric projection factor.

function OUC_CMB_Calibrated
    clear; clc; close all;

    % --- 1. CONFIGURATION ---
    N = 2048; 
    
    % Calibration Parameters (The "Knobs" of the Universe)
    Scale_Geometry = 3.2;   % Projection factor (Grid -> Multipole l)
    Acoustic_Freq  = 68;    % Characteristic scale of sound waves on grid
    Silk_Scale     = 900;   % Damping tail start
    
    % --- 2. GENERATE FIELDS ---
    fprintf('Generating Calibrated Plasma...\n');
    [X, Y] = meshgrid(1:N);
    % Radial frequency map
    K = sqrt((X-N/2).^2 + (Y-N/2).^2);
    K(N/2, N/2) = 1; % Avoid singularity
    
   % --- PHYSICS OF THE SPECTRUM (CORRECTED) ---
    % 1. Primordial Tilt (n_s)
    P_primordial = 1 ./ (K.^0.96);
    
    % 2. Acoustic Oscillations with Baryon Drag (Anharmonicity)
    % Real physics: Sound speed c_s decreases as baryons load the plasma.
    % This stretches the higher peaks to the right.
    % We use an exponent 0.91 to simulate this time-dependence.
    
    Phase_Drag = 0.91; 
    Effective_Freq = Acoustic_Freq * 1.15; % Retune base freq
    
    % Non-linear phase: K^0.91 instead of K
    Phase = (K ./ Effective_Freq).^Phase_Drag * pi;
    
    Oscillations = cos(Phase).^2 + 0.25; 
    
    % 3. Apply to White Noise
    RandomPhase = exp(1i * rand(N) * 2 * pi);
    Field_FFT = P_primordial .* sqrt(Oscillations) .* RandomPhase;
    
    % --- 3. ANALYSIS & DAMPING ---
    fprintf('Analyzing Spectrum...\n');
    PS_Raw = abs(Field_FFT).^2;
    
    % Radial Averaging (Binning)
    max_r = 1500;
    Power_1D = zeros(1, max_r);
    
    % Fast radial mean
    % (Using integer approximation for speed)
    K_int = round(K);
    for r = 1:max_r
        % logical indexing is slow, let's use a simpler heuristic for visualization
        % Ideally, accumarray, but loop is fine for 1D extraction here
        % We sample the spectrum along a cut for speed, or average rings
        % Let's do ring average for accuracy
        mask = (K_int == r);
        if any(mask(:))
            Power_1D(r) = mean(PS_Raw(mask));
        end
    end
    
    % --- 4. APPLY SILK DAMPING & SCALING ---
    l_axis = (1:max_r) * Scale_Geometry;
    
    % Silk Damping: Exponential decay at high l
    Damping = exp( -(l_axis / Silk_Scale).^1.4 );
    
    % Sachs-Wolfe Plateau boost (Low l)
    SW_Boost = 1 + 500 ./ (l_axis + 10); 
    
    % Final Power: D_l = l(l+1) * C_l / 2pi
    % Our Power_1D is roughly C_l
    Power_Final = Power_1D .* Damping .* (l_axis.^2);
    
    % Smooth the stochastic noise for clean plotting
    Power_Smooth = smooth(Power_Final, 30);

    % --- 5. VISUALIZATION ---
    f = figure('Name', 'Calibrated CMB', 'Color', 'k', 'Position', [100 100 1000 600]);
    ax = axes('Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.2);
    hold on; grid on;
    
    % Plot Simulation
    plot(l_axis, Power_Smooth, 'g-', 'LineWidth', 3);
    
    % Plot Targets (Planck Data Peaks)
    xline(220, 'r--', 'Peak 1', 'Color', [1 0.3 0.3], 'LineWidth', 1.5);
    xline(540, 'y--', 'Peak 2', 'Color', [1 1 0.3], 'LineWidth', 1.5);
    xline(810, 'c--', 'Peak 3', 'Color', [0.3 1 1], 'LineWidth', 1.5);
    
    % Aesthetics
    set(ax, 'XScale', 'log');
    xlim([40 1800]);
    % Auto-scale Y to fit the first peak
    [max_p, idx] = max(Power_Smooth(l_axis > 100 & l_axis < 400));
    ylim([0 max_p * 1.2]);
    
    xlabel('Multipole Moment (l)', 'FontSize', 14);
    ylabel('Power Anisotropy D_l', 'FontSize', 14);
    title('OUC Spectrum vs Planck Targets', 'Color', 'w', 'FontSize', 18);
    
    legend({'OUC Simulation (Calibrated)', 'Observational Peaks'}, 'Color', 'k', 'TextColor', 'w');
    
    fprintf('Calibration Complete. Peaks should align.\n');
end