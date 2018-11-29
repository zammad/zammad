# Status
[![Gem Version](https://img.shields.io/gem/v/omniauth-weibo-oauth2.svg)][gem]
[![Security Check](https://hakiri.io/github/beenhero/omniauth-weibo-oauth2/master.svg)][security]
[![Percentage of issues still open](https://isitmaintained.com/badge/open/beenhero/omniauth-weibo-oauth2.svg)][OpenIssues]
[![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/beenhero/omniauth-weibo-oauth2.svg)][IssueResolution]
[![Build Status](https://travis-ci.org/NeverMin/omniauth-weibo-oauth2.svg?branch=master)][travis]

[gem]: https://rubygems.org/gems/omniauth-weibo-oauth2
[security]: https://hakiri.io/github/beenhero/omniauth-weibo-oauth2/master
[OpenIssues]: https://isitmaintained.com/project/beenhero/omniauth-weibo-oauth2
[IssueResolution]: https://isitmaintained.com/project/beenhero/omniauth-weibo-oauth2
[travis]: https://travis-ci.org/NeverMin/omniauth-weibo-oauth2



# OmniAuth Weibo OAuth2

Weibo OAuth2 Strategy for OmniAuth 1.0.

Read Weibo OAuth2 docs for more details: http://open.weibo.com/wiki/授权机制

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth-weibo-oauth2'
```

Then `bundle install`.

Or install it yourself as:

    $ gem install omniauth-weibo-oauth2

## Usage

`OmniAuth::Strategies::Weibo` is simply a Rack middleware. Read the OmniAuth 1.0 docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :weibo, ENV['WEIBO_KEY'], ENV['WEIBO_SECRET']
end
```
## Configuration

you can set up redirect_uri in `omniauth.rb` as following:

```ruby
provider :weibo, ENV['WEIBO_KEY'], ENV['WEIBO_SECRET'],
         token_params: {redirect_uri: "http://127.0.0.1:3000/auth/weibo/callback" }
```

## Authentication Option
* **image_size**: This option defines the size of the user's image in *Authentication Hash* (info['image']). Valid options include `small` (30x30), `middle` (50x50), `large` (180x180) and `original` (the size of the image originally uploaded). Default is `middle`.

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :weibo, ENV['WEIBO_KEY'], ENV['WEIBO_SECRET'], :image_size => 'original'
end
```

## Authentication Hash

Here's an example *Authentication Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => 'weibo',
  :uid => '1234567890',
  :info => {
    :nickname => 'beenhero',
    :name => 'beenhero',
    :location => '浙江 杭州',
    :image => 'http://tp4.sinaimg.cn/1640099215/50/1287016234/1',
    :description => '移步twitter@beenhero',
    :urls => {  :Blog => 'http://beenhero.com'
                :Weibo => 'http://weibo.com/beenhero'
    },
  },
  :credentials => {
    :token => '2.00JjgzmBd7F...', # OAuth 2.0 access_token, which you may wish to store
    :expires_at => 1331780640, # when the access token expires (if it expires)
    :expires => true # if you request `offline_access` this will be false
  },
  :extra => {
    :raw_info => {
      ... # data from /2/users/show.json, check by yourself
    }
  }
}
```
*PS.* Built and tested on MRI Ruby 1.9.3

## Build&pulish gem
```
gem build omniauth-weibo-oauth2.gemspec
```

```
gem push omniauth-weibo-oauth2-VERSION.gem
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
Copyright (c) 2012-2017 by Bin He, See [LICENSE][] for details.

[license]: LICENSE.md
