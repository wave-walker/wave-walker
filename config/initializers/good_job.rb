# frozen_string_literal: true

Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.enable_cron = true
  config.good_job.queues = '+critical,default,low'

  config.good_job.cron = {
    asset_pair_create_task: {
      cron: '0 */4 * * *',
      class: 'CreateKrakenAssetPairsJob',
      description: 'Creates new Kraken asset pairs.'
    },
    asset_pair_sync_task: {
      cron: '*/5 * * * *',
      class: 'TradeImportJob',
      description: 'Get latest Kraken trades.'
    },
    schedual_ohlc_generation_task: {
      cron: '*/5 * * * *',
      class: 'TriggerOhlcGenerationJob',
      description: 'Schedual OHCL creation until the latest import.'
    },
    backtest_scheduling_task: {
      cron: '0 */4 * * *',
      class: 'BacktestSchedulerJob',
      description: 'Schedual backtesting for all assets.'
    }
  }
end
