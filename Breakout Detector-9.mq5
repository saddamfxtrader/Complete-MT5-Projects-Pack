#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_NONE

input int MaxCandles = 300;
input int MACD_Fast = 3;
input int MACD_Slow = 8;
input int MACD_Signal = 2;
input int RSI_Period = 5;
input int Stoch_K = 3;
input int Stoch_D = 2;
input int Stoch_Slowing = 2;
input int ArrowCode_Buy = 233;
input int ArrowCode_Sell = 234;
input int ArrowSize = 3;
input color ArrowColorBuy = clrLime;
input color ArrowColorSell = clrRed;

double dummyBuffer[];
datetime lastSignalTime = 0;
int lastSignalType = 0; // 1 for Buy, -1 for Sell, 0 for none

int macdLTF, rsiLTF, stochLTF;

int OnInit()
{
    SetIndexBuffer(0, dummyBuffer);

    macdLTF = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    rsiLTF = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    stochLTF = iStochastic(_Symbol, PERIOD_CURRENT, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, STO_CLOSECLOSE);

    if (macdLTF == INVALID_HANDLE || rsiLTF == INVALID_HANDLE || stochLTF == INVALID_HANDLE)
    {
        Print("❌ Indicator handle creation failed.");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
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
    if (rates_total < 10) return 0;

    int bar = rates_total - 2;

    double macdMain[], macdSignal[], rsiArr[], stochK[], stochD[];

    if (CopyBuffer(macdLTF, 0, 0, rates_total, macdMain) <= 0) return 0;
    if (CopyBuffer(macdLTF, 1, 0, rates_total, macdSignal) <= 0) return 0;
    if (CopyBuffer(rsiLTF, 0, 0, rates_total, rsiArr) <= 0) return 0;
    if (CopyBuffer(stochLTF, 0, 0, rates_total, stochK) <= 0) return 0;
    if (CopyBuffer(stochLTF, 1, 0, rates_total, stochD) <= 0) return 0;

    if (bar >= ArraySize(macdMain)) return 0;

    bool buy = (macdMain[bar] > macdSignal[bar]) &&
               (rsiArr[bar] > 50) &&
               (stochK[bar] > 50);

    bool sell = (macdMain[bar] < macdSignal[bar]) &&
                (rsiArr[bar] < 50) &&
                (stochK[bar] < 50);

    datetime sigTime = time[bar];
    string arrowBuyName = "BuyArrow_" + IntegerToString(sigTime);
    string arrowSellName = "SellArrow_" + IntegerToString(sigTime);

    // Buy Signal
    if (buy && lastSignalType != 1) // Ensure no same-direction signal multiple times
    {
        if (lastSignalType == -1) // If previous was Sell, delete Sell arrow
        {
            ObjectDelete(0, "SellArrow_Last");
        }

        // Delete any existing Buy signal
        ObjectDelete(0, "BuyArrow_Last");

        double y = low[bar] - (high[bar] - low[bar]) * 0.5;

        if (!ObjectCreate(0, "BuyArrow_Last", OBJ_ARROW, 0, sigTime, y))
            Print("❌ Failed to create Buy Arrow");

        ObjectSetInteger(0, "BuyArrow_Last", OBJPROP_ARROWCODE, ArrowCode_Buy);
        ObjectSetInteger(0, "BuyArrow_Last", OBJPROP_COLOR, ArrowColorBuy);
        ObjectSetInteger(0, "BuyArrow_Last", OBJPROP_WIDTH, ArrowSize);

        lastSignalTime = sigTime;
        lastSignalType = 1; // Set last signal type to Buy
    }
    // Sell Signal
    else if (sell && lastSignalType != -1) // Ensure no same-direction signal multiple times
    {
        if (lastSignalType == 1) // If previous was Buy, delete Buy arrow
        {
            ObjectDelete(0, "BuyArrow_Last");
        }

        // Delete any existing Sell signal
        ObjectDelete(0, "SellArrow_Last");

        double y = high[bar] + (high[bar] - low[bar]) * 0.5;

        if (!ObjectCreate(0, "SellArrow_Last", OBJ_ARROW, 0, sigTime, y))
            Print("❌ Failed to create Sell Arrow");

        ObjectSetInteger(0, "SellArrow_Last", OBJPROP_ARROWCODE, ArrowCode_Sell);
        ObjectSetInteger(0, "SellArrow_Last", OBJPROP_COLOR, ArrowColorSell);
        ObjectSetInteger(0, "SellArrow_Last", OBJPROP_WIDTH, ArrowSize);

        lastSignalTime = sigTime;
        lastSignalType = -1; // Set last signal type to Sell
    }

    return rates_total;
}
