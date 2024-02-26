import { Controller } from "@hotwired/stimulus"
import { createChart } from "lightweight-charts"

export default class extends Controller {
  static values = { ohlcSeries: Array, volumeSeries: Array }

  connect() {
    console.log('sssss')
    this.chart = createChart(this.element)
    const ohlcSeries = this.chart.addCandlestickSeries()

    const volumeSeries = this.chart.addHistogramSeries({
      priceFormat: { type: 'volume' },
      priceScaleId: '',
    })
    volumeSeries.priceScale().applyOptions({
      scaleMargins: {
        top: 0.7,
        bottom: 0,
      },
    });

    volumeSeries.setData(this.volumeSeriesValue)
    ohlcSeries.setData(this.ohlcSeriesValue);

    this.chart.timeScale().fitContent();
  }

  disconnect() {
    this.chart.remove()
    this.chart = undefined
  }
}
