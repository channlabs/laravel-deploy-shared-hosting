# 🚀 Laravel Shared Hosting Deployer (GitHub Action)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/channlabs/laravel-shared-hosting-deployer?color=emerald&style=flat-square)](https://github.com/channlabs/laravel-shared-hosting-deployer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform: Laravel](https://img.shields.io/badge/Platform-Laravel_11_/_12_/_13-red.svg?style=flat-square)](https://laravel.com)

Sebuah **Composite GitHub Action** premium besutan **Chann Labs Creative Studio** yang dirancang khusus untuk mengotomatisasi proses deployment aplikasi Laravel ke lingkungan **Shared Hosting (cPanel)** secara kilat, aman, dan anti-gagal.

---

## ⚡ Mengapa Menggunakan Action Ini?

Deployment konvensional menggunakan FTP biasa sering kali **macet, timeout, atau diblokir oleh firewall hosting** karena mencoba mengunggah puluhan ribu file kecil (seperti isi folder `vendor`). 

Action ini memecahkan masalah tersebut dengan **Metode ZIP-Express**:
1. **Otomatisasi Penuh:** Menjalankan `composer install`, setup Node, dan kompilasi asset Vite (`pnpm run build`) langsung di infrastruktur GitHub.
2. **Koneksi Kilat:** Mengompres seluruh project menjadi **satu file `.zip`** ringkas, lalu mengunggahnya via **LFTP Pasif (Port 21)** hanya dalam hitungan detik.
3. **Ekstraksi & Optimalisasi Lokal:** Memasok skrip enkapsulasi PHP aman (`unzip.php`) untuk mengekstrak file di dalam hosting, otomatis membersihkan cache usang, memicu migrasi database (`php artisan migrate --force`), dan mengaktifkan optimasi performa (`php artisan optimize`).

---

## 🛠️ Persyaratan Awal (Prerequisites)

Sebelum memasang Action ini, pastikan Anda telah menyiapkan komponen berikut di **cPanel** Anda:

1. **Akun FTP Dedikasi:** Buat akun FTP baru di cPanel yang jalurnya (*Directory*) langsung diarahkan ke **root directory** dari subdomain/domain target Anda (satu tingkat di atas folder `public`, bukan di dalam `public`).
2. **Domain/Subdomain Terarah:** Pastikan web server hosting Anda mengarah ke folder `public` dari project Laravel tersebut untuk alasan keamanan terbaik.

---

## 🚀 Cara Penggunaan

### 1. Simpan Kredensial di GitHub Secrets
Pergi ke Repositori GitHub Anda > **Settings** > **Secrets and variables** > **Actions** > **New repository secret**, lalu tambahkan:
* `FTP_SERVER` / `FTP_SERVER_STAGING` : Alamat host FTP (misal: `ftp.domain.com` atau IP server).
* `FTP_USERNAME` / `FTP_USERNAME_STAGING` : Username akun FTP cPanel Anda.
* `FTP_PASSWORD` / `FTP_PASSWORD_STAGING` : Password akun FTP cPanel Anda.

### 2. Buat Workflow Deployment
Buat file di dalam project Laravel Anda pada direktori `.github/workflows/deploy.yml` dan gunakan konfigurasi multi-branch (Staging & Production) di bawah ini:

```yaml
name: Deploy Dobha Perfume System to Hosting

on:
  push:
    branches:
      - main     # Memicu deploy otomatis ke server Production
      - staging  # Memicu deploy otomatis ke server Staging

jobs:
  web-deploy:
    name: 🚀 Deploy Project
    runs-on: ubuntu-latest
    
    steps:
    - name: 🚚 Get latest code
      uses: actions/checkout@v4

    - name: 🚀 Run Chann Labs Shared Hosting Deployer
      uses: channlabs/laravel-shared-hosting-deployer@v1
      with:
        ftp-server: ${{ github.ref_name == 'main' && secrets.FTP_SERVER || secrets.FTP_SERVER_STAGING }}
        ftp-username: ${{ github.ref_name == 'main' && secrets.FTP_USERNAME || secrets.FTP_USERNAME_STAGING }}
        ftp-password: ${{ github.ref_name == 'main' && secrets.FTP_PASSWORD || secrets.FTP_PASSWORD_STAGING }}
        deploy-url: ${{ github.ref_name == 'main' && 'hub.dobha.com' || 'staging.dobha.com' }}
        php-version: '8.4'  # Opsional, default '8.4'
        node-version: '24'  # Opsional, default '24'
        pnpm-version: '11'  # Opsional, default '9'
