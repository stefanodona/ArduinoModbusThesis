import json
from playsound import playsound

import tkinter as tk
from tkinter import ttk
import customtkinter as ctk
import os
import sys
import numpy as np

# playsound("./GUI/Finish.wav")

parameters = {
    "stat_creep_flag": 1,
    "loadcell_fullscale": 1,
    "min_pos": -10.0,
    "max_pos": 10.0,
    "num_pos": 0,
    "avg_flag": 0,
    "ar_flag": 0,
    "th1_val": 5.0,
    "th1_avg": 5,
    "th2_val": 12.0,
    "th2_avg": 3,
    "th3_val": 15.0,
    "th3_avg": 2,
    "vel_flag": 1,
    "vel_max": 50.0,
    "acc_max": 5,
    "time_flag": 0,
    "time_max": 0.5,
    "creep_displ": 10.0,
    "creep_period": 100.0,
    "creep_duration": 15.0,
}

# my_json = json.dumps(parameters, indent=4)

# file = open("provajson.json", 'r')
# parameters2 = json.loads(file.read())
# file.close()
# # print("p1: ",parameters)
# # print("p2: ",parameters2)

# # playsound("GUI/Finish.wav")

# # root = tk.Tk()
# ctk.set_appearance_mode("light")

# root = ctk.CTk()
# root.geometry("600x600")
# # width = root.winfo_screenwidth()
# root.update_idletasks()
# width_root = root.winfo_width()
# print(width_root)

# # button = ttk.Button(root, width=int(0.5*width_root))
# button1 = ctk.CTkButton(root, text="1")
# button2 = ctk.CTkButton(root, text="2", fg_color="gray")
# button2.pack(side = ctk.BOTTOM, expand=True, padx = 10, pady = 20)
# button1.pack(side = ctk.BOTTOM, expand=True, padx = 10, pady = 20)

# label = ctk.CTkLabel(root, text='cacca \n e premere OK')
# label.pack(padx=50, pady=50, side=ctk.BOTTOM, expand=True, anchor='center')

# # print(root.winfo_reqwidth())
# # print(button.winfo_width())
# root.bind('<Escape>', root.destroy)
# root.mainloop()

# path = os.getcwd()
# path = os.path.abspath(sys.argv[0])

# path = os.path.splitext(path)[0] + ".txt"
# path = os.path.split(path)[0]
# path = os.path.join(path, "ciao.txt")

# c = np.array([])
# c = np.empty((1,2))
# c = np.empty((0,2))
# x = [[1,2]]
# c=np.vstack([c,x])#, axis=0)
# c=np.vstack([c,[3,4]])#, axis=0)
# c=np.vstack([c,[5,6]])#, axis=0)
# c=np.append(c, [(1,2)], axis=0)


# print(c)
# print()

# for i in range(0,len(c)):
#      print(f"{c[i][0]:.5f}"+"\t"+f"{c[i][1]:.5f}"+"\t")
#      print(f"{c[i][0]:.5f}"+"\t"+f"{c[i][1]:.5f}"+"\n")
# print(np.array([]))

from deep_translator import GoogleTranslator
from deep_translator import DeeplTranslator

text_it = "Impostazioni\nSoglie e Medie"
translated = GoogleTranslator(source='italian', target='english').translate(text_it)

print(translated)
