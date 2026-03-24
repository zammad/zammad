# Service Patterns

## Structure

Services live in `app/services/service/` and encapsulate business logic.
They are used e.g. by GraphQL resolvers and REST controllers.

- Pass all arguments via the **constructor**
- `#execute` is the public entry point to run the service — **no parameters**
- Inherit from `Service::Base` or `Service::BaseWithCurrentUser`
