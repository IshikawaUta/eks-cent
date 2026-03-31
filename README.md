<p align="center">
  <img src="images/logo.webp" alt="Eks-Cent Logo" width="200" />
</p>

# Eks-Cent Framework v4.0.0 🚀

**Eks-Cent** adalah framework web Ruby modern yang ringan, menggunakan standar **Eks Interface**. Dirancang untuk kecepatan, keamanan tingkat tinggi, dan fleksibilitas tanpa beban dependensi eksternal yang besar. Dengan v4.0.0, Eks-Cent kini mendukung fitur arsitektural canggih seperti **URL Mapping** dan **Application Cascading**.

---

## ✨ Fitur Utama v4.0.0

- 🛤 **Modern Routing DSL**: Pendefinisian rute yang intuitif dengan parameter dinamis (`:name`), namespace, dan kontrol eksekusi (`halt`).
- 🗺 **URL Mapping & Cascading**: Jalankan beberapa aplikasi independen di bawah satu server berdasarkan sub-jalur (path mapping) atau fallback otomatis.
- 🔐 **Security First**: Session terenkripsi HMAC-SHA256, proteksi XSS otomatis, header keamanan bawaan, dan pembatasan parameter (DoS protection).
- 🛠 **Standard Middleware Suite**:
  - `Runtime`: Pantau performa dengan header `X-Runtime`.
  - `MethodOverride`: Gunakan `PUT/DELETE` dari form HTML biasa.
  - `Head`: Otomatisasi penanganan request `HEAD`.
  - `Session`, `Logger`, `Static`, `ShowExceptions`, dll.
- 🎨 **Smart Templating**: Integrasi **ERB** dengan sistem **Auto-Layout**, injeksi objek `@req`/`@res`, dan helper keamanan `h`.
- 🧪 **First-Class Testing**: Infrastruktur pengujian bawaan menggunakan `MockRequest` dan `MockResponse`.
- ⚡ **Production Ready**: Terintegrasi penuh dengan **Eksa-Server** (Cluster mode & Workers) dan CLI tool `ekscentup`.

---

## 🚀 Memulai Cepat (v4 Style)

Buat file `config.eks` untuk mendefinisikan aplikasi Anda:

```ruby
# 1. Global Middlewares
use EksCent::Middleware::Runtime
use EksCent::Middleware::MethodOverride
use EksCent::Middleware::Session
use EksCent::Middleware::Logger

# 2. Pemetaan Aplikasi API
map "/api" do
  api = EksCent::Router.new do
    get '/status' do |req, res|
      res.content_type = 'application/json'
      res.write({ status: 'online', version: EksCent::VERSION }.to_json)
    end
  end
  run api
end

# 3. Aplikasi Web Utama
router = EksCent::Router.new do
  get '/' do |req, res|
    req.session['visits'] ||= 0
    req.session['visits'] += 1
    res.write "<h1>Web Utama v#{EksCent::VERSION}</h1>"
    res.write "<p>Kunjungan Anda: #{req.session['visits']}</p>"
  end
end

run router
```

Jalankan dengan perintah:
```bash
ekscentup -R --port 3000
```

---

## 🛤 Dokumentasi Routing

### Router DSL
Anda dapat mendefinisikan rute menggunakan metode HTTP standar (`get`, `post`, `put`, `delete`, `patch`, `options`, `any`).

```ruby
router = EksCent::Router.new do
  get '/user/:id' do |req, res|
    id = req.params['id']
    res.write "User ID: #{id}"
  end

  namespace '/admin' do
    get '/dashboard' do |req, res|
      # Diakses via /admin/dashboard
    end
  end
  
  # Kontrol Eksekusi
  get '/secret' do |req, res|
    halt(403, "Akses ditolak") unless req.session['admin']
    res.write "Data Rahasia"
  end
end
```

### URL Mapping & Cascade
Gunakan `map` untuk membagi aplikasi besar menjadi sub-aplikasi yang lebih kecil. Gunakan `cascade` jika Anda ingin mencoba beberapa aplikasi secara bergantian hingga ada yang merespons (selain 404).

---

## 📦 Middleware Bawaan

| Middleware | Deskripsi |
|------------|-----------|
| `EksCent::Middleware::Runtime` | Menambahkan header `X-Runtime` dengan waktu eksekusi. |
| `EksCent::Middleware::MethodOverride` | Mengizinkan override method HTTP via parameter `_method`. |
| `EksCent::Middleware::Session` | Manajemen session aman berbasis cookie dengan HMAC. |
| `EksCent::Middleware::Logger` | Logging permintaan ke STDOUT atau file log. |
| `EksCent::Middleware::Static` | Melayani file statis dari direktori tertentu (misal: `public`). |
| `EksCent::Middleware::ShowExceptions` | Menampilkan halaman error yang informatif saat terjadi *crash*. |
| `EksCent::Middleware::ContentSecurity` | Menambahkan header keamanan standar (X-Content-Type, X-Frame-Options). |
| `EksCent::Middleware::Head` | Mengosongkan body untuk request HEAD secara otomatis. |

---

## 🎨 Templating & Layout

Letakkan file `.erb` Anda di dalam direktori `views/`. Secara otomatis, framework akan mencari `views/layout.erb` sebagai pembungkus utama.

**views/layout.erb**:
```erb
<html>
  <body>
    <header>My App</header>
    <%= @content %> <!-- Konten dari render akan disisipkan di sini -->
  </body>
</html>
```

Di dalam Router:
```ruby
res.render 'index', judul: "Halo Dunia"
```

**Context Injection**: Objek `@req` (request) dan `@res` (response) serta helper `@h` (escape HTML) selalu tersedia di dalam template.

---

## 🛠 Panduan API (Request & Response)

### EksCent::Request (`req`)
- `req.params`: Mengambil parameter query, POST, atau route params.
- `req.session`: Mengakses data session (Read/Write).
- `req.request_method`: Mendapatkan method HTTP (GET, POST, dll).
- `req.path`: Mendapatkan jalur URL saat ini.
- `req.user_agent`: Mendapatkan informasi browser.

### EksCent::Response (`res`)
- `res.write(string)`: Menambahkan konten ke body respons.
- `res.set_header(key, value)`: Mengatur header HTTP.
- `res.content_type = 'type'`: Shortcut untuk mengatur Content-Type.
- `res.status = code`: Mengatur status code (default: 200).
- `res.redirect(path)`: Melakukan pengalihan URL.
- `res.render(template, locals)`: Merender template ERB.

---

## 🧪 Pengujian (Testing)

Gunakan suite pengujian bawaan untuk memastikan aplikasi Anda berjalan dengan benar:

```ruby
require 'test/unit'
require 'eks-cent'

class MyAppTest < Test::Unit::TestCase
  def test_homepage
    app = EksCent.load('config.eks')
    mock = EksCent::MockRequest.new(app)
    
    res = mock.get('/')
    assert res.ok?
    assert_match "Welcome", res.body_content
  end
end
```

---

## 🛡 Keamanan Dasar (Eks Limits)
Anda dapat mengatur batasan penguraian parameter melalui variabel lingkungan untuk mencegah serangan DoS:
- `EKS_QUERY_PARSER_PARAMS_LIMIT`: Maksimal jumlah parameter (default: 1000).
- `EKS_QUERY_PARSER_DEPTH_LIMIT`: Maksimal kedalaman parameter nested.
- `EKS_MULTIPART_TOTAL_PART_LIMIT`: Maksimal part dalam form multipart.

---

## 📄 Lisensi
Eks-Cent v4.0.0 dipublikasikan di bawah [Lisensi MIT](LICENSE).