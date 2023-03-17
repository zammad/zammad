<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { keyBy } from 'lodash-es'
import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import ObjectAttributes from './ObjectAttributes.vue'
import attributesJson from './__tests__/attributes.json'

const attributes = attributesJson as ObjectManagerFrontendAttribute[]

const attributesByKey = keyBy(attributes, 'name')

const object = {
  login: 'some_object',
  address: 'Berlin, Street, House',
  vip: true,
  note: 'note',
  active: true,
  invisible: 'invisible',
  objectAttributeValues: [
    {
      attribute: attributesByKey.date_attribute,
      value: '2022-08-19',
      __typename: 'ObjectAttributeValue',
    },
    {
      attribute: attributesByKey.textarea_field,
      value: 'textarea text',
    },
    {
      attribute: attributesByKey.integer_field,
      value: 600,
    },
    {
      attribute: attributesByKey.date_time_field,
      value: '2022-08-11T05:00:00.000Z',
    },
    {
      attribute: attributesByKey.single_select,
      value: 'key1',
    },
    {
      attribute: attributesByKey.multi_select_field,
      value: ['key1', 'key2'],
    },
    {
      attribute: attributesByKey.single_tree_select,
      value: 'key1::key1_child1',
    },
    {
      attribute: attributesByKey.multi_tree_select,
      value: ['key1', 'key2', 'key2::key2_child1'],
    },
    {
      attribute: attributesByKey.some_url,
      value: 'https://url.com',
    },
    {
      attribute: attributesByKey.some_email,
      value: 'email@email.com',
    },
    {
      attribute: attributesByKey.phone,
      value: '+49 123456789',
    },
  ],
}
</script>

<template>
  <Story>
    <ObjectAttributes :attributes="attributes" :object="object" />
  </Story>
</template>
