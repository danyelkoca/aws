import base64
import argparse


def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Base64 encode and decode a message.")
    parser.add_argument(
        "text",
        nargs="?",
        default="Secret message",
        help="The text to encode and decode (default: 'Secret message')",
    )
    args = parser.parse_args()

    # Input text
    text = args.text

    # Encode the text using base64
    enc = base64.b64encode(text.encode("utf-8"))
    print("encoded")
    print(enc.decode("utf-8"))

    # Decode the base64-encoded text
    plain = base64.b64decode(enc).decode("utf-8")
    print("decoded")
    print(plain)


if __name__ == "__main__":
    main()
