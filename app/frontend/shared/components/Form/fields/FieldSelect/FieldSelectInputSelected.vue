<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts">
import { defineComponent, h } from 'vue'

export default defineComponent({
  props: {
    slotted: { type: Function },
    label: { type: [String, Number] },
  },
  render() {
    if (this.slotted) {
      return this.slotted({ label: this.label })
    }
    return h('span', this.label)
  },
})
</script>
