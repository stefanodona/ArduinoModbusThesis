import serial
import re
import time
import keyboard
import numpy as np
import matplotlib.pyplot as plt
# from serial import Serial

force=np.array([])
pos=np.array([])
plt.close('all')

def compare_strings(string1, string2):
    pattern = re.compile(string2)
    match = re.search(pattern, string1)
    return match

with serial.Serial('COM9', 9600) as ser:
    while True:
        if keyboard.is_pressed('q'):
            print('Exiting')
            break
        
        try:
            data = ser.readline()
        except:
            print("SeiScemo")

        data = data.decode()
        
        print(data)
        if(compare_strings(data, "fondoscala")):
            print("matched")
            ser.write("1\n".encode(),)
        if(compare_strings(data, "negativo")):
            print("matched")
            ser.write("15\n".encode())
        if(compare_strings(data, "positivo")):
            print("matched")
            ser.write("15\n".encode())
        if(compare_strings(data, "punti")):
            print("matched")
            ser.write("4\n".encode())
        if(compare_strings(data, "piccoli")):
            print("matched")
            ser.write("\n".encode())

        if(compare_strings(data, "enter")):
            time.sleep(1)
            print("matched")
            ser.write("\n".encode())

        if(compare_strings(data, "IDX")):
            arr = data.split()
            force = np.append(force, [float(arr[-2])])
            pos = np.append(pos, [float(arr[-5])])
            # force.append(float(arr[-2]))
            # pos.append(float(arr[-5]))
        if(compare_strings(data, "completato")):
            break

        # time.sleep(1)

ser.close()
print(ser.is_open)
print(pos)
print(force)
sort = np.argsort(pos)
print('--------------')
print('sorted')
print(pos[sort])
print(force[sort])

plt.figure(figsize=(10,6), layout="constrained")

plt.subplot(211)
plt.plot(pos[sort], force[sort])
plt.grid()
plt.title("Force vs Displacement")

plt.subplot(212)
plt.plot(pos[sort], force[sort]/pos[sort])
plt.grid()
plt.title("Stiffness vs Displacement")

plt.show()

