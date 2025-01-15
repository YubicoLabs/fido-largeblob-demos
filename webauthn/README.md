# A simple demo using largeBlobs from a web page

This demo illustrates the use of the WebAuthn largeBlob extention from a web page.

Create a credential and use the write/read buttons to store and retrieve arbitrary data on your FIDO Authenticator.

Note that in order to run the demo, you cannot just load the HTML into your browser, as WebAuthn requires a secure conext.
This means it needs to load from an HTTPS URL, although most browsers also allow http://localhost.

To load the page on localhost, you can use any web server.
For instance, if your system has python installed, use:

	python3 -m http.server 8080

to run a web server on localhost port 8080.
Point your browser to http://localhost:8080 to access the demo.

Also note that in order to run from a static web page, this demo does not have a server component to verify assertions (i.e. no signatures are checked).
