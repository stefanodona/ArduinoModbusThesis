import tkinter as tk
import customtkinter
import serial
import numpy as np
import re  # used to compare strings
import keyboard
import time
from threading import Thread
import os
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

this_path = os.getcwd()
config_path = os.path.join(this_path, "GUI\config.txt")
print(config_path)

# load state
f = open(config_path, "r")
loadcell_fullscale = int(f.readline().split()[1])
min_pos = float(f.readline().split()[1])
max_pos = float(f.readline().split()[1])
num_pos = int(f.readline().split()[1])
avg_flag = f.readline().split()[1]
f.close()

percent = 0

force = np.array([])
pos = np.array([])


def compare_strings(string1, string2):
    pattern = re.compile(string2)
    match = re.search(pattern, string1)
    return match


def setAvgFlag():
    global avg_flag
    avg_flag = checkbox.get()


def setLoadCell(val):
    global loadcell_fullscale
    # global loadcell_fullscale
    # str = load_cell_menu.get()#.split()
    # print(str)
    loadcell_fullscale = int(val.split()[0])
    print(loadcell_fullscale)


def saveState():
    ff = open(config_path, "w")
    ff.write("loadcell " + str(loadcell_fullscale) + " kg\n")
    ff.write("min_pos " + str(min_pos) + " mm\n")
    ff.write("max_pos " + str(max_pos) + " mm\n")
    ff.write("num_pos " + str(num_pos) + " \n")
    ff.write("media " + str(bool(avg_flag)) + " \n")
    ff.close()


def startMeasurement():
    print("Pezzo di merda")
    if float(min_pos_entry.get()) > 0:
        min_pos_entry.insert(0, "-")

    pPercent.configure(text="0%")
    pProgress.set(0)
    load_cell_menu.configure(state="disabled")
    min_pos_entry.configure(state="disabled")
    max_pos_entry.configure(state="disabled")
    num_pos_entry.configure(state="disabled")
    startButton.configure(state="disabled")

    global min_pos, max_pos, num_pos

    min_pos = float(min_pos_entry.get())
    max_pos = float(max_pos_entry.get())
    num_pos = int(num_pos_entry.get())

    print(min_pos)
    print(max_pos)
    print(num_pos)

    Thread(target=saveState).start()
    t = Thread(target=serialListener)
    t.start()
    # return


def serialListener():
    global percent
    with serial.Serial("COM9", 9600) as ser:
        while True:
            if keyboard.is_pressed("q"):
                print("Exiting")
                ser.close()
                break
            try:
                data = ser.readline()
            except:
                print("SeiScemo")

            data = data.decode()
            print(data)

            if compare_strings(data, "Ready"):
                print(data)

            if compare_strings(data, "loadcell"):
                ser.write(str(loadcell_fullscale).encode())

            if compare_strings(data, "min_pos"):
                ser.write(str(min_pos).encode())

            if compare_strings(data, "max_pos"):
                ser.write(str(max_pos).encode())

            if compare_strings(data, "num_pos"):
                ser.write(str(num_pos).encode())

            if compare_strings(data, "media"):
                ser.write(str(avg_flag).encode())
            
            if compare_strings(data, "Index"):
                i = int(data.split()[1])
                percent = float((i+1)/num_pos)
                pPercent.configure(text=str(int(percent*100))+"%")
                pProgress.set(percent)


            if compare_strings(data, "Finished"):
                # print("matched")
                ser.close()
                break

    load_cell_menu.configure(state="normal")
    min_pos_entry.configure(state="normal")
    max_pos_entry.configure(state="normal")
    num_pos_entry.configure(state="normal")
    startButton.configure(state="normal")
    


# appearance
customtkinter.set_appearance_mode("light")
customtkinter.set_default_color_theme("blue")

#############################################################################
# ----------------------------------------------------------------------------
#############################################################################

# create app
app = customtkinter.CTk()
app.geometry("780x540")
app.title("MyApp")

# app.grid_columnconfigure(0, weight=1)
# app.grid_rowconfigure(0, weight=1)

leftFrame = customtkinter.CTkFrame(app, 100, 500, fg_color="lightgray")
leftFrame.pack(side=customtkinter.LEFT, padx=20, pady=20, fill="y", expand=False, anchor="w")

rightFrame = customtkinter.CTkFrame(app, 500, 500, fg_color="darkgray")
rightFrame.pack(side=customtkinter.LEFT, padx=20, pady=20, fill="both", expand=True)

# leftFrame.grid_columnconfigure(0, weight=1)
# leftFrame.grid_rowconfigure(0, weight=1)
# rightFrame.grid_columnconfigure(0, weight=1)
# rightFrame.grid_rowconfigure(0, weight=1)

#############################################################################
# ----------------------------------------------------------------------------
#############################################################################

loadcell_label = customtkinter.CTkLabel(leftFrame, 
                                        text="Selezionare cella di carico",
                                        anchor="s")


load_cell_menu = customtkinter.CTkOptionMenu(
    leftFrame, values=["1 kg", "3 kg", "10 kg", "50 kg"], command=setLoadCell
)
load_cell_menu.set(str(loadcell_fullscale) + " kg")


min_pos_label = customtkinter.CTkLabel(leftFrame, 
                                       text="Posizione negativa massima", 
                                       anchor="s")

min_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(min_pos))
)
if float(min_pos_entry.get())>0: 
    min_pos_entry.insert(0, "-")


max_pos_label = customtkinter.CTkLabel(leftFrame, 
                                       text="Posizione positiva massima",
                                       anchor="s")

max_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(max_pos))
)


num_pos_label = customtkinter.CTkLabel(leftFrame, 
                                       text="Numero pari di punti spaziali",
                                       anchor="s")

num_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(num_pos))
)


checkbox = customtkinter.CTkCheckBox(leftFrame, text="Media", command=setAvgFlag)
checkbox.configure(variable=customtkinter.BooleanVar(app, avg_flag))


# create start button
startButton = customtkinter.CTkButton(
    leftFrame, text="START", height=50, command=startMeasurement
)


# plotts
figure = plt.Figure(dpi=100)
ax = figure.add_subplot(111)
chart_type = FigureCanvasTkAgg(figure, rightFrame)
chart_type.get_tk_widget().pack(fill="both", expand=True, side=customtkinter.TOP, pady=20, padx=20)

# progress barr
progressFrame = customtkinter.CTkFrame(rightFrame, 500, 40, fg_color="black")
progressFrame.pack(anchor="s", padx=20, pady=20, fill="x", expand=True, )

progressFrame.grid_columnconfigure(1, weight=2)
pPercent = customtkinter.CTkLabel(progressFrame, text="0%", text_color="white")
pProgress  = customtkinter.CTkProgressBar(progressFrame)
pProgress.set(percent)

pPercent.grid(row=0, column=0, sticky="ew", padx=5, pady=5)
pProgress.grid(row=0, column=1, sticky="ew", padx=10, pady=5)


# positioning
leftFrame.grid_rowconfigure(0, weight=1)
leftFrame.grid_rowconfigure(2, weight=1)
leftFrame.grid_rowconfigure(4, weight=1)
leftFrame.grid_rowconfigure(6, weight=1)
leftFrame.grid_rowconfigure(8, weight=2)
leftFrame.grid_rowconfigure(9, weight=3)


loadcell_label.grid(row=0, column=0, pady=10, padx=20, sticky="w")
load_cell_menu.grid(row=1, column=0, padx=20, sticky="w")

min_pos_label.grid(row=2, column=0, pady=10, padx=20, sticky="w")
min_pos_entry.grid(row=3, column=0, padx=20, sticky="w")

max_pos_label.grid(row=4, column=0, pady=10, padx=20, sticky="w")
max_pos_entry.grid(row=5, column=0, padx=20, sticky="w")

num_pos_label.grid(row=6, column=0, pady=10, padx=20, sticky="w")
num_pos_entry.grid(row=7, column=0, padx=20, sticky="w")

checkbox.grid(row=8, column=0, padx=20, sticky="w")
startButton.grid(row=9, column=0, padx=20, sticky="ew")




app.mainloop()
