# MT5 Indicator MaxDailyLoss
Indikator MT5 untuk monitoring daily loss limit berdasarkan persentase balance.

<img width="319" height="92" alt="MaxDailyLoss" src="https://github.com/user-attachments/assets/57b5f012-e0ae-4504-87df-9775001cf492" />

## Fungsi

- Menghitung maksimal loss harian berdasarkan persentase dari balance awal hari
- Menampilkan P/L saat ini (closed + floating)
- Menampilkan sisa loss yang diperbolehkan
- Perubahan warna otomatis berdasarkan sisa persentase
- Panel dapat dipindahkan dengan drag & drop

## Cara Install

1. Copy file `MaxDailyLoss.mq5` ke folder `MQL5/Indicators`
2. Compile di MetaEditor
3. Attach ke chart melalui Navigator

## Parameter Input

- `MaxLossPercent` - Maksimal loss harian dalam persen (default: 4.0%)
- `PanelBGColor` - Warna background panel
- `PanelWidth` - Lebar panel (default: 280)
- `PanelHeight` - Tinggi panel (default: 140)
- `Corner` - Posisi panel di chart
- `XDistance` - Jarak horizontal dari corner
- `YDistance` - Jarak vertikal dari corner
- `TextColor` - Warna teks default
- `FontSize` - Ukuran font (default: 10)
- `Font` - Jenis font (default: Consolas)

## Cara Menggunakan

1. Set `MaxLossPercent` sesuai risk management Anda
2. Indikator akan otomatis:
   - Reset balance di awal hari trading
   - Hitung P/L dari closed positions + floating
   - Tampilkan sisa loss yang tersedia
3. Warna indikator:
   - Hijau: Sisa > 70%
   - Kuning: Sisa 30-70%
   - Orange: Sisa 0-30%
   - Merah: Loss limit tercapai

## Perhitungan

```
Max Loss = Balance Awal Hari × (MaxLossPercent / 100)
Current Loss = |Daily P/L| (jika negatif)
Remaining = Max Loss - Current Loss
```

## Catatan

- Balance awal dihitung saat hari trading dimulai
- Termasuk profit/loss dari swap dan commission
- Reset otomatis setiap pergantian hari
