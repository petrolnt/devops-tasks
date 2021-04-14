import base64
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
import sys
import socket

def unpad(s):
    return s[:-ord(s[len(s)-1:])]

def decrypt( enc, user_key ):
    
    enc = base64.b64decode(enc)
    iv = enc[:16]
    enc = enc[16:]
    
    cipher = AES.new(key, AES.MODE_CBC, iv )
    return unpad(cipher.decrypt( enc ))

with open('env.dat') as f:
    enc = f.readline()
host = socket.gethostname()
hash = SHA256.new()
hash.update(host)
key = hash.digest()
if(len(enc)):
    print(decrypt(enc, key ))
