
import numpy as np
from matplotlib import pyplot as plt
import scipy as sc
from scipy import io
from scipy import signal as sig
import time as tm
import * from dsp
def mat2array(file_name):
    '''
    Receives .mat function name and transforms it in an 1D array(only valid for this use case)
    
    Parameters
    ----------
    file_name : str
       Name of the mat file 

    Returns
    ----------
    1D array
    '''
    input_matrix = sc.io.loadmat(file_name)
    aux = input_matrix['sinal']
    array = np.zeros(len(aux),dtype='complex128')
    for i in range(0,len(aux)-1):
        array[i] = aux[i,0]
    return array

num_sinais = 7
samp_array = mat2array("seg_19.mat")
num_samps = len(samp_array)
S = np.empty((num_sinais,num_samps),dtype='complex128')
for i  in range(19,26,1):
    idx = i-19
    print(idx)
    name = "seg_"+str(i)+".mat"
    print(name+"\n")
    S[idx,:]=mat2array(name)

I_DC  = np.empty((num_sinais,num_samps),dtype='complex128');
Q_DC  = np.empty((num_sinais,num_samps),dtype='complex128');
xD_DC = np.empty((num_sinais,num_samps),dtype='complex128');

for k in range(num_samps-1):
    
    XRt = S[k];
    realXRt = np.real(XRt)
    imagXRt = np.imag(XRt)
    [xc[k].yc[k],Re,a] = dsp.circfit(realXRt,imagXRt)
    I_DC[k][:] = realXRt -xc(k);
    Q_DC[k][:] = imagXRt - yc(k)
    xD_DC[k][:] = I_DC[k][:] + (1j*Q_DC[k][:])

