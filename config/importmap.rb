# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'lightweight-charts', to: 'https://ga.jspm.io/npm:lightweight-charts@4.1.3/dist/lightweight-charts.production.mjs'
pin 'fancy-canvas', to: 'https://ga.jspm.io/npm:fancy-canvas@2.1.0/index.mjs'
