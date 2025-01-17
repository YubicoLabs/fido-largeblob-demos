#!/bin/bash

TMP="/tmp"

# first FIDO device found:
HID="$(fido2-token -L | tail -1 | cut -d: -f1-2)"

challenge=$(head -c32 </dev/urandom| base64)

echo $challenge > assert.in
echo localhost >> assert.in

echo retrieving certificate...
# retrieving the certificate public key can be done using fido2-token, but that always requires UV
#fido2-token -G -b -n localhost c.der ${HID}
#openssl x509 -inform der -in c.der -noout -pubkey -out pubkey.pem
# therefore, use a python script using python-fido2
python read_crt.py | openssl x509 -noout -pubkey -out pubkey.pem

echo validating certificate
openssl verify -CAfile cacert.pem cert.der

echo get and verify assertion...
fido2-assert -G -r -i assert.in "$HID" | fido2-assert -V pubkey.pem es256

# succes
openssl x509 -inform der -in cert.der -noout -subject
echo done!
