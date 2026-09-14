# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-14

### Added

- Initial release of the shared Develoz RuboCop configuration.
- Shared configuration for plugins: `rubocop-performance`, `rubocop-rspec`,
  `rubocop-rspec_rails`, `rubocop-capybara`, `rubocop-factory_bot`,
  `rubocop-rubycw`, `rubocop-migration`, `rubocop-rails`.
- `inherit_mode.merge: [Exclude]` so consuming projects add their own
  exclusions without dropping the shared ones.