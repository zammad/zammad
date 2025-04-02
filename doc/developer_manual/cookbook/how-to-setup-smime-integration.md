# How to Setup S/MIME Integration

For development purposes, it's possible to set up S/MIME integration for a local Zammad instance. However, since the
approach uses self-generated test certificates, this is considered unsafe for production. You've been warned!

## Configure S/MIME Integration

Navigate to the **System > Integrations > S/MIME** section in GUI, and turn on the toggle switch on top to activate the
feature.

### Upload Sender Certificate & Private Key

1. In the same screen, click on the **Add Certificate** button.
2. Paste the following text in the **Paste Certificate** box:

   ```crt
   -----BEGIN TRUSTED CERTIFICATE-----
   MIIEmTCCA4GgAwIBAgIJAOOVkfcMlOvoMA0GCSqGSIb3DQEBCwUAMHYxCzAJBgNV
   BAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxpbjEaMBgGA1UE
   CgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0RldmVsb3BtZW50MRMwEQYD
   VQQDDAp6YW1tYWQub3JnMB4XDTIzMDExMTEwNDUwMloXDTMzMDEwODEwNDUwMlow
   gZwxCzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxp
   bjEaMBgGA1UECgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0RldmVsb3Bt
   ZW50MRgwFgYDVQQDDA9aYW1tYWQgSGVscGRlc2sxHzAdBgkqhkiG9w0BCQEWEHph
   bW1hZEBsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCd
   7ExEQqbNisuu/OB48dMZ+dYWOFgYC3z/JAiDexPYNzcZz6JWajaGwJTR2cYJxiyV
   rNhKusb7YaqOi20D1X4PKn8Siq2HWIMzg5MCR/IQs7tu6f86+pZS6Hyce89ttHEh
   j3gcv6Ms0ii6XpIAYUK2O7ZMaCiCpiUmmCwwcmv79GYOaFwfDt5WIhFuyKroxAXA
   qObgNai4xu4K8pj3SXed0W+YVJ1I+jCbY2V25iKLs0w9DaPUrhlbGeKezEwRURGD
   lGlIGX86BXB8tLFEG2qLhKYrokUDltIU+99Z/GiFhZRuuyL8BUv8kBbPI+YyhiP+
   e990WC0uipu0sorrAfbTAgMBAAGjggEBMIH+MAkGA1UdEwQCMAAwCwYDVR0PBAQD
   AgXgMB0GA1UdDgQWBBQulBRC4PUBK0VlRb1XgRSx3PNMbTAbBgNVHREEFDASgRB6
   YW1tYWRAbG9jYWxob3N0MBMGA1UdJQQMMAoGCCsGAQUFBwMEMIGSBgNVHSMEgYow
   gYeheqR4MHYxCzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcM
   BkJlcmxpbjEaMBgGA1UECgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0Rl
   dmVsb3BtZW50MRMwEQYDVQQDDAp6YW1tYWQub3JnggkAoyQmhzPcTqcwDQYJKoZI
   hvcNAQELBQADggEBAFSPJoakV7qsq8+0SSSp82O59kAmD2xMojzdv9wu+99Y5d4r
   Z/oN0S2ZYBu4d0v+RNysIaCSbxt8DKbZ67slhSLl7vON9pkbq9RbvYlVIcB0As+y
   a3MODFKLPOE6UfszW8TGsyWJrUXufucb4MxBICTa2ZQF+vmg9XSngO6emgo9UQWM
   Ojl/J0ETQK/oDVO0QtcCv12dnefK6maHuAHA6+MQ+PsxTFRa7VPPsMKM0sRMmyP8
   Nm154jJaJIb/QLdhPZ73aBmSopOIUOfc7Q39cd7TXaFHBMwe0wXVeuS4N7M+2a+s
   +Wmv1N+1HnB5/NT7GF3lmrB+PF/oPuMkOIcmbXMwIjAKBggrBgEFBQcDBKAUBggr
   BgEFBQcDAgYIKwYBBQUHAwE=
   -----END TRUSTED CERTIFICATE-----
   ```

3. Click on the **Add** button.
4. Click on the **Add Private Key** button.
5. Paste the following text in the **Paste Private Key** box:

   ```rsa
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCd7ExEQqbNisuu
   /OB48dMZ+dYWOFgYC3z/JAiDexPYNzcZz6JWajaGwJTR2cYJxiyVrNhKusb7YaqO
   i20D1X4PKn8Siq2HWIMzg5MCR/IQs7tu6f86+pZS6Hyce89ttHEhj3gcv6Ms0ii6
   XpIAYUK2O7ZMaCiCpiUmmCwwcmv79GYOaFwfDt5WIhFuyKroxAXAqObgNai4xu4K
   8pj3SXed0W+YVJ1I+jCbY2V25iKLs0w9DaPUrhlbGeKezEwRURGDlGlIGX86BXB8
   tLFEG2qLhKYrokUDltIU+99Z/GiFhZRuuyL8BUv8kBbPI+YyhiP+e990WC0uipu0
   sorrAfbTAgMBAAECggEAZABqGx+JuMaXTGvdSTj40I4gP1nWjwNXV8ldisS5QEVW
   owWUatw/Qv1YP7qDaVUQjocxP8Eel7i05CbuFWtvs/LZHMisMfSewFQlF2CvrFvj
   6MxMTvC3mDCYGA9evr1wlivfh3Tiw1Mhb0LLeWodcIBHZALhBDppdBMQiG0sbBLM
   aNpmKgvA+klA2OSip5VtuDmW0NroGdCKuTqWXLtvKwZcn4pI3vzSPIcZjsN2Jy0o
   u3G+vpju6KHIeULYy5ipeGAaMc27gI+hFYXxYkCSiFBXOOV9/gshX/9kyhh2Je7g
   tnf15g/daLaK4Gwtb0oRP/BuiInjvvzBjts9CWGOYQKBgQDQ0cx3Q6NGUVHTeJAz
   iNAFHrOqk37IYKrSkKGdUv33Xu9huGAv4K9ABw8TFXzPE+UCpyIp/drYTsjNhI7O
   nNuswdR6OHDDYJkiMvPaxw7f7jkNyx0A1c2oAVbe5FcZ3Lb01khFzSSSNgypK6aA
   9YQQ+Rpw6uLHqU9R9dZ4FMehLQKBgQDBmqB9Ub+RXmS9XmNUPJgB1N25+j2rF3uY
   WHRed9g+/ZWW6Ae4b3Ad8qcLDyPDLcLjZ2rbn3UJa/ObnDS+FmoPsl4h1HcH6EIH
   JNI9gQ8T/2iqNY65PQ1xXgi1GAWvZOVhwJ1s8zpr5gX1wCrr0UG7UJQl0Is1Dc2O
   aulTFf73/wKBgGoy6JuXCIiQft7fp+ato62W6aTMkmPx1a5049yRApw16eR20mRH
   DpmvfVklSm4+He/1dAiLFCuCFdl/muk1GPuJMDhgT+jtTbP42c/gAI6eJuH+9Gci
   VQ8mbzm4QxviBiIKgIMPS5QYbOP0UR+wvVOsfGgE7QTB9JcoQcScPNKZAoGAYjix
   jYLI3tZ144EcgaMQN3WoW+8yFDggs0TFHRxOMH70wo/LQu3+gqMVzk2LBj2UL0zL
   cMrwVKxY9iyEsZ+rhXUnvqANF4zk2rz6kMuGO84LarcrRp1L0aU0Y7PhRn+4xCQ1
   eg3YKN+VTH2HCQasA304/ApWZb8v9z4US9vP9D8CgYEAsDTlkDPYgJrvnV1M1O8m
   33HNt4q8DxNaAEgyeQNLWJeWhZ04BUxL+lUSAlwedIpNSkz29Gwr5cn72Sd6qiPA
   7n1sToL1jCXTDHSGh96syXxQ8Ph7i55AY2LdrdnwDzstpJSkvrMjkQ8incmFJteA
   DO2+7cq0BzbViPrYxeGEBdU=
   -----END PRIVATE KEY-----
   ```

6. Leave **Enter Private Key Secret** box empty.
7. Click on the **Add** button.

The test sender certificate above was generated for the following sender email address: `zammad@localhost`. In case
your sender address is different, please see below how to re-generate it.

### Upload Recipient Certificate

1. In the same screen, click again on the **Add Certificate** button.
2. Paste the following text in the **Paste Certificate** box:

   ```crt
   -----BEGIN TRUSTED CERTIFICATE-----
   MIIEpTCCA42gAwIBAgIJAOOVkfcMlOvnMA0GCSqGSIb3DQEBCwUAMHYxCzAJBgNV
   BAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxpbjEaMBgGA1UE
   CgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0RldmVsb3BtZW50MRMwEQYD
   VQQDDAp6YW1tYWQub3JnMB4XDTIzMDExMTA4NTExNloXDTMzMDEwODA4NTExNlow
   gaAxCzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxp
   bjEaMBgGA1UECgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0RldmVsb3Bt
   ZW50MRUwEwYDVQQDDAxOaWNvbGUgQnJhdW4xJjAkBgkqhkiG9w0BCQEWF25pY29s
   ZS5icmF1bkB6YW1tYWQub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
   AQEAq1/HC+dh0UoRvuMB/7pkydTLcivyxt5OVgmGsKT32YNrmJctYs38It2jiTzJ
   SIWMeAqTaAaRjjy3P3dUv9FAZFTEPI+zc2tuWCaXnO7ccvpz8QBTZsZZC0gKmXqo
   4/+qrfUJqC72DeuZlTg2iwaSp63Yeet5ShuVbF+gTgO+vMlRnaKMXNuIJM14Auzb
   Fsdc+0vMPE52arWORK9woajOCUn1xfGTu917+D24gX6Xic9gnLJKXNYyL7wctVS+
   US3FPdJLqeNNb2rJyZcrLBtzWXIiVJYnHx4knrWP1m+c3ThQEPeQef/DDws3+3Ub
   8WYay7oqO7eujYSFBTX1xlPeQwIDAQABo4IBCTCCAQUwCQYDVR0TBAIwADALBgNV
   HQ8EBAMCBeAwHQYDVR0OBBYEFFC5iaStg5uoFcetE2u+7rgffdKtMCIGA1UdEQQb
   MBmBF25pY29sZS5icmF1bkB6YW1tYWQub3JnMBMGA1UdJQQMMAoGCCsGAQUFBwME
   MIGSBgNVHSMEgYowgYeheqR4MHYxCzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCZXJs
   aW4xDzANBgNVBAcMBkJlcmxpbjEaMBgGA1UECgwRWmFtbWFkIEZvdW5kYXRpb24x
   FDASBgNVBAsMC0RldmVsb3BtZW50MRMwEQYDVQQDDAp6YW1tYWQub3JnggkAoyQm
   hzPcTqcwDQYJKoZIhvcNAQELBQADggEBAEgk7pW68d88cgD38oyHaMqQdQ0Odtzh
   78a6u2Bki2BtYK+4AwCWdeb+lZLKj6W/CPOWPJriFRMqiRQ6N6eIPRc4x70Q0fMJ
   JXAWQA4eliHFGLzA+YMyBKiW1EfLU6pIkvWONLG3oVch4gAccHgY6h436OmHtoRr
   VPiz25xCSe5YZWpLY1KeZ7Ucv51qaMlRHNdwB4ixETFG54bbK6mATiSCw2Wtwqlj
   qKX2l5VYSxhC51lveLQaVlQHy3nj1M2uGQN6Jv1wc0Pe6Twu3itqYZrJnTJdoq4K
   ty1IuHWXx7wJ64xa+Rbx5MHXsz1jsML8+UL9DgSw0zjL+BJcF+wuaEEwIjAKBggr
   BgEFBQcDBKAUBggrBgEFBQcDAgYIKwYBBQUHAwE=
   -----END TRUSTED CERTIFICATE-----
   ```

3. Click on the **Add** button.

The test recipient certificate above was generated for the following customer email address: `nicole.braun@zammad.org`.
In case your recipient address is different, please see below how to re-generate it.

### Upload CA Certificate

1. In the same screen, click on the **Add Certificate** button.
2. Paste the following text in the **Paste Certificate** box:

   ```crt
   -----BEGIN CERTIFICATE-----
   MIIDaDCCAlACCQCjJCaHM9xOpzANBgkqhkiG9w0BAQsFADB2MQswCQYDVQQGEwJE
   RTEPMA0GA1UECAwGQmVybGluMQ8wDQYDVQQHDAZCZXJsaW4xGjAYBgNVBAoMEVph
   bW1hZCBGb3VuZGF0aW9uMRQwEgYDVQQLDAtEZXZlbG9wbWVudDETMBEGA1UEAwwK
   emFtbWFkLm9yZzAeFw0yMzAxMTEwNzQ5MDRaFw0zMzAxMDgwNzQ5MDRaMHYxCzAJ
   BgNVBAYTAkRFMQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxpbjEaMBgG
   A1UECgwRWmFtbWFkIEZvdW5kYXRpb24xFDASBgNVBAsMC0RldmVsb3BtZW50MRMw
   EQYDVQQDDAp6YW1tYWQub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
   AQEA2K/NXzrMeKrbHebm9QIpQLOGVy9Apv76/jSciJ4lYrm/MVbSMnlhKM2GZsgp
   JQZgUgKFDxfu8WcMYTY9hYMj8HCqMKLjAa/JD1WKgqBuXq82dw+K+xrhON9yFHc7
   pGwDd+M362ps/dTdwDP9yddGj6JuPgnLfE7KwI/qHGo/Wvt6hTD1kbJ0wzOASvh+
   wa7FRBKzo3iO40NAJET/5o/dcHwIi+eHTR0KVoZVmaT+aPzewWel2JJCys55Abal
   NcgjibX6m/DeBDx7VuaArTFY1307ob54gZnjAxvk8dHlia2SMsVN77AujsRvB8BL
   2vv906nZG+YtoI/U23xpLoS6eQIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQB2CR8n
   km6J7HXpbjZh3/fFklM1cb7L2vB4JWMYnbCgaDU4vqXRXezAsi56ZdypofdAZ8C/
   jIVry+gWCCVXKLbpyWkqJyboOJnHMU93VHg+yAREVI7NmMle0DYRqKgcmXMtJXzc
   54dO0MxK0n+zUsT08a8e9HHNh++FZLJr7r3AvYvRRV0K2eMX4WETUIIfv1eqhHp1
   /kdVvaz52eK01Z7D6eE/2mE3nDwaokV/28B6pj4G9mS+68kUul+BhcSNqkeBBvKh
   4bH8QYop51x5VbUMFZBNjJ5ZkfjmF6G/+pyOeZtH2frPu2Ccxkr3NX/zZ1yKjf9j
   cdO0kbfpSLHCRbZ0
   -----END CERTIFICATE-----
   ```

3. Click on the **Add** button.

The test CA certificate above was used to sign both the test sender and test recipient certificates.

## Create a Test Email Ticket with Encrypted & Signed Content

1. Go to new ticket screen.
2. Switch to the **Send Email** article type.
3. Provide a **Title**.
4. Choose a **Customer** called _Nicole Braun_.
5. Provide some **Text**.
6. Choose a **Group**.
7. Verify that both **Encrypt** and **Sign** toggle buttons are now active.
8. Click on the **Create** button.
9. Verify that the first article has a **Security** field with both _Encrypted_ and _Signed_ flags.

## Re-generate Test Certificates

You will need an installation of a recent `openssl` utility for the following commands.

### Generate CA Certificate & Private Key

1. Navigate to an empty directory.
2. Create a text configuration file called `ca.conf` with the following content:

   ```ini
   [req]
   distinguished_name = req_distinguished_name

   [req_distinguished_name]
   countryName = Country Name (2 letter code)
   countryName_default = DE
   countryName_min = 2
   countryName_max = 2
   stateOrProvinceName = State or Province Name (full name)
   stateOrProvinceName_default = Berlin
   stateOrProvinceName_max = 32
   localityName = Locality Name (eg, city)
   localityName_default = Berlin
   0.organizationName = Organization Name (eg, company)
   0.organizationName_default = Zammad Foundation
   organizationalUnitName = Organizational Unit Name (eg, section)
   organizationalUnitName_default = Development
   commonName = Common Name (e.g. server FQDN or YOUR name)
   commonName_default = zammad.org
   commonName_max = 64
   emailAddress = Email Address
   emailAddress_default =
   emailAddress_max = 40
   ```

   Adjust all `*_default` values to match desired settings, except `emailAddress_default`. Please leave it empty.

3. Run the following command in the same directory:

   ```sh
   openssl req -x509 -new -nodes -days 3650 -config ca.conf -keyout ca.key -out ca.crt
   ```

   Confirm each field with a return (the value will be pre-populated from the configuration file).

You can now upload your new test CA certificate. Either upload the actual text file (`ca.crt`) or paste its content in
appropriate box. Note that in this case you should NOT upload the generated private key since the certificate may be
used only for the trust chain verification.

### Generate Sender Certificate & Private Key

1. Navigate to an empty directory.
2. Create a text configuration file called `sender.conf` with the following content:

   ```ini
   [req]
   distinguished_name = req_distinguished_name
   x509_extensions = v3_req

   [req_distinguished_name]
   countryName = Country Name (2 letter code)
   countryName_default = DE
   countryName_min = 2
   countryName_max = 2
   stateOrProvinceName = State or Province Name (full name)
   stateOrProvinceName_default = Berlin
   stateOrProvinceName_max = 32
   localityName = Locality Name (eg, city)
   localityName_default = Berlin
   0.organizationName = Organization Name (eg, company)
   0.organizationName_default = Zammad GmbH
   organizationalUnitName = Organizational Unit Name (eg, section)
   organizationalUnitName_default = Development
   commonName = Common Name (e.g. server FQDN or YOUR name)
   commonName_default = Zammad Foundation
   commonName_max = 64
   emailAddress = Email Address
   emailAddress_default = zammad@localhost
   emailAddress_max = 40

   [v3_req]
   basicConstraints = CA:FALSE
   keyUsage = nonRepudiation, digitalSignature, keyEncipherment
   subjectKeyIdentifier = hash
   subjectAltName = email:copy
   extendedKeyUsage = emailProtection
   ```

   Adjust all `*_default` values to match desired settings. The most important is `emailAddress_default` which must
   match your sender's email address.

3. Run the following command in the same directory to generate the certificate request:

   ```sh
   openssl req -new -nodes -keyout sender.key -out sender.csr -config sender.conf
   ```

   Confirm each field with a return (the value will be pre-populated from the configuration file).

4. Create a text configuration file called `v3_ca.conf`  with the following content:

   ```ini
   [v3_ca]
   basicConstraints = CA:FALSE
   keyUsage = nonRepudiation, digitalSignature, keyEncipherment
   subjectKeyIdentifier = hash
   subjectAltName = email:copy
   extendedKeyUsage = emailProtection
   authorityKeyIdentifier = keyid,issuer
   ```

5. Run the following command in the same directory to generate and sign the certificate:

   ```sh
   openssl x509 -req -days 3650 -in sender.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out sender.crt -addtrust emailProtection -addreject clientAuth -addreject serverAuth -trustout -extensions v3_ca -extfile v3_ca.conf
   ```

You can now upload your new test sender certificate & private key. Either upload the actual text files (`sender.crt`
and `sender.key`) or paste their contents in appropriate boxes. Remember to omit the input for the private key secret
since it was not defined during the re-generation, but don't skip the private key upload since the certificate may be
used for signing and decryption.

### Generate Recipient Certificate & Private Key

1. Navigate to an empty directory.
2. Create a text configuration file called `recipient.conf` with the following content:

   ```ini
   [req]
   distinguished_name = req_distinguished_name
   x509_extensions = v3_req

   [req_distinguished_name]
   countryName = Country Name (2 letter code)
   countryName_default = DE
   countryName_min = 2
   countryName_max = 2
   stateOrProvinceName = State or Province Name (full name)
   stateOrProvinceName_default = Berlin
   localityName = Locality Name (eg, city)
   localityName_default = Berlin
   0.organizationName = Organization Name (eg, company)
   0.organizationName_default = Zammad Foundation
   organizationalUnitName = Organizational Unit Name (eg, section)
   organizationalUnitName_default = Development
   commonName = Common Name (e.g. server FQDN or YOUR name)
   commonName_default = Nicole Braun
   commonName_max = 64
   emailAddress = Email Address
   emailAddress_default = nicole.braun@zammad.org
   emailAddress_max = 40

   [v3_req]
   basicConstraints = CA:FALSE
   keyUsage = nonRepudiation, digitalSignature, keyEncipherment
   subjectKeyIdentifier = hash
   subjectAltName = email:copy
   extendedKeyUsage = emailProtection
   ```

   Adjust all `*_default` values to match desired settings. The most important is `emailAddress_default` which must
   match your recipient's email address.

3. Run the following command in the same directory to generate the certificate request:

   ```sh
   openssl req -new -nodes -keyout recipient.key -out recipient.csr -config recipient.conf
   ```

   Confirm each field with a return (the value will be pre-populated from the configuration file).

4. Create a text configuration file called `v3_ca.conf`  with the following content:

   ```ini
   [v3_ca]
   basicConstraints = CA:FALSE
   keyUsage = nonRepudiation, digitalSignature, keyEncipherment
   subjectKeyIdentifier = hash
   subjectAltName = email:copy
   extendedKeyUsage = emailProtection
   authorityKeyIdentifier = keyid,issuer
   ```

5. Run the following command in the same directory to generate and sign the certificate:

   ```sh
   openssl x509 -req -days 3650 -in recipient.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out recipient.crt -addtrust emailProtection -addreject clientAuth -addreject serverAuth -trustout -extensions v3_ca -extfile v3_ca.conf
   ```

You can now upload your new test recipient certificate. Either upload the actual text file (`recipient.crt`) or paste
its content in appropriate box. Note that in this case you should NOT upload the generated private key since the
certificate may be used only for encryption.

## Other Useful OpenSSL commands

### Dump the Text Content of a Certificate

```sh
openssl x509 -in sender.crt -text
```

### Export Certificate to PKCS12 for Usage in Email Clients

```sh
openssl pkcs12 -export -in sender.crt -inkey sender.key -out sender.p12
```
