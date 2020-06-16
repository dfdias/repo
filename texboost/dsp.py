
import numpy as np
import matplotlib.pyplot as plt
import scipy as sp
class dsp :
    def __init__(self):
    
    
    def arc_correct(x,debug):
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
            if qq1 > 10
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
               
    