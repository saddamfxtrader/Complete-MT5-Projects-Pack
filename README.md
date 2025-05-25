# 📈 MT5 Indicator and Expert Advisor Suite

This repository contains a custom-built **MetaTrader 5 (MT5)** indicator and Expert Advisor (EA) designed to enhance precision trading using advanced logic like RSI filters, Smart Money Concepts (SMC), Fair Value Gaps (FVG), Order Blocks (OB), and volume confirmation.

---

## ⚙️ Features

### 🔹 Indicator:
- RSI-based filtering (multi-timeframe)
- Bullish/Bearish Order Block detection
- Fair Value Gap (FVG) visualization
- Volume spike confirmation
- Smart Liquidity Grab logic
- Signal strength scoring
- Real-time alerts and chart labels

### 🔹 Expert Advisor (EA):
- Auto-trading based on indicator signals
- Risk management settings (lot size, SL/TP)
- Signal delay filters
- HTF trend confirmation
- Works on low-latency M1 scalping (Binary/Forex)

---

## 🛠 Installation

1. Open **MetaTrader 5**.
2. Go to `File → Open Data Folder`.
3. Navigate to:  
   `MQL5/Indicators/` → Copy the `.mq5` indicator files  
   `MQL5/Experts/` → Copy the `.mq5` EA files
4. Open **MetaEditor**, compile the files.
5. Restart MT5 or refresh the Navigator panel.

---

## ✅ Recommended Settings

| Setting             | Value                  |
|---------------------|------------------------|
| Timeframe           | M1 (main), M5/M15 (HTF)|
| Pair                | EURUSD, GBPUSD         |
| RSI Period          | 7                      |
| Signal Check Delay  | 5 seconds before candle close |
| Volume Filter       | Enabled                |

---

## 📸 Screenshots

> _You can add screenshots here to show how the indicator/EA looks on the chart._

---

## 📢 Alerts

- Real-time pop-up + sound alerts
- Optional mobile push notifications
- Alert only when all confluence conditions are met

---

## 👨‍💻 Author

- Developed by: Saddam Forex Trader  
- Contact: saddamfxtrader@gmail.com  
- Whatsapp : +8801818206268 

---

## 📄 License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute the files with proper attribution.

---

## 🙌 Contributions

Pull requests and suggestions are welcome! If you find bugs or want to improve performance, feel free to submit an issue.

