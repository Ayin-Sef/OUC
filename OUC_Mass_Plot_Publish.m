%% OUC v3.7 - Mass Spectrum Plot (High Contrast Dark Mode)
% Visualizes the Geometric Coupling K ~ ln(4) for publication

function OUC_Mass_Plot_Dark
    clear; clc; close all;

    % --- DATA ---
    lep_mass = [0.511, 105.66, 1776.8];
    lep_gen  = [0, 1, 2]; 

    qrk_mass = [2.2, 1275, 173000];
    qrk_gen  = [0, 1, 2]; 

    % --- FITTING ---
    p_lep = polyfit(lep_gen, log(lep_mass), 1);
    p_qrk = polyfit(qrk_gen, log(qrk_mass), 1);
    
    Slope_L = p_lep(1);
    Slope_Q = p_qrk(1);
    K = Slope_Q / Slope_L;
    
    % Lines
    x_plot = -0.5:0.1:2.5;
    y_lep = exp(polyval(p_lep, x_plot));
    y_qrk = exp(polyval(p_qrk, x_plot));

    % --- VISUALIZATION (DARK THEME) ---
    % 'InvertHardcopy', 'off' is crucial to keep background black when saving
    f = figure('Color', 'k', 'Position', [100 100 1000 700], 'InvertHardcopy', 'off');
    
    % Main Axes
    ax = axes();
    set(ax, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', ...
        'FontSize', 14, 'LineWidth', 1.5, 'GridColor', 'w', 'GridAlpha', 0.25);
    hold on; grid on;
    
    % 1. Plot Lines (Bright Neon Colors)
    plot(x_plot, y_lep, 'c--', 'LineWidth', 2); % Cyan for Leptons
    plot(x_plot, y_qrk, 'm--', 'LineWidth', 2); % Magenta for Quarks
    
    % 2. Plot Points
    s1 = scatter(lep_gen, lep_mass, 150, 'c', 'filled', 'MarkerEdgeColor', 'w');
    s2 = scatter(qrk_gen, qrk_mass, 150, 'm', 'filled', 's', 'MarkerEdgeColor', 'w');
    
    % 3. Log Scale Settings
    set(ax, 'YScale', 'log');
    ylim([0.1 10^6]);
    xlim([-0.5 2.5]);
    
    % 4. Labels
    xlabel('Generation Index (n)', 'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Mass (MeV) [Log Scale]', 'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold');
    title('OUC Mass Hierarchy Scaling', 'Color', 'w', 'FontSize', 20);
    
    % 5. Legend
    lgd = legend([s2, s1], {'Quark Layer (Confinement)', 'Lepton Layer (Screening)'}, ...
           'Location', 'southeast', 'FontSize', 12);
    set(lgd, 'Color', 'k', 'TextColor', 'w', 'EdgeColor', 'w');
       
    % 6. The K-Factor Annotation (Fixed Visibility)
    str = sprintf('Geometric Coupling:\nK = Slope_Q / Slope_L\n\\bfK \\approx %.3f\n\\rm(Theoretical ln(4) \\approx 1.386)', K);
    
    dim = [0.15 0.7 0.25 0.15];
    annotation('textbox', dim, 'String', str, ...
               'FitBoxToText', 'on', ...
               'BackgroundColor', 'k', ... % Black background
               'Color', 'w', ...           % White Text
               'EdgeColor', 'w', ...       % White Border
               'LineWidth', 1, ...
               'FontSize', 13, ...
               'FaceAlpha', 0.8);          % Slight transparency

    % --- SAVE ---
    % Use 'BackgroundColor', 'current' to ensure it saves exactly as seen
    exportgraphics(f, 'OUC_Mass_Spectrum_Dark.png', 'Resolution', 300, 'BackgroundColor', 'current');
    fprintf('Plot saved: OUC_Mass_Spectrum_Dark.png (K = %.4f)\n', K);
end