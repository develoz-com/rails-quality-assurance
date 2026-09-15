# frozen_string_literal: true

# 1. Start SimpleCov immediately before any app code is loaded
require 'rails_quality_assurance/simplecov'

# 2. Configure RSpec core settings if RSpec is present
require 'rails_quality_assurance/rspec'

# 3. Load the Playwright helper. Rails-specific hooks are configured after
# rspec/rails loads by rails_quality_assurance/rails_helper.
require 'rails_quality_assurance/playwright/helper'
