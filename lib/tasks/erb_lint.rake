# frozen_string_literal: true

task erb_lint: :environment do
  print `bundle exec erb_lint --lint-all`
  abort('erb_lint requres changes!') unless $CHILD_STATUS.success?
end
