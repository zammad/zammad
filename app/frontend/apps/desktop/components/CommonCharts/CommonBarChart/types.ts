// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { BarSeriesOption } from 'echarts/charts'
import type {
  TitleComponentOption,
  TooltipComponentOption,
  LegendComponentOption,
  GridComponentOption,
} from 'echarts/components'
import type { ComposeOption } from 'echarts/core'

export type BarChartOptions = ComposeOption<
  | TitleComponentOption
  | TooltipComponentOption
  | LegendComponentOption
  | BarSeriesOption
  | GridComponentOption
>
