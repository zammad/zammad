# How to Use Forms

## Basics

Forms in Zammad are based on [FormKit](https://formkit.com/) and the documentation is referenced in the following
paragraphs.

They are defined by the `schema`. The schema data describes the form containing all needed form fields, e.g.
[the ticket creation screen](https://github.com/zammad/zammad/blob/develop/app/frontend/apps/mobile/pages/ticket/views/TicketCreate.vue#L121).
For more information, please see the [Formkit schema essentials description](https://formkit.com/essentials/schema).

## Usage of Reactivity

The forms provide reactivity to modify the form and form fields on events, e.g. user input or data manipulation.

### Schema Data

In addition to the static schema, the `Form` component can also include a `schemaData` prop. Values from the data object
and properties can then be referenced, and your schema will maintain the reactivity of the original data object.

To reference a value from the data object, you simply use `$` followed by the property name from the data object.
References can be used in the schema `attrs`, `props`, `conditionals`, and as children. Please have a look at the
[FormKit references page](https://formkit.com/essentials/schema#references).

In our implementation, the current form values are always available as `$values`.

Example:

```ts
const schemaData = reactive({
  securityIntegration: false,
})
```

Example (excerpt of static schema)

```ts
{
  if: '$securityIntegration === true && $values.articleSenderType === "email-out"',
  name: 'security',
  label: __('Security'),
  type: 'security',
}
```

### Change Fields

The `changeFields` is a reactive extension for the form implementation.

This is our preferred way of changing the state of fields after a user interacts with the form. This should be
manipulated with the `changed` event of the form.

A simple use case is to mark some fields as mandatory after a user selects the value `Support Request` in the field
`Category`.

### Handlers

This is the most powerful way to influence the behavior of the current form's reactivity.

If you need to share code between multiple forms that relate to reactivity, you have to use form handlers.

The form handler supports two execution types:

- `Initial`
- `FieldChange`

For a working example of a handler, please have a look at the
[ticket signature code](https://github.com/zammad/zammad/blob/develop/app/frontend/shared/composables/useTicketSignature.ts).
