import tkinter as tk
import customtkinter
from math import pi, cos, sin
from typing import Optional, Tuple, Union


class Meter(customtkinter.CTkToplevel):
    def __init__(self, master, bounds, *args, fg_color: str | Tuple[str, str] | None = None, **kwargs):
        super().__init__(master, *args, fg_color=fg_color, **kwargs)

        self.frame = customtkinter.CTkFrame(self)
        self.frame.pack()
        self.var = tk.IntVar(self, 0)

        self.canvas = customtkinter.CTkCanvas(self.frame, width=400, height=220,
                                borderwidth=2, relief='sunken',
                                bg='white')
        # self.scale = tk.Scale(self, orient='horizontal', from_=-50, to=50, variable=self.var)
        
        
        
        self.angle = 90
        span = 140 # degrees
        start_angle = (180-span)/2



        col = ["light gray","red","yellow","green"]
        for i in range(int(len(bounds)/2)):
            span_i = span/(bounds[1]-bounds[0])*(bounds[i*2+1]-bounds[i*2])
            print(i)
            print(span_i)
            print("____")
            start_angle_i = (180-span_i)/2
            self.canvas.create_arc(10, 10, 390, 390, extent=span_i, start=start_angle_i,
                                   style='pieslice', fill=col[i])
            
        self.center = self.canvas.create_line(200, 10, 200, 40,
                                            fill='white',
                                            width=3)
        
        self.meter = self.canvas.create_line(200, 200, 20, 200,
                                             fill='black',
                                             width=8,
                                             arrow='last')

        self.canvas.pack(fill='both')
        # self.scale.pack()

        self.var.trace_add('write', self.updateMeter)  # if this line raises an error, change it to the old way of adding a trace: self.var.trace('w', self.updateMeter)

    def updateMeterLine(self, a):
        """Draw a meter line"""
        self.angle = a

        x = 200 - 190 * cos(a * pi / 180)
        y = 200 - 190 * sin(a * pi / 180)
        self.canvas.coords(self.meter, 200, 200, x, y)

    def updateMeter(self, op):
        """Convert variable to angle on trace"""
        # mini = self.scale.cget('from')
        # maxi = self.scale.cget('to')
        mini = bounds[0]
        maxi = bounds[1]
        pos = (op - mini) / (maxi - mini)
        # self.updateMeterLine(pos * 0.6 + 0.2)
        self.updateMeterLine(20+pos*140)

if __name__ == '__main__':
    root = customtkinter.CTk()
    bounds = [0, 4 ,
              1, 3, 
              1.5, 2.5
              ]
    print(range(int(len(bounds)/2)))
    meter = Meter(root, bounds)
    meter.updateMeter(1)
    root.mainloop()