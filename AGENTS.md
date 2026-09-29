# AGENTS.md

`rails-quality-assurance` is a **gem**, not a Rails app. It ships an opinionated QA
toolchain (lint config, Rake tasks, test helpers, CI harness) to downstream Develoz
Rails apps. There is no database and no `config/application.rb`; the `qa:*` and
`spec:parallel` tasks only exist after a host app loads the Railtie.

## Setup

- The gemspec requires Ruby >= 4.0, but no `.ruby-version`/mise/asdf pin is committed.
  If `ruby -v` reports an older interpreter, activate the project's version manager
  before running `bundle`, or you will silently test against the wrong Ruby.
- `Gemfile.lock` is gitignored (untracked); run `bundle install` after pulling.
- `bundle exec rake` defaults to the `:spec` task.

## Commands

- `bin/ci` — canonical gate, in order: RuboCop → Reek → RSpec → `gem build`. Run it before pushing.
- `bundle exec rspec` — full suite. Single file/test: `bundle exec rspec spec/rails_quality_assurance/run_lock_spec.rb:35`.
- `bundle exec rubocop`
- `bundle exec reek --config .reek.yml lib` — Reek is scoped to `lib` in this repo only.

## Two config files, different audiences

Do not confuse shipped artifacts with the gem's own config:

- `rubocop.yml` (root) and `config/reek.yml`, `config/biome-default.json`,
  `config/stylelint-default.json` are **shipped** to consuming apps. Editing them
  changes every consumer; apps inherit `rubocop.yml` via `inherit_gem`.
- `.rubocop.yml` (dot) and `.reek.yml` are this gem's **own** config, layered on the shipped files.
- The gemspec packages only `Dir['{config,lib}/**/*']` plus `rubocop.yml`, `CHANGELOG.md`,
  `LICENSE.txt`, `README.md`. New shipped files must live under `config/` or `lib/`,
  or be added to `spec.files`.

## Architecture

- `lib/rails_quality_assurance.rb` is the public API (config paths, importmap/npm audit
  command resolution, `spec_lock_path`) and loads the Railtie that mounts
  `lib/tasks/quality_assurance.rake`.
- Features come in pairs: `foo.rb` requires `foo/helper.rb` and calls `configure!`;
  the logic lives in `foo/helper.rb` (`simplecov`, `rspec`, `playwright`,
  `rails_helper`/`rails/helper`).
- `all.rb` is the single require for a downstream `spec/spec_helper.rb`;
  `rails_helper.rb` is required after the Rails env boots.
- `ci.rb` is the pipeline class; `ci_runner.rb` aliases
  `ActiveSupport::ContinuousIntegration.run` to it for a generated app `bin/ci`.
- Two `bin/ci` exist: this repo's hand-written one, and the one emitted by the
  `rails_quality_assurance:ci` generator for host apps.
- The `qa:*` tasks deliberately do **not** boot Rails (`Rails/RakeEnvironment` is
  disabled). Keep it that way so lint-only jobs run without native libraries.

## Tests

- `spec/spec_helper.rb` intentionally does **not** require `rails_quality_assurance/all`,
  so the gem's own suite is plain RSpec without SimpleCov or Playwright. Don't add it.
- It requires `rake` and `rubocop` because specs load the rake tasks and parse `rubocop.yml`.
- Shell commands are stubbed (`sh`/`system`); keep the suite fast and network-free.

## Releases

- Bump `lib/rails_quality_assurance/version.rb` and add a Keep-a-Changelog entry.
- Push a `v*` tag: GitHub Actions runs `bin/ci`, then publishes via RubyGems trusted publishing (OIDC).
- CI runs `bin/ci` on pushes/PRs to `main` and `develop`.

## Style

- Ruby 4.0, frozen string literals, single quotes, `Style/HashSyntax` shorthand (`value:`),
  120-char lines. RuboCop caps: MethodLength 30, AbcSize 35, ClassLength 150.
- Follow the `develoz-rails-style` skill for Ruby/Rails changes.
