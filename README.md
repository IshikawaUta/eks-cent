# Eks-Cent Framework 🚀

**Eks-Cent** adalah framework web Ruby ringan yang terinspirasi oleh Rack. Dirancang untuk kecepatan, keamanan, dan kemudahan penggunaan tanpa dependensi eksternal yang berat.

Eks-Cent menggunakan **Eksa-Server** sebagai engine server bawaan untuk performa tinggi di lingkungan produksi.

## ✨ Fitur Utama

- 🛤 **Advanced Routing**: DSL rute yang bersih dengan dukungan parameter dinamis dan namespace.
- 🔐 **Security Pack**:
  - **Signed Sessions**: Data session aman dengan HMAC-SHA256.
  - **XSS Protection**: Helper `h` otomatis untuk escape HTML di template.
  - **Security Headers**: Middleware bawaan untuk header Frame-Options, XSS-Protection, dll.
- 🎨 **Templating**: Integrasi native dengan **ERB** (Embedded Ruby).
- 📦 **JSON Ready**: Parsing otomatis untuk request body `application/json`.
- ⚡ **High Performance**: Terintegrasi dengan Eksa-Server (Cluster mode & Workers).
- 🛠 **CLI Tool**: Jalankan aplikasi dengan perintah `ekscentup` layaknya `rackup`.

## 📦 Instalasi

Tambahkan baris ini ke dalam Gemfile aplikasi Anda:

```ruby
gem 'eks-cent'
```

Lalu jalankan:
```bash
gem install eks-cent
```

## 🚀 Memulai Cepat

Buat file bernama `config.eks`:

```ruby
# config.eks
use EksCent::Middleware::ContentSecurity
use EksCent::Middleware::Session
use EksCent::Middleware::Logger
use EksCent::Middleware::ShowExceptions

router = EksCent::Router.new do
  # Halaman Utama
  get '/' do |req, res|
    req.session['visits'] ||= 0
    req.session['visits'] += 1
    res.write "<h1>Halo! Anda sudah berkunjung #{req.session['visits']} kali.</h1>"
  end

  # Rute Dinamis
  get '/hello/:name' do |req, res|
    res.render 'welcome', name: req.params['name']
  end

  # API JSON
  namespace '/api' do
    post '/data' do |req, res|
      res.headers['Content-Type'] = 'application/json'
      res.write({ status: 'success', data: req.params }.to_json)
    end
  end
end

run router
```

Jalankan server:
```bash
./bin/ekscentup -p 3000
```

## 🛠 Penggunaan CLI (`ekscentup`)

| Opsi | Deskripsi |
|------|-----------|
| `-p, --port` | Menentukan port server (default: 3000) |
| `-o, --host` | Menentukan host server (default: 0.0.0.0) |
| `-w, --workers` | Jumlah worker untuk mode Cluster |
| `-R, --reload` | Aktifkan auto-reload saat file berubah |
| `-e, --env` | Set lingkungan (`development` atau `production`) |
| `-L, --log` | Simpan log ke file tertentu |

## 🛡 Mode Produksi

Untuk keamanan maksimal di produksi, pastikan Anda menyetel environment variable dan secret key:

```bash
export EKS_CENT_SECRET_KEY_BASE="kunci_rahasia_anda_yang_unik"
export RACK_ENV=production
./bin/ekscentup -p 80 -e production
```

## 🧪 Pengujian

Eks-Cent dilengkapi dengan suite pengujian yang lengkap. Untuk menjalankan semua tes:

```bash
ruby test/eks_cent_test.rb
ruby test/router_test.rb
ruby test/security_test.rb
```

## 📄 Lisensi

Eks-Cent didistribusikan di bawah [Lisensi MIT](LICENSE).