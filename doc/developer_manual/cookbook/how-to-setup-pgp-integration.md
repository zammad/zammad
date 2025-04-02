# How to Setup PGP Integration

For development purposes, it's possible to set up PGP integration for a local Zammad instance. However, since the
approach uses self-generated test keys, this is considered unsafe for production. You've been warned!

## Configure PGP Integration

Navigate to the **System > Integrations > PGP** section in GUI, and turn on the toggle switch on top to activate the
feature.

**Note**: In case your local `gpg` binary cannot be found or it's a wrong version, you may receive an error message on
top. Please try to fix it before proceeding by either installing or updating your GnuPG installation.

### Upload Sender Private Key

1. In the same screen, click on the **Add Key** button.
2. Paste the following text in the **Paste Key** box:

   ```text
   -----BEGIN PGP PRIVATE KEY BLOCK-----

   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
   =u7b7
   -----END PGP PRIVATE KEY BLOCK-----
   ```

3. Enter _zammad_ in **Passphrase** box.
4. Click on the **Add** button.

The test sender private key above was generated for the following sender email address: `zammad@localhost`. In case
your sender address is different, please see below on how to re-generate it.

### Upload Recipient Public Key

1. In the same screen, click again on the **Add Key** button.
2. Paste the following text in the **Paste Key** box:

   ```text
   -----BEGIN PGP PUBLIC KEY BLOCK-----

   mQINBGSw/p0BEADbEp2iLw5bFQ7J+GeFZKfVV6N6ETUiieWMmoRLrTYkHlpSqfVS
   v4xhDI+QSIZU/VZV7FlowaOEATQUDwtZ8ou16tWPqIe0G+NiumXyzjiH4Rhpx/Yp
   djJlFcVYfMIqRtd6zsYUkXqVA5ByAXeMkJaE/PQ//GwcPzqv5dEfxn0Jykfc4MRc
   rYsryg7QfrMJ8zLTmn2VpIAfjB54/EIEafSmmLYhX5MAI8U4AHnONG1xw3CC32sj
   rkaPHejhaVirAILEAs7+lnBT7hZInfCtjrEzprs/muJD9CIMcN5YWUXFwLmZsqvq
   DUi+rJnGdqS2q2G3RhndFr1aQiN7Eox7W4UDvDf7fxCpxT5c8ofifPM14c+sqLx4
   G+J6sKDVGdlEJHMY3XC2A3UkT3mSIzkU0enuehA3fk3819tJ+8Hj3zDV8R8rds3G
   k1rBSSLzTYxC2vQaoC25AdCY/Z+7NpsEHcu/FIPuqdmq30yqucNNztvN79lDRiNH
   Imzzfk7QgyYGR4+U2YE5q/aR+lEU+2HlGEeKocIjRkH4Qywxt8Z+Q76TrwZSsJWS
   smVgTexiuvJ65wUpr0nMmrqMS70NgWDOpm4wlmNv985ZmJU9xyc12Cxy32Jcalxv
   hZpZreCAY3YFDYwbduP+czaca8EeMCPt6TNK2aGa+jjh+0UbOCNjb+EX5wARAQAB
   tCZOaWNvbGUgQnJhdW4gPG5pY29sZS5icmF1bkB6YW1tYWQub3JnPokCVAQTAQgA
   PgIbDwUJEswDAAIXgBYhBNuqv9h9KWivuSFOlQpLbYxVAUwGBQJkvkDLBAsJCAcG
   FQoJCAsCBRYCAwEAAh4FAAoJEApLbYxVAUwGqFgP/0yUcAHJjkTYakCrrHf20ZSc
   O0K5V5ewLjjydXgqs+h7zqau3j0TYbKbTCoIVHEAIjp8Ie1PsgrfUs9UjzgF15Cr
   HCATdY42Xskwd9ys8riCjuFQ99pyNCJlYpFkx5g6NAa3DV+5kbhRvkbu1XcQXnWp
   f7ClHfjcru2WlZBaV6e7pZvCqb/8C81EGtIyoedX5ZyItuZU4oM31Z4rFRaw5f4K
   kKdCK1RcmqMp6OV9LaWJRCQilQ9tpgLAHf9oI3KlchOPNGdK3mJl4yhe7jecOCa6
   2LnN2+rDj7ai8rRyYB/v7A9cUR/KeJ5FhTJzmczD2PfF0pJyotlruGcc2KzEzljb
   JeK3H5VIBOIVVb/OtjUHaJj49m1y34dnGj7gwcei/lC/Sl7xlL0XEeLl2yXMW1WJ
   uMpbIyHbT1DWsEN55Gc/MqM+IbcENmZTuMz9ypqrJpsr7+n0zW50laE141ar8Rmv
   eueXKvZhcsv3e7QwiDVt3GFExpiR3uMYF82qr22M23jKVYhYn2j29CrJrfwzFFv6
   OlAtaSHCL89LOyTbP0sE2SVTT733qShfyZcQo+eTzJ9/7cwLNHrc1X5rcLdgAZyQ
   k7UHXuUKdmcLbt0t5nyyITWEGD+gI1pq73w/EXIt6TUn5r//5OrQVD0ln4744Euc
   dqLOvmePJn5lE4jEooMS
   =gFIf
   -----END PGP PUBLIC KEY BLOCK-----
    ```

3. Leave **Passphrase** box empty.
4. Click on the **Add** button.

The test recipient public key above was generated for the following customer email address: `nicole.braun@zammad.org`.
In case your recipient address is different, please see below how to re-generate it.

## Create a Test Email Ticket with Encrypted & Signed Content

1. Go to new ticket screen.
2. Switch to the **Send Email** article type.
3. Provide a **Title**.
4. Choose a **Customer** called _Nicole Braun_.
5. Provide some **Text**.
6. Choose _Users_ for the **Group**.
7. Verify that both **Encrypt** and **Sign** toggle buttons are now active.
8. Click on the **Create** button.
9. Verify that the first article has a **Security** attribute in article metadata with _PGP: Encrypted / Signed_ value.

## Re-generate Test Keys

You will need a recent installation of `gpg` utility (GnuPG) for the following commands.

### Generate Sender Key

1. Make a temporary GPG keyring for the following commands:

   ```sh
   GNUPGHOME=$(mktemp -d)
   export GNUPGHOME
   ```

   On systems with GnuPG version higher than 2.3.0, please set the following configuration option before generating new
   keys, so they can be backwards compatible:

   ```sh
   echo "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed" > "$GNUPGHOME/gpg.conf"
   ```

2. Generate the private key:

   ```sh
   gpg --quick-generate-key "zammad@localhost" rsa4096 sign,encr 10y
   ```

   Where `zammad@localhost` is the key UID, `rsa4096` key algorithm, `sign,encr` key usage and `10y` key expiration date
   relative to current time.

   Provide the key passphrase when asked, confirm it and remember it for later.

3. Export the private key in armor-ASCII format:

   ```sh
   gpg --output "zammad@localhost.asc" --armor --export-secret-key "zammad@localhost"
   ```

   Where `zammad@localhost.asc` is the file output for the private key and `zammad@localhost` the key UID.

   Provide the key passphrase when asked.

4. Clean up the temporary GPG keyring:

   ```sh
   rm -rf $GNUPGHOME
   unset GNUPGHOME
   ```

You can now upload your new test sender private key. Either upload the actual text file (`zammad@localhost.asc`) or
paste its contents in the appropriate box. Remember that the private key export includes the public key information
as well, there is no need to import them separately. Also, you will have to provide the passphrase for the private key
during the upload to Zammad.

### Generate Recipient Key

1. Make a temporary GPG keyring for the following commands:

   ```sh
   GNUPGHOME=$(mktemp -d)
   export GNUPGHOME
   ```

   On systems with GnuPG version higher than 2.3.0, please set the following configuration option before generating new
   keys, so they can be backwards compatible:

   ```sh
   echo "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed" > "$GNUPGHOME/gpg.conf"
   ```

2. Generate the private key:

   ```sh
   gpg --quick-generate-key "Nicole Braun <nicole.braun@zammad.org>" rsa4096 sign,encr 10y
   ```

   Where `Nicole Braun <nicole.braun@zammad.org>` is the key UID, `rsa4096` key algorithm, `sign,encr` key usage and
   `10y` key expiration date relative to current time.

   Provide the key passphrase when asked and confirm it.

3. Export the public key in armor-ASCII format:

   ```sh
   gpg --output "nicole.braun@zammad.org.pub.asc" --armor --export "Nicole Braun <nicole.braun@zammad.org>"
   ```

   Where `nicole.braun@zammad.org.pub.asc` is the file output for the public key and
   `Nicole Braun <nicole.braun@zammad.org>` the key UID.

4. Clean up the temporary GPG keyring:

   ```sh
   rm -rf $GNUPGHOME
   unset GNUPGHOME
   ```

You can now upload your new test recipient public key. Either upload the actual text file
(`nicole.braun@zammad.org.pub.asc`) or paste its content in the appropriate box. Note that in this case you should NOT
upload the generated private key since the public key may be used only for encryption.

## Other Useful GnuPG commands

### List Keys in the GPG Keyring

```sh
gpg --list-keys
```

### Show Info About a Keyfile

```sh
gpg --show-key path/to/keyfile.asc
```

With preferences included in the verbose mode:

```sh
gpg --list-options show-pref-verbose --show-key path/to/keyfile.asc
```

### Delete a Private Key from the GPG Keyring

```sh
gpg --delete-secret-key zammad@localhost
```

### Delete a Public Key from the GPG Keyring

```sh
gpg --delete-key zammad@localhost
```
