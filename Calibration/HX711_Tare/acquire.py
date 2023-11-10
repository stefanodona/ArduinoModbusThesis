import numpy as np
import serial 
import keyboard
import time
import re

hor = np.array([])
ver = np.array([])
ver_gancio = np.array([])
hang = np.array([])
hang_gancio = np.array([])

def compare_strings(string1, string2):
    pattern = re.compile(string2)
    match = re.search(pattern, string1)
    return match

with serial.Serial("COM9", 9600) as ser:
    # global hor, ver, hang, hang_gancio
    tmp = np.array([]) 
    while True:
        if keyboard.is_pressed('q'):
            break

        try:
            data = ser.readline()
        except:
            print("Not read")

        data = data.decode()
        print(data)

        if compare_strings(data,"enter"):
            keyboard.wait("enter")
            time.sleep(2)
            ser.write("\n".encode())

        if compare_strings(data, "#1"):
        # if data == "Porre la cella in posizione orizzontale\n":
            print()

        if compare_strings(data, "#2"):
        # if data == "Porre la cella in posizione verticale appoggiata\n":
            hor = np.copy(tmp)
            tmp = np.array([])
            print()

        if compare_strings(data, "#3"):
        # if data == "Porre la cella in posizione verticale appoggiata\n":
            ver = np.copy(tmp)
            tmp = np.array([])
            print()
        
        if compare_strings(data, "#4"):
            ver_gancio = np.copy(tmp)
            tmp = np.array([])
            print()

        if compare_strings(data, "#5"):
            hang = np.copy(tmp)
            tmp = np.array([])
            print()

        if compare_strings(data, "Finito"):
            hang_gancio = np.copy(tmp)
            tmp = np.array([])
            break

        if compare_strings(data, "val"):
            val= float(data.split()[1])
            print(val)
            tmp = np.append(tmp, val)

print(hor)
print(ver)
print(ver_gancio)
print(hang)
print(hang_gancio)

hor_avg = np.average(hor)
hor_std = np.std(hor)

ver_avg = np.average(ver)
ver_std = np.std(ver)

ver_g_avg = np.average(ver_gancio)
ver_g_std = np.std(ver_gancio)

hang_avg = np.average(hang)
hang_std = np.std(hang)

hang_g_avg = np.average(hang_gancio)
hang_g_std = np.std(hang_gancio)

print()
print("Orizzontale - avg: ",hor_avg," std: ", hor_std)
print("Appoggio - avg: ",ver_avg," std: ", ver_std)
print("Appoggio + gancio - avg: ",ver_g_avg," std: ", ver_g_std)
print("Appeso - avg: ",hang_avg," std: ", hang_std)
print("Appeso + gancio - avg: ",hang_g_avg," std: ", hang_g_std)

f = open("./TareData.txt", "w")
f.write("----- TARA CELLA DI CARICO -----\n")
# f.write("\nOrizzontale\t\tavg: "+str(hor_avg)+"\tstd: "+str(hor_std))
# f.write("\nAppoggio\t\tavg: "+str(ver_avg)+"\tstd: "+str(ver_std))
# f.write("\nAppoggio+gancio\tavg: "+str(ver_g_avg)+"\tstd: "+str(ver_g_std))
# f.write("\nAppeso\t\t\tavg: "+str(hang_avg)+"\tstd: "+str(hang_std))
# f.write("\nAppeso+gancio\tavg: "+str(hang_g_avg)+"\tstd: "+str(hang_g_std))
f.write(f"\nOrizzontale\t\t\tavg: {hor_avg:.3f} \tstd: {hor_std:.3f}")
f.write(f"\nAppoggio\t\t\tavg: {ver_avg:.3f} \tstd: {ver_std:.3f}")
f.write(f"\nAppoggio+gancio\t\tavg: {ver_g_avg:.3f} \tstd: {ver_g_std:.3f}")
f.write(f"\nAppeso\t\t\t\tavg: {hang_avg:.3f} \tstd: {hang_std:.3f}")
f.write(f"\nAppeso+gancio\t\tavg: {hang_g_avg:.3f} \tstd: {hang_g_std:.3f}")

f.close()