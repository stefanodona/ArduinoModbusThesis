from tkthread import tk, TkThread

root = tk.Tk()        # create the root window
tkt = TkThread(root)  # make the thread-safe callable

import threading, time
def run(func):
    threading.Thread(target=func).start()

run(lambda:     root.wm_title('FAILURE'))
run(lambda: tkt(root.wm_title,'SUCCESS'))

root.update()
time.sleep(2)  # _tkinter.c:WaitForMainloop fails
root.mainloop()
