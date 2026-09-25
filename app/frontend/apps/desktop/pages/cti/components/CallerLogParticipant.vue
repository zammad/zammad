<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ConfigList } from '#shared/types/store.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

import { getCallerLogMatchName, getCallerLogNamedMatches } from '../utils/callerLog.ts'

import CallerLogMaybeBadge from './CallerLogMaybeBadge.vue'

import type { CallerLogMatch } from '../types.ts'

interface Props {
  matches: CallerLogMatch[]
  nameFormat: ConfigList['user_name_format']
  number: string
  numberPretty: string
  comment?: Maybe<string>
  isExternal?: boolean
  isDone?: boolean
  isSidebar?: boolean
}

const props = defineProps<Props>()

defineEmits<{
  'ticket-create': [userInternalId?: number]
  'user-create': [phoneNumber: string]
}>()

const session = useSessionStore()

// The same gate as the user popover: a phone agent without ticket permissions can neither
//   open a user nor create one, so they only get the names as plain text.
const hasUserAccess = computed(() => session.hasPermission(['ticket.agent', 'admin.user']))

// A user admin may open and create users, but not the ticket create screen.
const hasTicketAccess = computed(() => session.hasPermission('ticket.agent'))

const namedMatches = computed(() => getCallerLogNamedMatches(props.matches, props.nameFormat))

const primaryMatch = computed(() => namedMatches.value[0])

const primaryMatchName = computed(() =>
  primaryMatch.value ? getCallerLogMatchName(primaryMatch.value, props.nameFormat) : '',
)

const additionalMatches = computed(() => namedMatches.value.slice(1))

const additionalMatchesCount = computed(() =>
  additionalMatches.value.length > 99 ? '+99' : `+${additionalMatches.value.length}`,
)

// A match can carry a comment instead of a user, so a row also has to work without one.
const additionalMatchEntries = computed(() =>
  additionalMatches.value.map((match, index) => ({
    key: match.user?.id ?? `comment-${index}`,
    name: getCallerLogMatchName(match, props.nameFormat) as string,
    user: match.user,
    isMaybe: match.level === 'maybe',
  })),
)

// Without a match, the name the telephony backend sent stands in, as in the old caller log:
//   the agent who took or made the call, the queue, or a user who has been deleted since.
const commentName = computed(() => (namedMatches.value.length ? '' : props.comment || ''))

const displayName = computed(() => primaryMatchName.value || commentName.value)

const isUnknown = computed(
  () => props.isExternal && namedMatches.value.length === 0 && !commentName.value,
)

const canCreateTicket = computed(() => props.isSidebar && hasTicketAccess.value)
</script>

<template>
  <div class="flex min-h-10 grow items-center gap-1">
    <div v-if="additionalMatches.length" class="flex grow flex-col">
      <!-- Indented past the avatar stack, so the number lines up with the single-caller rows. -->
      <CommonLabel
        v-if="isSidebar"
        class="line-clamp-1! ps-9 break-all text-stone-200! dark:text-neutral-500!"
        size="small"
        >{{ numberPretty || number }}</CommonLabel
      >
      <CommonLink
        v-else
        class="line-clamp-1 ps-9 break-all"
        :link="`tel:${number}`"
        external
        size="small"
        >{{ numberPretty || number }}</CommonLink
      >
      <div class="flex items-center gap-1">
        <div class="flex">
          <UserPopoverWithTrigger
            v-if="primaryMatch?.user"
            class="z-10"
            :avatar-config="{ size: 'xs', avatarClass: isDone ? 'grayscale' : undefined }"
            :popover-config="{ orientation: 'left' }"
            :user="primaryMatch.user"
            :is-maybe="primaryMatch.level === 'maybe'"
          />
          <CommonUserAvatar
            v-if="additionalMatchEntries[0].user"
            :entity="additionalMatchEntries[0].user"
            class="-ms-4"
            size="xs"
            :avatar-class="isDone ? 'grayscale' : undefined"
          />
          <CommonAvatar
            v-else
            class="-ms-4 bg-yellow-300"
            :class="{ grayscale: isDone }"
            size="xs"
            decorative
          />
        </div>
        <CommonLabel class="line-clamp-1! break-all" size="medium">{{
          primaryMatchName
        }}</CommonLabel>
        <CommonPopoverWithTrigger
          placement="arrowStart"
          trigger-link-class="rounded-full"
          trigger-link-active-class="outline-blue-800! outline-2!"
        >
          <template #popover-content="{ popoverId }">
            <section data-type="popover" class="flex flex-col gap-1 p-2">
              <CommonLabel
                :id="`${popoverId}-label`"
                class="px-1 py-0.5 text-stone-200! dark:text-neutral-500!"
                size="small"
                tag="h3"
              >
                {{ $t('Multiple matches') }}
              </CommonLabel>
              <ul :aria-labelledby="`${popoverId}-label`" class="flex flex-col gap-1.5">
                <li
                  v-for="match in additionalMatchEntries"
                  :key="match.key"
                  class="flex items-center gap-2"
                >
                  <CommonUserAvatar v-if="match.user" :entity="match.user" size="small" />
                  <CommonAvatar v-else class="bg-yellow-300" size="small" decorative />
                  <CallerLogMaybeBadge v-if="match.isMaybe" />
                  <CommonLink
                    v-if="match.user && hasUserAccess"
                    class="line-clamp-2 break-all"
                    :link="`/users/${match.user.internalId}`"
                    >{{ match.name }}</CommonLink
                  >
                  <CommonLabel v-else class="line-clamp-2! break-all">{{ match.name }}</CommonLabel>
                </li>
              </ul>
            </section>
          </template>
          <CommonBadge class="cursor-pointer" variant="tertiary" size="circle">{{
            additionalMatchesCount
          }}</CommonBadge>
        </CommonPopoverWithTrigger>
      </div>
    </div>
    <div v-else-if="displayName || isUnknown" class="flex grow items-center gap-1">
      <UserPopoverWithTrigger
        v-if="primaryMatch?.user"
        :avatar-config="{ size: 'small', avatarClass: isDone ? 'grayscale' : undefined }"
        :popover-config="{ orientation: 'left' }"
        :user="primaryMatch.user"
        :is-maybe="primaryMatch.level === 'maybe'"
      />
      <CommonAvatar
        v-else-if="isUnknown"
        class="bg-yellow-300"
        :class="{ grayscale: isDone }"
        size="small"
        :aria-label="$t('Unknown caller')"
      />
      <CommonAvatar
        v-else-if="commentName"
        class="bg-yellow-300"
        :class="{ grayscale: isDone }"
        size="small"
        decorative
      />
      <div class="flex grow flex-col">
        <CommonLabel
          v-if="isSidebar"
          class="line-clamp-1! break-all text-stone-200 dark:text-neutral-500"
          size="small"
          >{{ numberPretty || number }}</CommonLabel
        >
        <CommonLink
          v-else
          class="line-clamp-1 break-all"
          :link="`tel:${number}`"
          external
          size="small"
          >{{ numberPretty || number }}</CommonLink
        >
        <div class="flex items-center gap-1">
          <CallerLogMaybeBadge v-if="primaryMatch?.level === 'maybe'" :is-sidebar="isSidebar" />
          <CommonLabel v-if="displayName" class="line-clamp-1! break-all" size="large">{{
            displayName
          }}</CommonLabel>
        </div>
        <CommonLink
          v-if="isSidebar && isUnknown && hasUserAccess"
          class="group"
          link="#"
          @click="$emit('user-create', numberPretty || number)"
        >
          <CommonLabel
            class="text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!"
            prefix-icon="user-add"
            size="small"
          >
            <span class="line-clamp-1 break-all">{{ $t('New user') }}</span>
          </CommonLabel>
        </CommonLink>
      </div>
    </div>
    <CommonLink
      v-else
      class="line-clamp-1 ps-9 break-all"
      :link="`tel:${number}`"
      external
      size="small"
      >{{ numberPretty || number }}</CommonLink
    >
    <CommonButton
      v-if="!isSidebar && isUnknown && hasUserAccess"
      v-tooltip="$t('New user')"
      variant="secondary"
      icon="user-add"
      size="large"
      @click="$emit('user-create', numberPretty || number)"
    />
    <CommonButton
      v-if="canCreateTicket"
      v-tooltip="$t('New ticket')"
      variant="secondary"
      icon="plus-square-fill"
      size="large"
      @click="$emit('ticket-create', primaryMatch?.user?.internalId)"
    />
  </div>
</template>
