    #!/usr/bin/python3
import numpy
from gnuradio import analog 
from gnuradio import gr
from gnuradio import blocks
import scipy 
from scipy import io as scio
import numpy as np
import matplotlib.pyplot as plt
import time

class main_block(gr.top_block):
    def __init__(self):
        gr.top_block.__init__(self)
        
        samprate =200e3     #defining global diagram variables
        ampl = 1
        sin_freq = 100e3
        
        
     
        thr = blocks.throttle(gr.sizeof_gr_complex*1,samprate)
        filesink = blocks.file_sink(gr.sizeof_gr_complex*1, 'file3.dat')
        src0 = analog.sig_source_c(samprate,analog.GR_SIN_WAVE,sin_freq,ampl)
        
        self.connect(src0,thr,filesink)
        #self.connect((src0,0),(thr,0))
        #self.connect((thr,0),(filesink,0))


if __name__ == '__main__':
    

    tb = main_block()
    tb.start()
    time.sleep(1)
    tb.stop()
    
    #post_processing
    
    f = np.fromfile(open("file2.dat"),dtype=np.complex64)
    print(f)
    plt.figure(1)
    plt.plot((np.real(f[0:5600])))
    plt.show()
    scio.savemat('data.mat',{'f':f})
  
    

