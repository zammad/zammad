# How to Set Up A Development Environment for Zammad

To be able to start developing some fancy features or to make
Zammad even greater by fixing some issues, you'll need a development environment.

The following software/tools are needed for this.

Right now, we only have instructions for macOS users and Linux users using an dpkg/apt package manager
based distribution. Users of Linux distributions with other package managers should adapt accordingly
and are encouraged to contribute their info!

## Dependencies for Zammad

The following tools are either required or highly recommended to start hacking Zammad.

For macOS:

```screen
brew install postgresql forego imlib2 openssl@1.1 direnv geckodriver chromedriver shellcheck
```

For Linux:

```screen
sudo apt install postgresql libimlib2 libimlib2-dev openssl direnv shellcheck
```

Unfortunately there is no `forego` package / binary available for Linux. We recommend to build
it from [source](https://github.com/ddollar/forego) or alternatively use
[foreman](https://github.com/ddollar/foreman).

```screen
sudo mkdir -p /usr/local/lib/gecko
curl -L -k -s https://github.com/mozilla/geckodriver/releases/download/v0.32.0/geckodriver-v0.32.0-linux64.tar.gz -o - | sudo tar -xzf - -C /usr/local/lib/gecko/
sudo mv /usr/local/lib/gecko/geckodriver /usr/local/lib/gecko/geckodriver-0.32.0
sudo ln -sf /usr/local/lib/gecko/geckodriver-0.32.0 /usr/local/bin/geckodriver
```

```screen
sudo mkdir -p /usr/local/lib/chrome
curl -L -k -s https://chromedriver.storage.googleapis.com/109.0.5414.74/chromedriver_linux64.zip -o - | zcat - | sudo tee /usr/local/lib/chrome/chromedriver-109.0.5414.74 >/dev/null
sudo chmod +x /usr/local/lib/chrome/chromedriver-109.0.5414.74
sudo ln -sf /usr/local/lib/chrome/chromedriver-109.0.5414.74 /usr/local/bin/chromedriver
```

Beware chromedriver version has to match your installed Chrome browser version.

## RVM

To maintain different Ruby versions, we encourage the usage of [RVM](https://rvm.io/).

Attention: Please look up the Ruby version in the `Gemfile` and adapt it in the snippet.

For Linux and macOS:

```screen
curl -sSL https://get.rvm.io | bash -s stable --rails
rvm install ruby-3.2.8
rvm --default use 3.2.8
```

## NVM, Node.js and pnpm

We're using [NVM](https://github.com/nvm-sh/nvm) to manage all Node.js versions which are in use with Zammad.

Before executing the following snippet, please, make sure to look up the most recent version of NVM.

For Linux and macOS:

```screen
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install node
npm install -g pnpm

# Then, in the zammad directory, install required modules:
cd </path/to/zammad-develop>
pnpm install
```

## Linting tools

To ensure a well-readable and maintainable code base, we're using linting tools like:

- [CoffeeLint](http://www.coffeelint.org/)
- [Stylelint](https://stylelint.io/)
- [ESLint](https://eslint.org/)
- [Markdownlint](https://github.com/DavidAnson/markdownlint)

There is also a dependency on [Docker](https://www.docker.com/) for some linting tasks, make sure it's available on your
system.

For Linux and macOS:

```screen
npm install -g @coffeelint/cli
npm install -g stylelint
```

## Elasticsearch

Proper operation of Zammad requires [Elasticsearch](https://www.elastic.co/de/elasticsearch/).

For macOS:

```screen
brew tap elastic/tap
brew install elastic/tap/elasticsearch-full
elasticsearch-plugin install ingest-attachment
brew services start elastic/tap/elasticsearch-full
```

For Linux:

```screen
sudo apt install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elasticsearch.list
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt update
sudo apt install elasticsearch
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment
sudo systemctl restart elasticsearch.service
```

## Redis

For macOS:

```screen
brew install redis
brew services start redis
```

For Linux (Ubuntu/Debian):

```screen
sudo apt install lsb-release

curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt-get update
sudo apt-get install redis
```

Most major Linux distributions provide packages for Redis.

## Ruby

All Ruby dependencies (including development dependencies) can be installed easily via

For Linux and macOS:

```screen
cd </path/to/zammad-develop/>
bundle install
```

## Using HTTPS

Zammad uses the gem `localhost` to automatically generate self-signed certificates. This will place
`~/.local/state/localhost.rb/localhost.crt` and `~/.local/state/localhost.rb/localhost.key` files if needed. Then you
can use one of the following commands to start the development server:

```sh
VITE_RUBY_HOST=0.0.0.0 VITE_RUBY_HTTPS=true RAILS_ENV=development forego start -r -f Procfile.dev-https
# or
pnpm dev:https
```

The application will be listening on [https://localhost:3000](https://localhost:3000).

### Self-signed Certificate Exemption

By default, the browser will not allow you to access an HTTPS site with a self-signed certificate. You will need to add
an exemption by clicking on **Advanced** and choosing **Proceed (unsafe)** or **Accept the Risk and Continue**.

In Firefox, you will also have to add an exemption for WebSocket addresses, since they use a different port. Visit
[https://localhost:6042](https://localhost:6042) and [https://localhost:3036](https://localhost:3036) to kick-start the
process and then try to reload the app.

### Signed Certificate Issued via Let's Encrypt

Sometimes, using self-signed certificates might not be enough, due to some platforms still not executing the app in a
secure context. You can issue a proper signed certificate via [Let's Encrypt](https://letsencrypt.org/) service for
free. As a pre-requisite, you will need an access to a DNS table of a custom domain and a local instance of
[Docker](https://www.docker.com/).

First, decide on a subdomain for your app, i.e. if you own `example.com` you may want to use `localhost.example.com`.

Next, run the following Docker container to start the DNS01 challenge process to verify you own the domain in question:

```sh
docker run --rm -it -v /path/to/certs:/etc/letsencrypt certbot/dns-cloudflare certonly --manual --preferred-challenges dns --email you@example.com --agree-tos --no-eff-email --key-type rsa -d localhost.example.com
```

Where:

- `/path/to/certs` is a local directory where your certificate files will be stored
- `you@example.com` is your email address
- `localhost.example.com` is the FQDN of your subdomain

When asked to deploy a DNS TXT record by certbot, open the DNS table of your domain. Add a TXT record with suggested
name in form of `_acme-challenge.localhost.example.com.` and suggested random value. Save the record and wait some
seconds for changes to propagate (this may depend on your DNS host).

Then, press Enter to continue the challenge process. If the certbot identifies your DNS record, it will automatically
issue an appropriate certificate. Do not proceed if there was an error logged, resolve it first.

Next, backup your current self-signed certificate files (if they exist) and create symbolic links to the new ones:

```sh
cd ~/.local/state/localhost.rb
mv localhost.crt localhost.crt.self-signed
mv localhost.key localhost.key.self-signed
ln -s /path/to/certs/live/localhost.example.com/cert.pem ~/.local/state/localhost.rb/localhost.crt
ln -s /path/to/certs/live/localhost.example.com/privkey.pem ~/.local/state/localhost.rb/localhost.key
```

You may need to adjust the paths depending on your subdomain name.

Next, add an A DNS record for your subdomain that points to your local IP. You can find out your local IP via
`ifconfig` or a similar command.

For example, if your local IP is `192.168.0.39` and your subdomain is `localhost.example.com`, add an A DNS record with
the name of `localhost` and point it to `192.168.0.39`. This will allow you to access the app from within your local
network only by using the proper FQDN: perfect for testing the app on mobile devices.

Finally, start the development server with `pnpm dev:https` command. You can now access the app via
[https://localhost.example.com:3000](https://localhost.example.com:3000) and it should show up as a trusted site.
