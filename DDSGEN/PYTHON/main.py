import numpy as np
from matplotlib import pyplot as plt
from dds_gen import dds_gen
import sounddevice as sd
import queue
import threading
def main():
    q = queue.Queue()    
    fs = 192000
    N = 2048
    f0 = 1e3
    NumSamp = 192000*10
    dds = dds_gen(N,fs)
    a = dds.gen(f0,NumSamp)
    sd.default.samplerate = 192000
    sd.play(a)

    threads =  []
    ax1 = threading.Thread(target=dds.gen_threaded,args=(f0,NumSamp,q),daemon=False)
    threads.append(ax1)
    ax = threading.Thread(target=audioOutput,args=(q,fs,ax1),daemon=False)
    threads.append(ax)
    i = 0 
    for i in range(0,len(threads)):
        threads[i].start()

def audioOutput(txqueue,fs,ax1):
    #print('here2')
    sd.default.samplerate = 192000
    while(1):
        a = txqueue.get()
        sd.play(a)
            
if __name__ == "__main__":
    main()