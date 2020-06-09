import numpy as np
from matplotlib import pyplot as plt
from dds_gen import dds_gen
fs = 192000
N = 2048
f0 = 1e3
NumSamp = 1024
dds = dds_gen(N,fs)
a = dds.gen(f0,NumSamp)
last_phi = dds.getIniPhase()
print("here",last_phi)
b = dds.dumb_gen(2e3,NumSamp,last_phi)
c = np.concatenate((a,b[1,:]))
print(c)
plt.figure(1)
plt.plot(c)
plt.show()
