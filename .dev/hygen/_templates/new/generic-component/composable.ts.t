---
to: "<%= withComposable ? h.getPath('genericComponent', {directoryScope: directoryScope, suffix: `${h.usePrefix(componentName, 'generic')}/${h.usePrefix(componentName, 'use')}.ts`}) : null %>"
---
// <%= h.zammadCopyright() %>

export const <%= h.usePrefix(componentName, 'use') %> = () => {
  return {}
}
