# frozen_string_literal: true

task system_test: :environment do
  print `bin/rails test:system`
  abort('System test failed!') unless $CHILD_STATUS.success?
end
