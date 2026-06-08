# How to Design Services

## 1. Purpose of a service

A service is a small class with a single entry point that performs a specific task. It is used to encapsulate logic that
is not directly tied to a particular model. Or when a model has accumulated so many responsibilities that it becomes too
large.

## 2. Structure of a service

Services are located in `app/services` and inherit from `Service::Base`. The only required method is `#execute` instance
method.

An initializer is optional and should be defined only if arguments are needed. `#execute` must return the final result
as a stand-alone value. Services should be stateless.

To invoke a service, use `.execute` class method. This method initializes the service and calls `#execute`, returning
its result.

Example:

```ruby
class SampleService < Service::Base
  attr_reader :arg1, :arg2

  def initialize(arg1, arg2)
    @arg1 = arg1
    @arg2 = arg2
  end

  def execute
    SomeLibrary.do_something(arg1, arg2)
  end
end
```

Usage:

```ruby
SampleService.execute(arg1, arg2)
```

## 3. Handling the current user

The current user is important in many scenarios. Both explicit user to use inside the service logic and implicitly via
`UserInfo` to set `created_by_id/updated_by_id`.

REST controllers and GraphQL operations provide the current user and set `UserInfo` accordingly. However, services may
be used in other contexts, such as background jobs, or may need to run on behalf of a different user than the one
provided by the context.

Any service can be given a current user by chaining `.with_current_user` before `.execute`. This makes `#current_user`
available inside the service.

Declaring `requires_current_user!` in the class body enforces that a current user must be explicitly provided. Otherwise
it remains optional.

Please note that services inherit the current user of the execution context. To call a service without a current user
(i.e. with `UserInfo` unset), chain `.with_current_user(false)` before `.execute`.

Example:

```ruby
class SampleService < Service::Base
  requires_current_user!

  attr_reader :arg1, :arg2

  def initialize(arg1, arg2)
    @arg1 = arg1
    @arg2 = arg2
  end

  def execute
  current_user.do_something(arg1, arg2)
  end
end
```

Usage:

```ruby
SampleService.with_current_user(User.last).execute(arg1, arg2)
```

## 4. Testing services

Services should be tested using RSpec. Test should be placed in `spec/services`.

Example:

```ruby
RSpec.describe SampleService do
  subject(:service_result) { described_class.execute(arg1, arg2) }

  it 'expects to do something' do
    expect(service_result).to eq(expected_result)
  end
end
```

## 5. Using Services in Other Tests

When testing other parts of the system, services can be mocked by stubbing the .execute class method.

```ruby
allow(SampleService).to receive(:execute)
```

Please note that current_user is injected automatically. When asserting arguments, it should be included as well:

```ruby
allow(SampleService).to receive(:execute).with(arg1, arg2, current_user: User.last)
```

## 6. Service-Like classes

Not every class with `Service` in its name follows the conventions described here. This document applies only to classes
in `app/services` that inherit from `Service::Base`.

Classes located in `lib/service` or `lib/ai/service` represent a different pattern and are not covered by this guide.
