# Changelog - Eks-Cent

Semua perubahan penting pada proyek ini akan didokumentasikan dalam file ini.

## [4.0.0] - 2026-03-31

Rilis Major dengan peningkatan arsitektural signifikan dan fitur standar Eks Interface.

### Ditambahkan
- **URL Mapping (`map`)**: Memungkinkan menjalankan beberapa aplikasi di bawah jalur URL yang berbeda.
- **Application Cascade**: Mekanisme fallback otomatis antar aplikasi jika terjadi 404.
- **Middleware Baru**:
  - `EksCent::Middleware::Runtime`: Header `X-Runtime` untuk pelacakan performa.
  - `EksCent::Middleware::MethodOverride`: Dukungan method HTTP non-GET/POST via parameter `_method`.
  - `EksCent::Middleware::Head`: Penanganan otomatis permintaan `HEAD`.
- **Keamanan**: Batasan parameter (`EKS_QUERY_PARSER_PARAMS_LIMIT` dan `EKS_MULTIPART_TOTAL_PART_LIMIT`) untuk mitigasi serangan DoS.
- **Helper Respons**: Menambahkan metode `set_header` dan `content_type=` pada kelas `Response`.
- **Mock Testing**: Objek `MockResponse` yang lebih kaya fitur untuk pengujian unit.

### Diubah
- **Response Layout**: Sistem layout ERB kini mendeteksi `views/layout.erb` secara otomatis.
- **Error Handling**: Peningkatan UI pada middleware `ShowExceptions`.
- **CLI**: Perbaikan logika auto-reload pada `ekscentup -R`.

---

## [1.0.0] - [3.0.0] - 2026-03-28

Peningkatan stabilitas dan fitur pendukung rute.

### Ditambahkan
- Dukungan `multipart/form-data` menggunakan `Eks Standard Request` secara internal.
- Mekanisme `halt` di Router menggunakan `catch/throw`.
- Custom `not_found` dan `error` DSL di Router.
- Injeksi objek `@req` dan `@res` ke dalam template ERB.