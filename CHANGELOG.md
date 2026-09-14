# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-14

### Added

- Initial release of the Rails Quality Assurance kit.
- Shared RuboCop configuration for plugins: `rubocop-performance`, `rubocop-rspec`,
  `rubocop-rspec_rails`, `rubocop-capybara`, `rubocop-factory_bot`,
  `rubocop-rubycw`, `rubocop-migration`, `rubocop-rails`.
- `inherit_mode.merge: [Exclude]` so consuming projects add their own
  exclusions without dropping the shared ones.
- Reek base configuration with Rails-appropriate defaults.
- Biome and Stylelint configurations for frontend linting.
- Single-require test setup via `rails_quality_assurance/all`: SimpleCov
  100% line & branch coverage with LCOV output, RSpec core defaults, and
  Playwright/Capybara system test driver with parallel worker port
  allocation and failure HTML dumps.
- Rake tasks for quality checks (`qa:lint`, `qa:frontend`, `spec:parallel`).
- `rails_quality_assurance:ci` generator installing `bin/ci` and
  `config/ci.rb` for host-level CI execution.
- Release workflow using RubyGems trusted publishing (OIDC).