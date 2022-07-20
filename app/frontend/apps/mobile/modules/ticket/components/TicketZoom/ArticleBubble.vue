<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { computed } from 'vue'
import { i18n } from '@shared/i18n'
import useSessionStore from '@shared/stores/session'
import { useArticleToggleMore } from '../../composable/useArticleToggleMore'

export interface Props {
  position: 'left' | 'right'
  content: string
  internal: boolean
  user: AvatarUser
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'showContext'): void
}>()

const session = useSessionStore()

const bubbleClasses = computed(() => {
  const { internal, position } = props

  if (internal) return 'border border-blue bg-black'

  return {
    'rounded-bl-sm bg-white text-black': position === 'left',
    'rounded-br-sm bg-blue text-white': position === 'right',
  }
})

const username = computed(() => {
  const { user } = props
  if (session.user?.id === user.id) {
    return i18n.t('Me')
  }
  const username = user.firstname || user.lastname
  if (username !== '-') return username
  return ''
})

const { shownMore, bubbleElement, hasShowMore, toggleShowMore } =
  useArticleToggleMore()
</script>

<template>
  <div
    role="comment"
    class="relative flex"
    :class="{
      'flex-row-reverse': position === 'right',
    }"
  >
    <div
      class="h-6 w-6 self-end"
      :class="{
        'ltr:mr-2 rtl:ml-2': position === 'left',
        'ltr:ml-2 rtl:mr-2': position === 'right',
      }"
    >
      <CommonUserAvatar size="xs" :entity="user" />
    </div>
    <div
      class="content flex flex-col rounded-3xl px-4 py-2"
      :class="bubbleClasses"
    >
      <div
        class="flex text-xs font-bold"
        data-test-id="article-username"
        :class="{
          'text-black/80': !internal && position === 'left',
          'text-white/80': internal || position === 'right',
        }"
      >
        <CommonIcon v-if="internal" size="tiny" name="lock" />
        {{ username }}
      </div>
      <div
        ref="bubbleElement"
        class="Content overflow-hidden text-base"
        data-test-id="article-content"
        v-html="content"
      />
      <div
        class="relative flex h-5 gap-2"
        :class="{
          bubbleGradient: hasShowMore && !shownMore,
          gradientBlue: position === 'right',
          gradientWhite: position === 'left',
          'justify-end': !hasShowMore,
          'justify-between': hasShowMore,
        }"
      >
        <div
          v-if="hasShowMore"
          class="cursor-pointer"
          aria-hidden="true"
          @click="toggleShowMore()"
        >
          {{ shownMore ? $t('See less') : $t('See more') }}
        </div>
        <button
          class="rotate-90"
          :title="$t('Article actions')"
          @click="emit('showContext')"
          @keydown.enter="emit('showContext')"
        >
          <CommonIcon name="overflow-button" size="tiny" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.bubbleGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 1.25rem;
  height: 30px;
  pointer-events: none;
}

.bubbleGradient.gradientBlue::before {
  background: linear-gradient(
    rgba(255, 255, 255, 0),
    theme('colors.blue.DEFAULT')
  );
}

.bubbleGradient.gradientWhite::before {
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.white'));
}
</style>
