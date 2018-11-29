# Omniauth::Gitlab

[![Join the chat at https://gitter.im/linchus/omniauth-gitlab](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/linchus/omniauth-gitlab?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This is the OAuth2 strategy for authenticating to your GitLab service.

## Requirements

Gitlab 7.7.0+
 
## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-gitlab'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-gitlab

## Basic Usage

    use OmniAuth::Builder do
      provider :gitlab, ENV['GITLAB_KEY'], ENV['GITLAB_SECRET']
    end

## Standalone Usage

    use OmniAuth::Builder do
      provider :gitlab, ENV['GITLAB_KEY'], ENV['GITLAB_SECRET'], 
                                client_options: {
                                     site: 'https://gitlab.YOURDOMAIN.com',
                                     authorize_url: '/oauth/authorize',
                                     token_url: '/oauth/token'
                                 }      
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
