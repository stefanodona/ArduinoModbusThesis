import tkthread; tkthread.patch()


import tkinter as tk
from tkinter import ttk
import customtkinter as ctk
from threading import Thread
import time
# from typing import Optional, Tuple, Union

confirm_flag=None

class ConfirmTopLevel(ctk.CTkToplevel):
    def __init__(self, *args, fg_color: str | tuple[str, str] | None = None, **kwargs):
        global confirm_flag
        confirm_flag = False
        super().__init__(*args, fg_color=fg_color, **kwargs)
        # self.okVar = ctk.BooleanVar(self, False)

        self.title("Conferma Azione")

        self.labelText = ctk.StringVar(self, "Test")    

        self.okButton = ctk.CTkButton(self, text="OK", command=self.okPressed)
        self.cancelButton = ctk.CTkButton(self, text="Annulla", fg_color="gray", command=self.cancelPressed)
         
        # okButton.pack(side=ctk.LEFT, pady=20)
        self.cancelButton.pack(side = ctk.BOTTOM, expand=True, padx = 10, pady = 20)
        self.okButton.pack(side = ctk.BOTTOM, expand=True, padx = 10)
        
        # cancelButton.pack(side=ctk.BOTTOM, pady=50)
        
        self.label = ctk.CTkLabel(self, textvariable=self.labelText)
        self.label.pack(padx=50, pady=50, side=ctk.BOTTOM)
        
        self.mainloop()
        # self.wait_variable(self.okVar)
        # app.wait_window(self)


    def okPressed(self, *args):
        # self.okVar.set(True)
        global confirm_flag
        confirm_flag= True
        self.destroy()
        self.update()


    def cancelPressed(self, *args):
        # self.okVar.set(False)
        global confirm_flag
        confirm_flag= False
        self.destroy()
        self.update()

    def setMessage(self, msg, *args):
        self.labelText.set(str(msg)+"\n e premere ok")


def open():
    global topLevel
    topLevel = ConfirmTopLevel(root)
    topLevel.setMessage("ciaociao")
    print(topLevel)
#    root.wait_window(topLevel)
    

def gino():
    root.after(0, open)
    return

def th():
    global topLevel
    Thread(target=tkt(open)).start()
    # time.sleep(1)
    root.wait_window(topLevel)


topLevel = None
ctk.set_appearance_mode("light")
root = ctk.CTk()
tkt = tkthread.TkThread(root)
root.geometry('500x400')
#root.wait_window(topLevel)

myButton = ctk.CTkButton(root, text="open", command=th)
myButton.pack(padx=20, pady=20)

temp = ctk.CTkToplevel(root)
temp.withdraw()

root.bind('<Escape>', root.destroy)

root.mainloop()
