---
to: "<%= withTypeFile ? h.getPath('genericComponent', {directoryScope, suffix: `${h.usePrefix(componentName, 'generic')}/types.ts`}) : null %>"
---
// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface Dummy {
  // Add your interface here
  [key: string]: unknown
}
