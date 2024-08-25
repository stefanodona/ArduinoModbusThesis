from tabulate import tabulate 
import numpy as np
import os

a_1 = np.array([1,2,3,4])
a_2 = np.array([5,6,7,8])
a_3 = np.array([9,10,11,12])

arr_1 = np.array([a_1,a_2,a_3])
arr_2 = np.transpose(arr_1)

print(arr_1)
print(arr_2)


file_path = os.getcwd()
ciao = os.path.relpath(file_path)
print (ciao)
print (os.path.abspath(ciao))

a = [1,2,3]

print(a)
# a.append([4,5,6])
b = []
b.append(a)
b.append([4,5,6])
print(b)