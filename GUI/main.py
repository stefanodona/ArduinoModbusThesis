from tkinter import *
from tkinter import font
from typing import Optional, Tuple, Union
import customtkinter
import serial
import struct
import numpy as np
import re  # used to compare strings
import keyboard
import time
from threading import Thread
import os
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk

#############################################################################
# ------------------------------C L A S S E S--------------------------------
#############################################################################
class ThrAvgFrame(customtkinter.CTkFrame):
    def __init__(self, master: any, width: int = 200, height: int = 200, corner_radius: int | str | None = None, border_width: int | str | None = None, bg_color: str | Tuple[str, str] = "transparent", fg_color: str | Tuple[str, str] | None = None, border_color: str | Tuple[str, str] | None = None, background_corner_colors: Tuple[str | Tuple[str, str]] | None = None, overwrite_preferred_drawing_method: str | None = None, name: str | None=None, slider_val: float | None=None, avg_num: int | None=None, **kwargs):
        super().__init__(master, width, height, corner_radius, border_width, bg_color, fg_color, border_color, background_corner_colors, overwrite_preferred_drawing_method, **kwargs)
        self.slider_val = customtkinter.DoubleVar(self, slider_val)
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
                                            text="Settings\nThresholds and Averages",
                                            font=('Segoe UI', 14))
        self.label.pack(padx=20, pady=10)
        # print(font.nametofont('TkTextFont').actual())

        self.th1 = ThrAvgFrame(self, name="Threshold 1", slider_val=th1_val, avg_num=th1_avg)
        self.th1.pack(padx=10, pady=10, fill="x", expand=True)

        self.th2 = ThrAvgFrame(self, name="Threshold 2", slider_val=th2_val, avg_num=th2_avg)
        self.th2.pack(padx=10, pady=10, fill="x", expand=True)

        self.th3 = ThrAvgFrame(self, name="Threshold 3", slider_val=th3_val, avg_num=th3_avg)
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


#############################################################################
# ----------------------------F U N C T I O N S------------------------------
#############################################################################
this_path = os.getcwd()
config_path = os.path.join(this_path, "GUI\config.txt")
print(config_path)



# load state
f = open(config_path, "r")
loadcell_fullscale = int(f.readline().split()[1])
min_pos = float(f.readline().split()[1])
max_pos = float(f.readline().split()[1])
num_pos = int(f.readline().split()[1])
avg_flag = bool(int(f.readline().split()[1]))
ar_flag = bool(int(f.readline().split()[1]))
th1_val = float(f.readline().split()[1])
th1_avg = int(f.readline().split()[1])
th2_val = float(f.readline().split()[1])
th2_avg = int(f.readline().split()[1])
th3_val = float(f.readline().split()[1])
th3_avg = int(f.readline().split()[1])
f.close()

percent = 0
max_iter = 0
meas_forward = True


force = np.array([])
force_ritorno = np.array([])
pos = np.array([])
pos_sorted = np.array([])

# cnt = 0


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
    print(loadcell_fullscale)


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

    sort = np.argsort(-np.abs(np.round(pos,4)))
    pos_sorted = np.flip(pos[sort])

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
    print(num_pos)
    print("max iter: ", max_iter)


def saveState():
    ff = open(config_path, "w")
    ff.write("loadcell " + str(loadcell_fullscale) + " kg\n")
    ff.write("min_pos " + str(min_pos) + " mm\n")
    ff.write("max_pos " + str(max_pos) + " mm\n")
    ff.write("num_pos " + str(num_pos) + " \n")
    ff.write("media " + str(int(avg_flag)) + " \n")
    ff.write("ritorno " + str(int(ar_flag)) + " \n")
    ff.write("th1_val " + str(th1_val) + " mm\n")
    ff.write("th1_avg " + str(th1_avg) + " \n")
    ff.write("th2_val " + str(th2_val) + " mm\n")
    ff.write("th2_avg " + str(th2_avg) + " \n")
    ff.write("th3_val " + str(th3_val) + " mm\n")
    ff.write("th3_avg " + str(th3_avg) + " \n")
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
    startButton.configure(text="Initializing...")

    global min_pos, max_pos, num_pos, percent, force, force_ritorno, pos, pos_sorted

    min_pos = float(min_pos_entry.get())
    max_pos = float(max_pos_entry.get())
    num_pos = int(num_pos_entry.get())
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

    populatePosArray()
    print(pos)
    print(pos_sorted)

    percent = 0

    Thread(target=saveState).start()
    t = Thread(target=serialListener)
    t.start()
    # return

def prepareMsgSerialParameters():
    # global loadcell_fullscale, min_pos, max_pos, num_pos, avg_flag, ar_flag, th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg
    param_array = [loadcell_fullscale, min_pos, max_pos, num_pos, avg_flag, ar_flag, th1_val, th1_avg, th2_val, th2_avg, th3_val, th3_avg]
    msg = ''
    for param in param_array:
        if isinstance(param, bool):
            msg += str(int(param)) + " "
        else:
            msg+= str(param)+" "
    return msg



def serialListener():
    global percent, force, force_ritorno, max_iter, meas_forward
    with serial.Serial("COM9", 38400) as ser:
        index = 0
        iter_count = 0
        meas_index = 0
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
                ser.write("Ready to write\n".encode())
                print(data)

            if compare_strings(data, "Parameters"):
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
                for p in pos_sorted:
                    # byte = struct.pack('!f', p) 
                    # msg+=byte
                    msg += str(p)+" "     
                print(msg)                               
                ser.write(msg.encode())
                # ser.write(str(pos_sorted[index]).encode())
                # print(pos_sorted[index])
                # index += 1

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
                if meas_forward:
                    force = np.append(force, meas_val)
                else:
                    force_ritorno = np.append(force_ritorno, meas_val)

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
    startButton.configure(text="START")
    print(force)
    print(force_ritorno)
    sort = np.argsort(pos_sorted)
    force = force[sort]
    if(ar_flag):
        force_ritorno = force_ritorno[sort]
    drawPLots()


def drawPLots():
    # plotts
    ax_force.clear()
    ax_force.plot(pos, force)
    if(ar_flag):
        ax_force.plot(pos, force_ritorno)
        ax_force.legend(["Andata", "Ritorno"])
    ax_force.set_xlabel("displacement [mm]")
    ax_force.set_ylabel("force [N]")
    ax_force.set_title("Force vs Displacement")
    ax_force.grid(visible=True, which="both", axis="both")

    ax_stiff.clear()
    ax_stiff.plot(pos, force / pos)
    if (ar_flag):
        ax_stiff.plot(pos, force_ritorno / pos)
        ax_stiff.legend(["Andata", "Ritorno"])
    ax_stiff.set_xlabel("displacement [mm]")
    ax_stiff.set_ylabel("stiffness [N/mm]")
    ax_stiff.set_title("Stiffness vs Displacement")
    ax_stiff.grid(visible=True, which="both", axis="both")

    chart_type_force.draw()
    chart_type_stiff.draw()


def panic():
    return

def thr_and_avg_setting_func():
    topWindow = ThrAvgWindows(app)
    # topWindow.grab_set()
    app.update()




#############################################################################
# ---------------------------C R E A T E   A P P-----------------------------
#############################################################################
# appearance
customtkinter.set_appearance_mode("light")
customtkinter.set_default_color_theme("blue")

# create app
app = customtkinter.CTk()
app.geometry("880x700")
app.title("MyApp")

leftFrame = customtkinter.CTkFrame(app, 100, 500, fg_color="lightgray")
leftFrame.pack(
    side=customtkinter.LEFT, padx=20, pady=20, fill="y", expand=False, anchor="w"
)

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
filemenu.add_command(label="Open", command=donothing)
filemenu.add_command(label="Save", command=donothing)
filemenu.add_command(label="Save as...", command=donothing)
filemenu.add_separator()
filemenu.add_command(label="Exit", command=app.quit)

menubar.add_cascade(label="File", menu=filemenu)


velacc_window = None
settingmenu = Menu(menubar, tearoff=0)
settingmenu.add_command(label="Vel & Acc", command=donothing)#=vel_and_acc_setting_func)
settingmenu.add_command(label="Medie & Soglie", command=thr_and_avg_setting_func)

menubar.add_cascade(label="Impostazioni", menu=settingmenu)


#############################################################################
# ----------------------------E L E M E N T S--------------------------------
#############################################################################

loadcell_label = customtkinter.CTkLabel(
    leftFrame, text="Selezionare cella di carico", anchor="s"
)


load_cell_menu = customtkinter.CTkOptionMenu(
    leftFrame, values=["1 kg", "3 kg", "10 kg", "50 kg"], command=setLoadCell
)
load_cell_menu.set(str(loadcell_fullscale) + " kg")


min_pos_label = customtkinter.CTkLabel(
    leftFrame, text="Posizione negativa massima", anchor="s"
)

min_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(min_pos))
)
if float(min_pos_entry.get()) > 0:
    min_pos_entry.insert(0, "-")


max_pos_label = customtkinter.CTkLabel(
    leftFrame, text="Posizione positiva massima", anchor="s"
)

max_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(max_pos))
)


num_pos_label = customtkinter.CTkLabel(
    leftFrame, text="Numero pari di punti spaziali", anchor="s"
)

num_pos_entry = customtkinter.CTkEntry(
    leftFrame, textvariable=customtkinter.StringVar(app, str(num_pos))
)


checkbox = customtkinter.CTkCheckBox(leftFrame, text="Media", command=setAvgFlag)
checkbox.configure(variable=customtkinter.BooleanVar(app, avg_flag))

checkbox_AR = customtkinter.CTkCheckBox(leftFrame, text="Andata e Ritorno", command=setARFlag)
checkbox_AR.configure(variable=customtkinter.BooleanVar(app, ar_flag))


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

# positioning
leftFrame.grid_rowconfigure(1, weight=1)
leftFrame.grid_rowconfigure(3, weight=1)
leftFrame.grid_rowconfigure(5, weight=1)
leftFrame.grid_rowconfigure(7, weight=1)
leftFrame.grid_rowconfigure(8, weight=2)
leftFrame.grid_rowconfigure(9, weight=2)
leftFrame.grid_rowconfigure(10, weight=3)

loadcell_label.grid(row=0, column=0, pady=10, padx=20, sticky="w")
load_cell_menu.grid(row=1, column=0, padx=20, sticky="w")

min_pos_label.grid(row=2, column=0, pady=10, padx=20, sticky="w")
min_pos_entry.grid(row=3, column=0, padx=20, sticky="w")

max_pos_label.grid(row=4, column=0, pady=10, padx=20, sticky="w")
max_pos_entry.grid(row=5, column=0, padx=20, sticky="w")

num_pos_label.grid(row=6, column=0, pady=10, padx=20, sticky="w")
num_pos_entry.grid(row=7, column=0, padx=20, sticky="w")

checkbox.grid(row=8, column=0, padx=20, sticky="w")
checkbox_AR.grid(row=9, column=0, padx=20, sticky="w")
startButton.grid(row=10, column=0, padx=20, sticky="ew")


prepareMsgSerialParameters()

app.config(menu=menubar)
app.mainloop()

