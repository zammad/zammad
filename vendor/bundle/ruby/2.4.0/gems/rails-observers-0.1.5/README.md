[![Build Status](https://secure.travis-ci.org/rails/rails-observers.png)](https://travis-ci.org/rails/rails-observers)
# Rails::Observers

Rails Observers (removed from core in Rails 4.0)

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'rails-observers'
```
And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-observers

## Usage

This gem contains two observers:

* Active Record Observer
* Action Controller Sweeper

### Active Record Observer

Observer classes respond to life cycle callbacks to implement trigger-like
behavior outside the original class. This is a great way to reduce the
clutter that normally comes when the model class is burdened with
functionality that doesn't pertain to the core responsibility of the
class. Observers are put in `app/models` (e.g.
`app/models/comment_observer.rb`). Example:

```ruby
class CommentObserver < ActiveRecord::Observer
  def after_save(comment)
    Notifications.comment("admin@do.com", "New comment was posted", comment).deliver
  end
end
```

This Observer sends an email when a Comment#save is finished.

```ruby
class ContactObserver < ActiveRecord::Observer
  def after_create(contact)
    contact.logger.info('New contact added!')
  end

  def after_destroy(contact)
    contact.logger.warn("Contact with an id of #{contact.id} was destroyed!")
  end
end
```

This Observer uses logger to log when specific callbacks are triggered.

The convention is to name observers after the class they observe. If you
absolutely need to override this, or want to use one observer for several
classes, use `observe`:

```ruby
class NotificationsObserver < ActiveRecord::Observer
  observe :comment, :like

  def after_create(record)
    # notifiy users of new comment or like
  end

end
```

Please note that observers are called in the order that they are defined. This means that callbacks in an observer
will always be called *after* callbacks defined in the model itself. Likewise, `has_one` and `has_many`
use callbacks to enforce `dependent: :destroy`. Therefore, associated records will be destroyed before
the observer's `before_destroy` is called.

For an observer to be active, it must be registered first. This can be done by adding the following line into the `application.rb`:

    config.active_record.observers = :contact_observer

Observers can also be registered on an environment-specific basis by simply using the corresponding environment's configuration file instead of `application.rb`.

### Action Controller Sweeper

Sweepers are the terminators of the caching world and responsible for expiring caches when model objects change.
They do this by being half-observers, half-filters and implementing callbacks for both roles. A Sweeper example:

```ruby
class ListSweeper < ActionController::Caching::Sweeper
  observe List, Item

  def after_save(record)
    list = record.is_a?(List) ? record : record.list
    expire_page(controller: "lists", action: %w( show public feed ), id: list.id)
    expire_action(controller: "lists", action: "all")
    list.shares.each { |share| expire_page(controller: "lists", action: "show", id: share.url_key) }
  end
end
```

The sweeper is assigned in the controllers that wish to have its job performed using the `cache_sweeper` class method:

```ruby
class ListsController < ApplicationController
  caches_action :index, :show, :public, :feed
  cache_sweeper :list_sweeper, only: [ :edit, :destroy, :share ]
end
```

In the example above, four actions are cached and three actions are responsible for expiring those caches.

You can also name an explicit class in the declaration of a sweeper, which is needed if the sweeper is in a module:

```ruby
class ListsController < ApplicationController
  caches_action :index, :show, :public, :feed
  cache_sweeper OpenBar::Sweeper, only: [ :edit, :destroy, :share ]
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
