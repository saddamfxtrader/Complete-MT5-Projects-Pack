#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrRed

double dummyBuffer[];

input int    XDISTANCE    = 10;
input int    YDISTANCE    = 30;
input int    FontSize     = 12;
input int    MaxCandles   = 50;
input int    RSIPeriod    = 2;
input color  BullColor    = clrLime;
input color  BearColor    = clrRed;
input ENUM_TIMEFRAMES HTF = PERIOD_M5;

string signalLabel = "NextMovePrediction";
datetime lastBarTime = 0;
int rsiHandle = INVALID_HANDLE;

int OnInit()
{
   SetIndexBuffer(0, dummyBuffer);
   rsiHandle = iRSI(_Symbol, HTF, RSIPeriod, PRICE_CLOSE);
   if (rsiHandle == INVALID_HANDLE)
      return INIT_FAILED;

   EventSetMillisecondTimer(200); // প্রতি ২০০ms-এ চেক
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, signalLabel);
   if (rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rsiHandle);
}

void OnTimer()
{
   datetime currentTime = TimeCurrent(); // সার্ভারের বর্তমান সময়
   int currentSecond = (int)currentTime % 60; // সেকেন্ড বের করা
   int secondsToClose = 60 - currentSecond; // বর্তমান M1 ক্যান্ডেলের ক্লোজ পর্যন্ত বাকি সেকেন্ড

   // ক্যান্ডেল ক্লোজের ৫ সেকেন্ড আগে চেক করা
   if (secondsToClose == 5)
   {
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
   bool volSpike  = (volCurrent > 1.2 * volAvg); // থ্রেশহোল্ড কমানো

   double rsiVal = GetHTFRSI();
   if (rsiVal < 0) return "⏳ RSI loading...";

   bool htfBull = rsiVal > 50;
   bool htfBear = rsiVal < 50;

   // শক্তিশালী সিগনাল
   if (sweepDown && volSpike && htfBull)
      return "✅ Bullish Setup";
   else if (sweepUp && volSpike && htfBear)
      return "🔻 Bearish Setup";

   // দুর্বল সিগনাল
   if (!sweepDown && !sweepUp && !volSpike)
   {
      if (htfBull)
         return "📈 Weak Bullish Signal";
      else if (htfBear)
         return "📉 Weak Bearish Signal";
   }

   return "⏳ No Clear Signal";
}

void DrawSignalLabel(string msg)
{
   ObjectDelete(0, signalLabel);

   color txtColor = clrWhite;
   if (StringFind(msg, "Bullish") >= 0)
      txtColor = BullColor;
   else if (StringFind(msg, "Bearish") >= 0)
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
   if (CopyBuffer(rsiHandle, 0, 0, 1, rsiVal) > 0)
      return rsiVal[0];
   return 50; // ডিফল্ট মান
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