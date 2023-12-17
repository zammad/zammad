# How It Works

Automocker (as the name suggests) mocks all requests automatically. This means that you will not get an error like
`Request handler not defined for query` when API is called in tests.

When a request is sent, mocker reads the document and finds a definition in `graphql_introspection.json` file. Based on
this definition, it creates an object with defined fields and randomized data.

Default values can be defined globally by placing a file inside `./factories` folder. This can be useful to fix several
problems:

- Prevent duplication (for example, some types only provide a specific number of variations like
  `ObjectManagerFrontendAttributesPayload`)

- Make some types predictable (for example, by default there is only one organization and one user group, also useful
  when there are fields that depend on others, like `fullname`)

- Prevent recursion (for example, organization provides a specific user as a member)

Algorithm is smart enough to not generate a new object if the ID is known. It will just take it from the cache - if
there are none in the cache, it will generate a new one. This is useful because you don't need to store all references
if you want to provide default values:

```ts
// For example, we can list the same users just by simply providing a correct ID.
mockGraphQLResult(TicketArticles, {
  // This is a simplified example.
  articles: [
    { createdBy: { id: convertToGraphQLId('User', 1) } },
    // You can also pass down a numerical string - automocker will convert it into a correct GraphQL ID.
    { createdBy: { id: '2' } },
    { createdBy: { id: '1' } },
    { createdBy: { id: convertToGraphQLId('User', 2) } },
  ],
})
```

Automocker will also prefer an object with a known ID if variables are provided. For example, if a mutation is called
with a variable ID like `userId` (it should match returned type name) and `input`, it will automatically find an object
inside the cache and apply changes from the `input` field. This logic _only_ applies to top-level property, so nested
objects are not affected.

Beware that cache will reset after each test, so mocking with `mockGraphQLResult` should be done inside the test or in
a `beforeEach` hook.

Even though most values are generated randomly, some are hardcoded - for example, `errors`, `createdBy` and `updatedBy`
are hardcoded to be `null` to prevent a recursion in future types.

## API

### `generateObjectData`

- **Path**: `#tests/graphql/builders/index.ts`

Generates an object from a GraphQL type name. You can provide a partial defaults object to make it more predictable.

This function always generates a new object and never caches it. It is useful to generate an object when testing a
single component that accepts a certain shape of an object like ticket.

```ts
import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import type { Ticket } from '#shared/graphql/types.ts'

test('renders component', () => {
  const ticket = generateObjectData<Ticket>('Ticket', {
    // Validates types because we passed it down as `<Ticket>`.
    number: 100,
  })

  renderComponent(Component, {
    props: {
      ticket,
    },
  })

  // Other checks...
})
```

### `getGraphQLMockCalls` and `waitForGraphQLMockCalls`

- **Path**: `#tests/graphql/builders/mocks.ts`

This returns information about every call to a specific API that was done at this point. This is a sync method, so you
need to make sure that the API call was already made. This is why it is recommended to use `waitForGraphQLMockCalls`
instead.

```ts
import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import type { LoginMutation } from '#shared/graphql/types.ts'

it('calls mutation', async () => {
  // Render a view/component first.

  clickButtonThatCallsMutation()

  const calls = getGraphQLMockCalls<LoginMutation>('mutation', 'Login')
  // or
  const calls = await waitForGraphQLMockCalls<LoginMutation>(
    'mutation',
    'Login',
  )
  console.log(calls) // [{ result: {}, variables: { login, password } }]

  // Other checks...
})
```

You can use this method to verify inputs (like login and password) or to get values that were returned from the API (in
cases where it was generated randomly). This method can also be used to ensure that the API was called before you make
other assertions, although it is preferred to use `view.findBy*` methods instead.

### `mockGraphQLResult`

- **Path**: `#tests/graphql/builders/mocks.ts`

To make sure that the API results are consistent you may need to provide your own data. This method needs to be called
**before** the API call is made. So, if you are calling a query, call this before `visitView`. If you are calling a
mutation, you can call this before making an action (like a click) that triggers said mutation.

This method also returns an object that can reassign defaults (via `updateDefaults`) or wait until the API is called
(via `waitForCalls`).

```ts
import type {
  LoginMutation,
  LoginMutationVariables,
} from '#shared/graphql/types.ts'
import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'

it('correctly returns result', async () => {
  const mocker = mockGraphQLResult<LoginMutation, LoginMutationVariables>(
    LoginDocument,
    {
      login: {
        // Since this test depends on these values, set them.
        twoFactorRequired: {
          recoveryCodesAvailable: false,
        },
      },
    },
  )

  // You can reassign defaults if needed (i.e. if there are several calls to the same API).
  //   This overrides previous defaults value.
  mocker.updateDefaults({
    login: {
      twoFactorRequired: {
        recoveryCodesAvailable: true,
      },
    },
  })

  // You can also always provide a function as the defaults value.
  //   It accepts variables that were passed down.
  //   This is useful if the API is called multiple times with different values (like a pagination).
  //   Since we provided `<LoginMutationVariables>`, we can use variables safely.
  mocker.updateDefaults(({ input }) => ({
    login: {
      twoFactorRequired: {
        recoveryCodesAvailable: input.login === 'admin',
      },
    },
  }))

  const view = await visitView('/login')

  // Same as `waitForGraphQLMockCalls<LoginMutation>(LoginDocument)`
  //   We don't need to provide `<LoginMutation>` because we called `mockGraphQLResult` with the same parameter.
  const calls = await mocker.waitForCalls()

  // Other assertions...
})
```

### `getGraphQLSubscriptionHandler`

- **Path**: `#tests/graphql/builders/mocks.ts`

This method returns a handler to manipulate a subscription. It should be called after the subscription has been
established or it will throw an error. You can trigger the next subscription event with `trigger` or `triggerErrors`
methods.

```ts
import { getGraphQLSubscriptionHandler } from '#tests/graphql/builders/mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import type { CurrentUserUpdatesSubscription } from '#shared/graphql/types.ts'

test('subscription is triggered', async () => {
  const userInternalId = 1
  const userId = convertToGraphQLId('User', userInternalId)
  const view = await visitView(`/user/${userInternalId}`)

  // If you provide a generic type, it will actually typecheck the name.
  const subscription =
    getGraphQLSubscriptionHandler<CurrentUserUpdatesSubscription>('userUpdates')

  // Because the type was provided to the handler, `.trigger` will validate it.
  await subscription.trigger({
    userUpdates: {
      user: {
        id: userId,
        fullname: 'Some New Name',
      },
    },
  })

  expect(
    await view.findByRole('heading', { name: 'Some New Name' }),
  ).toBeInTheDocument()
})
```
