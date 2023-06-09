# frozen_string_literal: true

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  begin
    config.filter_run_when_matching :focus

    config.example_status_persistence_file_path = 'spec/examples.txt'

    config.disable_monkey_patching!

    if config.files_to_run.one?
      # Use the documentation formatter for detailed output,
      # unless a formatter has already been configured
      # (e.g. via a command-line flag).
      config.default_formatter = 'doc'
    end

    # Print the 10 slowest examples and example groups at the
    # end of the spec run, to help surface which specs are running
    # particularly slow.
    config.profile_examples = 10

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = :random

    # Seed global randomization in this process using the `--seed` CLI option.
    # Setting this allows you to use `--seed` to deterministically reproduce
    # test failures related to randomization by passing the same `--seed` value
    # as the one that triggered the failure.
    Kernel.srand config.seed

    config.before(:each) do |_example|
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end
