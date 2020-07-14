
import numpy as np
import matplotlib.pyplot as plt
import scipy as sp
class dsp :
    def __init__(self):
        return 0
    
    def arc_correct(self,x,debug):
        """ arc correction algorithm
            x => input vector
            debug => toggles plots (bool)
        """
        xrot = x
        Q = np.angle(x)
        rad = (6*np.pi)/8;
        R = np.find(Q > rad or Q < -rad)
        qq1 = 0;

        while (R.len() != 0) :
            aux = np.exp(-j*(np.pi/5))
            x_rot = aux * x
            x_rot_i = np.imag(x_rot)
            x_rot_r = np.real(x_rot)
            Q = np.angle(x_rot)

            #roda pi/5
            R = np.find(Q > rad or Q < -rad)
            qq1 += 1;

            if debug :
                plt.polar(np.angle(x_rot),np.abs(x_rot))
                plt.show()
            if qq1 > 10:
                if debug :
                    print("Terminadas as 10 voltas \n")
                y_min = min(x_rot_i)
                y_max = max(x_rot_i)
                y_width = y_max - y_min

                x_min = min(x_rot_r)
                x_max = max(x_rot_r)
                x_width = x_max - x_min

                coef = np.polyfit(x_rot_r,x_rot_i,2,full=False)[0]
                
                if debug :
                    print("Xwidth = ", x_width)
                    print('Ywidth = ', y_width)
                    print('Coef = ', coef)

                flag = True;
                qq3 = 0;
                cond1 = x_width > 0.01
                bool = 1;
                cond2 = True
                cond3 = Ywidth < Xwidth
                print('stage2 \n')
                while cond1 or cond3 or cond2 :
                    x_rot = x_rot*aux
                    x_rot_i = np.imag(x_rot)  #talvez reciclar aqui um pouco de código
                    x_rot_r = np.real(x_rot)
                    y_min = min(x_rot_i)
                    y_max = max(x_rot_i)
                    y_width = y_max - y_min

                    x_min = min(x_rot_r)
                    x_max = max(x_rot_r)
                    x_width = x_max - x_min

                    coef1 = np.polyfit(x_rot_r,x_rot_i,2,full=False)[0]

                    coefs = [coef,coef1]
                    
                    if debug :
                        print("Xwidth = ", x_width)
                        print('Ywidth = ', y_width)
                        print('Coef = ', coef)
                        plt.polar(np.angle(x_rot),np.abs(x_rot))
                
                qq3 = qq3 + 1   #incrementa uma volta

                if  flag is False :
                    if coefs[coefs.len-2] < 0 and coeffvals(end) > 0:
                        bool = True
                    else  :
                        bool = False
                
                cond1 = x_width > 0.01
                cond3 = ywidth < x_width
                cond2 = bool
                if qq3 == 10 and flag == 0:
                    print("It wasn't possible to optimize the arc yet")
                    cond1 = x_width > 0.03
                    flag = True
                    qq3 = 0
                    bool = False
                elif qq3 == 10 and flag ==1 :
                    print("no arc optimization was performed")
                    break
        #Fase 3
        Q = np.angle(x_rot)
        R = np.find(Q > rad or Q < -rad)
        offset = 1e-4
        if debug :
            print("Beginning offset")
        x_min = np.min(np.real(x_rot))
        while x_min <= 0 :
            x_rot += offset
            offset += 1e-4
            Q = np.angle(x_rot)
            R = np.find(Q > rad or Q < -rad)       
            x_min = np.min(np.real(x_rot))
            
            if debug:
                plt.polar(np.angle(x_rot),np.abs(x_rot))
        return 0            

    def rate_calc(x,fa):
        angle = np.angle(x)
        resp = angle - np.mean(angle)
        L = len(resp)
        nfft = np.ceil(np.log2(np.abs(L))) #nextpow2
        F1, F2 = sp.signal.welch(resp,window=[],noverlap=[],nfft=10*nfft,fs=fa)
        F2i = np.linspace(F2[0],F2[len(F2)-1],len(F2))
        p = sp.signal.welch(resp,window=[],noverlap=[],nfft=nfft,fs=fa2)    
        t_interp = np.linspace(np.min(F2i),np.max(F2i),10*len(F2i));
        x_interp = F2i
        locs,peaks = sp.signal.find_peaks(F2i,'peak_heights')
        locs, peaks = sort_peaks(locs,peaks) #sorting peaks 
        if t_interp(locs[0]) > 0.05 & t_interp(locs[0]) < 0.55:
            freq = t_interp(locs[0])        
            break;
        elif t_interp(locs[1]) > 0.05 & t_interp(locs[1]) <0.55:
            freq = t_interp(locs(2));
        else :
            f = fa/2*linspace(0,1,(nftt*10)/2+1)
            test = sp.signal.fft(resp,nfft*10/2 +1)/L
            t_interp = linspace(min(f),max(f),10*len(nfft))
            x_interp = test
            locs, peaks = find_peaks(np.abs(x_interp[1:(10*nfft/2+1)])]
            locs, peaks = sort_peaks(locs,peaks)
            freq = (locs[0]/len(x_interp))*fa
            if freq > 0.05:
                freq = (locs[0]/len(x_interp))*fa
            else :
                freq = (locs[1]/len(x_interp))*fa
        rate = freq
        print("frequência detetada : ",rate, " Hz\n");
        return rate

    def sort_peaks(self,locs,peaks):
        aux_locs = 0 ;
        aux_peaks = 0;
        for i in range(0,len(locs)-1):
            if peaks[i] < peaks[i+1]
                aux_peaks = peaks[i]
                aux_locs = locs[i]
                peaks[i] = peaks[i+1]
                locs[i] = locs[i+1]
                peaks[i+1] = aux_peaks
                locs[i+1] = aux_locs
    return locs,peaks
                     

    def circfit(self,x,y):
        a = [x y np.ones(lenx(x))]\[-(np.exp2(x)+np.exp2(y))]
        xc = -0.5*a[0]
        yc = -0.5*a[1]
        R = np.sqrt(np.exp2(a[0])+np.exp2(a[1])/(4-a[2])

        return xc,yc,R,a