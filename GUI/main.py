from tkinter import *
from tkinter import ttk
import tkinter as tk
from tkinter import Misc, font
from tkinter.filedialog import asksaveasfile, asksaveasfilename, askopenfile, askopenfilename 
from tkinter import simpledialog
from typing import Optional, Tuple, Union
import customtkinter
import serial
import json
from math import floor
import struct
import numpy as np
import re  # used to compare strings
import keyboard
import time
from datetime import datetime
from threading import Thread
import os
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
import serial.tools.list_ports


#############################################################################
# ------------------------------C L A S S E S--------------------------------
#############################################################################
class ThrAvgFrame(customtkinter.CTkFrame):
    def __init__(self, master: any, width: int = 200, height: int = 200, corner_radius: int | str | None = None, border_width: int | str | None = None, bg_color: str | Tuple[str, str] = "transparent", fg_color: str | Tuple[str, str] | None = None, border_color: str | Tuple[str, str] | None = None, background_corner_colors: Tuple[str | Tuple[str, str]] | None = None, overwrite_preferred_drawing_method: str | None = None, name: str | None=None, slider_val: float | None=None, avg_num: int | None=None, **kwargs):
        super().__init__(master, width, height, corner_radius, border_width, bg_color, fg_color, border_color, background_corner_colors, overwrite_preferred_drawing_method, **kwargs)
        self.slider_val = customtkinter.DoubleVar(self, np.clip(slider_val, 1, max_pos))
        self.avg_val = customtkinter.StringVar(self, str(avg_num))

        self.sliderlabel = customtkinter.CTkLabel(self, 
                                                  text = name+" [mm]",
                                                  )
        self.sliderlabel.grid(row=0, column=0, columnspan=3, padx=10, pady=10)

        self.slider = customtkinter.CTkSlider(self, 
                                              from_ = 1, 
                                              to = max_pos,
                                              number_of_steps = (max_pos-1)*2,
                                              variable = self.slider_val,
                                              command = self.sliderChanged)
        self.slider.grid(row=1, column=1, padx=5, pady=5)

        self.slider_lowerbound = customtkinter.CTkLabel(self, text=str(1))
        self.slider_lowerbound.grid(row=1, column=0, padx=5)
        
        self.slider_upperbound = customtkinter.CTkLabel(self, text=str(max_pos))
        self.slider_upperbound.grid(row=1, column=2, padx=5)

        self.slider_value_label = customtkinter.CTkLabel(self, text=str(self.slider_val.get()))
        self.slider_value_label.grid(row=2, column=1, padx=10)

        self.avglabel = customtkinter.CTkLabel(self, text = "# Medie")
        self.avglabel.grid(row=0, column=4, padx=10, pady=10)

        self.avg_entry = customtkinter.CTkEntry(self, width=50, textvariable=self.avg_val)
        self.avg_entry.grid(row=1, column=4, padx=10, pady=10, sticky="e")

        self.dummy_spacer = customtkinter.CTkLabel(self, text="")
        self.dummy_spacer.grid(row=0, column=3, padx=20)
    
    def sliderChanged(self, event):
        slider_val = self.slider_val.get()
        self.slider_value_label.configure(text=str(slider_val))


class ThrAvgWindows(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(*args, fg_color=fg_color, **kwargs)
        # self.geometry("500x400")
        self.title("Soglie e Medie")

        self.label = customtkinter.CTkLabel(self, 
                                            text="Impostazioni\nSoglie e Medie",
                                            font=('Segoe UI', 14))
        self.label.pack(padx=20, pady=10)
        # print(font.nametofont('TkTextFont').actual())

        self.th1 = ThrAvgFrame(self, name="Soglia 1", slider_val=th1_val, avg_num=th1_avg)
        self.th1.pack(padx=10, pady=10, fill="x", expand=True)

        self.th2 = ThrAvgFrame(self, name="Soglia 2", slider_val=th2_val, avg_num=th2_avg)
        self.th2.pack(padx=10, pady=10, fill="x", expand=True)

        self.th3 = ThrAvgFrame(self, name="Soglia 3", slider_val=th3_val, avg_num=th3_avg)
        self.th3.pack(padx=10, pady=10, fill="x", expand=True)

        self.th1.slider_val.trace('w', callback=self.getWinState)
        self.th1.avg_val.trace('w', callback=self.getWinState)

        self.th2.slider_val.trace('w', callback=self.getWinState)
        self.th2.avg_val.trace('w', callback=self.getWinState)

        self.th3.slider_val.trace('w', callback=self.getWinState)
        self.th3.avg_val.trace('w', callback=self.getWinState)


        # self.grab_set()
    def getWinState(self, *args):
        global th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg

        th1_val = self.th1.slider_val.get()
        if (not self.th1.avg_val.get()==''): 
            th1_avg = int(self.th1.avg_val.get())

        th2_val = self.th2.slider_val.get()
        if (not self.th2.avg_val.get()==''): 
            th2_avg = int(self.th2.avg_val.get())

        th3_val = self.th3.slider_val.get()
        if (not self.th3.avg_val.get()==''): 
            th3_avg = int(self.th3.avg_val.get())
        saveState()


class VelAccWindows(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(*args, fg_color=fg_color, **kwargs)
        self.title("Velocità e Accelerazione")

        # --- VARIABLES --- #
        self.vel_max_tkvar = customtkinter.StringVar(self, str(vel_max))
        self.acc_max_tkvar = customtkinter.StringVar(self, str(acc_max))
        self.time_max_tkvar = customtkinter.StringVar(self, str(time_max))

        self.vel_bool_tkvar = customtkinter.BooleanVar(self, vel_flag)
        self.time_bool_tkvar = customtkinter.BooleanVar(self, time_flag)

        # --- ELEMENTS --- #
        self.label = customtkinter.CTkLabel(self, 
                                            text="Impostazioni\nVelocita' e Accelerazione",
                                            font=('Segoe UI', 14))
        self.label.pack(padx=20, pady=10)

        self.vel_frame = customtkinter.CTkFrame(self)
        self.vel_frame.pack(padx=10, pady=10, fill='x', expand=True)

        self.time_frame = customtkinter.CTkFrame(self)
        self.time_frame.pack(padx=10, pady=10, fill='x', expand=True)

        # --- VELOCITY --- #
        self.vel_checkbox = customtkinter.CTkCheckBox(self.vel_frame, text="velocita' costante", variable=self.vel_bool_tkvar, command=self.vel_chk_pressed)
        self.vel_checkbox.grid(row=0, column=0, padx=10, pady=10, sticky='w', columnspan=2)

        self.vel_entry = customtkinter.CTkEntry(self.vel_frame, width=50, textvariable=self.vel_max_tkvar)
        self.vel_entry_label = customtkinter.CTkLabel(self.vel_frame, text="Velocita' [rps]")

        self.acc_entry = customtkinter.CTkEntry(self.vel_frame, width=50, textvariable=self.acc_max_tkvar)
        self.acc_entry_label = customtkinter.CTkLabel(self.vel_frame, text="Accelerazione [rps^2]")

        self.vel_entry.grid(row=1, column=0, padx=10, pady=5, sticky='w')
        self.vel_entry_label.grid(row=1, column=1, padx=10, pady=5, sticky='w')

        self.acc_entry.grid(row=2, column=0, padx=10, pady=5, sticky='w')
        self.acc_entry_label.grid(row=2, column=1, padx=10, pady=5, sticky='w')

        # --- TIME --- #
        self.time_checkbox = customtkinter.CTkCheckBox(self.time_frame, text="tempo costante", variable=self.time_bool_tkvar, command=self.time_chk_pressed)
        self.time_checkbox.grid(row=0, column=0, padx=10, pady=10, sticky='w', columnspan=2)

        self.time_entry = customtkinter.CTkEntry(self.time_frame, width=50, textvariable=self.time_max_tkvar)
        self.time_entry_label = customtkinter.CTkLabel(self.time_frame, text="Tempo [s]")

        self.time_entry.grid(row=1, column=0, padx=10, pady=5, sticky='w')
        self.time_entry_label.grid(row=1, column=1, padx=10, pady=5, sticky='w')

        self.update_state()

        # self.vel_checkbox.trace('w', callback=self.getState)
        # self.time_checkbox.trace('w', callback=self.getState)

        self.vel_bool_tkvar.trace('w', callback=self.getState)
        self.time_bool_tkvar.trace('w', callback=self.getState)
        self.vel_max_tkvar.trace('w', callback=self.getState)
        self.acc_max_tkvar.trace('w', callback=self.getState)
        self.time_max_tkvar.trace('w', callback=self.getState)



    def update_state(self, *args):
        states = [customtkinter.DISABLED, customtkinter.NORMAL]

        self.vel_entry.configure(state = states[self.vel_checkbox.get()])
        self.acc_entry.configure(state = states[self.vel_checkbox.get()])
        self.time_entry.configure(state = states[self.time_checkbox.get()])
            

    def vel_chk_pressed(self, *args):
        if(self.vel_checkbox.get()):
            self.time_checkbox.deselect()
        else:
            self.time_checkbox.select()
        self.update_state()


    def time_chk_pressed(self, *args):
        if(self.time_checkbox.get()):
            self.vel_checkbox.deselect()
        else:
            self.vel_checkbox.select()
        self.update_state()

    def getState(self, *args):
        global vel_flag, vel_max, acc_max, time_flag, time_max
        vel_flag = self.vel_bool_tkvar.get()
        time_flag = self.time_bool_tkvar.get()

        if (not self.vel_entry.get()==""):
            vel_max = float(self.vel_entry.get())

        if (not self.acc_entry.get()==""):
            acc_max = float(self.acc_entry.get())
        
        if (not self.time_entry.get()==""):
            time_max = float(self.time_entry.get())

        saveState()

class SaveDialog(simpledialog.Dialog):
    # def __init__(self, parent: Misc | None, title: str | None = None) -> None:
        # super().__init__(parent, title)
    def body(self, master):
        self.label = tk.Label(master, text="Attenzione!\nDati non salvati")
        # self.button_frame = tk.Frame(self)

        
        self.label.pack(padx=50, pady=50)
        # self.button_frame.pack(padx=5, pady=5)

        # self.save_button.grid(row=0, column=0)
        # self.discard_button.grid(row=0, column=1)
        # self.cancel_button.grid(row=0, column=2)
    def buttonbox(self):

        self.box = Frame(self)
        self.save_button = Button(self.box, text="Salva", command=save, default=ACTIVE)
        self.discard_button = Button(self.box, text="Non Salvare", command=closeAll)
        self.cancel_button = Button(self.box, text="Annulla", command=self.cancel)

        self.save_button.pack(side=LEFT, padx=15, pady=5)
        self.discard_button.pack(side=LEFT, padx=15, pady=5)
        self.cancel_button.pack(side=LEFT, padx=15, pady=5)

        self.bind("<Return>", self.ok)
        self.bind("<Escape>", self.cancel)

        self.box.pack()




#############################################################################
# ----------------------------V A R I A B L E S------------------------------
#############################################################################
this_path = os.getcwd()
# config_path = os.path.join(this_path, "GUI\config.txt")
config_path = os.path.join(this_path, "GUI\config.json")
print(config_path)

port = "COM9"
spider_name = ''
saved_flag = False
panic_flag = False
last_params = None

txt_path='' 
json_path=''

# load state
f = open(config_path, "r")
params = json.loads(f.read())
f.close()

stat_creep_flag = params["stat_creep_flag"]
loadcell_fullscale = params["loadcell_fullscale"]
min_pos = params["min_pos"]
max_pos = params["max_pos"]
num_pos = params["num_pos"]
avg_flag = bool(params["avg_flag"])
ar_flag = bool(params["ar_flag"])
th1_val = params["th1_val"]
th1_avg = params["th1_avg"]
th2_val = params["th2_val"]
th2_avg = params["th2_avg"]
th3_val = params["th3_val"]
th3_avg = params["th3_avg"]
vel_flag = bool(params["vel_flag"])
vel_max = params["vel_max"]
acc_max = params["acc_max"]
time_flag = bool(params["time_flag"])
time_max = params["time_max"]
creep_displ = params["creep_displ"]
creep_period = params["creep_period"]
creep_duration = params["creep_duration"]

tare = 0
percent = 0
max_iter = 0
meas_forward = True

# arrays for static measurement 
force = np.array([])
force_ritorno = np.array([])
pos = np.array([])
pos_sorted = np.array([])

# arrays for creep measurement
time_axis = np.array([])

thr_avg_window = None
vel_acc_window = None

# cnt = 0


#############################################################################
# ----------------------------F U N C T I O N S------------------------------
#############################################################################
def compare_strings(string1, string2):
    pattern = re.compile(string2)
    match = re.search(pattern, string1)
    return match


def setAvgFlag():
    global avg_flag
    avg_flag = checkbox.get()

def setARFlag():
    global ar_flag
    ar_flag = checkbox_AR.get()


def setLoadCell(val):
    global loadcell_fullscale
    # global loadcell_fullscale
    # str = load_cell_menu.get()#.split()
    # print(str)
    loadcell_fullscale = int(val.split()[0])
    saveState()
    # print(loadcell_fullscale) 


def setAvgCnt(val):
    # global cnt
    cnt = 1
    if avg_flag:
        if abs(val) <= th3_val:
            cnt = th3_avg
        if abs(val) <= th2_val:
            cnt = th2_avg
        if abs(val) <= th1_val:
            cnt = th1_avg
    return cnt


def populatePosArray():
    global pos, pos_sorted, max_iter
    pos = np.linspace(min_pos, max_pos, num_pos)
    minus=np.flip(pos[0:int(num_pos/2)])
    plus=pos[int(num_pos/2):]

    sor=[]
    for i in range(0, int(num_pos/2)):
        sor.append(plus[i])
        sor.append(minus[i])
    pos_sorted = np.array(sor)

    # sort = np.argsort(-np.abs(np.round(pos,2)))
    # pos_sorted = np.flip(pos[sort])

    max_iter = 0
    j = 0
    while j < num_pos:
        if avg_flag:
            max_iter = max_iter + setAvgCnt(pos_sorted[j])
        else:
            max_iter = max_iter + 1
        j = j + 2
    max_iter = max_iter * 2
    if ar_flag:
        max_iter *= 2
    # print(num_pos)
    # print("max iter: ", max_iter)
    if (stat_creep_flag):
        max_iter = int(creep_duration*1000/creep_period)


def saveState():
    global params
    ff = open(config_path, "w")
    for key in params:
        params[key] = globals()[key]
    ff.write(json.dumps(params,indent=4))
    ff.close()


def pressOk(msg):
    topLevel = customtkinter.CTkToplevel(app)
    topLevel.geometry("300x300")

    okButton = customtkinter.CTkButton(topLevel, text="OK", command=topLevel.destroy)
    okButton.pack(side=customtkinter.BOTTOM, pady=50)

    label = customtkinter.CTkLabel(topLevel, text=str(msg)+'\n e premere OK')
    label.pack(padx=50, pady=50, side=customtkinter.BOTTOM)
    topLevel.focus()
    while(topLevel.winfo_exists()):
        pass


def startMeasurement():
    os.system('cls')
    if float(min_pos_entry.get()) > 0:
        min_pos_entry.insert(0, "-")

    pPercent.configure(text="0%")
    pProgress.set(0)

    load_cell_menu.configure(state="disabled")
    min_pos_entry.configure(state="disabled")
    max_pos_entry.configure(state="disabled")
    num_pos_entry.configure(state="disabled")
    startButton.configure(state="disabled")
    checkbox.configure(state="disabled")
    checkbox_AR.configure(state="disabled")

    displ_entry.configure(state="disabled")
    period_entry.configure(state="disabled")
    duration_entry.configure(state="disabled")


    startButton.configure(text="Initializing...")

    global min_pos, max_pos, num_pos, percent, force, force_ritorno, pos, pos_sorted, time_axis, creep_displ, creep_period, creep_duration

    min_pos = float(min_pos_entry.get())
    max_pos = float(max_pos_entry.get())
    num_pos = int(num_pos_entry.get())

    creep_displ = float(displ_entry.get())
    creep_period = float(period_entry.get())
    creep_duration = float(duration_entry.get())

    if num_pos % 2 == 1:
        num_pos += 1
        num_pos_entry.configure(textvariable=customtkinter.StringVar(app, str(num_pos)))

    # print(min_pos)
    # print(max_pos)
    # print(num_pos)

    force = np.array([])
    force_ritorno = np.array([])
    pos = np.array([])
    pos_sorted = np.array([])
    time_axis = np.array([])

    populatePosArray()
    print(pos)
    print(pos_sorted)

    percent = 0

    # Thread(target=saveState).start()
    saveState()
    Thread(target=serialListener).start()
    # return

def prepareMsgSerialParameters():
    # global loadcell_fullscale, min_pos, max_pos, num_pos, avg_flag, ar_flag, th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg
    param_array = [stat_creep_flag,
                   loadcell_fullscale, 
                   min_pos, max_pos, num_pos, 
                   avg_flag, ar_flag, 
                   th1_val, th1_avg, 
                   th2_val, th2_avg, 
                   th3_val, th3_avg,
                   vel_flag, vel_max, acc_max,
                   time_flag, time_max]
    msg = ''
    for param in param_array:
        if isinstance(param, bool):
            msg += str(int(param)) + " "
        else:
            msg+= str(param)+" "
    return msg



def serialListener():
    global pos,  pos_sorted, percent, force, force_ritorno, time_axis, max_iter, meas_forward, panic_flag
    print(port)
    with serial.Serial("COM9", 38400) as ser:
        index = 0
        iter_count = 0
        meas_index = 0
        while True:
            # if panic_flag:
            #     print("ER PANICO!")
            #     ser.write("PANIC\n".encode())
            #     ser.close()
            #     panic_flag = False
            #     break

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
                # print("adesso te manno")
                ser.write("Ready to write\n".encode())

            if compare_strings(data, "Parameters"):
                # time.sleep(0.5)
                msg = prepareMsgSerialParameters()
                ser.write(msg.encode())
                print(data)

            # if data == "loadcell\n":
            #     if ser.writable():
            #         ser.write(str(loadcell_fullscale).encode())

            # if data == "min_pos\n":
            #     ser.write(str(min_pos).encode())

            # if data == "max_pos\n":
            #     ser.write(str(max_pos).encode())

            # if data == "num_pos\n":
            #     ser.write(str(num_pos).encode())

            # if data == "media\n":
            #     ser.write(str(int(avg_flag)).encode())

            # if data == "a_r\n":
            #     ser.write(str(int(ar_flag)).encode())

            if data == "Connecting\n":
                print(data)
                startButton.configure(text="Connecting...")

            if data == "Measure Routine\n":
                startButton.configure(text="Getting Data...")

            if data == "Measuring\n":
                print(data)
                startButton.configure(text="Measuring...")

            if compare_strings(data, "centratore"):
                pressOk(data)
                time.sleep(1)
                ser.write("\n".encode())

            # if compare_strings(data, "send me"):
            if data == "send me\n":
                msg = ''
                if (not stat_creep_flag):   # static mode
                    for p in pos_sorted:
                        msg += str(p)+" "    
                else:
                    msg+= str(creep_displ) +" "
                    msg+= str(creep_period) +" "
                    msg+= str(creep_duration) +" "
                ser.write(msg.encode())
                

            if data == "check percent\n":
                iter_count += 1
                percent = iter_count / max_iter
                pPercent.configure(text=str(int(percent * 100)) + "%")
                pProgress.set(percent)

            if data == "andata\n":
                meas_forward = True
            if data == "ritorno\n":
                meas_forward = False

            if compare_strings(data, "val"):
                # print(data.split())
                meas_val = float(data.split()[1])
                print(meas_val)
                if (not stat_creep_flag):
                    if meas_forward:
                        force = np.append(force, meas_val)
                    else:
                        force_ritorno = np.append(force_ritorno, meas_val)
                else:
                    force = np.append(force, meas_val)

            if compare_strings(data, "tare"):
                globals()["tare"]=float(data.split()[1])
            

            if compare_strings(data, "time_ax"):
                time_val = float(data.split()[1])
                time_axis= np.append(time_axis, time_val) 
                

            if compare_strings(data, "Finished"):
                # print("matched")
                print(data)
                pPercent.configure(text="DONE")
                ser.close()
                break

    load_cell_menu.configure(state="normal")
    min_pos_entry.configure(state="normal")
    max_pos_entry.configure(state="normal")
    num_pos_entry.configure(state="normal")
    checkbox.configure(state="normal")
    checkbox_AR.configure(state="normal")
    startButton.configure(state="normal")

    displ_entry.configure(state="normal")
    period_entry.configure(state="normal")
    duration_entry.configure(state="normal")

    startButton.configure(text="START")
    print("force: ",force)
    print("Force_ret: ",force_ritorno)
    print("Time: ",time_axis)

    # TODO: da testare
    if (not stat_creep_flag):
        pos_sorted= np.append(pos_sorted,0)
        sort = np.argsort(pos_sorted)
        pos = pos_sorted[sort]
        force = np.append(force, tare)
        force = force[sort]
        if(ar_flag):
            force_ritorno = np.append(force_ritorno, tare)
            force_ritorno = force_ritorno[sort]
    
    print("pos: ",pos)
    print("force: ",force)
    print("Force_ret: ",force_ritorno)
    print("Time: ",time_axis)
    drawPlots()



def drawPlots():
    # plotts
    ax_force.clear()
    ax_stiff.clear()
    # global pos, force, force_ritorno, time_axis

    if not creep_bool_tkvar.get():
        ax_force.plot(pos, force)
        if(ar_flag):
            ax_force.plot(pos, force_ritorno)
            ax_force.legend(["Andata", "Ritorno"])
        ax_force.set_xlabel("displacement [mm]")
        ax_force.set_ylabel("force [N]")
        ax_force.set_title("Force vs Displacement")
        ax_force.grid(visible=True, which="both", axis="both")

        # avoid dividing by 0
        idx = list(range(len(pos)))
        idx.remove(floor(len(pos)/2))

        ax_stiff.plot(pos[idx], np.nan_to_num(force[idx]/pos[idx]))
        if (ar_flag):
            ax_stiff.plot(pos[idx], np.nan_to_num(force_ritorno[idx]/pos[idx]))
            ax_stiff.legend(["Andata", "Ritorno"])
        ax_stiff.set_xlabel("displacement [mm]")
        ax_stiff.set_ylabel("stiffness [N/mm]")
        ax_stiff.set_title("Stiffness vs Displacement")
        ax_stiff.grid(visible=True, which="both", axis="both")
    else:
        ax_force.plot(time_axis, force)
        # if(ar_flag):
        #     ax_force.plot(x, y2)
        #     ax_force.legend(["Andata", "Ritorno"])
        ax_force.set_xlabel("time [ms]")
        ax_force.set_ylabel("force [N]")
        ax_force.set_title("Force vs Time")
        ax_force.grid(visible=True, which="both", axis="both")

        ax_stiff.plot(time_axis, np.nan_to_num(force/creep_displ))
        # if (ar_flag):
        #     ax_stiff.plot(x, np.nan_to_num(y2 / x))
        #     ax_stiff.legend(["Andata", "Ritorno"])
        ax_stiff.set_xlabel("time [ms]")
        ax_stiff.set_ylabel("stiffness [N/mm]")
        ax_stiff.set_title("Stiffness vs Time")
        ax_stiff.grid(visible=True, which="both", axis="both")


    chart_type_force.draw()
    chart_type_stiff.draw()


def panic():
    global panic_flag
    panic_flag=True
    # return

def thr_and_avg_setting_func():
    global thr_avg_window 
    if (thr_avg_window==None or not thr_avg_window.winfo_exists()):
        thr_avg_window = ThrAvgWindows(app)
    
    thr_avg_window.focus()
    # topWindow.grab_set()
    app.update()

def vel_and_acc_setting_func():
    global vel_acc_window 
    if (vel_acc_window==None or not vel_acc_window.winfo_exists()):
        vel_acc_window = VelAccWindows(app)
    
    vel_acc_window.focus()
    # topWindow.grab_set()
    app.update()

def setCOMPort():
    global port
    port = COM_option.get()
    print(port)

def showFrame():
    global stat_creep_flag
    stat_creep_flag = bool(creep_switch.get())
    print(stat_creep_flag)
    if(not stat_creep_flag):
        showStaticFrame()
        creep_switch.configure(text="Statica")
    else:
        showCreepFrame()
        creep_switch.configure(text="Creep")
    saveState()

def updateTkVars():
    creep_bool_tkvar.set(stat_creep_flag)
    load_cell_menu.set(str(loadcell_fullscale) + " kg")
    spider_name_tkvar.set(spider_name)
    min_pos_tkvar.set(str(min_pos))
    max_pos_tkvar.set(str(max_pos))
    num_pos_tkvar.set(str(num_pos))
    avg_flag_tkvar.set(avg_flag)
    ar_flag_tkvar.set(ar_flag)
    creep_displ_tkvar.set(str(creep_displ))
    creep_period_tkvar.set(str(creep_period))
    creep_duration_tkvar.set(str(creep_duration))

# def get_and_saveTkVars():
#     global params, saved_flag
#     for key in params:
#         name = key+"_tkvar"
#         if name in globals():
#             var = globals()[name].get()
#             if (key=="loadcell_fullscale"):
#                 globals()[key] = int(var.split()[0])
#             else:     
#                 if isinstance(var, str) and not var=='':
#                     globals()[key] = float(var)
#     saved_flag=False
#     saveState()

def tkvar_changed():
    global saved_flag
    saveState()
    saved_flag = False


def closeAll():
    ports = serial.tools.list_ports.comports()
    for com in ports:
        # if (com[0]=="COM9"):
        if (com[0]==port):
          try:
              ser = serial.Serial(com.device)
              ser.close()
              print(f"Chiusa porta {com}")
          except serial.SerialException as e:
              print(f"Errore chiusura porta {com}: {e}")

    app.destroy()

def save_data(txt_path, json_path):
    global saved_flag, last_params
    root_name = os.path.splitext(txt_path)[0]
    with open(txt_path, 'w') as fl:
        fl.write("# Acquired on "+ datetime.now().strftime("%d/%m/%Y %H:%M:%S") +" \n")
        fl.write("# SPIDER: " + spider_name_tkvar.get() + "\n")
        if np.any(force):
            if(not stat_creep_flag):
                fl.write("# STATIC MEASUREMENT\n\n")
                fl.write("# pos [mm]\t\tforce_forw [N]\t\tforce_back [N]\n")
                for i in range(0,len(pos)):
                    if (ar_flag):
                            fl.write(f"{pos[i]:.3f}"+"\t\t\t"+ f"{force[i]:.3f}" +"\t\t\t" + f"{force_ritorno[i]:.3f}" +"\n")   
                    else:
                            fl.write(f"{pos[i]:.3f}"+"\t\t\t"+ f"{force[i]:.3f}"+"\t\t\t"+ f"{0:.3f}" +"\n")   
            else:
                fl.write("# CREEP MEASUREMENT\n\n")
                fl.write("# time [ms]\t\tforce [N]\t\tstiffness [N/mm]\n")
                for i in range(0,len(force)):
                    fl.write(f"{time_axis[i]:.3f}" +"\t\t\t"+ f"{force[i]:.3f}" +"\t\t\t"+ f"{force[i]/creep_displ:.3f}" + "\n")
        fl.close()

    saveState()
    with open(json_path, 'w') as js:
        js.write(json.dumps(params, indent=4))
        js.close()
    saved_flag=True
    app.title("MyApp - "+root_name)
    last_params = params


def save_as(): 
    global txt_path, json_path
    files = [('All Files', '*.*'),  
             ('Python Files', '*.py'), 
             ('Text Document', '*.txt')] 
    file_path = asksaveasfilename(initialfile = spider_name_tkvar.get()+'.txt',
                         filetypes = files, 
                         defaultextension = ".txt") 
    
    if file_path:
        folder = os.path.splitext(file_path)[0]
        name = folder.split('/')[-1]
        os.makedirs(folder, exist_ok=True)
        txt_path = os.path.join(folder,name+".txt")
        json_path = os.path.join(folder,name+".json")
        print(file_path)

        save_data(txt_path, json_path)
        
def save():
    if (not saved_flag):
        save_as()
    else:
        file_name = (os.path.splitext(txt_path)[0]).split('/')[-1]
        if(not file_name==spider_name_tkvar.get()):
            save_as()
        else:
            save_data(txt_path, json_path)

def load():
    global time_axis, pos, force, force_ritorno, params, saved_flag, last_params
    files = [('All Files', '*.*'),  
             ('Python Files', '*.py'), 
             ('Text Document', '*.txt')] 
    file_path = askopenfilename(defaultextension=".txt", filetypes=files)

    name = os.path.splitext(file_path)[0]

    if file_path:
        #apri json
        with open(name+'.json', 'r') as js:
            params = json.loads(js.read())
            for key in params:
                globals()[key] = params[key]
            js.close()
            updateTkVars()
            saveState()

        with open(file_path, 'r') as fl:
            fl.readline() # date time 
            spider_name_tkvar.set(fl.readline().split()[2])
            stat_creep = fl.readline().split()[1]
            fl.readline() # empty line
            fl.readline() # axis specification

            if stat_creep=="STATIC":
                p = []
                f = []
                f_r = []
                while True:
                    line = fl.readline()
                    data = line.split("\t\t\t")
                    if not line:
                        break
                    if not data[0]=="":
                        p.append(float(data[0]))
                        f.append(float(data[1]))
                        f_r.append(float(data[2]))

                pos = np.array(p)
                force = np.array(f)
                force_ritorno = np.array(f_r)


            elif stat_creep=="CREEP":
                t = []
                f = []
                while True:
                    line = fl.readline()
                    data = line.split("\t\t\t")
                    if not line:
                        break
                    if not data[0]=="":
                        t.append(float(data[0]))
                        f.append(float(data[1]))
                        # print(t)
                        # np.append(time_axis, t)
                        # np.append(force, f)

                time_axis = np.array(t)
                force = np.array(f)
            else:
                print("ERRORE NEL CARICAMENTO")

            fl.close()
        
        showFrame()
        drawPlots()    
        app.title("MyApp - "+ name)
        last_params = params
        saved_flag=True


def check_save_before_closing():
    if (not saved_flag):
        savedialog = SaveDialog(app)
    else:
        closeAll()
    

#############################################################################
# ---------------------------C R E A T E   A P P-----------------------------
#############################################################################
# appearance
customtkinter.set_appearance_mode("light")
customtkinter.set_default_color_theme("blue")

# create app
app = customtkinter.CTk()
app.geometry("900x700")
app.title("MyApp")


leftFrame = customtkinter.CTkFrame(app, 250, 500, fg_color="darkgray")
leftFrame.pack_propagate(0)
leftFrame.pack(
    side=customtkinter.LEFT, padx=20, pady=20, fill="y", expand=False, anchor="w"
)

creep_bool_tkvar = customtkinter.BooleanVar(app, stat_creep_flag)
creep_switch = customtkinter.CTkSwitch(leftFrame, text="Mode", command=showFrame, variable=creep_bool_tkvar)
creep_switch.pack(pady=10)


staticFrame = customtkinter.CTkFrame(leftFrame, 290, fg_color="lightgray")
creepFrame = customtkinter.CTkFrame(leftFrame, 290, fg_color="lightgray")
staticFrame.grid_propagate(0)
creepFrame.grid_propagate(0)



rightFrame = customtkinter.CTkFrame(app, 500, 500, fg_color="darkgray")
rightFrame.pack(side=customtkinter.LEFT, padx=20, pady=20, fill="both", expand=True)

def donothing():
   filewin = Toplevel(app)
   button = Button(filewin, text="Do nothing button")
   button.pack()

#############################################################################
# -------------------------C R E A T E   M E N U'----------------------------
#############################################################################
menubar = Menu(app)

filemenu = Menu(menubar, tearoff=0)
filemenu.add_command(label="New", command=donothing)
filemenu.add_command(label="Open", command=load)
filemenu.add_command(label="Save", command=donothing)
filemenu.add_command(label="Save as...", command=save_as)
filemenu.add_separator()
filemenu.add_command(label="Exit", command=app.quit)

menubar.add_cascade(label="File", menu=filemenu)


velacc_window = None
settingmenu = Menu(menubar, tearoff=0)
settingmenu.add_command(label="Vel & Acc", command=vel_and_acc_setting_func)
settingmenu.add_command(label="Medie & Soglie", command=thr_and_avg_setting_func)

menubar.add_cascade(label="Impostazioni", menu=settingmenu)

COM_menu = Menu(settingmenu, tearoff=0)
COM_list = serial.tools.list_ports.comports()
COM_option = tk.StringVar(app, port)
COM_option.trace('w', callback=lambda *args:setCOMPort())

for COM_port in COM_list:
    # COM_menu.add_command(label=str(COM_port))
    COM_menu.add_radiobutton(label=str(COM_port), variable=COM_option, value=COM_port[0])
    # print(COM_port[0])

settingmenu.add_cascade(label="Serial Ports", menu=COM_menu)

#############################################################################
# ----------------------------E L E M E N T S--------------------------------
#############################################################################


# ========================== #
# -----  T K - V A R S ----- #
# ========================== #

spider_name_tkvar = customtkinter.StringVar(app, spider_name)
loadcell_fullscale_tkvar = customtkinter.StringVar(app, str(loadcell_fullscale)+" kg")
min_pos_tkvar = customtkinter.StringVar(app, str(min_pos))
max_pos_tkvar = customtkinter.StringVar(app, str(max_pos))
num_pos_tkvar = customtkinter.StringVar(app, str(num_pos))
avg_flag_tkvar = customtkinter.BooleanVar(app, avg_flag)
ar_flag_tkvar = customtkinter.BooleanVar(app, ar_flag)
creep_displ_tkvar = customtkinter.StringVar(app, str(creep_displ))
creep_period_tkvar = customtkinter.StringVar(app, str(creep_period))
creep_duration_tkvar = customtkinter.StringVar(app, str(creep_duration))

spider_name_tkvar.trace('w', callback=lambda *args: tkvar_changed())
loadcell_fullscale_tkvar.trace('w', callback=lambda *args: tkvar_changed())
min_pos_tkvar.trace('w', callback=lambda *args: tkvar_changed())
max_pos_tkvar.trace('w', callback=lambda *args: tkvar_changed())
num_pos_tkvar.trace('w', callback=lambda *args: tkvar_changed())
avg_flag_tkvar.trace('w', callback=lambda *args: tkvar_changed())
ar_flag_tkvar.trace('w', callback=lambda *args: tkvar_changed())
creep_displ_tkvar.trace('w', callback=lambda *args: tkvar_changed())
creep_period_tkvar.trace('w', callback=lambda *args: tkvar_changed())
creep_duration_tkvar.trace('w', callback=lambda *args: tkvar_changed())




#############################################################################

spider_entry = customtkinter.CTkEntry(leftFrame, textvariable=spider_name_tkvar, placeholder_text="Culo")

loadcell_label = customtkinter.CTkLabel(
    leftFrame, text="Selezionare cella di carico", anchor="s"
)


load_cell_menu = customtkinter.CTkOptionMenu(
    leftFrame, values=["1 kg", "3 kg", "10 kg", "50 kg"], variable=loadcell_fullscale_tkvar,  command=setLoadCell
    # leftFrame, values=["1 kg", "3 kg", "10 kg", "50 kg"], variable=loadcell_fullscale_tkvar
)
# load_cell_menu.set(str(loadcell_fullscale) + " kg")


min_pos_label = customtkinter.CTkLabel(
    staticFrame, text="Posizione negativa massima", anchor="s"
)

min_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=min_pos_tkvar
)
if float(min_pos_entry.get()) > 0:
    min_pos_entry.insert(0, "-")


max_pos_label = customtkinter.CTkLabel(
    staticFrame, text="Posizione positiva massima", anchor="s"
)

max_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=max_pos_tkvar
)


num_pos_label = customtkinter.CTkLabel(
    staticFrame, text="Numero pari di punti spaziali", anchor="s"
)

num_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=num_pos_tkvar
)


checkbox = customtkinter.CTkCheckBox(staticFrame, text="Media", command=setAvgFlag)
checkbox.configure(variable=avg_flag_tkvar)

checkbox_AR = customtkinter.CTkCheckBox(staticFrame, text="Andata e Ritorno", command=setARFlag)
checkbox_AR.configure(variable=ar_flag_tkvar)



displ_entry_label = customtkinter.CTkLabel(creepFrame, text="Spostamento desiderato [mm]", anchor="s")
displ_entry = customtkinter.CTkEntry(creepFrame, textvariable=creep_displ_tkvar)

period_entry_label = customtkinter.CTkLabel(creepFrame, text="Intervallo di misura [ms]", anchor="s")
period_entry = customtkinter.CTkEntry(creepFrame, textvariable=creep_period_tkvar)

duration_entry_label = customtkinter.CTkLabel(creepFrame, text="Durata della misura [s]", anchor="s")
duration_entry = customtkinter.CTkEntry(creepFrame, textvariable=creep_duration_tkvar)


# create start button
startButton = customtkinter.CTkButton(
    leftFrame, text="START", height=50, command=startMeasurement
)




#############################################################################
# -------------------------------P L O T S-----------------------------------
#############################################################################

plot_tabview = customtkinter.CTkTabview(rightFrame)
plot_tabview.pack(padx=20, pady=0, fill="both", expand=True)
plot_tabview.add("Force")
plot_tabview.add("Stiffness")

figure_force = plt.Figure(dpi=100)
ax_force = figure_force.add_subplot(111)
ax_force.set_xlabel("displacement [mm]")
ax_force.set_ylabel("force [N]")
ax_force.set_title("Force vs Displacement")
ax_force.grid(visible=True, which="both")
chart_type_force = FigureCanvasTkAgg(figure_force, plot_tabview.tab("Force"))
chart_type_force.get_tk_widget().pack(
    fill="both", expand=True, side=customtkinter.TOP, pady=20, padx=20, anchor="n"
)
toolbar_force = NavigationToolbar2Tk(
    chart_type_force, plot_tabview.tab("Force"), pack_toolbar=False
)
toolbar_force.pack(fill="x", expand=False, padx=20, pady=5, anchor="n")

figure_stiff = plt.Figure(dpi=100)
ax_stiff = figure_stiff.add_subplot(111)
ax_stiff.set_xlabel("displacement [mm]")
ax_stiff.set_ylabel("stiffness [N/mm]")
ax_stiff.set_title("Stiffness vs Displacement")
ax_stiff.grid(visible=True, which="both")
chart_type_stiff = FigureCanvasTkAgg(figure_stiff, plot_tabview.tab("Stiffness"))
chart_type_stiff.get_tk_widget().pack(
    fill="both", expand=True, side=customtkinter.TOP, pady=20, padx=20, anchor="n"
)
toolbar_stiff = NavigationToolbar2Tk(
    chart_type_stiff, plot_tabview.tab("Stiffness"), pack_toolbar=False
)
toolbar_stiff.pack(fill="x", expand=False, padx=20, pady=5, anchor="n")


#############################################################################
# ------------------------P R O G R E S S   B A R----------------------------
#############################################################################

# progress barr
progressFrame = customtkinter.CTkFrame(rightFrame, 500, 40, fg_color="black")
progressFrame.pack(
    anchor="s", padx=10, pady=20, fill="x", expand=True, side=customtkinter.LEFT
)

panicButton = customtkinter.CTkButton(
    rightFrame,
    70,
    40,
    text="PANIC",
    fg_color="red",
    hover_color="dark red",
    command=panic,
)
panicButton.pack(side=customtkinter.LEFT, padx=10, pady=20, anchor="s")

progressFrame.grid_columnconfigure(1, weight=2)
pPercent = customtkinter.CTkLabel(progressFrame, text="0%", text_color="white")
pProgress = customtkinter.CTkProgressBar(progressFrame)
pProgress.set(percent)

pPercent.grid(row=0, column=0, sticky="e", padx=5, pady=5)
pProgress.grid(row=0, column=1, sticky="ew", padx=10, pady=5)

#############################################################################
# --------------------------P O S I T I O N I N G----------------------------
#############################################################################

# loadcell_label.grid(row=0, column=0, pady=10, padx=20, sticky="w")
# load_cell_menu.grid(row=1, column=0, padx=20, sticky="w")
spider_entry.pack(padx=10, pady=10)
loadcell_label.pack(padx=20)
load_cell_menu.pack(pady=10, padx=20)

# positioning
def showStaticFrame():
    creepFrame.pack_forget()
    staticFrame.pack(padx=10, fill="y", expand=True, anchor="w")
    # staticFrame.grid_rowconfigure(1, weight=1)
    staticFrame.grid_rowconfigure(3, weight=1)
    staticFrame.grid_rowconfigure(5, weight=1)
    staticFrame.grid_rowconfigure(7, weight=1)
    staticFrame.grid_rowconfigure(8, weight=2)
    staticFrame.grid_rowconfigure(9, weight=2)
    # staticFrame.grid_rowconfigure(10, weight=3)


    min_pos_label.grid(row=2, column=0, pady=10, padx=20, sticky="w")
    min_pos_entry.grid(row=3, column=0, padx=20, sticky="w")

    max_pos_label.grid(row=4, column=0, pady=10, padx=20, sticky="w")
    max_pos_entry.grid(row=5, column=0, padx=20, sticky="w")

    num_pos_label.grid(row=6, column=0, pady=10, padx=20, sticky="w")
    num_pos_entry.grid(row=7, column=0, padx=20, sticky="w")

    checkbox.grid(row=8, column=0, padx=20, sticky="w", pady=10)
    checkbox_AR.grid(row=9, column=0, padx=20, sticky="w", pady=10)
    app.update()

def showCreepFrame():
    staticFrame.pack_forget()
    creepFrame.pack(padx=10, fill="y", expand=True, anchor="w")

    creepFrame.grid_rowconfigure(2, weight=1)
    creepFrame.grid_rowconfigure(4, weight=1)
    creepFrame.grid_rowconfigure(6, weight=1)
    creepFrame.grid_rowconfigure(7, weight=8)

    displ_entry_label.grid(row=1, column=0, pady=10, padx=20, sticky="w")    
    displ_entry.grid(row=2, column=0, padx=20, sticky="w")    

    period_entry_label.grid(row=3, column=0, pady=10, padx=20, sticky="w")    
    period_entry.grid(row=4, column=0, padx=20, sticky="w")    

    duration_entry_label.grid(row=5, column=0, pady=10, padx=20, sticky="w")    
    duration_entry.grid(row=6, column=0, padx=20, sticky="w")    

# startButton.grid(row=10, column=0, padx=20, sticky="ew")
startButton.pack(padx=20, pady=20, side=customtkinter.BOTTOM)

showFrame()
app.config(menu=menubar)

# savedialog = simpledialog.Dialog(app)
# savedialog = SaveDialog(app)

app.protocol("WM_DELETE_WINDOW", check_save_before_closing)

app.bind('<Return>', lambda e: startMeasurement())
app.bind('<Escape>', lambda e: closeAll())
app.bind("<Control-s>", lambda e: save())
app.bind("<Control-o>", lambda e: load())
app.mainloop()



