# MT5 Indicator MaxDailyLoss

Indikator MT5 minimalis untuk monitoring batas kerugian harian berdasarkan persentase balance.

<img width="240" height="110" alt="MaxDailyLoss Minimal Panel" src="https://github.com/user-attachments/assets/57b5f012-e0ae-4504-87df-9775001cf492" />

## Fungsi Utama
- Menampilkan **Max Loss** harian (berdasarkan % dari balance tetap atau balance awal hari)
- Menampilkan **Current P/L** (closed + floating)
- Menampilkan **Remaining** loss yang masih diperbolehkan beserta persentasenya
- Perubahan warna otomatis sesuai sisa persentase
- Panel dapat dipindahkan (drag di area atas yang hampir tak terlihat)

## Cara Install
1. Salin file `MaxDailyLoss.mq5` ke folder `MQL5/Indicators`
2. Buka dan compile di MetaEditor
3. Attach indikator ke chart melalui Navigator → Indicators

## Parameter Input Utama
| Parameter            | Deskripsi                                      | Default       |
|----------------------|------------------------------------------------|---------------|
| `MaxLossPercent`     | Persentase maksimal loss harian                | 4.0           |
| `UseFixedBalance`    | Gunakan balance statis (true) atau otomatis    | true          |
| `FixedBalance`       | Nilai balance tetap jika UseFixedBalance = true| 10000.0       |
| `PanelBGColor`       | Warna latar panel                              | clrBlack      |
| `PanelWidth`         | Lebar panel                                    | 240           |
| `PanelHeight`        | Tinggi panel                                   | 110           |
| `Corner`             | Posisi sudut panel                             | CORNER_LEFT_UPPER |
| `XDistance` / `YDistance` | Jarak dari sudut chart                    | 10 / 10       |

Parameter lain (warna teks, font, ukuran) tetap ada tapi jarang diubah.

## Cara Menggunakan
1. Atur `MaxLossPercent` sesuai aturan risk Anda
2. Pilih mode balance:
   - `UseFixedBalance = true` → gunakan nilai `FixedBalance` (disarankan untuk konsistensi)
   - `UseFixedBalance = false` → pakai balance awal hari (mode original)
3. Indikator akan:
   - Reset perhitungan setiap awal hari baru
   - Hitung P/L harian (termasuk swap & komisi)
   - Tampilkan sisa loss secara real-time

## Warna Indikator (sisa %)
- **Hijau terang** → Sisa > 70%  
- **Kuning**       → Sisa 30–70%  
- **Oranye**       → Sisa 0–30%  
- **Merah**        → Limit tercapai / melebihi

## Perhitungan Dasar
Max Loss     = Basis Balance × (MaxLossPercent / 100)
Daily P/L    = Closed P/L hari ini + Floating P/L saat ini
Current Loss = |Daily P/L| jika negatif, 0 jika positif
Remaining    = Max Loss - Current Loss


## Catatan Penting
- Mode fixed balance (`UseFixedBalance = true`) membuat limit harian lebih konsisten dan tidak terpengaruh profit/loss sebelumnya.
- Floating P/L dihitung real-time → panel akan berubah warna secara dinamis saat posisi terbuka.
- Tidak ada alert/email/push notification (bisa ditambahkan jika diperlukan).
- Pastikan history deal di MT5 cukup panjang agar closed P/L akurat.
