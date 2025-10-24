# wp-dev-kit (wp-env edition)

This template now relies on [`@wordpress/env`](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/) (`wp-env`) instead of a bespoke Docker Compose stack. It keeps the repo free of secrets, makes it quick to spin up fresh WordPress installs, and still leaves room for local Docker overrides when you need custom labels or routing metadata.

## Prerequisites

- Node.js 18+ (for `npx` and local `@wordpress/env`)
- Docker Desktop / Docker Engine

## Getting started

```bash
npm install
npm run start
```

`npm run start` (or `./build.sh`) will:
- launch the wp-env containers on port `8067`
- wait for WordPress to finish installing
- automatically install any plugin ZIPs dropped in `plugins/`

When the command finishes you can log in at `http://localhost:8067/wp-admin/` using the default credentials `admin` / `password`. These defaults come from wp-env and are safe to keep in version control.

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

- `public_html/wp-content` is mapped into the container so you can develop custom code in-place.
- `plugins/` is mounted at `/var/www/html/wp-content/wp-dev-kit-packages/` inside the container. Any ZIP you place here is available for `wp plugin install` commands.
- Everything under `db/`, `plugins/`, and `public_html/` is gitignored except for `.keep` placeholders, keeping secrets and generated content out of the repository.

## Overriding wp-env settings

- Copy `config/wp-config-extra.sample.php` to `config/wp-config-extra.php` and reference it from a `.wp-env.override.json` file if you need custom constants (`WP_HOME`, multisite flags, etc.).
- To add Docker labels (or other compose tweaks), run `npm run start` once so `.wp-env/docker-compose.yml` is generated. Then create `.wp-env/docker-compose.override.yml` next to it with your additional settings. wp-env will respect the override file on subsequent starts.

Example override snippet for labels:

```yaml
# .wp-env/docker-compose.override.yml
services:
  wordpress:
    labels:
      traefik.enable: "true"
      traefik.http.routers.wp-dev-kit.rule: Host(`example.local`)
```

Because override files live inside `.wp-env/` (which is gitignored), you can safely store machine-specific labels or secrets there without affecting the template.

## Running custom WP-CLI commands

Use `npm run cli -- <command>` or `npx wp-env run cli <command>`. For example:

```bash
npm run cli -- wp option update blogname "Local Dev"
```

This runs inside the WordPress container with access to the mapped content and plugin ZIPs.

## Resetting the environment

If you need a clean slate:

```bash
npm run destroy:hard
./reset.sh
npm run start
```

This sequence removes containers, clears generated content, and boots a fresh site.
