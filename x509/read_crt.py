"""
Connects to the first FIDO device found (starts from USB, then looks into NFC),
"""
from fido2.server import Fido2Server
from fido2.utils import websafe_decode
from fido2.hid import CtapHidDevice
from fido2.client import Fido2Client, WindowsClient, UserInteraction
import sys
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization


try:
    from fido2.pcsc import CtapPcscDevice
except ImportError:
    CtapPcscDevice = None


# Handle user interaction via CLI prompts
class CliInteraction(UserInteraction):
    def prompt_up(self):
        sys.stderr.write("\nTouch your authenticator device now...\n")


def enumerate_devices():
    for dev in CtapHidDevice.list_devices():
        yield dev
    if CtapPcscDevice:
        for dev in CtapPcscDevice.list_devices():
            yield dev


def get_client(predicate=None, **kwargs):
    """
    Locate a CTAP device suitable for use.
    If running on Windows as non-admin, the predicate check will be skipped and
    a webauthn.dll based client will be returned.
    Extra kwargs will be passed to the constructor of Fido2Client.
    """

    if WindowsClient.is_available() and not ctypes.windll.shell32.IsUserAnAdmin():
        # Use the Windows WebAuthn API if available, and we're not running as admin
        return WindowsClient("http://localhost")

    user_interaction = CliInteraction()

    # Locate a device
    for dev in enumerate_devices():
        # Set up a FIDO 2 client using the origin https://example.com
        client = Fido2Client(
            dev,
            "http://localhost",
            user_interaction=user_interaction,
            **kwargs,
        )
        # Check if it is suitable for use
        if predicate is None or predicate(client):
            return client
    else:
        raise ValueError("No suitable Authenticator found!")

# Locate a suitable FIDO authenticator
client = get_client(lambda client: "largeBlobKey" in client.info.extensions)

server = Fido2Server({"id": "localhost", "name": "Example RP"})

# Prepare parameters for getAssertion
request_options, state = server.authenticate_begin(user_verification="discouraged")

# Authenticate the credential
selection = client.get_assertion(
    {
        **request_options["publicKey"],
        # Read the blob
        "extensions": {"largeBlob": {"read": True}},
    }
)

# Only one cred in allowCredentials, only one response.
result = selection.get_response(0)
der_data = websafe_decode(result.extension_results["largeBlob"]["blob"])

cert = x509.load_der_x509_certificate(der_data, default_backend())

cert_val = cert.public_bytes(serialization.Encoding.PEM)
print(cert_val.decode())
