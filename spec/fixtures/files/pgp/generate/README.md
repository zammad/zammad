# Zammad PGP test key generation

This folder contains a shell script to generate various PGP keys for testing purposes.

The following files will be (re)generated:

- `spec/fixtures/files/gpg/*.asc` - private key in ASCII armored format
- `spec/fixtures/files/gpg/*.pub.asc` - public key in ASCII armored format
- `spec/fixtures/files/gpg/*.passphrase` - private key passphrase

To execute the script, simply run `run.sh` in this directory. There is nothing more to it except of having `gpg` binary
installed and available in the path.
