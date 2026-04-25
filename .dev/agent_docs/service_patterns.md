# Service Patterns

## Structure

Services live in `app/services/service/` and encapsulate business logic.
They are used e.g. by GraphQL resolvers and REST controllers.

- Pass all arguments via the execute class method, e.g. Service.execute(param: :value). It is the single entry point.
- Some services have with_current_user chainable method, e.g.g Service.with_current_user(user).execute(param: :value)
- Inherit from `Service::Base`
- Current user is supplied automatically and available as current_user instance method
- Services expecting current user should have requires_current_user! in their class body
- In specs, Service.execute class method should be stubbed when needed
- Add attr_reader for all arguments passed to the initializer, so they are available in instance methods
- Service initializer should not have super() call, as Service::Base does not have an initializer
