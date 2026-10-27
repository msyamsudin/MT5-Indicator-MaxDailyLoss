# MT5 Indicator — MaxDailyLoss

Indikator MetaTrader 5 untuk memantau batas kerugian harian (*daily loss limit*) dan penggunaan margin akun, termasuk estimasi leverage efektif berdasarkan pengaturan margin simbol.

## Fitur

### Daily Risk Monitor

- **Max Loss** — batas kerugian harian berdasarkan persentase dari basis balance.
- **P/L** — closed P/L hari ini ditambah floating P/L akun.
- **Remaining** — sisa batas kerugian yang tersedia, ditampilkan dalam nominal atau persentase.
- **Risk Bar** — visualisasi sisa batas kerugian dengan warna status.
- **Last Trade** — jumlah hari sejak transaksi terakhir ditutup. Dapat disembunyikan melalui parameter.

### Margin Monitor

- **Usage** — penggunaan margin sebagai persentase equity.
- **Level** — margin level akun.
- **Used** dan **Free** — margin terpakai dan margin bebas.
- **Leverage** — estimasi leverage efektif berdasarkan leverage akun dan margin rate yang digunakan indikator.

### Panel dan Posisi

- Panel ringkas dengan ukuran, warna, font, dan posisi awal yang dapat disesuaikan.
- **Double-click** area header untuk mengaktifkan mode `MOVING`, yaitu panel mengikuti posisi kursor.
- **Single-click** area header ketika mode `MOVING` aktif untuk mengunci posisi (`LOCKED`).
- Posisi panel disimpan menggunakan Terminal Global Variables dengan kunci berdasarkan akun dan simbol, sehingga dapat dipulihkan saat indikator dipasang kembali pada kombinasi akun dan simbol yang sama.

## Instalasi

1. Salin `MaxDailyLoss.mq5` ke folder data terminal MT5, di dalam `MQL5/Indicators`.
2. Buka MetaEditor, lalu compile file dengan menekan **F7**.
3. Kembali ke MT5 dan buka **Navigator → Indicators → Custom Indicators**.
4. Pasang `MaxDailyLoss` ke chart.

## Parameter Input

| Parameter | Deskripsi | Default |
|---|---|---:|
| `MaxLossPercent` | Batas kerugian harian sebagai persentase basis balance | `4.0` |
| `UseFixedBalance` | Jika `true`, gunakan `FixedBalance`; jika `false`, gunakan estimasi balance awal hari | `true` |
| `FixedBalance` | Nilai balance tetap yang menjadi basis perhitungan | `10000.0` |
| `ShowDaysSinceLast` | Tampilkan atau sembunyikan informasi `Last Trade` | `true` |
| `RemainingDisplay` | Format `Remaining`: `REMAINING_USD` (nominal) atau `REMAINING_PERCENT` (persentase) | `REMAINING_USD` |
| `MaxMarginUsageSafe` | Batas atas status aman untuk penggunaan margin (%) | `30.0` |
| `MaxMarginUsageWarning` | Batas atas status peringatan untuk penggunaan margin (%) | `50.0` |
| `CustomMarginRate` | Margin rate override untuk estimasi leverage efektif. Nilai `0` menggunakan initial margin rate dari broker jika tersedia | `4.0` |
| `TextColor` | Warna teks umum | `clrWhite` |
| `PanelBGColor` | Warna latar belakang panel | `clrBlack` |
| `PanelWidth` | Lebar panel dalam piksel | `290` |
| `PanelHeight` | Tinggi panel dalam piksel | `320` |
| `Corner` | Sudut chart sebagai acuan posisi awal panel | `CORNER_LEFT_UPPER` |
| `XDistance` | Jarak horizontal posisi awal panel dari sudut acuan | `10` |
| `YDistance` | Jarak vertikal posisi awal panel dari sudut acuan | `10` |
| `FontSize` | Ukuran font panel | `10` |
| `Font` | Jenis font panel | `Consolas` |

## Cara Menggunakan

1. Atur `MaxLossPercent` dan basis balance sesuai aturan risiko yang ingin dipantau.
2. Untuk memakai nilai balance tetap, set `UseFixedBalance = true` dan sesuaikan `FixedBalance`.
3. Jika `UseFixedBalance = false`, indikator mengambil balance akun dikurangi floating P/L ketika basis harian di-reset.
4. Pilih format `Remaining` melalui `RemainingDisplay`:
   - `REMAINING_USD` — sisa batas kerugian dalam nominal.
   - `REMAINING_PERCENT` — persentase batas kerugian yang masih tersisa.
5. Atur ambang warna margin melalui `MaxMarginUsageSafe` dan `MaxMarginUsageWarning`.
6. Atur `CustomMarginRate` untuk estimasi leverage efektif (untuk menentukan nilai, bisa dilihat pada bagian Spesifikasi - initial margin):
   - Nilai lebih besar dari `0` — gunakan nilai override tersebut.
   - Nilai `0` — gunakan initial margin rate yang dilaporkan broker; jika tidak tersedia, indikator memakai fallback `1.0`.
7. Untuk memindahkan panel, double-click area header sampai status berubah menjadi `MOVING`, lalu gerakkan kursor. Single-click area header untuk mengunci panel kembali.

## Warna Status

### Remaining

- **Hijau** — lebih dari 70% batas kerugian masih tersisa.
- **Kuning** — lebih dari 30% hingga 70% masih tersisa.
- **Oranye** — lebih dari 0% hingga 30% masih tersisa.
- **Merah** — tidak ada sisa batas kerugian.

### Margin Usage

Warna mengikuti ambang input:

- **Hijau** — `Usage` kurang dari atau sama dengan `MaxMarginUsageSafe`.
- **Kuning** — `Usage` di atas `MaxMarginUsageSafe` dan kurang dari atau sama dengan `MaxMarginUsageWarning`.
- **Merah** — `Usage` di atas `MaxMarginUsageWarning`.

Dengan nilai default, status hijau berlaku sampai 30%, kuning di atas 30% sampai 50%, dan merah di atas 50%.

## Perhitungan

- **Max Loss** = basis balance × (`MaxLossPercent` / 100)
- **Daily P/L** = closed P/L hari ini + floating P/L akun
- **Remaining (nominal)** = nilai maksimum antara `Max Loss − kerugian berjalan` dan `0`
- **Remaining (%)** = `Remaining` nominal / `Max Loss` × 100
- **Margin Usage (%)** = Used Margin / Equity × 100
- **Margin Level (%)** = nilai `ACCOUNT_MARGIN_LEVEL` dari MT5
- **Leverage efektif (estimasi)** = leverage akun / margin rate yang digunakan indikator
- **Last Trade** = jumlah pergantian hari kalender server sejak waktu transaksi terakhir dengan `DEAL_ENTRY_OUT`

## Catatan dan Batasan

- Data diperbarui ketika `OnCalculate` dipanggil oleh terminal, umumnya saat ada tick baru pada simbol chart. Pembaruan tidak dijamin terjadi tepat setiap detik.
- Closed P/L dihitung dari deal dengan `DEAL_ENTRY_OUT` pada hari berjalan, termasuk profit, swap, dan komisi yang tercatat pada deal tersebut. Pastikan riwayat transaksi MT5 tersedia.
- `UseFixedBalance = false` menggunakan balance akun dikurangi floating P/L saat basis harian di-reset. Verifikasi bahwa perilaku ini sesuai dengan cara batas kerugian dihitung oleh broker atau prop firm.
- `CustomMarginRate` memengaruhi angka leverage yang ditampilkan. Angka ini merupakan estimasi berbasis margin rate, bukan jaminan bahwa margin aktual semua posisi atau simbol akan selalu mengikuti nilai tersebut.
- Perhitungan batas kerugian pada indikator ini tidak menggantikan aturan resmi broker atau prop firm, termasuk zona waktu reset, komponen biaya yang dihitung, dan metode equity/balance yang digunakan.

---

**Versi kode:** 5.10

**Fitur yang tercakup:** pemantauan daily loss dan margin, pilihan format Remaining, pengaturan margin rate untuk estimasi leverage efektif, serta panel `MOVING` / `LOCKED` dengan penyimpanan posisi.
