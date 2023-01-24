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
sudo apt install postgresql libimlib2 openssl direnv shellcheck
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

Beware chromedriver version has to match your installed chrome browser version.

## RVM

To maintain different Ruby versions, we encourage the usage of [RVM](https://rvm.io/).

Attention: Please look up the Ruby version in the `Gemfile` and adapt it in the snippet.

For Linux and macOS:

```screen
curl -sSL https://get.rvm.io | bash -s stable --rails
rvm install ruby-3.1.3
rvm --default use 3.1.3
```

## NVM, Node.js and Yarn

We're using [NVM](https://github.com/nvm-sh/nvm) to manage all Node.js versions which are in use with Zammad.

Before executing the following snippet, please, make sure to look up the most recent version of NVM.

For Linux and macOS:

```screen
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
nvm install node
npm install -g yarn

# Then, in the zammad directory, install required modules:
cd </path/to/zammad-develop>
yarn install
```

## Linting tools

To ensure a well-readable and maintainable code base, we're using linting tools like:

- [CoffeeLint](http://www.coffeelint.org/)
- [Stylelint](https://stylelint.io/)
- [ESLint](https://eslint.org/)

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

If you would like to develop something for the new mobile front end, you need

- to set `ENABLE_EXPERIMENTAL_MOBILE_FRONTEND` to `true`
- and install a Redis server on your machine.

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
$ cd </path/to/zammad-develop/>
$ bundle install
```

## Using HTTPS

To enable HTTPS in your development environment, you need to generate self-signed SSL certificates.
For this, you need to install [`mkcert`](https://github.com/FiloSottile/mkcert#installation).

You could simply use our script to generate the certificates:

```screen
$ sh contrib/ssl/generate-ssl.sh
```

This will create `localhost.crt` and `localhost.key` files and put them inside `config/ssl`. It is possible to use the environment variable `ZAMMAD_BIND_IP` or the first script argument to pass down more domains or IPs for these certificates.

Now you can run Zammad:

```sh
# to run Desktop Zammad
$ RAILS_ENV=development forego start -f Procfile.dev-https

# to run Mobile Zammad
$ VITE_RUBY_HTTPS=true RAILS_ENV=development forego start -f Procfile.dev-https
# or
$ yarn dev:https
```
