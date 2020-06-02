import multiprocessing 
import  numpy as np
from matplotlib import pyplot as plt
from matplotlib import pyplot as plt2
import scipy as sc
from scipy import io
from scipy import signal as sig
import time as tm
import queue
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
    aux = input_matrix['Ry']
    array = np.zeros(len(aux),dtype='complex128')
    for i in range(0,len(aux)-1):
        array[i] = aux[i,0]
    return array

def demod(vector):
    start_sample = 143                  
    #start_sample = 411;             
    sinal_bb1_D1 = vector[start_sample-1:] 
    #tem de se subtrair um ao starting sample pq por default o python usa clike indexing ao contrário do matlab que usa fortran indexing
    plt.figure(1)
    plt.polar(np.angle(sinal_bb1_D1),abs(sinal_bb1_D1))
    plt.title("Diagrama polar do sinal útil em banda base")
    plt.show()
    plt.close()

def resp(vector,toneFreq,toneSampRate,T):
    M = 1000
    fa2 = toneSampRate/M
    start_sample = 143                  
    resp = np.angle(vector[start_sample-1:])
    time = np.arange(0,fa2*T,1,dtype='double')/fa2
    time_min = time[start_sample-1:]/60                              
    plt2.figure(1)
    plt2.plot(time_min,resp)
    plt2.axis(xlim=(time_min[0], time_min[len(time_min)-1]),ylim=( min(resp)-0.1, max(resp)+0.1))
    plt2.title("Sinal Desmodulado em fase")
    plt2.xlabel("Tempo(min)")
    plt2.ylabel("Fase(radianos)")

    plt2.show()
    plt2.close()



if __name__ == "__main__":
    Ry =mat2array('Ry_b210_POtimo.mat')
 
    toneFreq = 10e3
    toneAmp = 1
    toneSamples = 1
    toneComplexOut = True
    toneSampRate = 100e3
    toneOutData = 'double'
    T = 100
    time_norm = np.arange(0,toneSampRate*T,1,dtype='double')/toneSampRate
    aux = np.transpose(np.exp(-1j*2*np.pi*toneFreq*time_norm))
    # dá para usar o expm1 se quiseres maior precisão nas contas
    sinal_bb1 = aux * Ry
##Decimação
   
    '''Tive de usar decimação com um filtro fir, pois por default este utiliza um iir cherbichev de oitava ordem
    (tal como o matlab), porém aqui os coeficientes dão valores errados e o resultado final dá um array de NaN
    Para prevenir que o filtro introduza diferenças de fase no sinal final usei a flag, zero_phase
    posteriormente podemos implementar a nossa própria rotina de decimação'''
    idx = 10;
    i=0;
    times=[]
    while(i<idx):
        t = tm.time()   
        M = 1000
        sinal_bb1_D1 = sig.decimate(sinal_bb1,M,20,ftype='fir',zero_phase=True)
        p1 = multiprocessing.Process(target=demod,args=(sinal_bb1_D1,))
        p2 = multiprocessing.Process(target=resp,args=(sinal_bb1_D1,toneFreq,toneSampRate,T))
        p1.start()
        p2.start()

        p1.join()
        p2.join()
        elapsed = tm.time() - t
        i= i +1
        times.append(elapsed)
        print(elapsed)
        print(i)
    print('average time = ',np.mean(times))



