from main import *

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

def populatePosArray():
    global pos, pos_sorted
    pos = np.linspace(min_pos, max_pos, num_pos)

    sort = np.argsort(-np.abs(pos))
    pos_sorted = np.flip(pos[sort])

def setAvgCnt(val):
    global cnt
    th1 = 1 # mm
    th2 = 3 # mm
    th3 = 5 # mm
    if (abs(val)<=th3):
        cnt = 2
    if (abs(val)<=th2):
        cnt = 4
    if (abs(val)<=th1):
        cnt = 6
    else:
        cnt = 1


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
    if (num_pos%2==1):
        num_pos+=1
        num_pos_entry.configure(textvariable=customtkinter.StringVar(app, str(num_pos)))

    print(min_pos)
    print(max_pos)
    print(num_pos)

    populatePosArray()
    print(pos)
    print(pos_sorted)

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
                if ser.writable():
                    ser.write(str(loadcell_fullscale).encode())

            if compare_strings(data, "min_pos"):
                ser.write(str(min_pos).encode())

            if compare_strings(data, "max_pos"):
                ser.write(str(max_pos).encode())

            if compare_strings(data, "num_pos"):
                ser.write(str(num_pos).encode())

            if compare_strings(data, "media"):
                ser.write(str(avg_flag).encode())

            if compare_strings(data, "centratore"):
                time.sleep(1)
                ser.write('\n'.encode())
            
            if compare_strings(data, "Measure Routine"):
                i=0
                while i<num_pos:
                    print("ahia")
            

            if compare_strings(data, "Finished"):
                # print("matched")
                ser.close()
                break

    load_cell_menu.configure(state="normal")
    min_pos_entry.configure(state="normal")
    max_pos_entry.configure(state="normal")
    num_pos_entry.configure(state="normal")
    startButton.configure(state="normal")
    