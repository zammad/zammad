<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { BarChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  AriaComponent,
} from 'echarts/components'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import VChart from 'vue-echarts'

import { useChartTheme } from '../useChartTheme.ts'

import type { BarChartOptions } from './types.ts'

use([
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  BarChart,
  CanvasRenderer,
  GridComponent,
  AriaComponent,
])

interface Props {
  option: BarChartOptions
}

defineProps<Props>()

useChartTheme()
</script>

<template>
  <VChart :option="option" autoresize />
</template>
