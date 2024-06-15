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

class Datafeed {
  constructor(url) {
    this._url = url
    this._nextRangePosition = null
    this.slowTrends = []
    this.fastTrends = []
    this.volumes = []
    this.candles = []
    this.backtestTrades = []
  }

  load = async () => {
    if (this._all_loaded) { return }

    const url = new URL(this._url)

    if (this._nextRangePosition) {
      url.searchParams.append('next_range_position', this._nextRangePosition)
    }

    const response = await fetch(url)
    const data = await response.json()

    if (!data.meta.nextRangePosition) {
      this._all_loaded = true
      return
    }

    this._nextRangePosition = data.meta.nextRangePosition
    this.slowTrends = [...data.slowTrends, ...this.slowTrends]
    this.fastTrends = [...data.fastTrends, ...this.fastTrends]
    this.volumes = [...data.volumes, ...this.volumes]
    this.candles = [...data.candles, ...this.candles]
    this.backtestTrades = [...data.backtestTrades, ...this.backtestTrades]
  }
}

export default class extends Controller {
  static values = {
    chartTicksUrl: String,
    priceFormat: Object
  }

  connect = async () => {
    this.loadedRanges = []
    this.chart = createChart(this.element, { localization: { timeFormatter: timeFormatter } })
    this.ohlcSeries = this.chart.addCandlestickSeries()
    this.backtestTrades = this.chart.addLineSeries({ color: 'transparent', lineWidth: 0, crossHairMarkerVisible: false })
    this.smoothedTrendSlow = this.chart.addLineSeries()
    this.smoothedTrendFast = this.chart.addLineSeries()
    this.volumeSeries = this.chart.addHistogramSeries(volumeHistogramOptions)
    this.volumeSeries.priceScale().applyOptions(volumePriceScaleOptions);

    this.ohlcSeries.applyOptions({ priceFormat: this.priceFormatValue })
    this.datafeed = new Datafeed(this.chartTicksUrlValue)
    await this.load()
    this.chart.timeScale().subscribeVisibleLogicalRangeChange(this.load)
  }

  load = async (logicalRange) => {
    if (this._loading || logicalRange && logicalRange.from > 10) { return }
    this._loading = true

    await this.datafeed.load()

    this.smoothedTrendSlow.setData(this.datafeed.slowTrends);
    this.smoothedTrendFast.setData(this.datafeed.fastTrends);
    this.volumeSeries.setData(this.datafeed.volumes);
    this.ohlcSeries.setData(this.datafeed.candles);
    this.backtestTrades.setData(this.datafeed.backtestTrades.map(({ time, value }) => ({ time, value })));
    this.backtestTrades.setMarkers(this.datafeed.backtestTrades);
    this._loading = false
  }

  disconnect() {
    this.chart.remove()
    this.chart = undefined
  }
}
