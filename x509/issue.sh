#!/bin/bash

TMP="/tmp"

# first FIDO device found:
HID="$(fido2-token -L | tail -1 | cut -d: -f1-2)"

now=$(date -u "+%y%m%d%H%M%SZ")
thn=$(date -u -v+1y "+%y%m%d%H%M%SZ")
serial=$(head -c16 </dev/urandom|xxd -p)

# generate passkey
challenge=$(head -c32 </dev/urandom| base64)
relyingparty="localhost"
username="test"
userid=$(head -c32 </dev/urandom|xxd -p -c32)

echo Generate passkey...
echo $challenge > $TMP/cred.in
echo $relyingparty >> $TMP/cred.in
echo $username >> $TMP/cred.in
echo $userid  >> $TMP/cred.in

fido2-cred -M -r -i $TMP/cred.in "$HID" > $TMP/cred.out
cat $TMP/cred.out | fido2-cred -V -o $TMP/cred

# extract the public key from the credential
tail -n +2 $TMP/cred > pubkey.pem

# quick & dirty: extract public key bytes from a EC p256 public key
pubkey=$(openssl pkey -in pubkey.pem -pubin -outform der | tail -c +27 | xxd -p | tr -d '\n')

echo Generate certificate
# X.509 certificate template before signing
cat << EOF > $TMP/tbs.asn1
asn1 = SEQUENCE:tbs

[tbs]
version = EXPLICIT:0,INTEGER:0x02
serialNumber = INTEGER:0x$serial
signatureAlgorithm = SEQUENCE:ecdsa-with-SHA256
issuer = SEQUENCE:issuerDN
validity = SEQUENCE:validity
subject = SEQUENCE:subjectDN
subjectPKInfo = SEQUENCE:PublicKeyInfo

[validity]
notbefore = UTCTime:"$now"
notafter = UTCTIME:"$thn"

[issuerDN]
dn = SET:issuerRDN
[issuerRDN]
cn = SEQUENCE:issuerCN
[issuerCN]
cn = OBJECT:commonName
val = FORMAT:UTF8,UTF8String:"Example CA"

[subjectDN]
dn = SET:subjectRDN
[subjectRDN]
cn = SEQUENCE:subjectCN
[subjectCN]
cn = OBJECT:commonName
val = FORMAT:UTF8,UTF8String:"test"

[PublicKeyInfo]
algorithm = SEQUENCE:algorithm
subjectPublicKey = FORMAT:HEX,BITSTRING:$pubkey

[algorithm]
algorithm = OBJECT:id-ecPublicKey
parameters = OBJECT:prime256v1

[ecdsa-with-SHA256]
algorithm = OBJECT:ecdsa-with-SHA256
EOF

# compile ASN.1
openssl asn1parse -genconf $TMP/tbs.asn1 -out $TMP/tbs.der >/dev/null

# sign using CA key
openssl dgst -binary -sha256 -out $TMP/hash.bin $TMP/tbs.der
openssl pkeyutl -sign -inkey cakey.pem -in $TMP/hash.bin -out $TMP/sig.der
# just checking: verify signature
openssl dgst -sha256 -prverify cakey.pem -signature $TMP/sig.der $TMP/tbs.der

# Generate certificate ASN.1, include CA signature
cat << EOF > $TMP/crt.asn1
asn1 = SEQUENCE:x509

[x509]
x509 = SEQUENCE:tbs
alg = SEQUENCE:ecdsa-with-SHA256
sig = FORMAT:HEX,BITSTRING:$(xxd -p /tmp/sig.der | tr -d '\n')
EOF
cat $TMP/tbs.asn1 | grep -v ^asn1 >> $TMP/crt.asn1
# compile ASN.1
openssl asn1parse -genconf $TMP/crt.asn1 -out cert.der >/dev/null

# verify CA signature
openssl verify -CAfile cacert.pem cert.der
openssl x509 -in cert.der -inform der -noout -text

echo Store certificate largeBlob
fido2-token -S -b -n localhost cert.der ${HID}
