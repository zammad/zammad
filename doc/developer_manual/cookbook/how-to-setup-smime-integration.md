# How to Setup S/MIME Integration

For development purposes, it's possible to set up S/MIME integration for a local Zammad instance. However, since the approach uses self-generated test certificates, this is considered unsafe for production. You've been warned!

## Configure S/MIME Integration

Navigate to the **System > Integrations > S/MIME** section in GUI, and turn on the toggle switch on top to activate the feature.

### Upload Sender Certificate & Private Key

1. In the same screen, click on the **Add Certificate** button.
2. Paste the following text in the **Paste Certificate** box:

   ```crt
   -----BEGIN CERTIFICATE-----
   MIIEHDCCAwSgAwIBAgIJAM62PKRKUf2uMA0GCSqGSIb3DQEBCwUAMIGWMQswCQYD
   VQQGEwJERTEPMA0GA1UECAwGQmVybGluMQ8wDQYDVQQHDAZCZXJsaW4xFDASBgNV
   BAoMC1phbW1hZCBHbWJIMRQwEgYDVQQLDAtEZXZlbG9wbWVudDEYMBYGA1UEAwwP
   WmFtbWFkIEhlbHBkZXNrMR8wHQYJKoZIhvcNAQkBFhB6YW1tYWRAbG9jYWxob3N0
   MB4XDTIzMDEwNDE1MTcxOFoXDTIzMDIwMzE1MTcxOFowgZYxCzAJBgNVBAYTAkRF
   MQ8wDQYDVQQIDAZCZXJsaW4xDzANBgNVBAcMBkJlcmxpbjEUMBIGA1UECgwLWmFt
   bWFkIEdtYkgxFDASBgNVBAsMC0RldmVsb3BtZW50MRgwFgYDVQQDDA9aYW1tYWQg
   SGVscGRlc2sxHzAdBgkqhkiG9w0BCQEWEHphbW1hZEBsb2NhbGhvc3QwggEiMA0G
   CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCd7ExEQqbNisuu/OB48dMZ+dYWOFgY
   C3z/JAiDexPYNzcZz6JWajaGwJTR2cYJxiyVrNhKusb7YaqOi20D1X4PKn8Siq2H
   WIMzg5MCR/IQs7tu6f86+pZS6Hyce89ttHEhj3gcv6Ms0ii6XpIAYUK2O7ZMaCiC
   piUmmCwwcmv79GYOaFwfDt5WIhFuyKroxAXAqObgNai4xu4K8pj3SXed0W+YVJ1I
   +jCbY2V25iKLs0w9DaPUrhlbGeKezEwRURGDlGlIGX86BXB8tLFEG2qLhKYrokUD
   ltIU+99Z/GiFhZRuuyL8BUv8kBbPI+YyhiP+e990WC0uipu0sorrAfbTAgMBAAGj
   azBpMAkGA1UdEwQCMAAwCwYDVR0PBAQDAgXgMB0GA1UdDgQWBBQulBRC4PUBK0Vl
   Rb1XgRSx3PNMbTAbBgNVHREEFDASgRB6YW1tYWRAbG9jYWxob3N0MBMGA1UdJQQM
   MAoGCCsGAQUFBwMEMA0GCSqGSIb3DQEBCwUAA4IBAQAwnTs6//5tku3bnZfjoWAN
   x+AerlhM4tVr/FmyupqhF8Mu8LKqMJ7g4ViBRZmT2a14VzEnzBbbfpARHv0sC0kR
   xkLfk8yyozmpgipCMtiPQkaCOC/oq4zDc7KVN0w9UpIAl5V/855x2WxDMlmi1d55
   NwbpVUqC1tPbPhDcC8LifJrovyo8oIvuzVP3ahKdRj5qKYTCThbxEniuKPLXmL+c
   z19ctAnbEMhxUc9GnVOigB0qGg89w0xNK+Zxc4+HgOn5V36Lp7dPzQjSbs5OPKC5
   FxzRszDJvJEnF1WOeHNW/K8SlOHM0W0ZvgmVPwqYcWJ5S1yug7MwiiFTecec7k2t
   -----END CERTIFICATE-----
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

The test sender certificate above was generated for the following sender email address: `zammad@localhost`. In case your sender address is different, please see below how to re-generate it.

### Upload Recipient Certificate

1. In the same screen, click again on the **Add Certificate** button.
2. Paste the following text in the **Paste Certificate** box:

   ```crt
   -----BEGIN CERTIFICATE-----
   MIIENzCCAx+gAwIBAgIJAIzJal+S+jSEMA0GCSqGSIb3DQEBCwUAMIGgMQswCQYD
   VQQGEwJERTEPMA0GA1UECAwGQmVybGluMQ8wDQYDVQQHDAZCZXJsaW4xGjAYBgNV
   BAoMEVphbW1hZCBGb3VuZGF0aW9uMRQwEgYDVQQLDAtEZXZlbG9wbWVudDEVMBMG
   A1UEAwwMTmljb2xlIEJyYXVuMSYwJAYJKoZIhvcNAQkBFhduaWNvbGUuYnJhdW5A
   emFtbWFkLm9yZzAeFw0yMzAxMDQxNTI0NDlaFw0yMzAyMDMxNTI0NDlaMIGgMQsw
   CQYDVQQGEwJERTEPMA0GA1UECAwGQmVybGluMQ8wDQYDVQQHDAZCZXJsaW4xGjAY
   BgNVBAoMEVphbW1hZCBGb3VuZGF0aW9uMRQwEgYDVQQLDAtEZXZlbG9wbWVudDEV
   MBMGA1UEAwwMTmljb2xlIEJyYXVuMSYwJAYJKoZIhvcNAQkBFhduaWNvbGUuYnJh
   dW5AemFtbWFkLm9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKtf
   xwvnYdFKEb7jAf+6ZMnUy3Ir8sbeTlYJhrCk99mDa5iXLWLN/CLdo4k8yUiFjHgK
   k2gGkY48tz93VL/RQGRUxDyPs3Nrblgml5zu3HL6c/EAU2bGWQtICpl6qOP/qq31
   Cagu9g3rmZU4NosGkqet2HnreUoblWxfoE4DvrzJUZ2ijFzbiCTNeALs2xbHXPtL
   zDxOdmq1jkSvcKGozglJ9cXxk7vde/g9uIF+l4nPYJyySlzWMi+8HLVUvlEtxT3S
   S6njTW9qycmXKywbc1lyIlSWJx8eJJ61j9ZvnN04UBD3kHn/ww8LN/t1G/FmGsu6
   Kju3ro2EhQU19cZT3kMCAwEAAaNyMHAwCQYDVR0TBAIwADALBgNVHQ8EBAMCBeAw
   HQYDVR0OBBYEFFC5iaStg5uoFcetE2u+7rgffdKtMCIGA1UdEQQbMBmBF25pY29s
   ZS5icmF1bkB6YW1tYWQub3JnMBMGA1UdJQQMMAoGCCsGAQUFBwMEMA0GCSqGSIb3
   DQEBCwUAA4IBAQB/x3YH6AJkXpcr7JLi2eLg5Jdt0MpkoBaXRWrPiQgM//geGJxN
   mu3P0iH/KjzSpVihEm7LBs0vCpQ1mWv85WznKFtBOip5M0I0l7eyqDkuIHkwhrlS
   2j6wLAMwCi2LbVGzzvn1wEwMTH0ayBuETy68CQrLXEf2du/QfnFFTbJDqN/DGzP0
   jxelvRfyPWTHho2LxRgizTW/FS79W53b4a7a6lTOAV019hAA6H/Pghzdl7b80G5m
   h4YVZxK5uydGHaJL1KZ0H0JiLYH22FYjfll6DDwnBbPvppA0bwDgni/i9fS7yP7O
   LuqgJdzlTyOjoH7ooCm80CNNl3YpA813q7GZ
   -----END CERTIFICATE-----
   ```

3. Click on the **Add** button.

The test recipient certificate above was generated for the following customer email address: `nicole.braun@zammad.org`. In case your recipient address is different, please see below how to re-generate it.

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
   commonName_default = Zammad Helpdesk
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

   Adjust all `*_default` values to match desired settings. The most important is `emailAddress_default` which must match your sender's email address.

3. Run the following command in the same directory:

   ```sh
   openssl req -x509 -new -nodes -config sender.conf -keyout sender.key -out sender.crt
   ```

   When prompted, enter the pass phrase of the private key from the previous step.

   Confirm each field with a return (the value will be pre-populated from the configuration file).

You can now upload your new test sender certificate & private key. Either upload the actual text files (`sender.crt` and `sender.key`) or paste their contents in appropriate boxes. Remember to omit the input for the private key secret since it was not defined during the re-generation, but don't skip the private key upload since the certificate may be used for signing and decryption.

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

   Adjust all `*_default` values to match desired settings. The most important is `emailAddress_default` which must match your recipient's email address.

3. Run the following command in the same directory:

   ```sh
   openssl req -x509 -new -nodes -config recipient.conf -keyout recipient.key -out recipient.crt
   ```

   When prompted, enter the pass phrase of the private key from the previous step.

   Confirm each field with a return (the value will be pre-populated from the configuration file).

You can now upload your new test recipient certificate. Either upload the actual text file (`recipient.crt`) or paste its content in appropriate box. Note that in this case you should NOT upload the generated private key since the certificate may be used only for encryption.
