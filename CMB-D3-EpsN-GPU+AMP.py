import numpy as np
import torch
import time

# --- Параметры OUC (Калибровка) ---
# Примечание: Установлено steps = 300 для быстрой проверки.
grid_size = 64
dt = 0.005
steps = 90000  # Верните 3000, когда будете готовы к долгой симуляции
chi0 = 1.0
Gamma0 = 0.001
kappa0 = 1.5
A = 1.0
B = 0.5
C_star = 0.5  # Было C0 = 0.5 в предыдущей версии, используем C_star по формализму
epsilon_std = 0.01  # epsilon (ξ) - стохастический шум, усилен для локальных C→0
device = 'cuda' if torch.cuda.is_available() else 'cpu'  # Автоопределение GPU
use_amp = True  # Включить AMP для mixed precision (ускорение)

def V_prime(C):
    return 2 * A * (C - 1) + 4 * B * (C - C_star)**3

# Laplacian kernel для 3D conv (на GPU)
lap_kernel = torch.tensor([[[[0.0, 0.0, 0.0],
                             [0.0, 1.0, 0.0],
                             [0.0, 0.0, 0.0]],
                            [[0.0, 1.0, 0.0],
                             [1.0, -6.0, 1.0],
                             [0.0, 1.0, 0.0]],
                            [[0.0, 0.0, 0.0],
                             [0.0, 1.0, 0.0],
                             [0.0, 0.0, 0.0]]]], dtype=torch.float64, device=device)
lap_kernel = lap_kernel.unsqueeze(0)  # Для conv3d: [out_ch, in_ch, d, h, w] = [1,1,d,h,w]

# --- Основной Цикл Симуляции на GPU ---
C = torch.full((grid_size, grid_size, grid_size), 0.98, dtype=torch.float64, device=device)
C += torch.normal(mean=0.0, std=epsilon_std, size=C.shape, device=device)
dC_dt = torch.zeros_like(C, device=device)
mean_C_history = np.zeros(steps)

print(f"Запуск GPU-симуляции OUC (сетка {grid_size}³) на {device} с AMP={use_amp}...")
start_time = time.time()

# AMP autocast (без scaler, так как нет gradients)
with torch.amp.autocast(device_type='cuda', dtype=torch.float16, enabled=use_amp):
    for t in range(steps):
        mean_C = torch.mean(C).item()
        mean_C_history[t] = mean_C
        
        # Расчет динамических констант
        kappa = kappa0 * (1 - mean_C)**2 + 1e-6
        Gamma = Gamma0 * (1 - mean_C)
        chi = chi0 * torch.sqrt(torch.tensor(kappa / kappa0, device=device))
        
        # Шум epsilon (ξ) на GPU
        xi = torch.normal(mean=0.0, std=epsilon_std, size=C.shape, device=device)
        
        # V_prime на GPU
        V_prime_arr = V_prime(C)
        
        # Laplacian через conv3d (periodic padding)
        C_padded = torch.nn.functional.pad(C.unsqueeze(0).unsqueeze(0), (1,1,1,1,1,1), mode='circular')  # [1,1,d+2,h+2,w+2]
        lap_C = torch.nn.functional.conv3d(C_padded, lap_kernel, padding=0).squeeze()
        
        # Уравнение движения OUC: accel = (1/chi) * (-Gamma*dC_dt - V' + kappa*lap_C + xi)
        accel = (-Gamma * dC_dt - V_prime_arr + kappa * lap_C + xi) / chi
        
        # Интегрирование по времени
        dC_dt += accel * dt
        C += dC_dt * dt
        
        # Границы C [0,1] на GPU
        C = torch.clamp(C, min=0.0, max=1.0)

end_time = time.time()
print(f"Симуляция завершена. Время выполнения: {end_time - start_time:.2f} сек.")

# --- БЛОК АНАЛИЗА И СОХРАНЕНИЯ РЕЗУЛЬТАТОВ ---
print("---")
print("Сохранение финального поля C и истории mean_C...")

# 1. Сохранение финального поля C (to CPU for np.savez)
C_cpu = C.cpu().numpy()
np.savez_compressed('CMB_final_C_128_{}s.npz'.format(steps), C=C_cpu)

# 2. Сохранение истории средней когерентности
np.save('CMB_mean_C_history_{}s.npy'.format(steps), mean_C_history)

final_mean_C = mean_C_history[-1]
print(f"Финальная средняя когерентность: {final_mean_C:.5f}")
print(f"Изменение mean_C за симуляцию: {mean_C_history[0]:.5f} -> {final_mean_C:.5f}")

# 3. Вычисление и сохранение Спектра Мощности P(k)
delta_C = C - torch.mean(C)
fft_delta = torch.fft.fftn(delta_C)
P_k = torch.abs(fft_delta)**2 / torch.prod(torch.tensor(delta_C.shape, device=device))

# Вычисление k_mag (на GPU)
k = torch.fft.fftfreq(grid_size, d=1/grid_size, device=device)
kx, ky, kz = torch.meshgrid(k, k, k, indexing='ij')
k_mag = torch.sqrt(kx**2 + ky**2 + kz**2)
k_bins = torch.arange(0, grid_size // 2 + 1, 1, device=device)

# Радиальный спектр P(k) (усреднение)
P_radial = torch.zeros(len(k_bins) - 1, device=device)
k_mids = torch.zeros(len(k_bins) - 1, device=device)

for i in range(len(P_radial)):
    mask = (k_bins[i] <= k_mag) & (k_mag < k_bins[i+1])
    if mask.any():
        P_radial[i] = torch.mean(P_k[mask])
    k_mids[i] = (k_bins[i] + k_bins[i+1]) / 2

# Сохранение спектра (to CPU)
k_mids_cpu = k_mids.cpu().numpy()
P_radial_cpu = P_radial.cpu().numpy()
np.savez('CMB_spectrum_{}s.npz'.format(steps), k=k_mids_cpu, Pk=P_radial_cpu)
print("Спектр мощности P(k) сохранен в CMB_spectrum_{}s.npz.".format(steps))
print("---")
# --- КОНЕЦ БЛОКА АНАЛИЗА И СОХРАНЕНИЯ РЕЗУЛЬТАТОВ ---