# 🚀 Laravel Shared Hosting Deployer (GitHub Action)

<p align="left">
  <a href="https://github.com/channlabs/laravel-deploy-shared-hosting"><img src="https://img.shields.io/github/v/release/channlabs/laravel-deploy-shared-hosting?color=7c3aed&style=for-the-badge&logo=github" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-3b82f6.svg?style=for-the-badge" alt="License"></a>
  <a href="https://laravel.com"><img src="https://img.shields.io/badge/Laravel-10%20%7C%2011%20%7C%2012%20%7C%2013-ff2d20.svg?style=for-the-badge&logo=laravel" alt="Laravel"></a>
</p>

A production-grade **Composite GitHub Action** engineered by **Chann Labs Creative Studio** for seamlessly deploying Laravel applications to traditional **Shared Hosting (cPanel / Hostinger / DirectAdmin)** environments via passive FTP.

---

## ⚡ Why Use This Action?

> [!IMPORTANT]
> Traditional FTP deployments often **fail, time out, or get blocked by web hosting firewalls** due to transferring tens of thousands of tiny vendor files individually.

This Action solves that bottleneck using the **ZIP-Express Engine**:

1. **Automated Compilation:** Runs Composer dependencies (`--no-dev --optimize-autoloader`), Node.js, and Vite production asset bundling (`pnpm run build`) directly on GitHub Actions infrastructure.
2. **Lightning Fast Transfer:** Compresses the complete application into a **single `.zip` archive**, transferring it via **Passive LFTP (Port 21)** in seconds.
3. **Remote Extraction & Auto-Config:** Deploys a secure PHP encapsulation script (`deploy.php` / `unzip.php`) to extract files on the server, auto-initialize `.env` from `.env.example`, create SQLite database files if needed, trigger database migrations (`php artisan migrate --force`), optimize performance caches (`php artisan optimize`), and automatically self-clean after completion.

---

## 🏗️ Architecture Flow

```
┌──────────────────────────┐      ┌──────────────────────────┐      ┌──────────────────────────┐
│   GitHub Infrastructure  │      │      LFTP Transfer       │      │    Remote Host Server    │
├──────────────────────────┤      ├──────────────────────────┤      ├──────────────────────────┤
│ 1. composer install      │ ───► │ Uploads deploy.zip       │ ───► │ Executes deploy.php      │
│ 2. pnpm build (Vite)     │      │ Uploads deploy.php       │      │  ├── Unzips deploy.zip   │
│ 3. Package deploy.zip    │      │ Uploads unzip.php        │      │  ├── Auto-creates .env   │
└──────────────────────────┘      └──────────────────────────┘      │  ├── Runs migrations     │
                                                                    │  ├── Runs optimize       │
                                                                    │  └── Self-cleans files   │
                                                                    └──────────────────────────┘
```

---

## 🛠️ Prerequisites

> [!TIP]
> Before integrating this Action, ensure you have configured the following on your web hosting account:

1. **Dedicated FTP Account:** Create an FTP account with its root directory set to your target domain/subdomain folder.
2. **Web Server Domain Mapping:** Ensure your domain or subdomain is active and pointing to the target folder on your hosting server.

---

## 🚀 Quick Start

### 1. Add Repository Secrets

Navigate to your GitHub Repository > **Settings** > **Secrets and variables** > **Actions** > **New repository secret**, and add:

- `FTP_SERVER` / `FTP_SERVER_STAGING` : FTP Hostname or IP address (e.g., `ftp.domain.com`).
- `FTP_USERNAME` / `FTP_USERNAME_STAGING` : FTP Username.
- `FTP_PASSWORD` / `FTP_PASSWORD_STAGING` : FTP Password.
- `DEPLOY_TOKEN` : Secure random token for authenticating deployment requests.

### 2. Create Workflow File

Create a workflow file in your Laravel project at `.github/workflows/deploy.yml`:

```yaml
name: 🚀 Deploy Application to Shared Hosting

on:
  push:
    branches:
      - main # Triggers production deployment on push to main
      - staging # Triggers staging deployment on push to staging

jobs:
  web-deploy:
    name: 🚚 Execute Automated Deployment
    runs-on: ubuntu-latest

    steps:
      - name: 🚚 Checkout Code
        uses: actions/checkout@v4

      - name: 🚀 Run Chann Labs Deployer
        uses: channlabs/laravel-deploy-shared-hosting@v1
        with:
          ftp-server: ${{ github.ref_name == 'main' && secrets.FTP_SERVER || secrets.FTP_SERVER_STAGING }}
          ftp-username: ${{ github.ref_name == 'main' && secrets.FTP_USERNAME || secrets.FTP_USERNAME_STAGING }}
          ftp-password: ${{ github.ref_name == 'main' && secrets.FTP_PASSWORD || secrets.FTP_PASSWORD_STAGING }}
          deploy-url: ${{ github.ref_name == 'main' && 'domain.com' || 'staging.domain.com' }}
          deploy-token: ${{ secrets.DEPLOY_TOKEN }}
          php-version: "8.4" # Optional, default '8.4'
          node-version: "24" # Optional, default '24'
          pnpm-version: "10" # Optional, default '10'
          run-migrations: "true"
          optimize: "true"
          health-check: "true"
```

---

## ⚙️ Configuration Inputs

| Input            | Description                                        | Required | Default |
| :--------------- | :------------------------------------------------- | :------: | :-----: |
| `ftp-server`     | FTP Server Hostname or IP                          | **Yes**  |    -    |
| `ftp-username`   | FTP Account Username                               | **Yes**  |    -    |
| `ftp-password`   | FTP Account Password                               | **Yes**  |    -    |
| `deploy-url`     | Public Deployment URL (Domain / Subdomain)         | **Yes**  |    -    |
| `deploy-token`   | Secure Deployment Token                            | **Yes**  |    -    |
| `ftp-directory`  | Remote Deployment FTP Path                         |    No    |   `/`   |
| `php-version`    | PHP Version for build process                      |    No    |  `8.4`  |
| `node-version`   | Node.js Version for asset compilation              |    No    |  `24`   |
| `pnpm-version`   | PNPM Package Manager version                       |    No    |  `10`   |
| `run-migrations` | Execute database migrations (`migrate --force`)    |    No    | `true`  |
| `optimize`       | Execute Laravel optimizations (`artisan optimize`) |    No    | `true`  |
| `health-check`   | Perform post-deployment HTTP health check          |    No    | `true`  |

---

## 🛡️ Security & Self-Cleaning

> [!NOTE]
> **Self-Cleaning Engine:** The application `.zip` archive and remote PHP extraction scripts (`deploy.php` / `unzip.php`) are automatically deleted from the server upon execution.

- **Token Guard:** Remote execution is secured with a SHA256 / UUID token to block unauthorized access.
- **Smart Rewrite Fallback:** Automatically generates a root `.htaccess` fallback if the hosting Document Root points to the project root directory rather than `public/`.
- **Zero Residual Trace:** No temporary ZIP archives or execution scripts remain on the host server after deployment completes.

---

<p align="center">
Designed & Developed by <b>Chann Labs Creative Studio</b>
</p>
