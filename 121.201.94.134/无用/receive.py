# this py will run backend when the server restart

import socket
import os

ip_port = ('121.201.94.134',8080)
back_log = 5
buffer_size = 1024

ser = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
ser.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)

ser.bind(ip_port)
ser.listen(back_log)

while 1:
    con,address = ser.accept()
    msg = con.recv(buffer_size)
    if msg.decode('utf-8') == '1':
        print("the slave has become the master, and now the master should become the slave")
        os.system("/root/reset_to_slave.sh")
#ser.close()
