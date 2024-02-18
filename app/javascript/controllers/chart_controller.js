import { Controller } from "@hotwired/stimulus"
import { createChart } from "lightweight-charts"

export default class extends Controller {
  static values = { ohlcSeries: Array, volumeSeries: Array }

  connect() {
    this.chart = createChart(this.element)
    const ohlcSeries = this.chart.addCandlestickSeries()

    const volumeSeries = this.chart.addHistogramSeries({
      priceFormat: { type: 'volume' },
      priceScaleId: '', // set as an overlay by setting a blank priceScaleId
    })
    volumeSeries.priceScale().applyOptions({
      // set the positioning of the volume series
      scaleMargins: {
        top: 0.7, // highest point of the series will be 70% away from the top
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
