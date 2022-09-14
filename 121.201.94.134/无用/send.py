import socket
import os

p = socket.socket()
r = p.connect_ex(('121.201.125.74',8080))
if r == 0:
    msg = '1'
    p.send(msg.encode('utf-8'))    
else:
    print("connect failed. The other server is waiting for the recovery")

p.close()