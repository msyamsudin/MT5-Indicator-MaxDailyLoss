//+------------------------------------------------------------------+
//| MaxDailyLoss.mq5                                                 |
//| Copyright 2026, Syam                                             |
//| Version 4.04                                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Syam"
#property link      ""
#property version   "4.04"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrNONE

//--- Inputs
input double MaxLossPercent   = 4.0;     // Max Daily Loss (%)
input bool   UseFixedBalance  = true;    // true = pakai balance statis
input double FixedBalance     = 10000.0; // Balance tetap (USD)
input bool   ShowDaysSinceLast= true;    // Tampilkan jumlah hari dari terakhir trade
input color  TextColor        = clrWhite;
input color  PanelBGColor     = clrBlack;
input int    PanelWidth       = 260;     // Diperlebar untuk margin info
input int    PanelHeight      = 225;     // Diperbesar
input int    Corner           = CORNER_LEFT_UPPER;
input int    XDistance        = 10;
input int    YDistance        = 10;
input int    FontSize         = 10;
input string Font             = "Consolas";

//--- Object names
string DragArea         = "MaxLoss_DragArea";
string LabelLastTrade   = "MaxLoss_Lbl_LastTrade";
string LabelLastVal     = "MaxLoss_Lbl_LastVal";
string LabelAllowed     = "MaxLoss_Lbl_Allowed";
string LabelAllowedVal  = "MaxLoss_Lbl_AllowedVal";
string LabelPL          = "MaxLoss_Lbl_PL";
string LabelPLVal       = "MaxLoss_Lbl_PLVal";
string LabelRem         = "MaxLoss_Lbl_Remaining";
string LabelRemVal      = "MaxLoss_Lbl_RemVal";
string LabelPerc        = "MaxLoss_Lbl_Percent";

//--- Margin Usage Labels
string LabelMarginTitle = "MaxLoss_Lbl_MarginTitle";
string LabelUsage       = "MaxLoss_Lbl_Usage";
string LabelUsageVal    = "MaxLoss_Lbl_UsageVal";
string LabelLevel       = "MaxLoss_Lbl_Level";
string LabelLevelVal    = "MaxLoss_Lbl_LevelVal";
string LabelUsed        = "MaxLoss_Lbl_Used";
string LabelUsedVal     = "MaxLoss_Lbl_UsedVal";
string LabelFree        = "MaxLoss_Lbl_Free";
string LabelFreeVal     = "MaxLoss_Lbl_FreeVal";
string LabelLeverage    = "MaxLoss_Lbl_Leverage";

//--- Globals
double StartDailyBalance = 0.0;
datetime CurrentDay = 0;
bool IsDragging = false;
int  DragOffsetX = 0;
int  DragOffsetY = 0;
double DummyBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, DummyBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);

   // Background utama
   CreateRectLabel("MaxLoss_BG", XDistance-8, YDistance-8, PanelWidth+16, PanelHeight+16,
                   PanelBGColor, BORDER_FLAT, clrNONE, true);

   // Area drag
   CreateRectLabel(DragArea, XDistance-8, YDistance-8, PanelWidth+16, 24,
                   clrNONE, BORDER_FLAT, clrNONE, false);

   // Content labels
   int y = 12;
   if(ShowDaysSinceLast)
     {
      CreateLabel(LabelLastTrade, "Last Trade :", 10, y, TextColor, FontSize);
      CreateLabel(LabelLastVal, "---", 150, y, TextColor, FontSize);
      y += 22;
     }

   CreateLabel(LabelAllowed, "Max Loss :", 10, y, TextColor, FontSize);
   CreateLabel(LabelAllowedVal,"---", 150, y, TextColor, FontSize); y += 22;

   CreateLabel(LabelPL, "P/L :", 10, y, TextColor, FontSize);
   CreateLabel(LabelPLVal, "---", 150, y, TextColor, FontSize); y += 22;

   CreateLabel(LabelRem, "Remaining :", 10, y, clrLime, FontSize+1);
   CreateLabel(LabelRemVal, "---", 150, y, clrLime, FontSize+1);
   CreateLabel(LabelPerc, "---", 235, y, clrLime, FontSize); y += 26;

   // === Margin Usage Section ===
   CreateLabel(LabelMarginTitle, "=== MARGIN USAGE ===", 10, y, clrAqua, FontSize); y += 22;
   CreateLabel(LabelUsage, "Margin Usage :", 10, y, TextColor, FontSize);
   CreateLabel(LabelUsageVal, "---", 150, y, clrWhite, FontSize); y += 20;

   CreateLabel(LabelLevel, "Margin Level :", 10, y, TextColor, FontSize);
   CreateLabel(LabelLevelVal, "---", 150, y, clrWhite, FontSize); y += 20;

   CreateLabel(LabelUsed, "Used Margin :", 10, y, TextColor, FontSize);
   CreateLabel(LabelUsedVal, "---", 150, y, clrWhite, FontSize); y += 20;

   CreateLabel(LabelFree, "Free Margin :", 10, y, TextColor, FontSize);
   CreateLabel(LabelFreeVal, "---", 150, y, clrWhite, FontSize); y += 20;

   CreateLabel(LabelLeverage, "Leverage : ---", 10, y, TextColor, FontSize);

   ChartRedraw();
   ResetDailyBalance();
   CurrentDay = TimeCurrent() / 86400 * 86400;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   int total = ObjectsTotal(ChartID(), 0, -1);
   for(int i = total-1; i >= 0; i--)
     {
      string name = ObjectName(ChartID(), i);
      if(StringFind(name, "MaxLoss_") == 0)
         ObjectDelete(ChartID(), name);
     }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Create Rectangle Label                                           |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int x, int y, int w, int h, color bg, ENUM_BORDER_TYPE border, color brdclr, bool back=false)
  {
   ObjectCreate(ChartID(), name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(), name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(ChartID(), name, OBJPROP_XSIZE, w);
   ObjectSetInteger(ChartID(), name, OBJPROP_YSIZE, h);
   ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrNONE);
   ObjectSetInteger(ChartID(), name, OBJPROP_BACK, back);
   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(ChartID(), name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//| Create Label                                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int relx, int rely, color clr, int size=10, string font="Consolas")
  {
   ObjectCreate(ChartID(), name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(), name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, XDistance + relx);
   ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, YDistance + rely);
   ObjectSetString (ChartID(), name, OBJPROP_TEXT, text);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, size);
   ObjectSetString (ChartID(), name, OBJPROP_FONT, font);
   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Move all objects (drag)                                          |
//+------------------------------------------------------------------+
void MoveAllObjects(int dx, int dy)
  {
   string prefix[] = {"MaxLoss_BG", DragArea,
                      LabelLastTrade, LabelLastVal,
                      LabelAllowed, LabelAllowedVal,
                      LabelPL, LabelPLVal,
                      LabelRem, LabelRemVal, LabelPerc,
                      LabelMarginTitle, LabelUsage, LabelUsageVal,
                      LabelLevel, LabelLevelVal, LabelUsed, LabelUsedVal,
                      LabelFree, LabelFreeVal, LabelLeverage};

   for(int i = 0; i < ArraySize(prefix); i++)
     {
      if(ObjectFind(ChartID(), prefix[i]) < 0) continue;
      long x = ObjectGetInteger(ChartID(), prefix[i], OBJPROP_XDISTANCE);
      long y = ObjectGetInteger(ChartID(), prefix[i], OBJPROP_YDISTANCE);
      ObjectSetInteger(ChartID(), prefix[i], OBJPROP_XDISTANCE, x + dx);
      ObjectSetInteger(ChartID(), prefix[i], OBJPROP_YDISTANCE, y + dy);
     }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Chart events (drag support)                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == DragArea)
     {
      DragOffsetX = (int)lparam - (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_XDISTANCE);
      DragOffsetY = (int)dparam - (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_YDISTANCE);
      IsDragging = true;
     }
   else if(id == CHARTEVENT_MOUSE_MOVE && IsDragging)
     {
      if((lparam & 1) == 0) { IsDragging = false; return; }
    
      int newX = (int)lparam - DragOffsetX;
      int newY = (int)dparam - DragOffsetY;
      int currX = (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_XDISTANCE);
      int currY = (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_YDISTANCE);
      MoveAllObjects(newX - currX, newY - currY);
     }
  }

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
//+------------------------------------------------------------------+
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
   datetime today = TimeCurrent() / 86400 * 86400;
   if(today != CurrentDay)
     {
      ResetDailyBalance();
      CurrentDay = today;
     }

   double closedPL     = CalculateDailyPL();
   double floatingPL   = AccountInfoDouble(ACCOUNT_PROFIT);
   double dailyPL      = closedPL + floatingPL;
   double maxLoss      = StartDailyBalance * (MaxLossPercent / 100.0);
   double currentLoss  = (dailyPL < 0) ? -dailyPL : 0.0;
   double remaining    = MathMax(maxLoss - currentLoss, 0.0);
   double percentRem   = (maxLoss > 0) ? remaining / maxLoss * 100.0 : 0.0;

   color remColor = (percentRem > 70) ? clrLimeGreen :
                    (percentRem > 30) ? clrYellow :
                    (percentRem > 0)  ? clrOrange : clrRed;
   color plColor  = (dailyPL >= 0) ? clrLime : clrRed;

   // Update Daily Loss Labels
   ObjectSetString(ChartID(), LabelAllowedVal, OBJPROP_TEXT, StringFormat("%.2f", maxLoss));
   ObjectSetString(ChartID(), LabelPLVal, OBJPROP_TEXT, StringFormat("%.2f", dailyPL));
   ObjectSetString(ChartID(), LabelRemVal, OBJPROP_TEXT, StringFormat("%.2f", remaining));
   ObjectSetString(ChartID(), LabelPerc, OBJPROP_TEXT, StringFormat("(%.1f%%)", percentRem));

   ObjectSetInteger(ChartID(), LabelPLVal, OBJPROP_COLOR, plColor);
   ObjectSetInteger(ChartID(), LabelRem, OBJPROP_COLOR, remColor);
   ObjectSetInteger(ChartID(), LabelRemVal, OBJPROP_COLOR, remColor);
   ObjectSetInteger(ChartID(), LabelPerc, OBJPROP_COLOR, remColor);

   // Update Last Trade
   if(ShowDaysSinceLast && ObjectFind(ChartID(), LabelLastVal) >= 0)
     {
      int days = DaysSinceLastTrade();
      string text = (days == 0) ? "Today" : StringFormat("%d days", days);
      ObjectSetString(ChartID(), LabelLastVal, OBJPROP_TEXT, text);
     }

   // === Margin Usage Section ===
   double equity       = AccountInfoDouble(ACCOUNT_EQUITY);
   double used_margin  = AccountInfoDouble(ACCOUNT_MARGIN);
   double free_margin  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   long   leverage     = AccountInfoInteger(ACCOUNT_LEVERAGE);

   double margin_usage = (equity > 0 && used_margin > 0) ? (used_margin / equity) * 100.0 : 0.0;

   color usageColor = (margin_usage <= 30) ? clrLime :
                      (margin_usage <= 50) ? clrYellow : clrRed;

   ObjectSetString(ChartID(), LabelUsageVal,  OBJPROP_TEXT, StringFormat("%.1f%%", margin_usage));
   ObjectSetString(ChartID(), LabelLevelVal,  OBJPROP_TEXT, StringFormat("%.1f%%", margin_level));
   ObjectSetString(ChartID(), LabelUsedVal,   OBJPROP_TEXT, StringFormat("%.2f", used_margin));
   ObjectSetString(ChartID(), LabelFreeVal,   OBJPROP_TEXT, StringFormat("%.2f", free_margin));
   ObjectSetString(ChartID(), LabelLeverage,  OBJPROP_TEXT, StringFormat("Leverage : 1:%d", leverage));

   ObjectSetInteger(ChartID(), LabelUsageVal, OBJPROP_COLOR, usageColor);

   if(margin_usage > 50)
      ObjectSetString(ChartID(), LabelUsageVal, OBJPROP_TEXT, StringFormat("%.1f%% ⚠️", margin_usage));

   DummyBuffer[0] = 0.0;
   ChartRedraw(ChartID());
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Hitung jumlah hari sejak trade terakhir ditutup                  |
//+------------------------------------------------------------------+
int DaysSinceLastTrade()
  {
   datetime lastCloseTime = 0;
   if(!HistorySelect(0, TimeCurrent() + 86400)) return 0;
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         lastCloseTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         break;
        }
     }
   if(lastCloseTime == 0) return 0;
   datetime todayStart = TimeCurrent() / 86400 * 86400;
   long secondsDiff = todayStart - (lastCloseTime / 86400 * 86400);
   return (int)(secondsDiff / 86400);
  }

//+------------------------------------------------------------------+
//| Reset balance                                                    |
//+------------------------------------------------------------------+
void ResetDailyBalance()
  {
   if(UseFixedBalance)
      StartDailyBalance = FixedBalance;
   else
      StartDailyBalance = AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_PROFIT);
  }

//+------------------------------------------------------------------+
//| Hitung closed P/L hari ini                                       |
//+------------------------------------------------------------------+
double CalculateDailyPL()
  {
   double pl = 0.0;
   datetime day_start = CurrentDay;
   if(!HistorySelect(day_start, TimeCurrent() + 86400)) return 0.0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         datetime t = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         if(t >= day_start)
           {
            pl += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            pl += HistoryDealGetDouble(ticket, DEAL_SWAP);
            pl += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
           }
        }
     }
   return pl;
  }
//+------------------------------------------------------------------+
