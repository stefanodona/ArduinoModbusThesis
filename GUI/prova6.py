import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import tkinter as tk
from tkinter import ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# Funzione per disegnare il parallelepipedo (la cassa acustica)
def draw_box(ax, width, height, depth, wood_thickness):
    ax.clear()

    # Definire i vertici del parallelepipedo (esterno)
    vertices = np.array([[0, 0, 0], [width, 0, 0], [width, depth, 0], [0, depth, 0],
                         [0, 0, height], [width, 0, height], [width, depth, height], [0, depth, height]])

    # Definire le facce della cassa acustica
    faces = [[vertices[j] for j in [0, 1, 2, 3]],  # Base
             [vertices[j] for j in [4, 5, 6, 7]],  # Top
             [vertices[j] for j in [0, 3, 7, 4]],  # Lato frontale
             [vertices[j] for j in [1, 2, 6, 5]],  # Lato posteriore
             [vertices[j] for j in [0, 1, 5, 4]],  # Lato sinistro
             [vertices[j] for j in [3, 2, 6, 7]]]  # Lato destro

    # Aggiungere le facce al grafico 3D
    ax.add_collection3d(Poly3DCollection(faces, facecolors='cyan', linewidths=1, edgecolors='r', alpha=.25))

    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_xlim([0, width])
    ax.set_ylim([0, depth])
    ax.set_zlim([0, height])

    canvas.draw()

# Funzione per aggiornare la visualizzazione 3D
def update_plot():
    try:
        width = float(entry_width.get())
        height = float(entry_height.get())
        depth = float(entry_depth.get())
        wood_thickness = float(entry_thickness.get())
    except ValueError:
        width, height, depth, wood_thickness = 200, 300, 400, 10  # valori predefiniti

    draw_box(ax, width, height, depth, wood_thickness)

# Creare la finestra principale
root = tk.Tk()
root.title("Cassa Acustica GUI")

# Creare il frame principale
frame = tk.Frame(root)
frame.pack(fill=tk.BOTH, expand=True)

# Pannello di sinistra per inserire i parametri della cassa
left_panel = tk.Frame(frame)
left_panel.pack(side=tk.LEFT, padx=10, pady=10)

tk.Label(left_panel, text="Larghezza (mm):").pack(anchor='w')
entry_width = tk.Entry(left_panel)
entry_width.pack(fill=tk.X)

tk.Label(left_panel, text="Altezza (mm):").pack(anchor='w')
entry_height = tk.Entry(left_panel)
entry_height.pack(fill=tk.X)

tk.Label(left_panel, text="Profondità (mm):").pack(anchor='w')
entry_depth = tk.Entry(left_panel)
entry_depth.pack(fill=tk.X)

tk.Label(left_panel, text="Spessore del legno (mm):").pack(anchor='w')
entry_thickness = tk.Entry(left_panel)
entry_thickness.pack(fill=tk.X)

# Area per la visualizzazione 3D
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
canvas = FigureCanvasTkAgg(fig, master=frame)
canvas.get_tk_widget().pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

# Pulsante per aggiornare il grafico
update_button = tk.Button(left_panel, text="Aggiorna visualizzazione", command=update_plot)
update_button.pack(pady=10)

# Avvio del main loop
root.mainloop()

