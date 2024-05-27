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
    chartTicksUrl: String,
    priceFormat: Object
  }

  connect() {
    this.chart = createChart(this.element, { localization: { timeFormatter: timeFormatter } })
    this.ohlcSeries = this.chart.addCandlestickSeries()
    this.smoothedTrendSlow = this.chart.addLineSeries()
    this.smoothedTrendFast = this.chart.addLineSeries()
    this.volumeSeries = this.chart.addHistogramSeries(volumeHistogramOptions)
    this.volumeSeries.priceScale().applyOptions(volumePriceScaleOptions);

    this.ohlcSeries.applyOptions({ priceFormat: this.priceFormatValue })
    this.loadData()
  }

  loadData = async () => {
    const response = await fetch(this.chartTicksUrlValue)
    const data = await response.json()

    this.smoothedTrendSlow.setData(data.slowTrends);
    this.smoothedTrendFast.setData(data.fastTrends);
    this.volumeSeries.setData(data.volumes)
    this.ohlcSeries.setData(data.candles)

    this.chart.timeScale().fitContent();
  }

  disconnect() {
    this.chart.remove()
    this.chart = undefined
  }
}
