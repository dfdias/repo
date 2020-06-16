import uhd
import numpy as np
import argparse
import threading
import logging
from matplotlib import pyplot as plt
import scipy.io as sio
from datetime import datetime, timedelta
import time
import cmath #need this to deal with complex numbers

CLOCK_TIMEOUT = 1000  # 1000mS timeout for external clock locking
INIT_DELAY = 0.05  # 50mS initial delay before transmit
"""
def tx(usrp,wave,numsamples,samprate):

    

"""
def rx(usrp, rx_streamer):
    num_channels = rx_streamer.get_num_channels()
    buffer_samps = rx_streamer.get_max_num_samps()
    print("buffersamps",buffer_samps)
    num_samps = buffer_samps
    result = np.empty((num_channels,buffer_samps),dtype=np.complex64)
    metadata = uhd.types.RXMetadata()
    recv_buffer = np.zeros(
            (num_channels, buffer_samps), dtype=np.complex64)
    recv_samps = 0
    
    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.start_cont)
    stream_cmd.stream_now = True
    rx_streamer.issue_stream_cmd(stream_cmd)
    samps = np.array([],dtype = np.complex64)
    while recv_samps < num_samps:
        samps = rx_streamer.recv(recv_buffer,metadata)
        if metadata.error_code != uhd.types.RXMetadataErrorCode.none:
            print(metadata.strerror())
        if samps:
            real_samps = min(num_samps - recv_samps, samps)
            result[:, recv_samps:recv_samps + real_samps] = recv_buffer[:, 0:real_samps]
            recv_samps += real_samps

    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.stop_cont)
    rx_streamer.issue_stream_cmd(stream_cmd)
    
    return result    
    
    
    
    

def tx_work_unit(waveform,tx_streamer,duration,num_channels,rate,channels):
    buffer_samps = tx_streamer.get_max_num_samps()
    proto_len = waveform.shape[-1]
    
    if proto_len < buffer_samps:
        waveform = np.tile(waveform,(1, int(np.ceil(float(buffer_samps/proto_len)))))
        proto_len = waveform.shape[-1]
    
    metadata = uhd.types.TXMetadata()
    send_samps = 0
    max_samps = int(np.floor(duration * rate))
    
    if len(waveform.shape) == 1:
        waveform = waveform.reshape(1,waveform.size)
    if waveform.shape[0] < len(channels):
        waveform = np.tile(waveform[0],(len(channels),1))
    
    while send_samps < max_samps:
        real_samps = min(proto_len, max_samps-send_samps)
        if real_samps < proto_len:
            samples = tx_streamer.send(waveform[:, :real_samps], metadata)
        else:
            samples = tx_streamer.send(waveform,metadata)
        send_samps += samples
    
    tx_streamer = None
    return send_samps


def main():
    '''Estou a seguir quase à linha o código que fiz em C++'''
    
    #RF Frontend Setup
    device_args = "serial=308F981"
    subdevTX ="A:A"
    subdevRX ="A:B"
    ant_tx = "TX/RX"
    ant_rx = "RX2"
    rx_gain = 76
    tx_gain = 70
    ref = "internal"
    sampRateSig = 400e3;
    sampRate = 400e3
    num_samples = 2040
    freq = 5.9e9
    
    
    usrp = uhd.usrp.MultiUSRP(device_args)
    usrp.set_rx_subdev_spec(uhd.usrp.SubdevSpec(subdevRX))
    usrp.set_tx_subdev_spec(uhd.usrp.SubdevSpec(subdevTX))
    print(usrp.get_pp_string())
    usrp.set_clock_source(ref)
    usrp.set_rx_antenna(ant_rx)
    usrp.set_tx_antenna(ant_tx)
    usrp.set_rx_bandwidth(sampRate)
    usrp.set_tx_bandwidth(sampRate)
    usrp.set_rx_rate(sampRate)
    usrp.set_tx_rate(sampRate)
    usrp.set_rx_gain(rx_gain)
    usrp.set_tx_gain(tx_gain)
  
    tune=uhd.types.TuneRequest(target_freq=freq) # this one was an hard sob
    usrp.set_tx_freq(tune_request=tune,chan=0)
    usrp.set_rx_freq(tune_request=tune,chan=0)
    

    usrp.set_time_now(uhd.types.TimeSpec(0.0))
    
    
    print("USRP CONFIG REPORT")
    print(usrp.get_pp_string())
    print("USRP RX ANTENNA =>",usrp.get_rx_antenna())
    print("USRP TX ANTENNA =>",usrp.get_tx_antenna())
    print("USRP RX RATE =>",usrp.get_rx_rate())
    print("USRP TX RATE =>",usrp.get_tx_rate())
    print("USRP RX GAIN =>",usrp.get_rx_gain(),"dB")
    print("USRP TX GAIN =>",usrp.get_tx_gain(),"dB")
    print("USRP TX freq =>", usrp.get_tx_freq()/1e9,"GHz")
    print("USRP RX freq =>", usrp.get_rx_freq()/1e9,"GHz")
    
    
    ##TX Wave configure 
    tone_freq = 10e3
    t = np.arange(0,2040,dtype=np.complex64)/sampRate
    print(len(t))
    print(t)
   # sin = np.sin(t*tone_freq*np.pi*2)
    teta =t*tone_freq*np.pi*2
    csin =(np.exp(teta*1j)+np.exp(-teta*1j))/(2*1j)
    print("complexSin",csin)
    duration = len(csin)*(1/sampRate)*4
    plt.figure(1)
    #plt.plot(t,sin)
    plt.show(block=False)
    sio.savemat('recv.mat',{'in':csin})

    st_args = uhd.usrp.StreamArgs("fc32","sc16")
    st_args.channels = []
    tx_streamer = usrp.get_tx_stream(st_args)
    st_args.channels = []
    rx_streamer = usrp.get_rx_stream(st_args)
    thread = threading.Thread(target=tx_work_unit,args=(csin,tx_streamer,duration,1,sampRate,[0]))
    ##rx thread launch
    thread.start()

    a = rx(usrp,rx_streamer)
    thread.join()
    print(a)
    
    #t = np.linspace(1,len(a))    
    plt.figure(2)
    plt.plot(np.real(a))
    plt.show()
    sio.savemat('recv.mat',{'a':a})
        
    




if __name__ == "__main__":
    main()