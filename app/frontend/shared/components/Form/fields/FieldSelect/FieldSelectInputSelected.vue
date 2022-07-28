<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts">
import { defineComponent, h } from 'vue'

export default defineComponent({
  props: {
    slotted: { type: Function },
    label: { type: [String, Number] },
    small: { type: Boolean },
  },
  render() {
    if (this.slotted) {
      return this.slotted({ label: this.label })
    }
    return h(
      'span',
      {
        class: {
          'max-w-[60vw] overflow-hidden text-ellipsis whitespace-nowrap text-sm':
            this.small,
        },
      },
      this.label,
    )
  },
})
</script>
