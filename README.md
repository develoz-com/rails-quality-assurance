# RuboCop Develoz

Shared RuboCop configuration for all [Develoz](https://github.com/develoz-com) projects — Rails apps and Ruby gems. Shaped like [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase): a gem that ships a `rubocop.yml` you inherit.

## What's inside

- Plugins: `rubocop-performance`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-capybara`, `rubocop-factory_bot`, `rubocop-rubycw`, `rubocop-migration`, `rubocop-rails`
- Shared style decisions: 120-column lines, `Style/HashSyntax` shorthand `always`, no `Style/Documentation`, relaxed metrics, generous RSpec limits
- `inherit_mode.merge: [Exclude]` — your project's `Exclude` entries add to ours, they don't replace them

Application-specific relaxations (single-file metric excludes, unusual `Max` overrides) stay in each project's own `.rubocop.yml`.

## Installation

Add to your Gemfile:

```ruby
gem "rubocop-develoz", require: false, group: [ :development, :test ]
```

Then run `bundle`.

Point your project's `.rubocop.yml` at the shared configuration:

```yml
inherit_gem:
  rubocop-develoz: rubocop.yml

# Your own specialized rules go here
```

Now run `bundle exec rubocop` to check compliance and `bundle exec rubocop -a` to auto-fix violations.

The gem depends on all the RuboCop plugins it configures, so you don't need to list them separately.

## Usage in gems

For gems without Rails, override the Rails-oriented bits locally:

```yml
inherit_gem:
  rubocop-develoz: rubocop.yml

plugins: [] # inherit what applies; disable Rails cops in your own file as needed
```

## What not to expect

These styles are the Develoz house style, not a proposal. If a rule doesn't fit your project, specialize it in your own `.rubocop.yml`.

## Development

```bash
bundle install
bundle exec rspec
gem build rubocop-develoz.gemspec
```

## License

Released under the [MIT License](https://opensource.org/license/mit/).