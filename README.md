# fido-largeblob-demos

This repository contains demos for the use of FIDO largeBlobs - opaque data that can be stored on a FIDO authenticator such as a YubiKey.

LargeBlobs are part of the [FIDO CTAP spec](https://fidoalliance.org/specs/fido-v2.1-ps-20210615/fido-client-to-authenticator-protocol-v2.1-ps-errata-20220621.html#authenticatorLargeBlobs)
and can also be used from web pages via a [WebAuthn extension](https://www.w3.org/TR/webauthn-2/#sctn-large-blob-extension).

Demos are located in the following subdirectories:

- [ssh-certificate](ssh-certificate): storing SSH certificates, for access to SSH servers.
- [webauthn](webauthn) - a simple example of using largeBlobs from a web page.
- [x509](x509) - storing X.509 certificates that bridge FIDO credentials to a PKI.

See the README.md files in those directories for further instructions.

To use the demos, you will need a FIDO Authenticator with largeBlob support.
YubiKeys have support for largeBlobs starting with firmware version 5.5.

When using largeBlobs from a web appliation, you need a browser that supports the WebAuthn largeBlob extension, such as Chrome or Edge.
For other browsers, check largeBlob support for WebAuthn [get](https://caniuse.com/mdn-api_credentialscontainer_get_publickey_option_extensions_largeblob)
and [create](https://caniuse.com/mdn-api_credentialscontainer_create_publickey_option_extensions_largeblob) calls.

