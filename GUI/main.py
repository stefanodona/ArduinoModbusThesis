# import tkthread; tkthread.patch()
import tkthread; tkthread.tkinstall()

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
from math import floor, pi, cos, sin
import struct
import numpy as np
import re  # used to compare strings
# import keyboard
import time
from datetime import datetime
from threading import Thread
import os
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
import serial.tools.list_ports
from playsound import playsound
from PIL import ImageTk
from tabulate import tabulate
from PyInstaller.utils.hooks import collect_data_files
from saving_presets import *


datas = collect_data_files('tkthread')

## ciao prova

#############################################################################
# ------------------------------C L A S S E S--------------------------------
#############################################################################
# class Meter(customtkinter.CTkToplevel):
#     def __init__(self, master, bounds, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
#         super().__init__(master, *args, fg_color=fg_color, **kwargs)

#         self.frame = customtkinter.CTkFrame(self)
#         self.frame.pack()
#         self.var = tk.IntVar(self, 0)

#         self.canvas = customtkinter.CTkCanvas(self.frame, width=400, height=220,
#                                 borderwidth=2, relief='sunken',
#                                 bg='white')
#         # self.scale = tk.Scale(self, orient='horizontal', from_=-50, to=50, variable=self.var)
        
        
        
#         self.angle = 90
#         span = 140 # degrees
#         self.bounds = bounds



#         col = ["light gray","red","yellow","green"]
#         for i in range(int(len(bounds)/2)):
#             span_i = span/(bounds[1]-bounds[0])*(bounds[i*2+1]-bounds[i*2])
#             print(i)
#             print(span_i)
#             print("____")
#             start_angle_i = (180-span_i)/2
#             self.canvas.create_arc(10, 10, 390, 390, extent=span_i, start=start_angle_i,
#                                    style='pieslice', fill=col[i])
            
#         self.center = self.canvas.create_line(200, 10, 200, 40,
#                                             fill='white',
#                                             width=3)
        
#         self.meter = self.canvas.create_line(200, 200, 20, 200,
#                                              fill='black',
#                                              width=8,
#                                              arrow='last')

#         self.canvas.pack(fill='both')
#         # self.scale.pack()

#         self.var.trace_add('write', self.updateMeter)  # if this line raises an error, change it to the old way of adding a trace: self.var.trace('w', self.updateMeter)

#     def updateMeterLine(self, a):
#         """Draw a meter line"""
#         self.angle = a

#         x = 200 - 190 * cos(a * pi / 180)
#         y = 200 - 190 * sin(a * pi / 180)
#         self.canvas.coords(self.meter, 200, 200, x, y)

#     def updateMeter(self, op):
#         """Convert variable to angle on trace"""
#         # mini = self.scale.cget('from')
#         # maxi = self.scale.cget('to')
#         mini = self.bounds[0]
#         maxi = self.bounds[1]
#         pos = (op - mini) / (maxi - mini)
#         # self.updateMeterLine(pos * 0.6 + 0.2)
#         self.updateMeterLine(20+pos*140)


class ThrAvgFrame(customtkinter.CTkFrame):
    def __init__(self, master: any, width: int = 200, height: int = 200, corner_radius: int | str | None = None, border_width: int | str | None = None, bg_color: str | Tuple[str, str] = "transparent", fg_color: str | Tuple[str, str] | None = None, border_color: str | Tuple[str, str] | None = None, background_corner_colors: Tuple[str | Tuple[str, str]] | None = None, overwrite_preferred_drawing_method: str | None = None, name: str | None=None, slider_val: float | None=None, avg_num: int | None=None, **kwargs):
        super().__init__(master, width, height, corner_radius, border_width, bg_color, fg_color, border_color, background_corner_colors, overwrite_preferred_drawing_method, **kwargs)
        max_pos = float(max_pos_tkvar.get())
        step = float(step_pos_tkvar.get())

        self.slider_val = customtkinter.DoubleVar(self, np.round(np.clip(slider_val, step, max_pos),2))
        self.avg_val = customtkinter.StringVar(self, str(avg_num))

        self.sliderlabel = customtkinter.CTkLabel(self, 
                                                  text = name+" [mm]",
                                                  )
        self.sliderlabel.grid(row=0, column=0, columnspan=3, padx=10, pady=10)

        self.slider = customtkinter.CTkSlider(self, 
                                              from_ = step, 
                                              to = max_pos,
                                              number_of_steps = (max_pos-step)/step,
                                              variable = self.slider_val,
                                              command = self.sliderChanged)
        self.slider.grid(row=1, column=1, padx=5, pady=5)

        self.slider_lowerbound = customtkinter.CTkLabel(self, text=str(1))
        self.slider_lowerbound.grid(row=1, column=0, padx=5)
        
        self.slider_upperbound = customtkinter.CTkLabel(self, text=str(max_pos))
        self.slider_upperbound.grid(row=1, column=2, padx=5)

        self.slider_value_label = customtkinter.CTkLabel(self, text=str(np.round(self.slider_val.get(), 2)))
        self.slider_value_label.grid(row=2, column=1, padx=10)

        self.avglabel = customtkinter.CTkLabel(self, text = "# Medie")
        self.avglabel.grid(row=0, column=4, padx=10, pady=10)

        self.avg_entry = customtkinter.CTkEntry(self, width=50, textvariable=self.avg_val)
        self.avg_entry.grid(row=1, column=4, padx=10, pady=10, sticky="e")

        self.dummy_spacer = customtkinter.CTkLabel(self, text="")
        self.dummy_spacer.grid(row=0, column=3, padx=20)
    
    def sliderChanged(self, event):
        slider_val = round(self.slider_val.get(),2)
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

        self.th1.slider_val.trace_add('write', callback=self.getWinState)
        self.th1.avg_val.trace_add('write', callback=self.getWinState)

        self.th2.slider_val.trace_add('write', callback=self.getWinState)
        self.th2.avg_val.trace_add('write', callback=self.getWinState)

        self.th3.slider_val.trace_add('write', callback=self.getWinState)
        self.th3.avg_val.trace_add('write', callback=self.getWinState)


        # self.grab_set()
    def getWinState(self, *args):
        global th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg

        th1_val = round(self.th1.slider_val.get(),2)
        if (not self.th1.avg_val.get()==''): 
            th1_avg = int(self.th1.avg_val.get())

        th2_val = round(self.th2.slider_val.get(),2)
        if (not self.th2.avg_val.get()==''): 
            th2_avg = int(self.th2.avg_val.get())

        th3_val = round(self.th3.slider_val.get(),2)
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

        self.vel_bool_tkvar.trace_add('write', callback=self.getState)
        self.time_bool_tkvar.trace_add('write', callback=self.getState)
        self.vel_max_tkvar.trace_add('write', callback=self.getState)
        self.acc_max_tkvar.trace_add('write', callback=self.getState)
        self.time_max_tkvar.trace_add('write', callback=self.getState)



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

class MovePistWindow(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(*args, fg_color=fg_color, **kwargs)
        self.title("Reset Piston")

        self.reset_button = customtkinter.CTkButton(self, text="Reset Piston", height=50, font=('Helvetica', 18, 'bold'), command=self.resetPiston)
        self.reset_button.grid(row=0, column=0, columnspan=2, padx=50, pady=20, sticky="ew")

        # self.up_button = customtkinter.CTkButton(self, text="˄", font=('Helvetica', 20, 'bold'))
        # self.up_button.grid(row=1, column=0, padx=[50, 25], pady=20)

        # self.down_button = customtkinter.CTkButton(self, text="˅", font=('Helvetica', 20, 'bold'))
        # self.down_button.grid(row=1, column=1, padx=[25, 50], pady=20)

        # self.stop_button = customtkinter.CTkButton(self, text="STOP", fg_color="red", hover_color="dark red", height=50, font=('Helvetica', 18, 'bold'))
        # self.stop_button.grid(row=2, column=0, columnspan=2, padx=50, pady=20, sticky="ew")
    
    def resetPiston(self,*args):
        Thread(target=tkt(self.serialResetPiston)).start()
    
    def serialResetPiston(self, *args):
        with serial.Serial(port, 38400) as ser:
            while True:
                try:
                    data = ser.readline()
                except:
                    print("DATO NON LETTO!")

                data = data.decode()
                print(data)

                if compare_strings(data, "Ready"):
                    time.sleep(1)
                    ser.write("GO HOME\n".encode())

                if compare_strings(data, "HOMED"):
                    break
        time.sleep(1)
        return



class WeightsWindows(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(*args, fg_color=fg_color, **kwargs)
        self.title("Supports Weights")

        self.up_disk_w_tkvar = customtkinter.StringVar(self, str(up_disk_weight))
        self.dw_disk_w_tkvar = customtkinter.StringVar(self, str(dw_disk_weight))
        self.vc_coil_w_tkvar = customtkinter.StringVar(self, str(vc_coil_weight))

        self.label_1 = customtkinter.CTkLabel(self, text="Upper disk weight [g]: ")
        self.label_2 = customtkinter.CTkLabel(self, text="Lower disk weight [g]: ")
        self.label_3 = customtkinter.CTkLabel(self, text="Voice coil weight [g]: ")

        self.entry_1 = customtkinter.CTkEntry(self, textvariable=self.up_disk_w_tkvar)
        self.entry_2 = customtkinter.CTkEntry(self, textvariable=self.dw_disk_w_tkvar)
        self.entry_3 = customtkinter.CTkEntry(self, textvariable=self.vc_coil_w_tkvar)

        self.label_1.pack(padx=30, pady=[20,0])
        self.entry_1.pack(padx=30, pady=[0,10])
        self.label_2.pack(padx=30, pady=[20,0])
        self.entry_2.pack(padx=30, pady=[0,10])
        self.label_3.pack(padx=30, pady=[20,0])
        self.entry_3.pack(padx=30, pady=[0,20])

        self.okButton = customtkinter.CTkButton(self, text="OK", height=50, command=self.update_state).pack(padx=30, pady=20)

    def update_state(self, *args):
        globals()["up_disk_weight"] = float(self.up_disk_w_tkvar.get())
        globals()["dw_disk_weight"] = float(self.dw_disk_w_tkvar.get())
        globals()["vc_coil_weight"] = float(self.vc_coil_w_tkvar.get())
        saveState()

class TrackEvolutionWindow(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(*args, fg_color=fg_color, **kwargs)
        self.snap_path = ""
        # creazione locale delle variabili, così da non intaccare le originali
        self.pos = np.transpose(t_track)[0]
        self.force = np.transpose(t_track)[1]
        self.time = np.transpose(t_track)[2]
        print(self.pos)

        self.title("Tracking Stiffness Evolution")
        self.geometry("900x600")

        self.control_frame = customtkinter.CTkFrame(self)
        self.plot_frame = customtkinter.CTkFrame(self)

        self.plot_frame.pack(padx=10, pady=10, fill='both', expand=True)
        self.control_frame.pack(padx=10, pady=10, fill='x', expand=False)

        figure_st = plt.Figure(dpi=100, figsize=(1,1))
        self.ax_st = figure_st.add_subplot(111)
        self.ax_st.set_xlabel("displacement [mm]")
        self.ax_st.set_ylabel("force [N]")
        self.ax_st.set_title("Force vs Displacement")
        self.ax_st.grid(visible=True, which="both")
        self.chart_type_st = FigureCanvasTkAgg(figure_st, self.plot_frame)
        self.chart_type_st.get_tk_widget().pack(
            fill="both", expand=True, side=customtkinter.TOP, pady=(20,0), padx=20, anchor="n"
        )
        self.toolbar_st = NavigationToolbar2Tk(
            self.chart_type_st, self.plot_frame, pack_toolbar=False
        )
        self.toolbar_st.pack(fill="x", expand=False, padx=20, pady=(5,20), anchor="n")

        self.slider_frame = customtkinter.CTkFrame(self.control_frame)
        self.ar_checkbox = customtkinter.CTkSwitch(self.control_frame, text="Show Back", command=self.slider_changed)
        self.save_btn = customtkinter.CTkButton(self.control_frame, text="Save Curve", command=self.save_this_curve)
        self.save_all_btn = customtkinter.CTkButton(self.control_frame, text="Save All Curves")

        self.ar_checkbox.pack(padx=(50,10), pady=10, side="left")
        self.slider_frame.pack(padx=(0,10), pady=10, side="left")
        self.save_btn.pack(padx=(0,10), pady=10, side="left")
        self.save_all_btn.pack(padx=(0,10), pady=10, side="left")

        self.slider_val = customtkinter.DoubleVar(self,100)
        # self.slider_val_str = customtkinter.StringVar(self, str(self.slider_val.get()))
        self.timestamp_slider = customtkinter.CTkSlider(self.slider_frame, from_=100, to=wait_time, number_of_steps=round(wait_time/100)-1, variable=self.slider_val, command=self.slider_changed)

        self.slider_label = customtkinter.CTkLabel(self.slider_frame, text="Timestamp\nSlider")
        # self.slider_val_label = customtkinter.CTkLabel(self.slider_frame, textvariable=self.slider_val_str)
        self.slider_val_label = customtkinter.CTkLabel(self.slider_frame, text=str(self.slider_val.get())+" ms")

        self.slider_label.pack(padx=10,pady=10,side="left")
        self.timestamp_slider.pack(padx=10,pady=10,side="left")
        self.slider_val_label.pack(padx=10,pady=10,side="left", expand=False)
        self.slider_changed()

    def slider_changed(self, *args):
        self.pos_to_plot = []
        # self.stiff_to_plot = []
        self.force_to_plot = []
        self.pos_to_plot_r = []
        self.force_to_plot_r = []
        self.stiff_array=[[],[]]
        # self.slider_val_str.set(str(self.slider_val.get()))
        self.slider_val_label.configure(text=str(self.slider_val.get())+" ms")
        val = self.slider_val.get()
        
        if not tracking_flag:
            return
        else:
            idx = int(val/100 - 1) 
            inc = int(wait_time/100)
            # print(idx)
            
            idx_inc = 0
            i = 0
            while True:
                
                if not ar_flag:
                    if idx+idx_inc >= len(self.pos):
                        break
                    self.pos_to_plot.append(self.pos[idx + idx_inc])
                    self.force_to_plot.append(self.force[idx + idx_inc])
                
                else:
                    if idx+idx_inc >= len(self.pos):
                        break
                    if idx+idx_inc <= len(self.pos)/2:
                        self.pos_to_plot.append(self.pos[idx + idx_inc])
                        self.force_to_plot.append(self.force[idx + idx_inc])
                    else:
                        self.pos_to_plot_r.append(self.pos[idx + idx_inc])
                        self.force_to_plot_r.append(self.force[idx + idx_inc])


                # print(idx + idx_inc)
                idx_inc += 10
                
                #non prendere quando passa per lo 0 ma solo spostamenti positivi e negativi
                i+=1
                if i==2:
                    idx_inc+=10
                    i=0
            
            self.pos_to_plot = np.array(self.pos_to_plot)
            self.force_to_plot = np.array(self.force_to_plot)

            sort = np.argsort(self.pos_to_plot)
            self.pos_to_plot = self.pos_to_plot[sort]
            self.force_to_plot = self.force_to_plot[sort]

            if ar_flag and self.ar_checkbox.get():
                self.pos_to_plot_r = np.array(self.pos_to_plot_r)
                self.force_to_plot_r = np.array(self.force_to_plot_r)
                sort = np.argsort(self.pos_to_plot_r)
                self.pos_to_plot_r = self.pos_to_plot_r[sort]
                self.force_to_plot_r = self.force_to_plot_r[sort]


            if ar_flag and self.ar_checkbox.get():
                self.pos_array = [self.pos_to_plot, self.pos_to_plot_r]
                self.force_array = [self.force_to_plot, self.force_to_plot_r]
            else:
                self.pos_array = [self.pos_to_plot]
                self.force_array = [self.force_to_plot]

            for i in np.arange(0,len(self.pos_array)):

                if postprocessing_flag_tkvar.get():
                    degree = fit_order.get()[0]
                    if degree != "N":
                        degree = int(degree)
                        print(degree)

                        # FORW STIFF FIT
                        # coeff = np.polyfit(self.pos_to_plot, -self.force_to_plot/self.pos_to_plot, degree, w=np.abs(self.pos_to_plot))
                        # stiff_forw_fitted = np.polyval(coeff, self.pos_to_plot)
                        # self.stiff_to_plot = stiff_forw_fitted 

                        coeff = np.polyfit(self.pos_array[i], -self.force_array[i]/self.pos_array[i], degree, w=np.abs(self.pos_array[i]))
                        stiff_forw_fitted = np.polyval(coeff, self.pos_array[i])
                        self.stiff_array[i] = stiff_forw_fitted 

                    else:
                        f_DC = np.interp(0, self.pos_array[i], self.force_array[i])
                        # print(f_DC)
                        self.stiff_array[i] = -(self.force_array[i]-f_DC)/self.pos_array[i]
                else:
                    self.stiff_array[i] = -self.force_array[i]/self.pos_array[i]

            self.drawTrackingPlot()


    def drawTrackingPlot(self, *args):
        self.ax_st.clear()
        for i in np.arange(0,len(self.pos_array)):
            self.ax_st.plot(self.pos_array[i], self.stiff_array[i])
            if i>=1:
                BF_legend = ["Forw", "Back"]
                self.ax_st.legend(BF_legend)
        self.ax_st.set_xlabel("displacement [mm]")
        self.ax_st.set_ylabel("stiffness [N/mm]")
        self.ax_st.set_title("Stiffness vs Displacement")
        self.ax_st.grid(visible=True, which="both", axis="both")
        self.chart_type_st.draw()

    def save_this_curve(self, *args):
        initialfile = spider_name_tkvar.get()+"_snap_"+str(int(self.slider_val.get()))+" ms"
        self.save(initialfile)
        array_to_save = []
        # array_to_save = np.transpose([self.pos_array, self.force_array, self.stiff_array])
        for i in range(0, len(self.pos_array)):
            array_to_save.append(np.transpose([self.pos_array[i], self.force_array[i], self.stiff_array[i]]))
        write_stiff_file(array_to_save, spider_name_tkvar.get(), "tracking_this_curve", self.snap_path, self.slider_val.get())

    def file_in_dir_exists (self, dir_name, *args):
        for file_name in os.listdir(dir_name):
                if file_name.endswith(".stsnap"):
                    return True
        return False

    def save(self, initial_name, *args):
        files = [('Static Stiffness Test Snapshot', '*.stsnap'),
                ('Text Files', '*.txt'), 
                ('All Files', '*.*')]

        file_path = asksaveasfilename(initialfile = initial_name+'.stsnap',
                            filetypes = files, 
                            defaultextension = ".stsnap") 
        
        if file_path:
            root = os.path.split(file_path)[0]
            folder = root

            # if not os.path.exists(file_path) and not os.path.exists(folder):
            #     os.makedirs(folder, exist_ok=True)
            if not self.file_in_dir_exists(root):
                folder_name = "Tracking Snapshots"
                folder = os.path.join(root, folder_name)
                os.makedirs(folder, exist_ok=True)

            name = os.path.split(file_path)[-1]
            self.snap_path = os.path.join(folder,name)
            print(file_path)
            print(folder)
            print(name)
            



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
        self.save_button = ttk.Button(self.box, text="Salva", command=save, default=ACTIVE)
        self.discard_button = ttk.Button(self.box, text="Non Salvare", command=closeAll)
        self.cancel_button = ttk.Button(self.box, text="Annulla", command=self.cancel)

        self.save_button.pack(side=LEFT, padx=15, pady=5)
        self.discard_button.pack(side=LEFT, padx=15, pady=5)
        self.cancel_button.pack(side=LEFT, padx=15, pady=5)

        self.bind("<Return>", self.ok)
        self.bind("<Escape>", self.cancel)

        self.box.pack()

class ConfirmTopLevel(customtkinter.CTkToplevel):
    def __init__(self, *args, fg_color: str | tuple[str, str] | None = None, **kwargs):
        global confirm_flag
        confirm_flag = False
        super().__init__(*args, fg_color=fg_color, **kwargs)
        # self.okVar = customtkinter.BooleanVar(self, False)

        self.title("Conferma Azione")

        self.labelText = customtkinter.StringVar(self, "Test")    

        self.okButton = customtkinter.CTkButton(self, text="OK", command=self.okPressed)
        self.cancelButton = customtkinter.CTkButton(self, text="Annulla", fg_color="gray", command=self.cancelPressed)
         
        # okButton.pack(side=customtkinter.LEFT, pady=20)
        self.cancelButton.pack(side = customtkinter.BOTTOM, expand=True, padx = 10, pady = 20)
        self.okButton.pack(side = customtkinter.BOTTOM, expand=True, padx = 10)
        
        # cancelButton.pack(side=customtkinter.BOTTOM, pady=50)
        
        self.label = customtkinter.CTkLabel(self, textvariable=self.labelText)
        self.label.pack(padx=50, pady=50, side=customtkinter.BOTTOM)
        self.focus()
        # self.wait_variable(self.okVar)
        # app.wait_window(self)


    def okPressed(self, *args):
        # self.okVar.set(True)
        global confirm_flag
        confirm_flag = True
        self.destroy()
        self.update()


    def cancelPressed(self, *args):
        # self.okVar.set(False)
        global confirm_flag
        confirm_flag = False
        # globals()["serial_thread"].interrupt()
        # globals()["serial_thread"].join()
        self.destroy()
        self.update()

    def setMessage(self, msg, *args):
        self.labelText.set(str(msg)+"\n e premere ok")


#############################################################################
# ----------------------------V A R I A B L E S------------------------------
#############################################################################
this_path = os.getcwd()
print(this_path)
# config_path = os.path.join(this_path, "GUI\config.txt")
config_path = os.path.join(this_path, "GUI/config.json")
default_path = os.path.join(this_path, "GUI/default_state.json")
print(config_path)

port = "COM9"
spider_name = ''
saved_flag = True
panic_flag = False
last_params = None
confirm_flag = False

tracking_flag = False

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
step_pos = params["step_pos"]
wait_time = params["wait_time"]
avg_flag = bool(params["avg_flag"])
ar_flag = bool(params["ar_flag"])
tracking_flag = bool(params["tracking_flag"])
th1_val = params["th1_val"]
th1_avg = params["th1_avg"]
th2_val = params["th2_val"]
th2_avg = params["th2_avg"]
th3_val = params["th3_val"]
th3_avg = params["th3_avg"]
zero_approx = params["zero_approx"]
zero_avg = params["zero_avg"]
vel_flag = bool(params["vel_flag"])
vel_max = params["vel_max"]
acc_max = params["acc_max"]
time_flag = bool(params["time_flag"])
time_max = params["time_max"]
creep_displ = params["creep_displ"]
creep_period = params["creep_period"]
creep_duration = params["creep_duration"]
search_zero_flag =  params["search_zero_flag"]
up_disk_weight =  params["up_disk_weight"]
dw_disk_weight =  params["dw_disk_weight"]
vc_coil_weight =  params["vc_coil_weight"]


tare = 0
percent = 0
max_iter = 0
meas_forward = True

# arrays for static measurement 
force = np.array([])
dev_force = np.array([])
force_ritorno = np.array([])
dev_force_ritorno = np.array([])
pos = np.array([])
pos_sorted = np.array([])

pos_acquired = np.array([])
dev_pos_acquired = np.array([])
pos_acquired_ritorno = np.array([])
dev_pos_acquired_ritorno = np.array([])

# stiff_forw = np.array([])
# stiff_back = np.array([])

zero_f = np.array([])
zero_p = np.array([])

t_rise = np.array([])
t_fall = np.array([])
t_start = np.array([])
t_end = np.array([])

t_track = np.empty((0,3))

# ax_name: 
#   - pos_forw
#   - force_forw
#   - pos_back
#   - force_back
#   - t_track
#   - t_creep
#   - force_creep

main_data_dict = {"ax_name":[],
                  "val":[]}

# arrays for creep measurement
time_axis = np.array([])

thr_avg_window = None
vel_acc_window = None
move_piston_window = None
weights_window = None
gauge_window = None

track_evol_window = None


STATIC = 10
CREEP = 11
TRACKING = 12  

#############################################################################
# ----------------------------F U N C T I O N S------------------------------
#############################################################################
def compare_strings(string1, string2):
    pattern = re.compile(string2)
    match = re.search(pattern, string1)
    return match


def setAvgFlag():
    global avg_flag
    avg_flag = bool(avg_flag_tkvar.get())
    print("SetAvgFlag: ", avg_flag)

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
    if abs(val) == zero_approx:
        cnt = zero_avg
    return cnt


def populatePosArray():
    global pos, pos_sorted, max_iter, num_pos, step_pos
    # pos = np.linspace(min_pos, max_pos, num_pos)

    pos = np.arange(min_pos, max_pos+step_pos, step_pos)

    if not pos[-1]==max_pos:
        pass    
    # pos = np.array([-10, -9.5, -9, -8.5, -8, -7.5, -7, -6.5, -6, -5.5, 5, -4.5, -4, -3.5, -3, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.95, -0.9,  -0.85, -0.8, -0.75, -0.7, -0.65, -0.6, -0.55, -0.5, -0.45, -0.4, -0.35, -0.3, -0.25, -0.2, -0.15, -0.1, -0.05, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10])

    pos = pos[abs(pos)>0.0025]
    num_pos = len(pos)

    minus=np.flip(pos[0:int(num_pos/2)])
    plus=pos[int(num_pos/2):]

    sor=[]
    for i in range(0, int(num_pos/2)):
        sor.append(plus[i])
        sor.append(minus[i])
    pos_sorted = np.array(sor)
    # pos_sorted = np.append([zero_approx, -zero_approx], pos_sorted)
    num_pos = len(pos_sorted)

    print(pos_sorted)
    
    max_iter = 0

    if (stat_creep_flag):
        max_iter = int(creep_duration*1000/creep_period)
    else:
        j = 0
        while j < num_pos:
            # if avg_flag:
            max_iter = max_iter + setAvgCnt(pos_sorted[j])
            # else:
                # max_iter = max_iter + 1
            j = j + 2
        max_iter *= 2
        if ar_flag:
            max_iter *= 2

    print(max_iter)

def saveState():
    global params
    ff = open(config_path, "w")
    for key in params:
        params[key] = globals()[key]
    ff.write(json.dumps(params,indent=4))
    ff.close()

def setPanic(var):
    globals()["panic_flag"]=var


def pressOk(the_msg):
    toplevel = ConfirmTopLevel(app)
    toplevel.setMessage(the_msg)

    app.wait_window(toplevel)
    print(toplevel)

    time.sleep(0.5)

# def check_avg_checkbox():
#     if tracking_flag:
#         checkbox.configure(state="disabled")



def startMeasurement():
    os.system('cls')
    if float(min_pos_entry.get()) > 0:
        min_pos_entry.insert(0, "-")


    global min_pos, max_pos, num_pos, step_pos, wait_time, percent, force, dev_force, force_ritorno, pos, pos_acquired, dev_pos_acquired, pos_acquired_ritorno, dev_pos_acquired_ritorno, pos_sorted, time_axis, creep_displ, creep_period, creep_duration, zero_p, zero_f, t_rise, t_fall, t_start, t_end, t_track, tracking_flag 

    reverse_bool_tkvar.set(False)

    min_pos = float(min_pos_tkvar.get())
    max_pos = float(max_pos_tkvar.get())
    num_pos = float(num_pos_tkvar.get())
    step_pos = float(step_pos_tkvar.get())
    wait_time = int(wait_time_tkvar.get())

    creep_displ = float(creep_displ_tkvar.get())
    creep_period = float(creep_period_tkvar.get())
    creep_duration = float(creep_duration_tkvar.get())

    # RESETTING ALL ARRAYS
    force = np.array([])
    dev_force = np.array([])
    force_ritorno = np.array([])
    pos = np.array([])
    pos_acquired = np.array([])
    dev_pos_acquired = np.array([])
    pos_acquired_ritorno = np.array([])
    dev_pos_acquired_ritorno = np.array([])
    pos_sorted = np.array([])
    time_axis = np.array([])

    zero_f = np.array([])
    zero_p = np.array([])

    # t_rise = np.array([])
    # t_fall = np.array([])

    t_rise = np.empty((0,2))
    t_fall = np.empty((0,2))
    t_start = np.empty((0,2))
    t_end = np.empty((0,2))

    t_track = np.empty((0,3))

    # get here the value in order to not have saving problems
    tracking_flag = bool(checkbox_tracking.get())
    print("tracking flag: ", tracking_flag)

    populatePosArray()
    print(pos)
    print(pos_sorted)

    percent = 0

    # Thread(target=saveState).start()
    saveState()
    serial_thread = Thread(target=tkt(serialListener))
    serial_thread.start()
    app.update()
    time.sleep(2)
    # pdb.set_trace()
    # return

def prepareMsgSerialParameters():
    # global loadcell_fullscale, min_pos, max_pos, num_pos, avg_flag, ar_flag, th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg
    param_array = [stat_creep_flag,
                   loadcell_fullscale, 
                   min_pos, max_pos, 
                   num_pos, wait_time,
                   avg_flag, ar_flag, tracking_flag,
                   th1_val, th1_avg, 
                   th2_val, th2_avg, 
                   th3_val, th3_avg,
                   zero_approx, zero_avg,
                   vel_flag, vel_max, acc_max,
                   time_flag, time_max,
                   search_zero_flag,
                   up_disk_weight, dw_disk_weight, vc_coil_weight]
    msg = ''
    for param in param_array:
        if isinstance(param, bool):
            msg += str(int(param)) + " "
        else:
            msg+= str(param)+" "
    return msg



def serialListener():
    global pos, pos_sorted, pos_acquired, dev_pos_acquired, pos_acquired_ritorno, dev_pos_acquired_ritorno, percent, force, dev_force, force_ritorno, dev_force_ritorno, time_axis, max_iter, meas_forward, panic_flag, zero_p, zero_f, t_rise, t_fall, t_start, t_end, t_track, gauge_window
    print(port)
    with serial.Serial(port, 38400) as ser:
        # pdb.set_trace()

        index = 0
        iter_count = 0
        meas_index = 0
        cal_index = 0

        pPercent.configure(text="0%")
        pProgress.set(0)

        spider_entry.configure(state="disabled")

        load_cell_menu.configure(state="disabled")
        min_pos_entry.configure(state="disabled")
        max_pos_entry.configure(state="disabled")

        # num_pos_entry.configure(state="disabled")
        step_pos_entry.configure(state="disabled")

        startButton.configure(state="disabled")
        # checkbox.configure(state="disabled")
        checkbox_AR.configure(state="disabled")
        checkbox_tracking.configure(state="disabled")

        displ_entry.configure(state="disabled")
        period_entry.configure(state="disabled")
        duration_entry.configure(state="disabled")
        reverse_switch.configure(state="disabled")

        startButton.configure(text="Initializing...")
        logfile = open("./log.txt", "w")
    
        while True:
            
            if panic_flag:
                print("ER PANICO!")
                ser.write("PANIC\n".encode())
                time.sleep(0.1)
                panic_flag = False
                break


            try:
                data = ser.readline()
            except:
                print("DATO NON LETTO!")

            data = data.decode()
            print(data)

            if compare_strings(data, "Ready"):
                time.sleep(1)
                ser.write("Ready to write\n".encode())

            if compare_strings(data, "Parameters"):
                # time.sleep(0.5)
                msg = prepareMsgSerialParameters()
                ser.write(msg.encode())
                print(data)

            if data == "Connecting\n":
                print(data)
                startButton.configure(text="Connecting...")

            if data == "Taratura\n":
                print(data)
                startButton.configure(text="Calibrating...")
            
            if compare_strings(data, "cal_info"):
                print(data)
                cal_index = data.split()[1]
                cal_index = cal_index[0]
                startButton.configure(text="Calibrating..."+cal_index+"/3")
            # T A R A T U R A 

            # if compare_strings(data, "tare"):
            #     abs_tol = 0.1 
            #     # up_bound = data.split()[1]+abs_tol/0.5
            #     # lo_bound = data.split()[1]-abs_tol/0.5
            #     bounds_frac = [0.5,1,5,20]
            #     for i in range(4):
            #         bounds.append(float(data.split()[1])-abs_tol/bounds_frac[i])
            #         bounds.append(float(data.split()[1])+abs_tol/bounds_frac[i])
            #     lo_bound = bounds[0]
            #     up_bound = bounds[1]
            #     gauge_window = Meter(app, bounds)


            # if compare_strings(data, "cal_info"):
            #     val = float(data.split()[3])
            #     val = np.clip(val, lo_bound, up_bound)
            #     gauge_window.updateMeter(val)

            if data == "Measure Routine\n":
                startButton.configure(text="Data Acquisition...")
                # gauge_window.destroy()

            if data == "Measuring\n":
                print(data)
                startButton.configure(text="Measuring...")

            if compare_strings(data, "centratore"):
                time.sleep(0.5)
                pressOk(data)                
                
                if confirm_flag:
                    ser.write("ok\n".encode())
                else:
                    ser.write("nope\n".encode())
                    time.sleep(1)
                    break

                time.sleep(1)

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

            if data == "ErrorPos\n":
                iter_count -= 2

            if data == "andata\n":
                meas_forward = True
            if data == "ritorno\n":
                meas_forward = False

            if compare_strings(data, "val"):
                meas_val = float(data.split()[1])
                print(meas_val)
                if (not stat_creep_flag):
                    if meas_forward:
                        force = np.append(force, meas_val)
                    else:
                        force_ritorno = np.append(force_ritorno, meas_val)
                else:
                    force = np.append(force, meas_val)

            if compare_strings(data, "std"):
                # print(data.split())
                std_f = float(data.split()[1])
                std_p = float(data.split()[2])
                print(std_f)
                print(std_p)
                if (not stat_creep_flag):
                    if meas_forward:
                        dev_force = np.append(dev_force, std_f)
                        dev_pos_acquired = np.append(dev_pos_acquired, std_p)
                    else:
                        dev_force_ritorno = np.append(dev_force_ritorno, std_f)
                        dev_pos_acquired_ritorno = np.append(dev_pos_acquired_ritorno, std_p)
                else:
                    dev_force = np.append(dev_force, meas_val)

            if compare_strings(data, "driver_pos"):
                # print(data.split())
                meas_val = float(data.split()[1])
                if meas_forward:
                    pos_acquired = np.append(pos_acquired, meas_val)
                else:
                    pos_acquired_ritorno = np.append(pos_acquired_ritorno, meas_val)

            if compare_strings(data, "zero"):
                # a_r = data.split()[0]
                zerof = float(data.split()[2])
                zerop = float(data.split()[3])
                
                zero_f = np.append(zero_f, zerof)
                zero_p = np.append(zero_p, zerop)


            if compare_strings(data, "tare"):
                globals()["tare"]=float(data.split()[1])
                            

            if compare_strings(data, "time_ax"):
                time_val = float(data.split()[1])
                time_axis= np.append(time_axis, time_val)

            if compare_strings(data, "t_r"):
                time_val = float(data.split()[1])
                pos_val = float(data.split()[2])
                # t_rise = np.append(t_rise, [time_val, pos_val])
                t_rise = np.vstack([t_rise, [time_val, pos_val]])

            if compare_strings(data, "t_f"):
                time_val = float(data.split()[1])
                pos_val = float(data.split()[2])
                # t_fall = np.append(t_fall, [time_val, pos_val])
                t_fall = np.vstack([t_fall, [time_val, pos_val]])

            if compare_strings(data, "t_s"):
                time_val = float(data.split()[1])
                pos_val = float(data.split()[2])
                t_start = np.vstack([t_start, [time_val, pos_val]])

            if compare_strings(data, "t_e"):
                time_val = float(data.split()[1])
                pos_val = float(data.split()[2])
                t_end = np.vstack([t_end, [time_val, pos_val]])

            if compare_strings(data, "t_track"):
                x =  float(data.split()[1])
                f =  float(data.split()[2])
                t =  float(data.split()[3])

                t_track = np.vstack([t_track, [x,f,t]])
                

            if compare_strings(data, "Finished"):
                # print("matched")
                print(data)
                pPercent.configure(text="DONE")
                break
            
            app.update()
            logfile.write(data)
        ser.flush()
        try:
            ser.close()
            print(f"Chiusa porta {port}")
        except serial.SerialException as e:
            print(f"Errore chiusura porta {port}: {e}")
        del ser

    logfile.close()
    spider_entry.configure(state="normal")
    load_cell_menu.configure(state="normal")
    min_pos_entry.configure(state="normal")
    max_pos_entry.configure(state="normal")
    num_pos_entry.configure(state="normal")
    step_pos_entry.configure(state="normal")
    # checkbox.configure(state="normal")
    checkbox_AR.configure(state="normal")
    checkbox_tracking.configure(state="normal")
    startButton.configure(state="normal")

    displ_entry.configure(state="normal")
    period_entry.configure(state="normal")
    duration_entry.configure(state="normal")  

    reverse_switch.configure(state="normal")


    startButton.configure(text="START")

    # check_avg_checkbox()


    print("pos: ",pos)
    print("pos_ac: ",pos_acquired)
    print("force: ",force)  
    print("dev_pos_ac: ",dev_pos_acquired)
    print("dev_force: ",dev_force)  

    print("pos_ac_ret: ",pos_acquired_ritorno)
    print("Force_ret: ",force_ritorno)
    print("dev_pos_ac_ret: ",dev_pos_acquired_ritorno)
    print("dev_Force_ret: ",dev_force_ritorno)

    print("Time: ",time_axis)

    if np.any(pos_acquired) or np.any(force) or np.any(t_track):
        if (not stat_creep_flag):
            sort = np.argsort(pos_acquired)
            pos_acquired = pos_acquired[sort]  
            force = force[sort]
            dev_pos_acquired = dev_pos_acquired[sort] 
            dev_force = dev_force[sort]
            if(ar_flag):
                pos_sorted_sort = np.flip(pos_acquired_ritorno)
                # sort = np.argsort(pos_sorted_sort)
                sort = np.argsort(pos_acquired_ritorno)
                pos_acquired_ritorno = pos_acquired_ritorno[sort]
                force_ritorno = force_ritorno[sort]
                dev_pos_acquired_ritorno = dev_pos_acquired_ritorno[sort]
                dev_force_ritorno = dev_force_ritorno[sort]
            else:
                l = len(pos_acquired)
                pos_acquired_ritorno = np.zeros(l)
                force_ritorno = np.zeros(l)
                dev_pos_acquired_ritorno = np.zeros(l)
                dev_force_ritorno = np.zeros(l)

            # mirror = True
            # if mirror:
            #     pos = np.flip(-pos)
            #     force = np.flip(-force)
            #     force_ritorno = np.flip(-force_ritorno)
        # else:
        #     force = force
        # t_track = np.transpose(t_track)


        print("pos: ",pos)
        print("pos_ac: ",pos_acquired)
        print("pos_ac_ret: ",pos_acquired_ritorno)
        print("force: ",force)  
        print("Force_ret: ",force_ritorno)
        print("Time: ",time_axis)

        print("Time Track", np.transpose(t_track)[2])
        print("Force Track", np.transpose(t_track)[1])

        Thread(target=playFinish).start()
        drawPlots()

    return
    # sys.exit()

def resetPlots():
    ax_force.clear()
    ax_stiff.clear()
    ax_inc_stiff.clear()

    ax_force.set_xlabel("displacement [mm]")
    ax_force.set_ylabel("force [N]")
    ax_force.set_title("Force vs Displacement")
    ax_force.grid(visible=True, which="both", axis="both")

    ax_stiff.set_xlabel("displacement [mm]")
    ax_stiff.set_ylabel("stiffness [N/mm]")
    ax_stiff.set_title("Stiffness vs Displacement")
    ax_stiff.grid(visible=True, which="both", axis="both")
    
    ax_inc_stiff.set_xlabel("displacement [mm]")
    ax_inc_stiff.set_ylabel("incremental stiffness [N/mm]")
    ax_inc_stiff.set_title("Incremental Stiffness vs Displacement")
    ax_inc_stiff.grid(visible=True, which="both", axis="both")

    chart_type_force.draw()
    chart_type_stiff.draw()
    chart_type_inc_stiff.draw()


def drawPlots():
    # plotts
    ax_force.clear()
    ax_stiff.clear()
    ax_inc_stiff.clear()
    # global pos, force, force_ritorno, time_axis

    BF_legend = ["Forw", "Back"]
    BF_fit_legend = ["Forw", "Back", "Forw Fit", "Back Fit"]
    F_fit_legend = ["Forw", "Forw Fit"]

    global pos_forw_to_plot, pos_back_to_plot, time_to_plot, force_forw_to_plot, force_back_to_plot, stiffness_forw, stiffness_back, force_forw_fitted, force_back_fitted, stiff_forw_fitted, stiff_back_fitted

    pos_forw_to_plot   = pos_acquired
    pos_back_to_plot   = pos_acquired_ritorno
    force_forw_to_plot = force 
    force_back_to_plot = force_ritorno 

    if not creep_bool_tkvar.get():
        if not tracking_flag:
            sign = (-1)**int(not reverse_bool_tkvar.get())

            if postprocessing_flag_tkvar.get():
                f_forw_DC = np.interp(0, pos_forw_to_plot, force_forw_to_plot)
                f_back_DC = np.interp(0, pos_back_to_plot, force_back_to_plot)
                force_forw_to_plot = force_forw_to_plot - f_forw_DC
                force_back_to_plot = force_back_to_plot - f_back_DC

            stiffness_forw = force_forw_to_plot/pos_forw_to_plot
            if(ar_flag):
                stiffness_back = force_back_to_plot/pos_back_to_plot 
            else:
                stiffness_back = np.zeros(len(stiffness_forw))
            

            # ax_force.plot(pos_acquired, force)
            ax_force.plot(pos_forw_to_plot, force_forw_to_plot)
            if(ar_flag):
                # ax_force.plot(pos_acquired_ritorno, force_ritorno)
                ax_force.plot(pos_back_to_plot, force_back_to_plot)
                ax_force.legend(BF_legend)
            ax_force.set_xlabel("displacement [mm]")
            ax_force.set_ylabel("force [N]")
            ax_force.set_title("Force vs Displacement")
            ax_force.grid(visible=True, which="both", axis="both")

            # ax_stiff.plot(pos_acquired, sign*force/pos_acquired)
            # ax_stiff.plot(pos_forw_to_plot, sign*force_forw_to_plot/pos_forw_to_plot)
            ax_stiff.plot(pos_forw_to_plot, sign*stiffness_forw)
            if (ar_flag):
                # ax_stiff.plot(pos, np.nan_to_num(force_ritorno/pos))
                # ax_stiff.plot(pos_acquired_ritorno, sign*force_ritorno/pos_acquired_ritorno)
                # ax_stiff.plot(pos_back_to_plot, sign*force_back_to_plot/pos_back_to_plot)
                ax_stiff.plot(pos_back_to_plot, sign*stiffness_back)
                ax_stiff.legend(BF_legend)
            ax_stiff.set_xlabel("displacement [mm]")
            ax_stiff.set_ylabel("stiffness [N/mm]")
            ax_stiff.set_title("Stiffness vs Displacement")
            ax_stiff.grid(visible=True, which="both", axis="both")


            # gradient = np.gradient(force/pos_acquired, pos_acquired)
            # gradient = np.diff(force)/np.diff(pos_acquired)

            # gradient = np.gradient(sign*force, pos_acquired)
            gradient = np.gradient(sign*force_forw_to_plot, pos_forw_to_plot)
            # ax_inc_stiff.plot(pos_acquired[:-1], gradient)
            ax_inc_stiff.plot(pos_acquired, gradient)
            if (ar_flag):
                # gradient_ritorno = np.gradient(sign*force_ritorno, pos_acquired_ritorno)
                gradient_ritorno = np.gradient(sign*force_back_to_plot, pos_back_to_plot)
                # ax_stiff.plot(pos, np.nan_to_num(force_ritorno/pos))
                ax_inc_stiff.plot(pos_acquired_ritorno, gradient_ritorno)
                ax_inc_stiff.legend(BF_legend)
            ax_inc_stiff.set_xlabel("displacement [mm]")
            ax_inc_stiff.set_ylabel("incremental stiffness [N/mm]")
            ax_inc_stiff.set_title("Incremental Stiffness vs Displacement")
            ax_inc_stiff.grid(visible=True, which="both", axis="both")

            if postprocessing_flag_tkvar.get():
                degree = fit_order.get()[0]
                if degree != "N":
                    degree = int(degree)
                    print(degree)

                    # FORW STIFF FIT
                    coeff = np.polyfit(pos_forw_to_plot, stiffness_forw, degree, w=np.abs(pos_forw_to_plot))
                    stiff_forw_fitted = np.polyval(coeff, pos_forw_to_plot)
                    ax_stiff.plot(pos_forw_to_plot, sign*stiff_forw_fitted)

                    # FORW FORCE FIT
                    force_forw_fitted = stiff_forw_fitted*pos_forw_to_plot
                    ax_force.plot(pos_forw_to_plot, force_forw_fitted)
                    
                    ax_force.legend(F_fit_legend)
                    ax_stiff.legend(F_fit_legend)
                    
                    if ar_flag:
                        # BACK FORCE FIT
                        coeff = np.polyfit(pos_back_to_plot, force_back_to_plot, degree+1, w=np.abs(pos_back_to_plot))

                        # BACK STIFF FIT
                        coeff = np.polyfit(pos_back_to_plot, stiffness_back, degree, w=np.abs(pos_back_to_plot))
                        stiff_back_fitted = np.polyval(coeff, pos_back_to_plot)
                        ax_stiff.plot(pos_back_to_plot, sign*stiff_back_fitted)
                        
                        force_back_fitted = stiff_back_fitted*pos_back_to_plot
                        ax_force.plot(pos_back_to_plot, force_back_fitted)

                        ax_force.legend(BF_fit_legend)
                        ax_stiff.legend(BF_fit_legend)
                    else:
                        pos_back_to_plot  = np.zeros(len(pos_forw_to_plot))
                        force_back_fitted = np.zeros(len(pos_forw_to_plot)) 
                        stiff_back_fitted = np.zeros(len(pos_forw_to_plot)) 

        else:
            ax_force.stem(np.transpose(t_track)[2], np.transpose(t_track)[1])
            # if(ar_flag):
            #     ax_force.plot(pos_acquired_ritorno, force_ritorno)
            #     ax_force.legend(["Andata", "Ritorno"])
            ax_force.set_xlabel("time [ms]")
            ax_force.set_ylabel("force [N]")
            ax_force.set_title("Force vs Time")
            ax_force.grid(visible=True, which="both", axis="both")

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
    chart_type_inc_stiff.draw()


def panic():
    global panic_flag
    panic_flag = True
    # return

def vel_and_acc_setting_func():
    global vel_acc_window 
    if (vel_acc_window==None or not vel_acc_window.winfo_exists()):
        vel_acc_window = VelAccWindows(app)
    
    vel_acc_window.focus()
    # topWindow.grab_set()
    app.update()

def support_weights_func():
    global weights_window 
    if (weights_window==None or not weights_window.winfo_exists()):
        weights_window = WeightsWindows(app)
    
    weights_window.focus()
    # topWindow.grab_set()
    app.update()

def move_piston_func():
    global move_piston_window 
    if (move_piston_window==None or not move_piston_window.winfo_exists()):
        move_piston_window = MovePistWindow(app)
    
    move_piston_window.focus()
    # topWindow.grab_set()
    app.update()


def tracking_stiffness_evolution():
    global track_evol_window 
    if (track_evol_window==None or not track_evol_window.winfo_exists()):
        track_evol_window = TrackEvolutionWindow(app)
    
    track_evol_window.focus()
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
        # creep_switch.configure(text="Statica")
        creep_switch.configure(text="Static")
    else:
        showCreepFrame()
        # creep_switch.configure(text="Creep")
        # creep_switch.configure(text="Rilassamento")
        creep_switch.configure(text="Relaxation")
    saveState()

def updateTkVars():
    creep_bool_tkvar.set(stat_creep_flag)
    load_cell_menu.set(str(loadcell_fullscale) + " kg")
    spider_name_tkvar.set(spider_name)
    min_pos_tkvar.set(str(min_pos))
    max_pos_tkvar.set(str(max_pos))
    num_pos_tkvar.set(str(num_pos))
    step_pos_tkvar.set(str(step_pos))
    wait_time_tkvar.set(str(wait_time))
    avg_flag_tkvar.set(avg_flag)
    ar_flag_tkvar.set(ar_flag)
    tracking_flag_tkvar.set(tracking_flag)
    creep_displ_tkvar.set(str(creep_displ))
    creep_period_tkvar.set(str(creep_period))
    creep_duration_tkvar.set(str(creep_duration))
    search_zero_flag_tkvar.set(search_zero_flag)


def reverse_plot():
    global pos_acquired, pos_acquired_ritorno, force, force_ritorno
    pos_acquired = np.flip(-pos_acquired)
    pos_acquired_ritorno = np.flip(-pos_acquired_ritorno)
    force = np.flip(force)
    force_ritorno = np.flip(force_ritorno)
    drawPlots()

def tkvar_changed():
    global saved_flag
    saveState()
    saved_flag = False
    # populatePosArray()


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
    # del app

def save_data(txt_path, json_path, zero_path):
    global saved_flag, last_params
    root_name = os.path.splitext(txt_path)[0]
    procedure_id = ""
    array_to_save = []
    if stat_creep_flag:
        # CREEP
        array_to_save = []
        procedure_id = "creep"
    else:
        if tracking_flag:
            # TRACKING
            array_to_save = t_track
            procedure_id = "tracking"
        else:
            # STATICA
            array_to_save = [[],[]]
            if save_fit_data_flag_tkvar.get():
                array_to_save[0] = np.transpose([pos_forw_to_plot,force_forw_fitted,-stiff_forw_fitted])
                array_to_save[1] = np.transpose([pos_back_to_plot,force_back_fitted,-stiff_back_fitted])
            else:
                array_to_save[0] = np.transpose([pos_acquired,force,-stiffness_forw])
                array_to_save[1] = np.transpose([pos_acquired_ritorno,force_ritorno,-stiffness_back])
            print("array_len=", len(array_to_save))
            procedure_id = "static"
 
    write_stiff_file(array_to_save, spider_name_tkvar.get(), procedure_id, txt_path)    

    saveState()
    with open(json_path, 'w') as js:
        js.write(json.dumps(params, indent=4))
        js.close()
    

    if (not tracking_flag):
        with open(zero_path, 'w') as zfl:
            zfl.write("# zero pos")
            zfl.write("\t\t\t zero force\n")
            for i in range(0, len(zero_f)):
                zfl.write(f"{zero_p[i]:.5f}"+"\t\t\t"+f"{zero_f[i]:.5f}"+"\n")
            zfl.close()

        time_path = os.path.split(json_path)[0]
        time_path = os.path.join(time_path, "times.txt")

        with open(time_path, 'w') as tp:
            tp.write("# t_start ")
            tp.write("\t\t\t pos ")
            tp.write("\t\t\t t_rise ")
            tp.write("\t\t\t pos ")
            tp.write("\t\t\t t_fall")
            tp.write("\t\t\t pos")
            tp.write("\t\t\t t_end")
            tp.write("\t\t\t pos\n")
            for i in range(0, len(t_rise)):
                tp.write(f"{t_start[i][0]:.5f}"+"\t\t\t"+f"{t_start[i][1]:.5f}"+"\t\t\t")
                tp.write(f"{t_rise[i][0]:.5f}"+"\t\t\t"+f"{t_rise[i][1]:.5f}"+"\t\t\t")
                tp.write(f"{t_fall[i][0]:.5f}"+"\t\t\t"+f"{t_fall[i][1]:.5f}"+"\t\t\t")
                tp.write(f"{t_end[i][0]:.5f}"+"\t\t\t"+f"{t_end[i][1]:.5f}"+"\n")
            tp.close()
    
    saved_flag = True
    app.title(apptitle+" - "+root_name)
    last_params = params


# def save_data(txt_path, json_path, zero_path):
#     global saved_flag, last_params
#     root_name = os.path.splitext(txt_path)[0]
#     with open(txt_path, 'w') as fl:
#         fl.write("# Acquired on "+ datetime.now().strftime("%d/%m/%Y %H:%M:%S") +" \n")
#         fl.write("# SPIDER: " + spider_name_tkvar.get() + "\n")
#         if np.any(force) or np.any(t_track):
#             if(not stat_creep_flag):
                

#                 if (tracking_flag):
#                     fl.write("# TRACKING MEASUREMENT\n\n")
#                     # fl.write("# pos [mm]\t\t")
#                     # fl.write(" force [N]\t\t")
#                     # fl.write(" time [ms]\n")

#                     table_track = []
#                     headers_track = ["# pos [mm]","force [N]", "time [ms]"]
#                     for i in range(0, len(t_track)):

#                         table_track.append([t_track[i][0], t_track[i][1], t_track[i][2]])

#                         # fl.write(f"{t_track[i][0]:.5f}"+"\t\t\t")
#                         # fl.write(f"{t_track[i][1]:.5f}"+"\t\t\t")
#                         # fl.write(f"{t_track[i][2]:.5f}"+"\n")
#                     fl.write(tabulate(table_track, headers_track, tablefmt="plain",floatfmt=".5f"))
#                 else:
#                     fl.write("# STATIC MEASUREMENT\n\n")
#                     # fl.write("# pos [mm]\t\tdev_pos [mm]\t\tforce_forw [N]\t\tdev_force_forw [N]\t\tforce_back [N]\n")
#                     # fl.write("# pos_forw [mm]\t\t")          # 0
#                     # # fl.write("dev_pos [mm]\t\t")        # 1    
#                     # fl.write("force_forw [N]\t\t")      # 2    
#                     # # fl.write("dev_force_forw [N]\t\t")  # 3        
#                     # fl.write("pos_back [mm]\t\t")       # 4    
#                     # # fl.write("dev_p_back [mm]\t\t")     # 5    
#                     # fl.write("force_back [N]\t\t")     # 6    
#                     # # fl.write("dev_f_forw_back [N]\t\t") # 7  
#                     # fl.write("\n")
#                     headers_forw = ["# x_forw [mm]", "f_forw [N]", "kms_forw [N/mm]"]
#                     headers_back = ["# x_back [mm]", "f_back [N]", "kms_back [N/mm]"]


#                     if save_fit_data_flag_tkvar.get():
#                         pos_forw_to_save = pos_forw_to_plot
#                         pos_back_to_save = pos_back_to_plot
#                         for_forw_to_save = force_forw_fitted
#                         for_back_to_save = force_back_fitted
#                         kms_forw_to_save = -stiff_forw_fitted
#                         kms_back_to_save = -stiff_back_fitted
#                     else:
#                         pos_forw_to_save = pos_acquired
#                         pos_back_to_save = pos_acquired_ritorno
#                         for_forw_to_save = force
#                         for_back_to_save = force_ritorno
#                         kms_forw_to_save = -stiffness_forw
#                         kms_back_to_save = -stiffness_back
                    
#                     table_forw = []
#                     table_back = []
#                     for i in range(0,len(pos_forw_to_save)):

#                         # with devs
#                         # fl.write(f"{pos_forw_to_save[i]:.5f}"+"\t\t\t"+f"{dev_pos_acquired[i]:.5f}"+"\t\t\t"+f"{for_forw_to_save[i]:.5f}" +"\t\t\t" + f"{dev_force[i]:.5f}" +"\t\t\t"+f"{pos_back_to_save[i]:.5f}"+"\t\t\t"+f"{dev_pos_acquired_ritorno[i]:.5f}"+"\t\t\t"+f"{for_back_to_save[i]:.5f}"+"\t\t\t"+f"{dev_force_ritorno[i]:.5f}"+"\n") 

#                         # no devs
#                         # fl.write(f"{pos_forw_to_save[i]:.5f}"+"\t\t\t"+f"{for_forw_to_save[i]:.5f}" +"\t\t\t"+f"{pos_back_to_save[i]:.5f}"+"\t\t\t"+f"{for_back_to_save[i]:.5f}"+"\n")
                        
#                         table_forw.append([pos_forw_to_save[i], for_forw_to_save[i], kms_forw_to_save[i]])
#                         table_back.append([pos_back_to_save[i], for_back_to_save[i], kms_back_to_save[i]])
#                             # fl.write(f"{pos_acquired[i]:.5f}"+"\t\t\t"+f"{dev_pos_acquired[i]:.5f}"+"\t\t\t"+ f"{force[i]:.5f}"+"\t\t\t" + f"{dev_force[i]:.5f}" +"\t\t\t"+ f"{0:.5f}"+"\n")   
#                     print(tabulate(table_forw, headers_forw, tablefmt="plain",floatfmt=".5f"))
#                     fl.write(tabulate(table_forw, headers_forw, tablefmt="plain",floatfmt=".5f"))

#                     fl.write("\n\n")

#                     print(tabulate(table_back , headers_back, tablefmt="plain",floatfmt=".5f"))
#                     fl.write(tabulate(table_back, headers_back, tablefmt="plain",floatfmt=".5f"))
#             else:
#                 fl.write("# CREEP MEASUREMENT\n\n")
#                 fl.write("# time [ms]\t\tforce [N]\t\tstiffness [N/mm]\n")
#                 for i in range(0,len(force)):
#                     fl.write(f"{time_axis[i]:.3f}" +"\t\t\t"+ f"{force[i]:.3f}" +"\t\t\t"+ f"{force[i]/creep_displ:.3f}" + "\n")
#         fl.close()
    

#     saveState()
#     with open(json_path, 'w') as js:
#         js.write(json.dumps(params, indent=4))
#         js.close()
    

#     if (not tracking_flag):
#         with open(zero_path, 'w') as zfl:
#             zfl.write("# zero pos")
#             zfl.write("\t\t\t zero force\n")
#             for i in range(0, len(zero_f)):
#                 zfl.write(f"{zero_p[i]:.5f}"+"\t\t\t"+f"{zero_f[i]:.5f}"+"\n")
#             zfl.close()

#         time_path = os.path.split(json_path)[0]
#         time_path = os.path.join(time_path, "times.txt")

#         with open(time_path, 'w') as tp:
#             tp.write("# t_start ")
#             tp.write("\t\t\t pos ")
#             tp.write("\t\t\t t_rise ")
#             tp.write("\t\t\t pos ")
#             tp.write("\t\t\t t_fall")
#             tp.write("\t\t\t pos")
#             tp.write("\t\t\t t_end")
#             tp.write("\t\t\t pos\n")
#             for i in range(0, len(t_rise)):
#                 tp.write(f"{t_start[i][0]:.5f}"+"\t\t\t"+f"{t_start[i][1]:.5f}"+"\t\t\t")
#                 tp.write(f"{t_rise[i][0]:.5f}"+"\t\t\t"+f"{t_rise[i][1]:.5f}"+"\t\t\t")
#                 tp.write(f"{t_fall[i][0]:.5f}"+"\t\t\t"+f"{t_fall[i][1]:.5f}"+"\t\t\t")
#                 tp.write(f"{t_end[i][0]:.5f}"+"\t\t\t"+f"{t_end[i][1]:.5f}"+"\n")
#             tp.close()
    
#     saved_flag = True
#     app.title(apptitle+" - "+root_name)
#     last_params = params


def save_as(): 
    global txt_path, json_path
    files = [('Static Stiffness Test', '*.stiff'),
             ('Text Files', '*.txt'), 
             ('All Files', '*.*')]

    file_path = asksaveasfilename(initialfile = spider_name_tkvar.get()+'.stiff',
                         filetypes = files, 
                         defaultextension = ".stiff") 
    
    if file_path:
        folder = os.path.split(file_path)[0]
        utils = os.path.join(folder,"util")


        if not os.path.exists(file_path):
            folder = os.path.splitext(file_path)[0]
            utils = os.path.join(folder,"util")
            os.makedirs(folder, exist_ok=True)
            os.makedirs(utils, exist_ok=True)

        name = folder.split('/')[-1]
        
        txt_path = os.path.join(folder,name+".stiff")
        json_path = os.path.join(utils,name+".json")
        zero_path = os.path.join(utils,"zero_"+name+".txt")
        print(file_path)

        save_data(txt_path, json_path, zero_path)
        
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
    global time_axis, pos, pos_acquired, dev_pos_acquired, pos_acquired_ritorno, dev_pos_acquired_ritorno, force, dev_force, force_ritorno, dev_force_ritorno, params, saved_flag, last_params
    files = [('Static Stiffness Test', '*.stiff'),
             ('Text Files', '*.txt'), 
             ('All Files', '*.*')] 
    file_path = askopenfilename(defaultextension=".stiff", filetypes=files)
    folder = os.path.split(file_path)[0]
    name = os.path.splitext(file_path)[0]
    name = name.split("/")[-1]

    json_path = os.path.join(folder,"util",name+'.json')

    print("name: "+name)
    if file_path:
        #apri json
        # with open(name+'.json', 'r') as js:
        with open(json_path, 'r') as js:
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
            # fl.readline() # axis specification

            

            if stat_creep=="STATIC":
                p = []
                f = []

                p_r = []
                f_r = []
                
                idx = 0

                for line in fl:
                    line = line.strip()
                    # print(len(line.split()))
                    print(line)
                    if not line:
                        idx +=1 
                        print("idx = "+str(idx))
                    else:
                        if not line.split()[0]=="#":
                            # 2 COLUMNS FILE
                            if len(line.split())==2 or len(line.split())==3:
                                if idx < 1:
                                    p.append(float(line.split()[0]))
                                    f.append(float(line.split()[1]))
                                elif idx < 2:
                                    p_r.append(float(line.split()[0]))
                                    f_r.append(float(line.split()[1]))
                                else:
                                    break
                            # 4 COLUMNS FILE
                            if len(line.split())==4:
                                if idx < 1:
                                    p.append(float(line.split()[0]))
                                    f.append(float(line.split()[1]))
                                    p_r.append(float(line.split()[2]))
                                    f_r.append(float(line.split()[3]))
                                else:
                                    break

                pos_acquired = np.array(p)
                force = np.array(f)

                pos_acquired_ritorno = np.array(p_r)
                force_ritorno = np.array(f_r)


            elif stat_creep=="TRACKING":
                global tracking_flag, t_track
                tracking_flag = True
                p=[]
                f=[]
                t=[]
                for line in fl:
                    
                    line = line.strip()
                    if not line.split()[0]=="#":
                        data = line.split()

                        p.append(float(data[0]))
                        f.append(float(data[1]))
                        t.append(float(data[2]))
                    
                        print(data)
                t_track=np.transpose(np.array([p,f,t]))
                print(t_track)

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
        app.title(apptitle+" - "+ name)
        last_params = params
        saved_flag=True

def new_test():
    global params 
    with open(default_path, 'r') as js:
        params = json.loads(js.read())
        for key in params:
            globals()[key]=params[key]
        js.close()
        app.title(apptitle)
        updateTkVars()
        saveState()
        resetPlots()
        showFrame()
        globals()["saved_flag"]=True

def check_save_before_closing():
    if saved_flag:
        closeAll()
    if globals()["last_params"] != globals()["params"]:
        SaveDialog(app)
    else:
        closeAll()

def setZeroSearch():
    global search_zero_flag
    search_zero_flag = search_zero_flag_tkvar.get()

def playFinish():
    #file_dir = os.path.dirname(this_path+'\GUI\Finish.wav')
    file_path = this_path + '/GUI/Finish.wav'

    print(this_path)
    #print(file_dir)
    print(file_path)
    playsound(file_path)
    return

#############################################################################
# ---------------------------C R E A T E   A P P-----------------------------
#############################################################################
# appearance
customtkinter.set_appearance_mode("light")
customtkinter.set_default_color_theme("blue")
customtkinter.deactivate_automatic_dpi_awareness()

# appWidth, appHeight = 900, 700

# create app
app = customtkinter.CTk()
w,h = app.winfo_screenwidth(), app.winfo_screenheight()
app.geometry("900x700")
# app.geometry(f"{w}x{h}+0+0")
# app.geometry(f"{appWidth}x{appHeight}")
apptitle = "Static Stiffness Test" 
app.title(apptitle)
iconpath = ImageTk.PhotoImage(file=os.path.join(this_path, "GUI/App Icon.png"))
print(iconpath)
app.wm_iconbitmap()
app.iconphoto(False, iconpath)

tkt = tkthread.TkThread(app)


app.update_idletasks()


appWidth = app.winfo_width()
appHeight = app.winfo_height()
print("app width: ", appWidth)
print("app height: ", appHeight)

leftFrame = customtkinter.CTkFrame(app, 250, 500, fg_color="darkgray")
leftFrame.pack_propagate(0)
leftFrame.pack(
    side=customtkinter.LEFT, padx=20, pady=20, fill="y", expand=False, anchor="w"
)

creep_bool_tkvar = customtkinter.BooleanVar(app, stat_creep_flag)
creep_switch = customtkinter.CTkSwitch(leftFrame, text="Mode", command=showFrame, variable=creep_bool_tkvar)
creep_switch.pack(pady=10)


staticFrame = customtkinter.CTkFrame(leftFrame, 310, fg_color="lightgray")
creepFrame = customtkinter.CTkFrame(leftFrame, 310, fg_color="lightgray")
staticFrame.grid_propagate(0)
creepFrame.grid_propagate(0)



rightFrame = customtkinter.CTkFrame(app, 500, 500, fg_color="darkgray")
# rightFrame.pack_propagate(0)
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
filemenu.add_command(label="New", command=new_test)
filemenu.add_command(label="Open", command=load)
filemenu.add_command(label="Save", command=save)
filemenu.add_command(label="Save as...", command=save_as)
filemenu.add_separator()
filemenu.add_command(label="Exit", command=app.quit)

menubar.add_cascade(label="File", menu=filemenu)


velacc_window = None
settingmenu = Menu(menubar, tearoff=0)

settingmenu.add_command(label="Reset Piston", command=move_piston_func)
settingmenu.add_command(label="Vel & Acc", command=vel_and_acc_setting_func)
settingmenu.add_command(label="Support Weights", command=support_weights_func)
# settingmenu.add_command(label="Avg & Thresholds", command=thr_and_avg_setting_func)

search_zero_flag_tkvar = tk.BooleanVar(app, search_zero_flag)
settingmenu.add_checkbutton(label="Zero Calibration", variable=search_zero_flag_tkvar, command=setZeroSearch)

# menubar.add_cascade(label="Impostazioni", menu=settingmenu)
menubar.add_cascade(label="Settings", menu=settingmenu)

COM_menu = Menu(settingmenu, tearoff=0)
COM_list = serial.tools.list_ports.comports()
COM_option = tk.StringVar(app, port)
COM_option.trace_add('write', callback=lambda *args:setCOMPort())


for COM_port in COM_list:
    # COM_menu.add_command(label=str(COM_port))
    COM_menu.add_radiobutton(label=str(COM_port), variable=COM_option, value=COM_port[0])
    # print(COM_port[0])

settingmenu.add_cascade(label="Serial Ports", menu=COM_menu)

mathsmenu = Menu(menubar, tearoff=0)
menubar.add_cascade(label="Maths", menu=mathsmenu)

postprocessing_flag_tkvar = tk.BooleanVar(app, False)

mathsmenu.add_checkbutton(label="Post-processing Static", variable=postprocessing_flag_tkvar, command=drawPlots)

fitting_curve_menu = Menu(mathsmenu, tearoff=0)
mathsmenu.add_cascade(label="Stiffness Fit Order", menu=fitting_curve_menu)

fit_order = tk.StringVar(app,"None")

fitting_curve_menu.add_radiobutton(label = "None", variable = fit_order, command=drawPlots)
fitting_curve_menu.add_radiobutton(label = "2nd" , variable = fit_order, command=drawPlots)
fitting_curve_menu.add_radiobutton(label = "3rd" , variable = fit_order, command=drawPlots)
fitting_curve_menu.add_radiobutton(label = "4th" , variable = fit_order, command=drawPlots)
fitting_curve_menu.add_radiobutton(label = "5th" , variable = fit_order, command=drawPlots)
fitting_curve_menu.add_radiobutton(label = "6th" , variable = fit_order, command=drawPlots)

save_fit_data_flag_tkvar = tk.BooleanVar(app, False) 
mathsmenu.add_checkbutton(label="Save Fitted Data", variable=save_fit_data_flag_tkvar)

tools_menu = Menu(menubar, tearoff=0)
menubar.add_cascade(label="Tools", menu=tools_menu)

tools_menu.add_command(label="Tracking Stiffness Evolution", command=tracking_stiffness_evolution)




#############################################################################
# ----------------------------E L E M E N T S--------------------------------
#############################################################################


# ========================= #
# ----- T K - V A R S ----- #
# ========================= #

spider_name_tkvar = customtkinter.StringVar(app, spider_name)
loadcell_fullscale_tkvar = customtkinter.StringVar(app, str(loadcell_fullscale)+" kg")
min_pos_tkvar = customtkinter.StringVar(app, str(min_pos))
max_pos_tkvar = customtkinter.StringVar(app, str(max_pos))

num_pos_tkvar = customtkinter.StringVar(app, str(num_pos))
step_pos_tkvar = customtkinter.StringVar(app, str(step_pos))
wait_time_tkvar = customtkinter.StringVar(app, str(wait_time))

avg_flag_tkvar = customtkinter.BooleanVar(app, avg_flag)
ar_flag_tkvar = customtkinter.BooleanVar(app, ar_flag)
creep_displ_tkvar = customtkinter.StringVar(app, str(creep_displ))
creep_period_tkvar = customtkinter.StringVar(app, str(creep_period))
creep_duration_tkvar = customtkinter.StringVar(app, str(creep_duration))

tracking_flag_tkvar = customtkinter.BooleanVar(app, tracking_flag)

spider_name_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
loadcell_fullscale_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
min_pos_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
max_pos_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
num_pos_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
step_pos_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
avg_flag_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
ar_flag_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
tracking_flag_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
creep_displ_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
creep_period_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())
creep_duration_tkvar.trace_add('write', callback=lambda *args: tkvar_changed())


#############################################################################

spider_entry = customtkinter.CTkEntry(leftFrame, textvariable=spider_name_tkvar, placeholder_text="Culo")

loadcell_label = customtkinter.CTkLabel(
    # leftFrame, text="Selezionare cella di carico", anchor="s"
    leftFrame, text="Select load cell", anchor="s"
)


load_cell_menu = customtkinter.CTkOptionMenu(
    leftFrame, values=["3 kg", "10 kg", "50 kg"], variable=loadcell_fullscale_tkvar,  command=setLoadCell
    # leftFrame, values=["1 kg", "3 kg", "10 kg", "50 kg"], variable=loadcell_fullscale_tkvar
)
# load_cell_menu.set(str(loadcell_fullscale) + " kg")


min_pos_label = customtkinter.CTkLabel(
    # staticFrame, text="Posizione negativa massima [mm]", anchor="s"
    staticFrame, text="Maximum Negative Position [mm]", anchor="s"
)

min_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=min_pos_tkvar
)
if float(min_pos_entry.get()) > 0:
    min_pos_entry.insert(0, "-")


max_pos_label = customtkinter.CTkLabel(
    # staticFrame, text="Posizione positiva massima [mm]", anchor="s"
    staticFrame, text="Maximum Positive Position [mm]", anchor="s"
)

max_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=max_pos_tkvar
)


num_pos_label = customtkinter.CTkLabel(
    staticFrame, text="Numero pari di punti spaziali", anchor="s"
)

step_pos_label = customtkinter.CTkLabel(
    # staticFrame, text="Intervallo [mm]", anchor="s", width=80
    staticFrame, text="Step [mm]", anchor="s", width=80
)

wait_time_label = customtkinter.CTkLabel(
    # staticFrame, text="Tempo [ms]", anchor="s", width=80
    staticFrame, text="Time [ms]", anchor="s", width=80
)

num_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=num_pos_tkvar
)

step_pos_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=step_pos_tkvar, width=80
)

wait_time_entry = customtkinter.CTkEntry(
    staticFrame, textvariable=wait_time_tkvar, width=80
)


mesh_label = customtkinter.CTkLabel(
    staticFrame, text="Il valore massimo non è multiplo\ndel passo scelto ", anchor="s",
    font=('Segoe UI', 10),
    text_color="red"
)

# checkbox = customtkinter.CTkCheckBox(staticFrame, text="Media", command=setAvgFlag)

# checkbox = customtkinter.CTkCheckBox(staticFrame, text="Average", command=setAvgFlag)
# checkbox.configure(variable=avg_flag_tkvar)

# checkbox_AR = customtkinter.CTkCheckBox(staticFrame, text="Andata e Ritorno", command=setARFlag)
checkbox_AR = customtkinter.CTkCheckBox(staticFrame, text="Forw & Back", command=setARFlag)
checkbox_AR.configure(variable=ar_flag_tkvar)

checkbox_tracking = customtkinter.CTkCheckBox(staticFrame, text="Tracking")#, command=set_tracking)
checkbox_tracking.configure(variable=tracking_flag_tkvar)


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

reverse_bool_tkvar = customtkinter.BooleanVar(app, False)
reverse_switch = customtkinter.CTkSwitch(rightFrame, text="Mirror", command=reverse_plot, variable=reverse_bool_tkvar)
reverse_switch.pack(padx=20, pady=10, fill="x", anchor="sw")

rightFrameWidth = rightFrame.winfo_width()
rightFrameHeight = rightFrame.winfo_height()
print(rightFrameWidth)
print(rightFrameHeight)
print(int(rightFrameHeight*0.9))


plot_tabview = customtkinter.CTkTabview(rightFrame)
plot_tabview.pack(padx=20, pady=0, fill="both", expand=True)
plot_tabview.add("Force")
plot_tabview.add("Stiffness")
plot_tabview.add("Inc. Stiff.")


figure_force = plt.Figure(dpi=100, figsize=(1,1))
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

figure_stiff = plt.Figure(dpi=100, figsize=(1,1))
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

figure_inc_stiff = plt.Figure(dpi=100, figsize=(1,1))
ax_inc_stiff = figure_inc_stiff.add_subplot(111)
ax_inc_stiff.set_xlabel("displacement [mm]")
ax_inc_stiff.set_ylabel("incremental stiffness [N/mm]")
ax_inc_stiff.set_title("Incremental Stiffness vs Displacement")
ax_inc_stiff.grid(visible=True, which="both")
chart_type_inc_stiff = FigureCanvasTkAgg(figure_inc_stiff, plot_tabview.tab("Inc. Stiff."))
chart_type_inc_stiff.get_tk_widget().pack(
    fill="both", expand=True, side=customtkinter.TOP, pady=20, padx=20, anchor="n"
)
toolbar_inc_stiff = NavigationToolbar2Tk(
    chart_type_inc_stiff, plot_tabview.tab("Inc. Stiff."), pack_toolbar=False
)
toolbar_inc_stiff.pack(fill="x", expand=False, padx=20, pady=5, anchor="n")


#############################################################################
# ------------------------P R O G R E S S   B A R----------------------------
#############################################################################

# progress bar
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
    # staticFrame.grid_columnconfigure(0, weight=1)
    # staticFrame.grid_columnconfigure(1, weight=2)

    # staticFrame.grid_rowconfigure(10, weight=3)


    min_pos_label.grid(row=2, column=0, pady=10, padx=20, sticky="w", columnspan=2)
    min_pos_entry.grid(row=3, column=0, padx=20, sticky="w", columnspan=2)

    max_pos_label.grid(row=4, column=0, pady=10, padx=20, sticky="w", columnspan=2)
    max_pos_entry.grid(row=5, column=0, padx=20, sticky="w", columnspan=2)

    # num_pos_label.grid(row=6, column=0, pady=10, padx=20, sticky="w")
    # num_pos_entry.grid(row=7, column=0, padx=20, sticky="w")

    step_pos_label.grid(row=6, column=0, pady=10, padx=10)
    step_pos_entry.grid(row=7, column=0, padx=20)

    wait_time_label.grid(row=6, column=1, pady=10, padx=10, sticky="w")
    wait_time_entry.grid(row=7, column=1, padx=20, sticky="w")

    # checkbox.grid(row=8, column=0, padx=20, sticky="w", pady=10, columnspan=2)
    checkbox_tracking.grid(row=8, column=0, padx=20, sticky="w", pady=10, columnspan=2)

    checkbox_AR.grid(row=9, column=0, padx=20, sticky="w", pady=10, columnspan=2)
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
# check_avg_checkbox()
app.config(menu=menubar)

# savedialog = simpledialog.Dialog(app)
# savedialog = SaveDialog(app)

app.protocol("WM_DELETE_WINDOW", check_save_before_closing)


app.bind('<Return>', lambda e: startMeasurement())
app.bind('<Escape>', lambda e: closeAll())
app.bind("<Control-s>", lambda e: save())
app.bind("<Control-o>", lambda e: load())
app.mainloop()
