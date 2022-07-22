# How to Set Up A Development Environment for Zammad

To be able to start developing some fancy features or to make
Zammad even greater by fixing some issues, you'll need a development environment.

The following software/tools are needed for this.

Right now, we only have instructions for macOS users. Linux users should adapt
accordingly and are encouraged to contribute their info!

## Dependencies for Zammad

The following tools are either required or highly recommended to start hacking Zammad.

For macOS:
```screen
brew install postgresql forego imlib2 openssl@1.1 direnv geckodriver chromedriver shellcheck
```

For Linux:
```screen
...
```

## RVM

To maintain different Ruby versions, we encourage the usage of [RVM](https://rvm.io/).

Attention: Please look up the Ruby version in the `Gemfile` and adapt it in the snippet.

For Linux and macOS:
```screen
curl -sSL https://get.rvm.io | bash -s stable --rails
rvm install ruby-3.0.4
rvm --default use 3.0.4
```

## NVM, Node.js and Yarn

We're using [NVM](https://github.com/nvm-sh/nvm) to manage all Node.js versions which are in use with Zammad.

Before executing the following snippet, please, make sure to look up the most recent version of NVM.

For Linux and macOS:
```screen
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
nvm install node
npm install -g yarn

# Then, in the zammad directory, install required modules:
cd </path/to/zammad-develop>
yarn install
```

## Linting tools

To ensure a well readable and maintainable code base, we're using linting tools like:
* [CoffeeLint](http://www.coffeelint.org/)
* [Stylelint](https://stylelint.io/)
* [ESLint](https://eslint.org/)

For Linux and macOS:
```screen
npm install -g coffeelint@1
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
...
```

## Ruby

All Ruby dependencies (including development dependencies) can be installed easily via

For Linux and macOS:
```screen
$ cd </path/to/zammad-develop/>
$ bundle install
```
