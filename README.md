# MT5 Indicator MaxDailyLoss

Indikator MT5 untuk monitoring **batas kerugian harian** sekaligus **penggunaan margin** secara real-time.

<img width="315" height="238" alt="MaxDailyLoss Panel v4.04" src="https://github.com/user-attachments/assets/01f70bdd-3828-4859-9a5e-b260ff51b1e4" />


## Fungsi Utama (v4.04)

- Menampilkan **Max Loss** harian berdasarkan persentase
- Menampilkan **Current P/L** (closed + floating)
- Menampilkan **Remaining** loss yang masih diperbolehkan + persentasenya
- Menampilkan **Last Trade** (jumlah hari sejak trade terakhir ditutup)
- **Fitur Margin Usage Monitor** (real-time):
  - Margin Usage (%) dengan warna peringatan
  - Margin Level (%)
  - Used Margin & Free Margin
  - Leverage akun (otomatis)
- Panel dapat dipindahkan (drag & drop di area atas)
- Perubahan warna otomatis sesuai kondisi

## Cara Install

1. Salin file `MaxDailyLoss.mq5` ke folder `MQL5/Indicators`
2. Buka MetaEditor → Compile (F7)
3. Attach indikator ke chart melalui Navigator → Custom Indicators

## Parameter Input Utama

| Parameter                  | Deskripsi                                                      | Default     |
|----------------------------|----------------------------------------------------------------|-------------|
| `MaxLossPercent`           | Persentase maksimal loss harian                                | 4.0         |
| `UseFixedBalance`          | Gunakan balance statis (`true`) atau otomatis dari balance awal hari | true        |
| `FixedBalance`             | Nilai balance tetap (jika `UseFixedBalance = true`)            | 10000.0     |
| `ShowDaysSinceLast`        | Tampilkan informasi "Last Trade" (hari sejak trade terakhir)   | true        |
| `MaxMarginUsageSafe`       | Batas aman penggunaan margin (hijau)                           | 30.0        |
| `MaxMarginUsageWarning`    | Batas peringatan penggunaan margin (kuning → merah)            | 50.0        |
| `PanelWidth`               | Lebar panel                                                    | 260         |
| `PanelHeight`              | Tinggi panel                                                   | 225         |
| `PanelBGColor`             | Warna latar belakang panel                                     | clrBlack    |
| `Corner`                   | Posisi sudut panel                                             | CORNER_LEFT_UPPER |
| `XDistance` / `YDistance`  | Jarak dari sudut chart                                         | 10 / 10     |

> **Catatan**: Parameter `MaxMarginUsageSafe` dan `MaxMarginUsageWarning` memungkinkan Anda menyesuaikan batas margin sesuai gaya trading masing-masing (contoh: ubah menjadi 25.0 dan 45.0 jika ingin lebih konservatif).

## Cara Menggunakan

1. Atur `MaxLossPercent` sesuai aturan risk management Anda (disarankan 1–4%).
2. Atur `UseFixedBalance` sesuai preferensi:
   - `true` → lebih konsisten (rekomendasi)
   - `false` → pakai balance awal hari
3. `ShowDaysSinceLast = true` untuk menampilkan informasi Last Trade.
4. Attach ke chart → panel akan menampilkan semua informasi secara real-time.

**Fitur Margin Usage** membantu menjaga penggunaan margin tetap di bawah **20–30%** sesuai praktik trader profesional.

## Warna Indikator

### Remaining Loss
- **Hijau terang** → Sisa > 70%
- **Kuning** → Sisa 30–70%
- **Oranye** → Sisa 0–30%
- **Merah** → Limit tercapai / melebihi

### Margin Usage
- **Hijau** → ≤ 30% (Aman)
- **Kuning** → 30–50% (Waspada)
- **Merah** → > 50% (Bahaya – kurangi posisi)

## Perhitungan Dasar

- **Max Loss** = Basis Balance × (MaxLossPercent / 100)
- **Daily P/L** = Closed P/L hari ini + Floating P/L
- **Remaining** = Max Loss – Current Loss (jika negatif)
- **Margin Usage (%)** = (Used Margin / Equity) × 100
- **Last Trade** = Jumlah hari sejak trade terakhir ditutup (DEAL_ENTRY_OUT)

## Catatan Penting

- Semua data (**P/L, Remaining, Margin Usage**) update **real-time** setiap tick.
- `ShowDaysSinceLast` dapat dimatikan jika tidak diperlukan.
- Mode fixed balance membuat limit harian lebih stabil dan konsisten.
- Pastikan history deal di MT5 cukup panjang agar perhitungan Closed P/L dan Last Trade akurat.
- Panel dirancang tetap minimalis meskipun sudah menampilkan banyak informasi.

---

**Versi saat ini**: 4.04  
**Update terbaru**: Penambahan Margin Usage Monitor + informasi Last Trade yang sudah ditampilkan di panel.
