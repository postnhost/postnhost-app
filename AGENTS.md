# AGENTS.md

This file is the canonical guidance for changes to the self-hosted PostnHost Rails application.

## Repository Boundary

The host application owns deployment, runtime infrastructure, engine integration, host configuration, and host-level smoke tests. It consumes the PostnHost engine; reusable CMS behavior belongs in the engine repository.

The application consumes the released PostnHost gem. Host guidance and code must not depend on an engine checkout, engine-internal documentation, or parent-relative paths.

## Project Overview

The host is a Rails 8.1 application that mounts the PostnHost engine at `/` and provides a production-ready single-node deployment.

- Ruby and Node versions are pinned in `mise.toml`.
- SQLite stores application, cache, cable, and queue data in one database.
- Solid Cache, Solid Cable, and Solid Queue provide runtime infrastructure.
- Litestream replicates the SQLite database to S3-compatible storage.
- Mission Control Jobs is mounted at `/jobs` behind the CMS session.
- Propshaft serves host and packaged engine assets.
- Tailwind compiles the engine and host view sources into one stylesheet scoped to PostnHost layouts.
- Docker supports standalone development and production builds.
- Fly.io configuration provides the single-node deployment shape and persistent `/data` volume.
- RSpec covers integration and system smoke behavior.

## Working Rules

### Read Before Editing

- Read every relevant file in full before changing it.
- Search for existing implementations, references, tests, and generated counterparts before adding code.
- Inspect `git status` first and preserve unrelated user changes.
- Consider multiple approaches and prefer the smallest cohesive change.
- Perform a final self-review and remove anything that does not serve the requested behavior.

### File Hygiene

- New files must use mode `644` unless they are intentionally executable.
- Keep machine-local credentials, databases, uploads, logs, coverage, and build caches untracked.
- Never commit `config/credentials.yml.enc`, `config/master.key`, raw secrets, or local deployment values.
- Do not add host files that only make sense while the engine is nested in this repository.

### Quality Checks

- Run `bundle exec rubocop -a` before finishing Ruby changes.
- Run focused specs while iterating, followed by the relevant host smoke suite.
- Rebuild host assets when Tailwind inputs or build configuration changes.
- Verify Docker changes against the production build contract.

## Architecture

### Host Versus Engine Responsibilities

Host code should be limited to:

- mounting and configuring the engine;
- runtime services such as database, caching, queues, backups, and monitoring;
- deployment and container configuration;
- host-owned branding, favicons, robots.txt, and optional copied-view overrides;
- integration and deployment smoke tests.

Do not copy engine models, controllers, services, generators, locale internals, or reusable UI behavior into the host. Changes that should benefit every installation belong in the engine.

### Rails Conventions

- Keep controllers thin and use strong parameters.
- Persistent domain rules belong in models.
- Procedural workflows and external integrations belong in focused service objects.
- Concerns are for behavior intentionally shared by multiple classes, not one-off workflow buckets.
- Prefer explicit loaders and redirects after state changes.
- Do not wrap Active Record relations with `Array(...)`; handle `nil` explicitly and preserve relation behavior.

### Authentication and Internal Tools

- CMS authentication is session-based and provided by the engine.
- Protect host-mounted internal tools with the same authenticated CMS session.
- Do not add a second authentication system or public monitoring endpoints.

## Frontend and Views

### Hotwire First

- Prefer server-rendered HTML, Turbo Drive, Turbo Frames, and Turbo Streams.
- Use Rails forms for data submission. Try `form_with`, `button_to`, or a Turbo response before adding JavaScript requests.
- Use Stimulus only for interaction that cannot be expressed cleanly on the server.
- Links to mutable actions must use `data: { turbo_prefetch: false }`.

### ERB

- Never assign variables in ERB templates.
- Keep templates declarative and move data preparation into helpers, presenters, controllers, or models.
- Use Rails helpers and partials instead of raw form markup.
- Keep public presentation classes in templates so copied views remain easy to restyle.
- Use semantic HTML and ensure clickable controls include `cursor-pointer`.

### Tailwind and Assets

- Use Tailwind utility classes only; do not add custom CSS files or inline styles.
- The engine ships `postnhost/application.css` and `postnhost/application.js` as packaged assets.
- Host Tailwind customization uses:
  - `app/assets/stylesheets/postnhost/host.tailwind.css`
  - `app/assets/builds/postnhost/application.css`
- Use ordinary Tailwind classes in copied PostnHost views; the build scopes the resulting selectors automatically.
- Keep `data-postnhost` on copied PostnHost layout roots.
- Run `rails g postnhost:tailwindcss:install` when enabling host-side compilation in another application.
- Use Heroicons outline SVGs with `stroke-width="1.5"` and the engine `icon` helper.

## Runtime Infrastructure

### Database

- Use the single SQLite database configured in `config/database.yml`.
- Keep Solid Cache, Solid Cable, and Solid Queue tables in the main schema.
- Engine migrations copied into `db/migrate/` are installed application migrations and must remain available for new deployments.
- Do not introduce multiple-database configuration without an explicit architecture decision.

### Background Jobs

- Use Active Job with Solid Queue.
- Configure recurring work in `config/recurring.yml`.
- Use `bin/jobs` for a separate worker or `SOLID_QUEUE_IN_PUMA=true` for the single-process deployment.

### Caching

- Prefer conditional HTTP caching and fragment caching.
- Use timestamps and `touch: true` for invalidation.
- Do not manually expire record or collection caches when timestamp-based invalidation can express the dependency.
- Never place user-specific content in shared public fragments.

### Uploads and Backups

- CarrierWave uses local test/development storage and S3-compatible production storage.
- Litestream configuration belongs to this host under `config/litestream.yml` and `config/initializers/litestream.rb`; it is not engine configuration.
- The production SQLite path must live on the persistent `/data` volume.
- Credentials come from local encrypted credentials or the environment and must not be committed.

## Internationalization and Host Overrides

- Configure available locales, the default locale, and English fallback in `config/application.rb`.
- Keep host-specific locale overrides in the host application; reusable default translations belong in the engine.
- Site-level SEO settings are configured through PostnHost settings or `Postnhost.configure`.
- Host-owned public files include favicons, PWA icons, `site.webmanifest`, the static service worker, and `robots.txt`.
- When copying engine views into the host, preserve engine route/helper contracts and compile any new Tailwind classes through the host pipeline.

## Testing

### Commands

```bash
# All host specs
bundle exec rspec

# Request-level engine mount smoke test
bundle exec rspec spec/requests/engine_mount_smoke_spec.rb

# Browser smoke tests
bundle exec rspec spec/system

# Visible browser
SYSTEM_TESTS_BROWSER=1 bundle exec rspec spec/system
```

### Conventions

- Request specs define their language, authentication, and host setup explicitly in each file.
- Use `have_http_status(:ok)` for successful responses.
- Use strict boolean matchers when exact values matter.
- System specs use Selenium and real UI flows; do not use Rack::Test session APIs or direct model mutation as a substitute for user behavior.
- Stub external HTTP services.
- Host specs should test integration boundaries, not duplicate the engine’s model or service suite.

## Key Host Files

- `Gemfile` — host dependencies and the released engine dependency.
- `config/routes.rb` — engine mount and authenticated operational dashboards.
- `config/database.yml` — single SQLite database configuration.
- `config/queue.yml` and `config/recurring.yml` — Solid Queue runtime behavior.
- `config/litestream.yml` and `config/initializers/litestream.rb` — replication.
- `config/initializers/postnhost.rb` — engine configuration.
- `Dockerfile`, `docker-compose.yml`, and `fly.toml` — development and production container workflows.
- `spec/requests/` and `spec/system/` — host integration smoke coverage.

Prefer server-side Rails solutions and keep the host a small, legible integration layer around the engine.
