from tabulate import tabulate
import os
import numpy as np
from datetime import datetime

TRACKING_HEADER = ["\n# pos [mm]","\nforce [N]", "\ntime [ms]"]
STATIC_HEADER = [["\n# x_forw [mm]", "\nf_forw [N]", "\nkms_forw [N/mm]"],
                 ["\n# x_back [mm]", "\nf_back [N]", "\nkms_back [N/mm]"]]


CREEP_HEADER = ["\n# time [s]","\nforce [N]", "\nkms [N/mm]"]

STATIC_HEADER_ONLY_STIFF = [["\n# x_forw [mm]", "\nkms_forw [N/mm]"],
                            ["\n# x_back [mm]", "\nkms_back [N/mm]"]]

def write_stiff_file(array_to_save, spider_name, procedure_id, stiff_path, istant=None, wait_time=None, only_stiff=None):
    root_name = os.path.splitext(stiff_path)[0]
    
    with open(stiff_path, 'w') as fl:
        fl.write("# Acquired on "+ datetime.now().strftime("%d/%m/%Y %H:%M:%S") +" \n")
        fl.write("# SPIDER: " + spider_name + "\n")
        # if np.any(array_to_save):
        if len(array_to_save)>0:
            match procedure_id:
                case "static":
                    fl.write("# STATIC MEASUREMENT\n")
                    for i in range(0,len(array_to_save)):
                        fl.write(tabulate(array_to_save[i], STATIC_HEADER[i], tablefmt="plain",floatfmt=".5f"))
                        fl.write("\n")

                case "creep":
                    fl.write("# CREEP MEASUREMENT\n")
                    fl.write(tabulate(array_to_save, CREEP_HEADER, tablefmt="plain",floatfmt=".5f"))
                
                case "tracking":
                    fl.write("# TRACKING MEASUREMENT\n")
                    fl.write(tabulate(array_to_save, TRACKING_HEADER, tablefmt="plain",floatfmt=".5f"))
                
                case "tracking_this_curve":
                    fl.write("# TRACKING CURVE AT ISTANT "+ str(istant) + " ms\n")
                    for i in range(0,len(array_to_save)):
                        if only_stiff:
                            fl.write(tabulate(array_to_save[i], STATIC_HEADER_ONLY_STIFF[i], tablefmt="plain",floatfmt=".5f"))
                        else:
                            fl.write(tabulate(array_to_save[i], STATIC_HEADER[i], tablefmt="plain",floatfmt=".5f"))
                        fl.write("\n")
                
                case "tracking_all_curves":
                    fl.write("# ALL TRACKING CURVES\n")
                    for i in range(0,len(array_to_save)):
                        #dentro a ogni snapshot
                        fl.write("# t = "+str((i+1)*100)+" ms\n")
                        # entro in forw o back
                        for j in range(0,len(array_to_save[i])): 
                            if only_stiff:
                                fl.write(tabulate(array_to_save[i][j], STATIC_HEADER_ONLY_STIFF[j], tablefmt="plain",floatfmt=".5f"))
                            else:
                                fl.write(tabulate(array_to_save[i][j], STATIC_HEADER[j], tablefmt="plain",floatfmt=".5f"))
                            fl.write("\n")
                        fl.write("\n")
                case _:
                    fl.write("gay")
        else:
            print("\nNO DATA TO SAVE\n")
        fl.close()


