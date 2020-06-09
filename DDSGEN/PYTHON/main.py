import numpy as np
from matplotlib import pyplot as plt
from dds_gen import dds_gen
fs = 41100
N = 2048
f0 = 4e3
NumSamp = 1024
dds = dds_gen(N,fs)
a = dds.gen(2e3,NumSamp)
last_phi = dds.getIniPhase()
print("here",last_phi)
b = dds.gen(2e3,NumSamp)
c = np.concatenate((a, b))
print (a)
print(b)
plt.figure(1)
plt.plot(c)
plt.figure(2)
plt.plot(a)
plt.figure(3)
plt.plot(b)
plt.show()