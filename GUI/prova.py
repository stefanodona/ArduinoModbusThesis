# f = open("GUI/config.txt", "r")

# def stocazzo():
#     f = open("GUI/config.txt", "w")
#     f.write("loadcell " + str(loadcell) + " kg\n")
#     f.write("min_pos " + str(min_pos) + " mm\n")
#     f.write("max_pos " + str(max_pos) + " mm\n")
#     f.write("num_pos " + str(num_pos) + " \n")
#     f.write("media " + str(bool(avg_flag)) + " \n")
#     f.close()  

# loadcell = int(f.readline().split()[1])
# min_pos = float(f.readline().split()[1])

# max_pos = float(f.readline().split()[1])
# num_pos = int(f.readline().split()[1])
# avg_flag = bool(f.readline().split()[1])

# print(loadcell)
# print(min_pos)
# print(max_pos)
# print(num_pos)
# print(avg_flag)

# loadcell= 10
# min_pos = -10
# max_pos = 60
# num_pos = 30
# avg_flag = True

# stocazzo()

import serial.tools.list_ports

print(serial.tools.list_ports.comports()[0][0])