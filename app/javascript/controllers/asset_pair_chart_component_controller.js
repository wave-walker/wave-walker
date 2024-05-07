import { Controller } from "@hotwired/stimulus"
import { createChart } from "lightweight-charts"

const volumeHistogramOptions = {
  priceFormat: { type: 'volume' },
  priceScaleId: '',
}

const volumePriceScaleOptions = {
  scaleMargins: {
    top: 0.7,
    bottom: 0,
  },
}

function timeFormatter(seconds) {
  const date = new Date(seconds * 1000)

  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString()
}

export default class extends Controller {
  static values = {
    ohlcSeries: Array,
    volumeSeries: Array,
    smoothedTrendSlowSeries: Array,
    smoothedTrendFastSeries: Array,
    priceFormat: Object
  }

  connect() {
    this.chart = createChart(this.element, { localization: { timeFormatter: timeFormatter } })
    const ohlcSeries = this.chart.addCandlestickSeries()
    const smoothedTrendSlow = this.chart.addLineSeries()
    const smoothedTrendFast = this.chart.addLineSeries()
    const volumeSeries = this.chart.addHistogramSeries(volumeHistogramOptions)
    volumeSeries.priceScale().applyOptions(volumePriceScaleOptions);

    ohlcSeries.applyOptions({ priceFormat: this.priceFormatValue })

    ohlcSeries.setData(this.ohlcSeriesValue);
    smoothedTrendSlow.setData(this.smoothedTrendSlowSeriesValue);
    smoothedTrendFast.setData(this.smoothedTrendFastSeriesValue);
    volumeSeries.setData(this.volumeSeriesValue)

    this.chart.timeScale().fitContent();
  }

  disconnect() {
    this.chart.remove()
    this.chart = undefined
  }
}
