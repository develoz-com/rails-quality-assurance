# Rails Quality Assurance

Opinionated quality assurance kit for Ruby on Rails applications.

`rails-quality-assurance` provides an out-of-the-box, comprehensive quality control setup designed to work with zero-configuration defaults. It integrates the standard quality control suite used across Develoz Rails applications.

## What's Included

### 1. Style & Linting

- **RuboCop**: Pre-configured `rubocop.yml` targeting Ruby 4.0 with all standard plugins loaded (`rubocop-rails`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-performance`, `rubocop-capybara`, `rubocop-factory_bot`, `rubocop-rubycw`, `rubocop-migration`).
- **Reek**: Code smell detection with sensible Rails defaults (`config/reek.yml`).
- **Flay**: Structural code duplication analysis.
- **Biome**: Pre-configured `config/biome.json` for fast JavaScript/TypeScript/JSON linting and formatting.
- **Stylelint**: Pre-configured `config/.stylelintrc.json` with Tailwind CSS support.

### 2. Security

- **Brakeman**: Static analysis security vulnerability scanner.
- **Bundler Audit**: Vulnerability scanner for gem dependencies.

### 3. Testing & Coverage

- **RSpec**: Shared helpers and configuration.
- **Playwright + Capybara**: Remote Chromium headless driver support with auto port assignment for parallel workers and HTML error state dumps on failure (`require 'rails_quality_assurance/playwright'`).
- **Parallel Tests**: `rake spec:parallel` task with automated system test isolation.
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

### 3. Continuous Integration: `bin/ci`

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

### 4. Rake Tasks (Optional)

The gem also provides tasks if you prefer `rake`:

```bash
bin/rails qa:lint          # Runs RuboCop, Reek, Flay, Brakeman, bundler-audit
bin/rails qa:frontend      # Runs Biome and Stylelint
bin/rails spec:parallel    # Runs RSpec in parallel with system specs isolated
```

---

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

Released under the [MIT License](https://opensource.org/license/mit/).
