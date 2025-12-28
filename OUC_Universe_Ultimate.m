%% OUC v3.7 - Ultimate Universe Engine (Simulation + CMB Analysis)
% 1. Runs Quantum Bounce Simulation on GPU
% 2. Saves Frames for GIF
% 3. Automatically generates and saves Planck-style CMB Map at the end

function OUC_Universe_Ultimate
    clear; clc; close all;

    % --- 1. CONFIGURATION ---
    N = 2048; 
    dt = 0.02;          
    Steps = 5000;
    Vis_Rate = 20; % Обновлять картинку реже для скорости
    
    OutputFolder = 'OUC_Ultimate_Output';
    
    % Physics
    c = 1.0;
    Gamma_Initial = 0.01; 
    Gamma_Late = 0.1;     
    Barrier_Height = 0.1; 
    Tilt_Bias = 0.3;      
    Quantum_Amp = 0.05; 
    
    % --- 2. SETUP ---
    fprintf('Initializing GPU...\n');
    try, g = gpuDevice(1); reset(g); catch, g=[]; end
    
    if ~exist(OutputFolder, 'dir'), mkdir(OutputFolder); end
    
    % --- 3. INITIAL STATE ---
    fprintf('Generating Hyperfield...\n');
    C = gpuArray.ones(N, N, 'single') * (-1.0); 
    C = C + gpuArray.randn(N, N, 'single') * 0.4;
    C_prev = C; 
    
    K_lap = gpuArray([0 1 0; 1 -4 1; 0 1 0]);
    
    % --- 4. LIVE VIEW SETUP ---
    f = figure('Name', 'OUC Live Simulation', 'Color', 'k', ...
               'Units', 'normalized', 'Position', [0.1 0.2 0.4 0.4], ...
               'InvertHardcopy', 'off');
    
    ax1 = subplot(1, 2, 1);
    hImg = imagesc(gather(C));
    axis off; axis equal; colormap(ax1, hot); caxis([-1.5 1.5]);
    title('Coherence Field', 'Color', 'w');
    
    ax2 = subplot(1, 2, 2);
    hMatter = imagesc(gather(1 - abs(C))); 
    axis off; axis equal; colormap(ax2, bone); caxis([0 0.1]);
    title('Emergent Structure', 'Color', 'w');
    
    lbl = annotation('textbox', [0.4 0.9 0.2 0.1], 'String', 'Init...', ...
                     'Color', 'g', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 12);

    % --- 5. MAIN PHYSICS LOOP ---
    fprintf('Starting Big Bang...\n');
    
    Gamma = Gamma_Initial;
    Phase = 'PRE-INVERSION';
    FrameIdx = 1;
    
    for t = 1:Steps
        % Physics
        Lap = conv2(C, K_lap, 'same'); 
        Force = -4 * Barrier_Height * C .* (C.^2 - 1) + Tilt_Bias;
        
        % Quantum Injection (Only near C=0)
        Quantum_Noise = gpuArray.randn(N, N, 'single') * Quantum_Amp;
        Injection_Window = exp(-5 * C.^2); 
        Quantum_Kick = Quantum_Noise .* Injection_Window;
        
        Vel = (C - C_prev) / dt;
        Acc = (c^2 * Lap) - (Gamma * Vel) + Force + Quantum_Kick;
        
        C_next = 2*C - C_prev + (dt^2 * Acc);
        C_prev = C; C = C_next;
        
        % Phase Control
        meanC = mean(C(:));
        if strcmp(Phase, 'PRE-INVERSION') && meanC > -0.5
             Phase = 'QUANTUM BOUNCE';
        elseif strcmp(Phase, 'QUANTUM BOUNCE') && meanC > 0.5
            Phase = 'COOLING / STRUCTURING';
            Gamma = Gamma_Late; 
            Tilt_Bias = 0;      
        end
        
        % Render
        if mod(t, Vis_Rate) == 0
            C_cpu = gather(C);
            set(hImg, 'CData', C_cpu);
            set(hMatter, 'CData', 1 - abs(C_cpu));
            set(lbl, 'String', sprintf('Step: %d | Phase: %s', t, Phase));
            drawnow;
            
            % Save Frame for GIF
            FileName = sprintf('frame_%04d.png', FrameIdx);
            exportgraphics(f, fullfile(OutputFolder, FileName), 'Resolution', 80); 
            FrameIdx = FrameIdx + 1;
        end
    end
    
    % --- 6. POST-PROCESSING: CMB GENERATION (INTEGRATED) ---
    fprintf('Simulation Complete. Generating Scientific CMB Map...\n');
    
    % Take the final state from GPU
    Field = gather(C);
    
    % 1. Dipole Subtraction (Remove average background)
    Anisotropy = Field - mean(Field(:));
    
    % 2. Gaussian Smoothing (Simulate Telescope Beam / Fluid Damping)
    % This makes the map look like Planck data, removing pixel noise
    CMB_Map = imgaussfilt(Anisotropy, 6); 
    
    % 3. Contrast Stretch
    Limits = stretchlim(CMB_Map, [0.01 0.99]);
    
    % 4. Generate Planck Colormap
    P_Map = [
        0.0, 0.0, 0.5;  % Deep Blue
        0.0, 0.5, 1.0;  % Azure
        0.9, 0.9, 0.9;  % White
        1.0, 0.7, 0.0;  % Orange
        0.5, 0.0, 0.0   % Dark Red
    ];
    PlanckCmap = interp1(linspace(0,1,5), P_Map, linspace(0,1,256));
    
    % --- 7. FINAL RENDER & SAVE ---
    f_cmb = figure('Name', 'OUC Final CMB', 'Color', 'k', ...
                   'Position', [50 50 1200 900], 'InvertHardcopy', 'off');
    
    ax_cmb = axes('Position', [0.05 0.1 0.9 0.85]);
    imagesc(CMB_Map);
    colormap(ax_cmb, PlanckCmap);
    axis off; axis equal;
    caxis([Limits(1) Limits(2)]);
    
    title('OUC Primordial Fluctuations (CMB Prediction)', 'Color', 'w', 'FontSize', 18);
    text(50, 2000, 'Simulated: RTX 5070 | Mode: Superinversion', 'Color', 'w', 'FontSize', 12);
    
    % Colorbar Fixed
    cb = colorbar('Color', 'w');
    ylabel(cb, 'Temperature Fluctuation (\Delta T)', 'Color', 'w', 'FontSize', 12);
    
    % Save High-Res Result
    FinalFile = fullfile(OutputFolder, 'OUC_Final_CMB.png');
    exportgraphics(f_cmb, FinalFile, 'Resolution', 300);
    
    fprintf('SUCCESS: Simulation frames and Final CMB map saved to "%s"\n', OutputFolder);
end