---
to: "<%= h.getPath('composable', {directoryScope: directoryScope, suffix: `${h.usePrefix(composableName, 'use')}.ts`}) %>"
---
// <%= h.zammadCopyright() %>

export const <%= h.usePrefix(composableName, 'use') %> = () => {
  return {}
}
