#!/usr/bin/python
import socket
import thread
import sys

def on_new_client(clientsocket,addr):
    while True:
        msg = clientsocket.recv(4096)
        print >>sys.stderr, 'received message from client at', addr
        
        if msg:
            print >>sys.stderr, 'sending (same) data back to the client'
            clientsocket.sendall(msg)
        else:
            print >>sys.stderr, 'no more data from', addr
            break
    clientsocket.close()

# Create a socket object
s = socket.socket()
host = '10.0.0.253'
port = 6001

print 'Server started!'
print 'Waiting for clients...'

s.bind((host, port))
s.listen(5)

while True:
    try:
        # Establish connection with the client
        c, addr = s.accept()
        print >>sys.stderr, 'Got connection from', addr
        # Start new thread to manage the newly established tcp session
        thread.start_new_thread(on_new_client,(c,addr))
    except KeyboardInterrupt:
        # Properly close socket upon calling ctrl+c
        print >>sys.stderr, 'keyboard interrupt, closing socket'
        s.close()
s.close()