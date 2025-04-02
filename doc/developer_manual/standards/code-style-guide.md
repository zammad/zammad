# Code Style Guide

## General

### Enforcing style guides

Our coding standards are enforced in the internal CI by various tools like Rubocop and ESLint.
To make sure you always keep them in mind, you can use git hooks based on
[**overcommit**](https://github.com/sds/overcommit) for this.

```screen
overcommit --install
```

This will execute several checks on the changed files whenever you commit.
Feel free to add suggestion for additional interesting commit hooks. 🚀

Linters can also be run manually:

```screen
# Robocop
bundle exec rubocop --parallel

# Type checks, ESLint, Stylelint & Markdownlint
pnpm lint

# Type checks, ESLint, Stylelint & Markdownlint with automatic fixing
pnpm lint:fix

# Just type checking
pnpm lint:ts

# Just ESLint checks
pnpm lint:js

# Just ESLint checks with automatic fixing
pnpm lint:js:fix

# Just Stylelint checks
pnpm lint:css

# Just Stylelint checks with automatic fixing
pnpm lint:css:fix

# Just Markdownlint checks
pnpm lint:md

# Just Markdownlint checks with automatic fixing
pnpm lint:md:fix

# Coffeelint
coffeelint --rules ./.dev/coffeelint/rules/* app/
```

### Wording

- Use common technical terms (allowlist, origin, etc.) for non user facing words/variable names.

## Ruby

Rubocop will tell you. Don't forget to run it. Here are some additional tips.

### Idiomatic ruby

- Use question mark methods for boolean returning methods.
- Use Array#any? when checking for matching entry.
- Use `&.` to safely call method on possible `nil` variable.
- Use `Hash#fetch` for receiving values from hash and providing fall back value.

### Idiomatic Rails

- Use `Object#presence` to return variable value while treating non `Object#present?` values as nil.

### Naming of Concerns

#### `Has*`

The methods are doing model related functions and events.
This area is mainly used to do changes to other related objects.

For example, a model

- gets some new events to clear the cache in the cache object
- will get some new events to verify attachments in the store object
- will modify the external sync object after destroying an object

#### `Checks*`

The code contains hooks to events (e.g. `after_commit`), validations or another pre/post function checks.

For example:

- added a check to verify the length of an attribute

#### `Can*`

The code contains new functions without any relations to any hook or event.

For example, a model will get some new util functions

- which can be used to read additional assets
- to handle parameters in a more efficient way

### RSpec

- Use let(:...) for common/setup variables.
- Use one expectation per example (it) where possible.

## Vue & Typescript

### Naming

#### class / interface / type / enum / decorator / type parameters

UpperCamelCase: e.g. ApolloClient

#### variable / parameter / function / method / property / module alias

lowerCamelCase_ e.g. fileSize

#### Files-Names

##### Vue Components

UpperCamelCase: e.g. CommonDateTime.vue

##### Typescript Files / Other

##### Vue Template Refs

- Use SnakeCase for template ref f.g `ref="resize-line"`
- Component instance variables should contain `${ComponentName}Instance`
- Prefer to use `useTemplateRef` over `ref` for template references

###### useTemplateRef

[docs](https://vuejs.org/api/composition-api-helpers.html#usetemplateref)

```vue
<script setup lang="ts">
import { useTemplateRef } from 'vue'

const buttonInstance =  useTemplateRef('button')
const resizeLineInstance = useTemplateRef('resize-line')

const listElement = useTemplateRef('list')
</script>

<template>
  <CommonButton ref="button"/>
  <ResizeLine ref="resize-line"/>

  <ul ref="list"/>
</template>
```

###### ref

[docs](https://vuejs.org/api/reactivity-core.html#ref)

```vue
<script>
  import { ref } from 'vue'

  export const usePopoverTarget = () => {
    const popoverTarget = ref()
    return { popoverTarget }
  }
</script>

<script setup lang="ts">
  const { popoverTarget } = usePopoverTarget()

</script>

<template>
  <button ref="popoverTarget"/>
</template>
```

TBD

### Template

#### Component-Naming-Style

UpperCamelCase:

```plain
<div>
<CommonDateTime ... />
<CommonDateTime>...</CommonDateTime>
</div>
```
