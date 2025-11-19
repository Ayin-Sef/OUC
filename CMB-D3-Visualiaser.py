import numpy as np
import matplotlib.pyplot as plt
import os
import tkinter as tk
from tkinter import ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

plt.style.use('dark_background')

class OUCVisualizer:
    def __init__(self):
        self.simulations = self.find_simulations()
        self.root = tk.Tk()
        self.root.title("OUC Visualizer — Когерентность Вселенной")
        self.root.geometry("1700x1000")
        self.root.configure(bg='#111111')
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

        save_btn = ttk.Button(self.root, text="Сохранить все графики как PNG", command=self.save_all)
        save_btn.pack(pady=10)

        canvas = tk.Canvas(self.root)
        scrollbar = ttk.Scrollbar(self.root, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        for steps in self.simulations:
            frame = ttk.Frame(scrollable_frame, relief="ridge", borderwidth=4)
            frame.pack(fill="both", expand=True, padx=20, pady=20)
            self.plot_simulation(steps, frame)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        self.root.mainloop()

    def on_close(self):
        self.root.quit()
        self.root.destroy()

    def find_simulations(self):
        steps_list = []
        for file in os.listdir('.'):
            if file.startswith('CMB_mean_C_history_') and file.endswith('.npy'):
                try:
                    steps = int(file.split('_')[-1].replace('s.npy', ''))
                    steps_list.append(steps)
                except:
                    continue
        steps_list.sort()
        print(f"Найдено симуляций: {steps_list}")
        return steps_list

    def load_data(self, steps):
        mean_C = np.load(f'CMB_mean_C_history_{steps}s.npy')
        spec = np.load(f'CMB_spectrum_{steps}s.npz')
        k = spec['k']
        Pk = spec['Pk']

        C_final = None
        grid_size = None
        for possible_grid in [64, 128, 256, 512, 1024]:
            fname = f'CMB_final_C_{possible_grid}_{steps}s.npz'
            if os.path.exists(fname):
                data = np.load(fname)
                C_final = data['C']
                grid_size = possible_grid
                break

        return mean_C, k, Pk, C_final, grid_size

    def plot_simulation(self, steps, parent_frame):
        mean_C, k, Pk, C_final, grid_size = self.load_data(steps)

        fig = plt.Figure(figsize=(18, 6), dpi=100)
        fig.suptitle(f"OUC — {steps} шагов (сетка {grid_size}³)", fontsize=18, color='white')

        ax1 = fig.add_subplot(131)
        ax1.plot(mean_C, linewidth=3, color='#ff5555')
        ax1.set_title('Эволюция ⟨C⟩')
        ax1.set_xlabel('Шаг')
        ax1.set_ylabel('⟨C⟩')
        ax1.grid(True, alpha=0.4)
        ax1.text(0.02, 0.95, f'начало = {mean_C[0]:.5f}\nконец = {mean_C[-1]:.5f}',
                 transform=ax1.transAxes, fontsize=14, bbox=dict(facecolor='black', alpha=0.8))

        ax2 = fig.add_subplot(132)
        ax2.loglog(k, Pk, 'o-', color='#55ffff', markersize=4)
        ax2.set_title('Спектр P(k)')
        ax2.set_xlabel('k')
        ax2.set_ylabel('P(k)')
        ax2.grid(True, which='both', alpha=0.4)

        ax3 = fig.add_subplot(133)
        if C_final is not None:
            z = C_final.shape[2] // 2
            im = ax3.imshow(C_final[:, :, z], cmap='plasma', vmin=C_final.min(), vmax=1.0)
            ax3.set_title(f'Срез C(x,y) при z={z}')
            fig.colorbar(im, ax=ax3, fraction=0.046)
        else:
            ax3.text(0.5, 0.5, 'C_final не найден', transform=ax3.transAxes,
                     fontsize=20, ha='center', color='gray')
            ax3.axis('off')

        canvas = FigureCanvasTkAgg(fig, master=parent_frame)
        canvas.draw()  # <-- Важно: отрисовка!
        canvas.get_tk_widget().pack()

        # Сохраняем готовую фигуру в атрибуте для save_all
        self.__dict__[f'fig_{steps}'] = fig

    def save_all(self):
        for steps in self.simulations:
            fig = self.__dict__[f'fig_{steps}']
            fig.savefig(f"OUC_Visualization_{steps}s.png", dpi=300, bbox_inches='tight', facecolor='#111111')
        print("Все графики успешно сохранены как PNG!")

if __name__ == "__main__":
    OUCVisualizer()