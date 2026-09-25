# Rails Quality Assurance

Opinionated quality assurance kit for Ruby on Rails applications.

`rails-quality-assurance` provides an out-of-the-box, comprehensive quality control setup designed to work with zero-configuration defaults. It integrates the standard quality control suite used across Develoz Rails applications.

## What's Included

### 1. Style & Linting

- **RuboCop**: Pre-configured `rubocop.yml` targeting Ruby 4.0 with all standard plugins loaded (`rubocop-rails`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-performance`, `rubocop-capybara`, `rubocop-factory_bot`, `rubocop-rubycw`, `rubocop-migration`).
- **Reek**: Code smell detection with sensible Rails defaults (`config/reek.yml`).
- **Flay**: Structural code duplication analysis.
- **Biome**: Pre-configured `config/biome-default.json` for fast JavaScript/TypeScript/JSON linting and formatting.
- **Stylelint**: Pre-configured `config/stylelint-default.json` with Tailwind CSS support.

### 2. Security

- **Brakeman**: Static analysis security vulnerability scanner.
- **Bundler Audit**: Vulnerability scanner for gem dependencies.
- **Importmap Audit**: Vulnerability scanner for pinned importmap packages. Runs
  only when the app has `config/importmap.rb`, using the app `bin/importmap`
  binstub when present and a dependency-light `importmap-rails` invocation
  otherwise.

### 3. Testing & Coverage

- **RSpec**: Shared helpers and configuration.
- **Playwright + Capybara**: Remote Chromium headless driver support with auto port assignment for parallel workers and HTML error state dumps on failure (`require 'rails_quality_assurance/playwright'`).
- **Parallel Tests**: `rake spec:parallel` task that matches the CPU count by
  default and isolates system specs into a dedicated worker.
- **SimpleCov**: 100% line and branch coverage threshold enforcement, LCOV reporting, and parallel process reporting (`require 'rails_quality_assurance/simplecov'`).

### 4. Continuous Integration Harness

- **`RailsQualityAssurance::CI`**: Built-in pipeline runner modeled after Rails CI harnesses.
- **CLI / Executable**: Run with `bundle exec rails-qa` or define your pipeline in `config/ci.rb`.

---

## Installation

Add to your `Gemfile`:

```ruby
group :development, :test do
  gem 'rails-quality-assurance', require: false
end
```

Then run:

```bash
bundle install
```

---

## Zero-Config Usage

### 1. RuboCop

In your `.rubocop.yml`:

```yaml
inherit_gem:
  rails-quality-assurance: rubocop.yml

# Only your application-specific overrides are needed here
```

### 2. Single Require for Testing & Coverage (spec/spec_helper.rb)

Add a single line at the very top of `spec/spec_helper.rb`:

```ruby
require 'rails_quality_assurance/all'
```

That single require sets up:

1. **SimpleCov**: Starts immediately before application code loads, enforcing 100% line & branch coverage thresholds, parallel process aggregation, and LCOV output.
2. **RSpec**: Configures mock verification of partial doubles, expectations, and metadata inheritance.
3. **Playwright + Capybara System Tests**: Registers the `:remote_playwright` headless driver, defaults system specs to `:rack_test`, escalates to Playwright for `js: true`, dynamically allocates ports for `parallel_tests` workers, and dumps HTML failure snapshots into `tmp/capybara`.

*(If you prefer to load them individually, `require 'rails_quality_assurance/simplecov'` and `require 'rails_quality_assurance/playwright'` remain available.)*

#### Configuring SimpleCov (`.simplecov`)

`rails_quality_assurance` requires SimpleCov and then calls
`SimpleCov.start 'rails'`. SimpleCov automatically loads a `.simplecov` file
from the project root while `require 'simplecov'` runs, so anything configured
there is applied **before** coverage starts:

```ruby
# .simplecov
SimpleCov.configure do
  cover_views            # measure ActionView templates (SimpleCov 1.2+)
  track_tests            # record which test covered each line
  group 'Components', 'app/components'
  skip 'app/views/pwa'
end
```

Use SimpleCov's native DSL for any option the gem does not wrap — `cover`,
`track_tests`, `group`, `minimum_coverage`, `maximum_coverage_drop`,
`baseline_file`, and so on. Because SimpleCov reads the file itself, a new
SimpleCov option is available to a project without a new
`rails-quality-assurance` release.

`.simplecov` is loaded with plain `load`, so bare method calls resolve against
`main`. Wrap them in `SimpleCov.configure` (which evaluates the block in
SimpleCov's context, as above) or prefix each call with `SimpleCov.`. Keep it
to configuration only: `SimpleCov.start` belongs in `spec/spec_helper.rb`, and
SimpleCov 1.3 deprecates calling it from `.simplecov`.

### 3. Rails Test Setup (spec/rails_helper.rb)

After the Rails environment boots, one require applies the shared Rails test configuration:

```ruby
require 'spec_helper'
require_relative '../config/environment'
require 'rails_quality_assurance/rails_helper'
```

That sets up, without any boilerplate in the app:

- `ActiveRecord::Migration.maintain_test_schema!` (aborts on pending migrations)
- `use_transactional_fixtures`, fixture paths, and `infer_spec_type_from_file_location!`
- `filter_rails_from_backtrace!`
- FactoryBot syntax methods and ActiveSupport time helpers
- WebMock network lockdown with a loopback + Playwright allowlist
- `I18n.locale = :en` before each example; `Faker::UniqueGenerator` reset after each
- CSRF forgery protection toggled on around system specs

Application-specific setup (auth helpers, custom matchers, gateway stubs) stays in the app's own `rails_helper.rb`.

### 4. Continuous Integration: `bin/ci`

Run the generator to install `bin/ci` and `config/ci.rb`:

```bash
bin/rails generate rails_quality_assurance:ci
```

This generates `bin/ci` (executable) and `config/ci.rb` following Develoz standards (matching Pitwall and Develoz B2B).

Run CI anytime on the host:

```bash
bin/ci
```
Or in Docker-based setups:
```bash
bin/run bin/ci
```

### 5. Rake Tasks (Optional)

The gem also provides tasks if you prefer `rake`:

```bash
bin/rails qa:lint                # Runs RuboCop, Reek, Flay, Brakeman, bundler-audit, importmap-audit
bin/rails qa:audit               # Runs bundler-audit
bin/rails qa:audit:importmap     # Runs the importmap audit when config/importmap.rb exists
bin/rails qa:frontend            # Runs Biome and Stylelint
bin/rails spec:parallel          # Runs RSpec in parallel with system specs isolated
```

`spec:parallel` reads these environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `PARALLEL_TEST_PROCESSORS` | Number of CPUs | Total worker count |
| `ISOLATE_SPEC_TASKS` | `1` (or `0` on a single CPU) | Workers reserved for `spec/system/` |
| `PARALLEL_SPEC_OPTIONS` | - | Extra options passed to RSpec |

Isolation workers are carved out of the total. On a 6-CPU machine the default
run uses 6 workers: 5 for the regular suite and 1 isolated worker for
`spec/system/`. Set `ISOLATE_SPEC_TASKS=0` to skip isolation entirely; system
specs then run as ordinary specs.

---

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

Released under the [MIT License](https://opensource.org/license/mit/).
