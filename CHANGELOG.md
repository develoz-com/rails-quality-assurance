# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.3] - 2026-09-28

### Fixed

- `Capybara/NegationMatcherAfterVisit` renamed to
  `Capybara/RSpec/NegationMatcherAfterVisit` in the packaged `rubocop.yml`.
  rubocop-capybara 2.23.0 moved the cop under the `Capybara/RSpec` department,
  so the old name triggered "has the wrong namespace" warnings on 2.23.0+ and
  on 3.0.0. The declared `rubocop-capybara` floor is raised to `>= 2.23.0`,
  the first release where the new name is canonical.

## [1.6.2] - 2026-09-28

### Added

- JavaScript dependency audit as a quality gate. `qa:audit:npm` (also part of
  `qa:lint` and the generated `config/ci.rb`) resolves the audit command from
  the lockfile in use — `npm audit`, `yarn audit`, or `pnpm audit` — and fails
  on high and critical advisories. Yarn 1 ignores `--level` for its exit code,
  so its severity bitmask is masked to high|critical. Skipped when the app has
  no lockfile.

### Changed

- Relaxed the RuboCop dependency pins from pessimistic (`~>`) to `>=` for
  `rubocop`, `rubocop-capybara`, `rubocop-performance`, `rubocop-rails`, and
  `rubocop-rspec`. The `~>` pins forced a downgrade when a consuming app pinned
  a newer RuboCop, which blocked adding the gem to those lockfiles.

## [1.6.1] - 2026-09-28

### Added

- Coverage thresholds are configurable. `MINIMUM_LINE_COVERAGE`,
  `MINIMUM_BRANCH_COVERAGE`, `MAXIMUM_COVERAGE_DROP`, and
  `MAXIMUM_COVERAGE_DROP_BRANCH` override the 100% line/branch defaults per run,
  and `.simplecov` values are honored. Precedence: environment, then
  `.simplecov`, then gem defaults.

### Fixed

- `SimpleCov.minimum_coverage` set in `.simplecov` is no longer overwritten by
  the gem's hardcoded 100% defaults. The defaults now apply only when the
  project has not configured the threshold.

## [1.6.0] - 2026-09-25

### Added

- `spec:parallel` holds a cross-process `flock` lock
  (`tmp/qa/spec_parallel.lock`). A second run aborts immediately with the
  holder's command, PID, and elapsed time instead of piling workers onto the
  machine. The kernel releases the lock when the holder exits, including on
  SIGKILL, and the descriptor is inherited by spawned workers so the lock
  outlives a killed coordinator for as long as any worker keeps running.

## [1.5.0] - 2026-09-25

### Changed

- `spec:parallel` defaults `PARALLEL_TEST_PROCESSORS` to the number of available
  CPUs instead of a hardcoded 3. On a 6-CPU machine the default run uses 6
  workers: 5 for the regular suite plus 1 isolated worker for `spec/system/`.

### Fixed

- `ISOLATE_SPEC_TASKS=0` now disables system spec isolation. `--isolate-n 0`
  was silently ignored by parallel_tests, which still reserved a dedicated
  worker and kept system specs out of the regular grouping.

## [1.4.2] - 2026-09-16

### Fixed

- Parallel workers no longer skip SimpleCov when their slice covers a single
  file. `filtered_run?` treated any one-file run as a filtered single-spec run,
  so a worker assigned an isolated phase (e.g. `--isolate --single spec/system/`)
  started no coverage at all. With no worker claiming the final merge, sibling
  workers wrote resultsets that nobody merged, and the parallel run silently
  skipped the line/branch thresholds it was supposed to enforce. Parallel runs
  now always collect coverage, and the first worker merges and enforces.

## [1.4.1] - 2026-09-15

### Fixed

- Replaced the deprecated `SimpleCov.add_filter` calls with `SimpleCov.skip`,
  silencing the deprecation warning every consuming app saw during test runs.
  `add_filter` was a thin alias for `skip`, so behavior is unchanged.

## [1.4.0] - 2026-09-15

### Added

- `qa:audit:gems` and `qa:audit:importmap` tasks. `qa:audit` runs the gem
  audit, `qa:audit:importmap` audits pinned importmap packages when the app
  has `config/importmap.rb` (skipped otherwise), and `qa:lint` runs both.
- `RailsQualityAssurance.importmap_audit_command` resolves the importmap audit
  command: the app `bin/importmap` binstub when present, otherwise a
  dependency-light `importmap-rails` invocation that does not boot Rails.

## [1.2.0] - 2026-09-14

### Added

- `rails_quality_assurance/rails_helper`: one require applying the shared Rails
  test configuration (schema check, transactional fixtures, spec-type inference,
  Rails backtrace filtering, FactoryBot, time helpers, WebMock lockdown with a
  loopback/Playwright allowlist, I18n locale, Faker reset, CSRF toggle).

### Changed

- SimpleCov upgraded to 1.3 with explicit `finalize_merge` so parallel workers
  enforce thresholds exactly once.
- QA rake tasks live under `qa:` and no longer boot the Rails environment, so a
  lint-only CI job passes without native image libraries.

### Fixed

- Packaged Biome/Stylelint configs renamed to avoid colliding with an app's root
  configuration when the gem sits under `vendor/bundle`.

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