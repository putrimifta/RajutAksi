# RajutAksi 🌍 
http://localhost:54935/
Platform yang menghubungkan **Relawan**, **Organisasi**, dan **Sponsor** untuk mendukung SDG 17 (Kemitraan untuk Tujuan).

Dibangun dengan **Flutter** + **Supabase** (Postgres + Auth + Storage + Realtime).

---

## ✨ Fitur yang sudah jadi

- Splash screen, onboarding 3 halaman, login & register
- **Multi-peran dalam satu akun** — user bisa mengaktifkan Relawan, Organisasi, dan Sponsor sekaligus, lalu berpindah peran aktif kapan saja lewat menu "Switch Role"
- Home berbeda tampilan sesuai peran aktif (Relawan / Organisasi / Sponsor)
- Detail event lengkap dengan progres kuota relawan & dana sponsor
- Form buat event (untuk Organisasi) dan form pengajuan sponsor (untuk Sponsor)
- Riwayat aktivitas, chat real-time antar pengguna, edit profil
- Warna utama aplikasi: `#4E8EA2`
- Data contoh (seed data) sudah disiapkan supaya aplikasi tidak kosong: 6 event, beberapa organisasi/sponsor/relawan, 1 percakapan dengan pesan

---

## 🧱 Struktur Proyek

```
rajutaksi_app/
├── lib/
│   ├── core/            # tema warna & konfigurasi Supabase
│   ├── models/           # model data (Profile, EventItem, dst)
│   ├── services/         # SupabaseService (semua query & auth di sini)
│   ├── screens/           # semua halaman UI
│   └── widgets/          # komponen UI yang dipakai berulang
├── supabase/
│   └── schema.sql        # SQL lengkap: tabel, RLS, trigger, dan seed data
└── pubspec.yaml
```

---

## 🚀 LANGKAH SETUP (ikuti urut dari atas ke bawah)

### 1. Buat Project Supabase
1. Buka https://supabase.com → **Start your project** → login/daftar
2. Klik **New Project**
   - **Name**: RajutAksi
   - **Database Password**: buat password kuat, **simpan baik-baik**
   - **Region**: pilih **Southeast Asia (Singapore)** (paling dekat & cepat dari Indonesia)
3. Tunggu ± 2 menit sampai project selesai dibuat

### 2. Jalankan Schema SQL
1. Di dashboard project, buka menu **SQL Editor** (ikon `</>`  di sidebar kiri)
2. Klik **New query**
3. Buka file `supabase/schema.sql` dari folder proyek ini, **copy semua isinya**
4. Paste ke SQL Editor, lalu klik **Run** (atau `Ctrl+Enter`)
5. Jika sukses akan muncul "Success. No rows returned"
6. Cek hasilnya: buka menu **Table Editor** → harusnya sudah ada tabel `profiles`, `events`, `registrations`, `sponsorships`, `conversations`, `messages`, lengkap dengan data contoh di dalamnya

### 3. Buat Storage Bucket (untuk foto profil & poster event)
1. Buka menu **Storage** di sidebar
2. Klik **New bucket**, buat 3 bucket berikut, dan **centang "Public bucket"** untuk ketiganya:
   - `avatars`
   - `event-posters`
   - `chat-attachments`

### 4. Ambil API Key Project
1. Buka menu **Project Settings** (ikon gear) → **API**
2. Catat dua nilai berikut:
   - **Project URL** (contoh: `https://xxxxxxxxxxxx.supabase.co`)
   - **anon public key** (key yang panjang, di bagian "Project API keys")
3. ⚠️ **Jangan** memakai "service_role key" di aplikasi Flutter — itu hanya untuk backend/admin.

### 5. Masukkan Kredensial ke Flutter
1. Buka file `lib/core/supabase_config.dart`
2. Ganti dua baris berikut dengan nilai kamu dari langkah 4:
   ```dart
   static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
   static const String supabaseAnonKey = 'YOUR-ANON-PUBLIC-KEY';
   ```

### 6. (Opsional tapi disarankan) Matikan "Confirm Email"
Supaya bisa langsung login setelah daftar tanpa perlu klik link verifikasi email dulu (memudahkan saat demo/presentasi ke dosen):
1. Buka menu **Authentication** → **Providers** → **Email**
2. Matikan toggle **"Confirm email"**
3. Klik **Save**

Jika ini tidak dimatikan, setelah daftar user harus membuka email dan klik link konfirmasi sebelum bisa login.

### 7. Install Dependency & Jalankan Aplikasi
Buka terminal di folder `rajutaksi_app`, lalu jalankan:

```bash
flutter pub get
flutter run
```

Pilih device (Chrome, emulator Android, atau HP fisik yang sudah di-debug mode).

---

## 🧪 Cara Mencoba Aplikasi

1. Jalankan aplikasi → lewati onboarding → klik **Daftar**
2. Isi nama, email, password → **pilih peran** (boleh centang lebih dari satu, misalnya Relawan **dan** Sponsor sekaligus)
3. Klik **Daftar** → otomatis masuk ke Home sesuai peran pertama yang dipilih
4. Untuk mencoba tampilan peran lain: buka **Profile → Switch Role**, aktifkan peran lain lewat toggle, lalu ketuk peran tersebut untuk menjadikannya aktif, klik **Ganti Peran Sekarang**
5. Data event, sponsor, dan chat contoh akan langsung terlihat karena sudah di-seed di database — kamu tidak perlu input manual dari nol

---

## 🎨 Palet Warna

| Nama | Kode | Kegunaan |
|---|---|---|
| Primary | `#4E8EA2` | Tombol utama, header, ikon aktif |
| Primary Dark | `#3A6E80` | Teks judul, elemen penekanan |
| Primary Light | `#E8F1F3` | Background badge/kartu terang |
| Accent | `#E8734A` | Badge "Butuh Sponsor" |

---

## 🗄️ Ringkasan Skema Database (Supabase)

| Tabel | Fungsi |
|---|---|
| `profiles` | Data user: nama, email, foto, **roles** (array, mendukung multi-peran), `active_role` |
| `events` | Kegiatan/event yang dibuat organisasi, termasuk kuota relawan & target dana sponsor |
| `registrations` | Relawan yang mendaftar ke sebuah event |
| `sponsorships` | Penawaran sponsor ke sebuah event beserta nominal & pesan |
| `conversations` | Percakapan antara dua pengguna |
| `messages` | Isi pesan di setiap percakapan (realtime) |

Semua tabel sudah diberi **Row Level Security (RLS)** supaya:
- Setiap orang bisa lihat event & profil publik
- User hanya bisa mengubah data miliknya sendiri
- Chat hanya bisa dilihat oleh yang terlibat di percakapan tersebut

---

## 🔧 Yang Bisa Dikembangkan Lagi (opsional)

- Upload poster event & foto profil ke Storage (kerangka fungsi `uploadFile()` sudah tersedia di `SupabaseService`, tinggal dihubungkan ke `image_picker`)
- Notifikasi push (Firebase Cloud Messaging)
- Halaman approve/reject relawan & sponsor untuk organisasi
- Search & filter lanjutan di halaman Activity

---

## ❓ Troubleshooting

| Masalah | Solusi |
|---|---|
| `AuthException: Email not confirmed` | Matikan "Confirm email" di langkah 6, atau cek email untuk klik link verifikasi |
| Data event tidak muncul | Pastikan `schema.sql` sudah dijalankan sampai selesai tanpa error, cek di Table Editor |
| Error `Invalid API key` | Pastikan `supabaseUrl` & `supabaseAnonKey` sudah benar dan tidak ada spasi tambahan |
| Gambar poster tidak tampil | Karena data contoh belum ada file gambar asli — upload poster lewat form "Buat Event" untuk event baru |
