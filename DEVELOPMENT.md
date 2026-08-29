# Development

## Table of Contents

- [Setup](#setup)
- [Docker development](#docker-development)
- [Required Credentials](#required-credentials)
  - [AWS S3 / Tigris](#aws-s3--tigris)
  - [Litestream (SQLite Backups to S3-Compatible Storage)](#litestream-sqlite-backups-to-s3-compatible-storage)
  - [Mission Control Jobs](#mission-control-jobs)
  - [OpenAI](#openai)
- [Backup & Restore](#backup--restore)
  - [Litestream Backup Operations](#litestream-backup-operations)
  - [Litestream Restore Operations](#litestream-restore-operations)
- [Testing](#testing)
- [Architecture](#architecture)
  - [Database](#database)
  - [Caching](#caching)
  - [Background Jobs](#background-jobs)
  - [File Uploads](#file-uploads)
  - [Customization](#customization)

## Setup

1. Install and activate [mise](https://mise.jdx.dev/getting-started.html)

2. Install the pinned Ruby and Node.js versions

```sh
mise install
```

3. Install Bundler

```sh
gem install bundler
```

4. Install dependencies

```sh
bundle install
```

5. Enable the Node-provided Corepack shim

```sh
corepack enable
```

This repository pins Yarn through `packageManager`; running `yarn` selects the correct version.

6. Install JS dependencies

```sh
yarn install
```

7. Optionally create encrypted credentials when testing OpenAI, S3-compatible uploads, or Litestream

```sh
EDITOR="vim" bin/rails credentials:edit
```

8. Set up the database

```sh
bin/rails db:prepare
```

9. Seed required reference data

```sh
bin/rails db:seed
```

This creates 9 language records with i18n translations. It does not create CMS users or sample content.

Visit `/onboarding` to create the first CMS administrator. The setup flow can add optional sample categories and articles after the account is created.

Alternatively, run `bin/rails g postnhost:user` to create a CMS user interactively.

10. Run the application

```sh
bin/dev
```

## Docker development

Install Docker Desktop, or another Docker installation with Compose, then run from the repository root:

```sh
docker compose up --build
```

Open http://localhost:3000/onboarding to create the first CMS administrator. Compose prepares the SQLite database and starts Rails, Tailwind, and Solid Queue through `bin/dev`. Source changes are bind-mounted, while the database and `node_modules` use persistent Docker volumes.

Use `docker compose down` to stop the application. Run `docker compose down --volumes` only when you also want to delete its local database and installed JavaScript packages.

## Required Credentials

Credential values under `postnhost:` are defaults. You can override them explicitly in `config/initializers/postnhost.rb` (`Postnhost.configure`), and explicit config values take priority.

### AWS S3 / Tigris

```yaml
postnhost:
  aws_access_key_id: your_aws_access_key_id
  aws_secret_access_key: your_aws_secret_access_key
  aws_bucket_name: your_s3_bucket_name
  aws_region: your_aws_region
```

### Litestream (SQLite Backups to S3-Compatible Storage)

This is **host app** configuration (`config/initializers/litestream.rb`, `config/litestream.yml`), not `Postnhost.configure`. Reuses existing AWS credentials. Works with AWS S3, Tigris, DigitalOcean Spaces, Backblaze B2, etc.

**Required credentials:**
```yaml
postnhost:
  aws_access_key_id: your_access_key_id
  aws_secret_access_key: your_secret_access_key
  aws_bucket_name: your_s3_bucket_name
  aws_endpoint_url_s3: https://fly.storage.tigris.dev # Optional: only for non-AWS S3-compatible services
  aws_region: auto

  # Litestream-specific settings
  litestream_bucket: your_backup_bucket_name
  litestream_endpoint: fly.storage.tigris.dev  # Optional: only for non-AWS S3-compatible services
```

**Examples:**
- **Tigris (Fly.io)**: `litestream_endpoint: fly.storage.tigris.dev`, `aws_region: auto`
- **AWS S3**: `aws_region: us-east-1`, no endpoint needed
- **DigitalOcean Spaces**: `litestream_endpoint: nyc3.digitaloceanspaces.com`, `aws_region: us-east-1`

**Setup via Rails Encrypted Credentials:**
```bash
EDITOR="vim" bin/rails credentials:edit

# Add Litestream settings (reuses existing AWS credentials):
# postnhost:
#   litestream_bucket: postnhost-backups
#   litestream_endpoint: fly.storage.tigris.dev
```

**How it works:**
- Litestream runs inside Puma process (via `plugin :litestream` in `config/puma.rb`)
- On app start, automatically restores database from backup if missing
- Continuously streams changes to S3-compatible storage in real-time
- No manual backup commands needed — it's automatic

**Dashboard:** Access replication monitoring at `/litestream` (requires authenticated CMS session)

**Troubleshooting:**

*Dashboard shows "not running":* This is normal when using the Puma plugin. Verify it's working by:
- Check logs for `"write wal segment"` messages
- Run: `bin/rails runner "puts Litestream::Commands.databases.inspect"`
- Verify snapshots and generations appear in the dashboard

*Multiple generations appear:* This is normal. Each deployment creates a new generation (replication session). Old generations auto-delete after 3 days (configurable in `config/litestream.yml`).

### Mission Control Jobs

Monitoring at `/jobs`. Protected by CMS session authentication — no additional credentials needed.

```yaml
postnhost:
  mission_control:
    http_basic_auth_user:
    http_basic_auth_password:
```

### OpenAI

```yaml
postnhost:
  openai_access_token: your_openai_key
```

## Backup & Restore

### Litestream Backup Operations

**List databases being replicated:**
```bash
bin/rails litestream:databases
```

**List generations for a database:**
```bash
bin/rails litestream:generations -- --database=/rails/storage/production.sqlite3
```

**List snapshots:**
```bash
bin/rails litestream:snapshots -- --database=/rails/storage/production.sqlite3
```

### Litestream Restore Operations

**Restore from latest backup:**
```bash
# 1. Stop the Rails app first
# 2. Rename or delete existing database files
# 3. Restore from latest backup
bin/rails litestream:restore -- --database=/rails/storage/production.sqlite3
```

**Restore to specific point in time:**
```bash
bin/rails litestream:restore -- --database=/rails/storage/production.sqlite3 --timestamp=2025-10-28T12:00:00Z
```

**Restore only if database doesn't exist:**
```bash
bin/rails litestream:restore -- --database=/rails/storage/production.sqlite3 --if-db-not-exists
```

## Testing

System specs use Capybara + Selenium:

- All system specs run with Selenium (no Rack::Test fallback)
- Default: headless Chrome (`:selenium_chrome_headless`)
- Headed mode: set `SYSTEM_TESTS_BROWSER=1`

```bash
# All specs
bundle exec rspec

# System specs only
bundle exec rspec spec/system

# Single file
bundle exec rspec spec/system/authentication_spec.rb

# Headed mode
SYSTEM_TESTS_BROWSER=1 bundle exec rspec spec/system
```

## Architecture

### Database

**SQLite3** — Single database for all data.

One database file (`storage/production.sqlite3`) contains:
- Application data (articles, users, categories, etc.)
- Cache entries (Solid Cache)
- WebSocket messages (Solid Cable)
- Job queue (SolidQueue)

**Deployment notes:**
- SQLite3 writes data to the local filesystem, requiring **persistent disks**
- **Docker**: Mount the database location as a persisted volume
- Without persistence, you'll lose all data on restart/redeploy

The included Fly.io configuration stores the production database on the persistent `/data` volume. Configure the application name, region, credentials, and volume before deployment.

### Caching

**Solid Cache** — Database-backed cache store (stored in main SQLite database)

- Size: 1GB in production, 256MB in development
- Retention: 90 days
- Expiry: Background jobs via SolidQueue (non-blocking)
- Toggle in development: `rails dev:cache`

### Background Jobs

**SolidQueue** — Database-backed job queue (stored in main SQLite database)

- Configuration: [config/queue.yml](config/queue.yml) and [config/recurring.yml](config/recurring.yml)
- Monitoring: Mission Control Jobs at `/jobs`
- Process: Start with `bin/jobs` (included in `bin/dev`)

### File Uploads

All image uploads use CarrierWave with S3/Tigris storage:
- User avatars (`AvatarUploader`)
- Article cover images (`CoverImageUploader`)
- Inline article editor images (`InlineArticleImageUploader`)
- Settings assets (`SettingAssetUploader`) for public logo and default OG image

### Customization

**Favicon & PWA Icons** (in `public/`):
- `favicon.ico`, `icon.svg`, `apple-touch-icon.png`
- `web-app-manifest-192x192.png`, `web-app-manifest-512x512.png`
- `site.webmanifest`

**Brand Assets** (in `app/assets/images/`):
- `og-image.webp` — Default OG image
- `logo.webp` — Logo

**Settings-driven brand customization** (dashboard → Settings):
- Canonical public origin and article pagination are editable under Site (`settings.site_url`, `settings.public_page_size`); blank values use `config.site_url` and `config.public_page_size`
- Public header logo is editable (`settings.site_logo`)
- Default OG image is editable (`settings.og_image`)
- Dashboard header logo and footer "Powered by" logo always use `logo.webp`

**Sitemap & Robots**:
- `sitemap.xml` is generated automatically from live public routes and templates
- Set the canonical production origin under Dashboard → Settings → Site or with `config.site_url`; the dashboard value takes priority
- Update `public/robots.txt` so the `Sitemap:` line matches the real sitemap URL, including any mount path such as `/blog/sitemap.xml`

Reusable layouts, SEO helpers, static pages, sitemap behavior, and locale internals belong to the engine. See the [engine README](https://github.com/postnhost/postnhost/blob/main/README.md) for generator and customization guidance.
