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

export default class extends Controller {
  static values = {
    ohlcSeries: Array,
    volumeSeries: Array,
    smoothedTrendSlowSeries: Array,
    smoothedTrendFastSeries: Array,
  }

  connect() {
    this.chart = createChart(this.element)
    const ohlcSeries = this.chart.addCandlestickSeries()
    const smoothedTrendSlow = this.chart.addLineSeries()
    const smoothedTrendFast = this.chart.addLineSeries()
    const volumeSeries = this.chart.addHistogramSeries(volumeHistogramOptions)
    volumeSeries.priceScale().applyOptions(volumePriceScaleOptions);

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
