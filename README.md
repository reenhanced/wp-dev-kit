# wp-dev-kit

`wp-dev-kit` is a WordPress starter template powered by [`@wordpress/env`](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/) (`wp-env`). It keeps the repository free of secrets, makes new site builds trivial, and stays flexible for custom Docker overrides and future automation.

## Using this template

This repository is published as a GitHub template. To create a fresh project based on it:

1. Click **Use this template** on the repository page and choose **Create a new repository**.
2. Name your new repository, decide whether it should be public or private, and confirm the creation.
3. Clone the newly created repository to your machine.
4. Run `npm install` followed by `./setup.sh` to bootstrap WordPress with your preferred settings.

Prefer the command line? The GitHub CLI can generate a repository directly:

```bash
gh repo create my-new-site --template reenhanced/wp-dev-kit
cd my-new-site
npm install
./setup.sh
```

Each derived repository remains independent, so any customisations or secrets stay within your project rather than the template.

## Script overview

| Script | When to use it | What it does |
| --- | --- | --- |
| `setup.sh` | First run after cloning your generated project | Prompts for site URL, ports, admin credentials, debugging, and multisite; writes `.wp-env.override.json`, `config/wp-config-extra.php`, a starter `.wp-env/docker-compose.override.yml`, and installs WordPress via `wp-env`. |
| `build.sh` | Non-interactive restarts or CI-style spins | Starts `wp-env`, waits for WordPress to come online, and installs any plugin ZIPs found in `plugins/`. Uses the configuration already captured by `setup.sh`/wp-env defaults. |
| `reset.sh` | Full local reset | Invokes `wp-env destroy --hard`, recreates `public_html/wp-content`, and leaves `.keep` placeholders so a fresh `setup.sh` run can rebuild the site. |
| `install_plugins.sh` | Reinstall bundled plugin ZIPs | Uses `npx wp-env run cli` to install and activate ZIPs located in `plugins/`. |

Run `setup.sh` once per clone to generate local overrides. After that, use `npm run start` whenever you need to bring the environment up quickly without prompts. Reach for `reset.sh` if you want to wipe data and start again, then rerun `setup.sh` to reapply your preferences.

## Prerequisites

- Node.js 18+ (for `npx` and local `@wordpress/env`)
- Docker Desktop / Docker Engine

## Getting started

```bash
npm install
npm run start
```

`npm run start` (or `./build.sh`) does the following:
- launches the wp-env containers on port `8067`
- waits for WordPress to finish installing
- automatically installs any plugin ZIPs located in `plugins/`

When the command finishes, log in at `http://localhost:8067/wp-admin/` using the default credentials `admin` / `password`. wp-env manages these defaults so they remain safe to store in version control.

## Useful scripts

| Command | Description |
| --- | --- |
| `npm run start` | Start the environment (alias for `wp-env start`). |
| `npm run stop` | Stop the containers (`wp-env stop`). |
| `npm run destroy` | Remove containers and volumes (`wp-env destroy --force`). |
| `npm run destroy:hard` | Full reset including generated databases (`wp-env destroy --hard`). |
| `npm run cli -- <cmd>` | Run arbitrary WP-CLI commands. Example: `npm run cli -- wp plugin list`. |
| `npm run install-plugins` | Re-run ZIP based plugin installs from the `plugins/` directory. |
| `./reset.sh` | Calls `wp-env destroy --hard` and cleans the local content folders. |

## Project layout

```
.
├── .wp-env.json              # wp-env configuration (no secrets)
├── build.sh                  # Wrapper around wp-env start + plugin bootstrap
├── config/
│   └── wp-config-extra.sample.php  # Copy to wp-config-extra.php for custom constants
├── plugins/                  # Drop plugin ZIP archives here; stays out of git
├── public_html/wp-content/   # Custom themes, mu-plugins, uploads, etc.
└── README.md
```

- `public_html/wp-content` maps into the container so you can develop custom code in-place.
- `plugins/` mounts to `/var/www/html/wp-content/wp-dev-kit-packages/` inside the container. Any ZIP placed here is available for `wp plugin install` commands.
- Everything under `db/`, `plugins/`, and `public_html/` stays out of version control except for `.keep` placeholders, ensuring secrets and generated content remain local.

## Overriding wp-env settings

- Copy `config/wp-config-extra.sample.php` to `config/wp-config-extra.php` and reference it from `.wp-env.override.json` when custom constants (`WP_HOME`, multisite flags, and more) are required.
- Add Docker labels or other compose tweaks by running `npm run start` once so `.wp-env/docker-compose.yml` exists, then create `.wp-env/docker-compose.override.yml` with your local additions. wp-env respects the override file on subsequent starts.

Example override snippet for labels:

```yaml
# .wp-env/docker-compose.override.yml
services:
  wordpress:
    labels:
      traefik.enable: "true"
      traefik.http.routers.wp-dev-kit.rule: Host(`example.local`)
```

Override files live inside `.wp-env/` (which is gitignored), so machine-specific labels or secrets stay out of the template.

## Running custom WP-CLI commands

Use `npm run cli -- <command>` or `npx wp-env run cli <command>`. For example:

```bash
npm run cli -- wp option update blogname "Local Dev"
```

This command executes inside the WordPress container with access to the mapped content and plugin ZIPs.

## Resetting the environment

If you need a clean slate:

```bash
npm run destroy:hard
./reset.sh
npm run start
```

This sequence removes containers, clears generated content, and boots a fresh site.
