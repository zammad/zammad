// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import HardBreak from '@tiptap/extension-hard-break'

export default HardBreak.extend({
  addKeyboardShortcuts() {
    return {
      // by default "Enter" doesn't add an actual line break, only "visible" break.
      // actual line break is added with "Shift+Enter", which is not very intuitive,
      // so we are rewriting it for out implementation to also use "Enter" for line break
      // WARNING: this should not be used for HTML editor as it causes bugs with other extensions
      Enter: () => this.editor.commands.setHardBreak(),
    }
  },
})
