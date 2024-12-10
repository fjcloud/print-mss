from flask import Flask, request, jsonify
import socket
import struct
import fcntl
import os

app = Flask(__name__)

def get_interface_mtu(interface):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # SIOCGIFMTU = 0x8921
    return struct.unpack('<I', fcntl.ioctl(sock.fileno(), 0x8921, struct.pack('256s', interface[:15].encode()))[16:20])[0]

@app.route('/')
def get_connection_info():
    client_ip = request.remote_addr
    client_port = request.environ.get('REMOTE_PORT')
    server_ip = request.host.split(':')[0]
    
    sock = socket.fromfd(request.environ['wsgi.input'].fileno(), socket.AF_INET, socket.SOCK_STREAM)
    tcp_info = sock.getsockopt(socket.SOL_TCP, socket.TCP_INFO, 192)
    
    # Get MTU of the interface
    interface = os.popen(f"ip route get {client_ip} | grep -Po '(?<=dev )[^ ]*'").read().strip()
    mtu = get_interface_mtu(interface)
    
    return jsonify({
        'client': f'{client_ip}:{client_port}',
        'server': server_ip,
        'interface': interface,
        'mtu': mtu,
        'tcp_window_size': sock.getsockopt(socket.SOL_TCP, socket.SO_RCVBUF),
        'tcp_mss': sock.getsockopt(socket.IPPROTO_TCP, socket.TCP_MAXSEG)
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
