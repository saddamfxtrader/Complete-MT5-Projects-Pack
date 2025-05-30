#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrRed

double dummyBuffer[];

input int    XDISTANCE    = 10;       // Default X Distance for label
input int    YDISTANCE    = 30;       // Default Y Distance for label
input int    FontSize     = 12;       // Default font size for label
input int    MaxCandles   = 50;       // Default number of candles for volume average
input int    RSIPeriod    = 14;       // Default RSI period
input color  BullColor    = clrLime;  // Default color for bullish signal
input color  BearColor    = clrRed;   // Default color for bearish signal
input ENUM_TIMEFRAMES HTF = PERIOD_H1; // Default higher timeframe (H1)

string signalLabel = "NextMovePrediction";
datetime lastBarTime = 0;
int rsiHandle = INVALID_HANDLE;

int OnInit()
{
   SetIndexBuffer(0, dummyBuffer);
   rsiHandle = iRSI(_Symbol, HTF, RSIPeriod, PRICE_CLOSE);
   if (rsiHandle == INVALID_HANDLE)
      return INIT_FAILED;

   EventSetTimer(1); // প্রতি 1 সেকেন্ডে চেক হবে
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, signalLabel);
   if (rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rsiHandle);
}

datetime lastPredictionTime = 0;

void OnTimer()
{
   datetime barTime = iTime(_Symbol, PERIOD_M1, 0);
   int secRemaining = 60 - (int)(TimeLocal() % 60);  // TimeLocal ব্যবহার করি এখানে

   // এলার্ট শুরু হবে ১ মিনিট আগে
   if (secRemaining <= 60 && secRemaining > 5)
   {
      AlertIfNeeded();
   }

   // সিগনাল দেখানো হবে ৫ সেকেন্ড আগে
   if (secRemaining == 5 && barTime != lastPredictionTime)
   {
      lastPredictionTime = barTime;

      string prediction = GetNextCandlePrediction();
      DrawSignalLabel(prediction);
   }
}

string GetNextCandlePrediction()
{
   int bars = Bars(_Symbol, PERIOD_M1);
   if (bars < MaxCandles + 2) return "⏳ Loading...";

   double high1 = iHigh(_Symbol, PERIOD_M1, 1);
   double low1 = iLow(_Symbol, PERIOD_M1, 1);
   double volCurrent = (double)iVolume(_Symbol, PERIOD_M1, 0); // Cast long to double

   double volAvg = 0;
   for (int i = 1; i <= MaxCandles; i++)
      volAvg += (double)iVolume(_Symbol, PERIOD_M1, i); // Cast long to double
   volAvg /= MaxCandles;

   bool sweepDown = (iLow(_Symbol, PERIOD_M1, 0) < low1);
   bool sweepUp   = (iHigh(_Symbol, PERIOD_M1, 0) > high1);
   bool volSpike  = (volCurrent > 1.2 * volAvg); // ভলিউম স্পাইক

   // EQH Sweep Detection (Equal High Sweep)
   bool eqhSweep = (iHigh(_Symbol, PERIOD_M1, 0) == high1);
   
   // Displacement Check (Price displacement)
   bool displacement = (iClose(_Symbol, PERIOD_M1, 0) > iClose(_Symbol, PERIOD_M1, 1));

   // FVG Rejection (Fair Value Gap Rejection)
   bool fvgRejection = (iClose(_Symbol, PERIOD_M1, 0) > iHigh(_Symbol, PERIOD_M1, 1));

   double rsiVal = GetHTFRSI();
   if (rsiVal < 0) return "⏳ RSI loading...";

   bool htfBull = rsiVal > 50;
   bool htfBear = rsiVal < 50;

   // Combined Logic for Buy Signal
   if (sweepDown && volSpike && eqhSweep && displacement && fvgRejection && htfBull)
      return "✅ Strong Buy Signal";

   // Combined Logic for Sell Signal
   if (sweepUp && volSpike && eqhSweep && displacement && fvgRejection && htfBear)
      return "🔻 Strong Sell Signal";

   return "⏳ No Clear Signal";
}

void DrawSignalLabel(string msg)
{
   ObjectDelete(0, signalLabel);

   color txtColor = clrYellow;
   if (StringFind(msg, "Buy") >= 0)
      txtColor = BullColor;
   else if (StringFind(msg, "Sell") >= 0)
      txtColor = BearColor;

   ObjectCreate(0, signalLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, signalLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, signalLabel, OBJPROP_XDISTANCE, XDISTANCE);
   ObjectSetInteger(0, signalLabel, OBJPROP_YDISTANCE, YDISTANCE);
   ObjectSetInteger(0, signalLabel, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, signalLabel, OBJPROP_COLOR, txtColor);
   ObjectSetString(0, signalLabel, OBJPROP_TEXT, "Next Candle: " + msg);
}

double GetHTFRSI()
{
   double rsiVal[1];
   int copied = CopyBuffer(rsiHandle, 0, 0, 1, rsiVal);
   if (copied > 0)
      return rsiVal[0];
   else
      return -1;  // Default value if RSI is not loaded
}

void AlertIfNeeded()
{
   static datetime lastAlertTime = 0;
   string prediction = GetNextCandlePrediction();

   // শুধুমাত্র Strong Buy বা Strong Sell হলে এলার্ট
   if ((StringFind(prediction, "Strong Buy") >= 0 || StringFind(prediction, "Strong Sell") >= 0) && 
       TimeLocal() - lastAlertTime >= 3) // ৩ সেকেন্ড পরপর এলার্ট
   {
      lastAlertTime = TimeLocal();
      string alertMsg = "Next Candle: " + prediction;
      MessageBox(alertMsg, "Signal Alert", MB_ICONINFORMATION);
   }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}