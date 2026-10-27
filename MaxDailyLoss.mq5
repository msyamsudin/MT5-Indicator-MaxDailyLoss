//+------------------------------------------------------------------+
//| MaxDailyLoss.mq5                                                 |
//| Copyright 2026, Syam                                             |
//| Version 5.10 		                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Syam"
#property link      ""
#property version   "5.10"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrNONE
//--- Inputs
input double MaxLossPercent        = 4.0;     // Max Daily Loss (%)
input bool   UseFixedBalance       = true;    // Gunakan balance statis
input double FixedBalance          = 10000.0; // Balance tetap (USD)
input bool   ShowDaysSinceLast     = true;    // Tampilkan Last Trade
enum ENUM_REMAINING_DISPLAY { REMAINING_USD=0, REMAINING_PERCENT=1 };
input ENUM_REMAINING_DISPLAY RemainingDisplay = REMAINING_USD; // Format Remaining
//--- Margin Usage Settings
input double MaxMarginUsageSafe    = 30.0;    // Batas aman Margin Usage (%) - Hijau
input double MaxMarginUsageWarning = 50.0;    // Batas warning Margin Usage (%) - Kuning
input double CustomMarginRate      = 4.0;     // Margin Rate Override (0 = auto dari broker)
input color  TextColor             = clrWhite;
input color  PanelBGColor          = clrBlack;
input int    PanelWidth            = 290;
input int    PanelHeight           = 320;
input int    Corner                = CORNER_LEFT_UPPER;
input int    XDistance             = 10;
input int    YDistance             = 10;
input int    FontSize              = 10;
input string Font                  = "Consolas";
//--- Object names
string DragArea         = "MaxLoss_DragArea";
string LabelDragStatus  = "MaxLoss_Lbl_DragStatus";
string LabelLastTrade   = "MaxLoss_Lbl_LastTrade";
string LabelLastVal     = "MaxLoss_Lbl_LastVal";
string LabelAllowed     = "MaxLoss_Lbl_Allowed";
string LabelAllowedVal  = "MaxLoss_Lbl_AllowedVal";
string LabelPL          = "MaxLoss_Lbl_PL";
string LabelPLVal       = "MaxLoss_Lbl_PLVal";
string LabelRem         = "MaxLoss_Lbl_Remaining";
string LabelRemVal      = "MaxLoss_Lbl_RemVal";
string LabelPerc        = "MaxLoss_Lbl_Percent";
string LabelHeader      = "MaxLoss_Lbl_Header";
string LabelSubHeader   = "MaxLoss_Lbl_SubHeader";
string LabelRiskTitle   = "MaxLoss_Lbl_RiskTitle";
string RiskBarBG        = "MaxLoss_RiskBarBG";
string RiskBarFill      = "MaxLoss_RiskBarFill";
string LabelLevVal      = "MaxLoss_Lbl_LevVal";
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
ulong LastHeaderClickMs = 0;
int  DoubleClickWindowMs = 450;
int  PanelX = 10;
int  PanelY = 10;
string PositionKeyX = "";
string PositionKeyY = "";
double DummyBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, DummyBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);

   // Restore last dragged position (persistent across MT5 restarts)
   PanelX = XDistance;
   PanelY = YDistance;
   string keyBase = StringFormat("MDL_%I64d_%s", AccountInfoInteger(ACCOUNT_LOGIN), _Symbol);
   PositionKeyX = keyBase + "_X";
   PositionKeyY = keyBase + "_Y";
   if(GlobalVariableCheck(PositionKeyX)) PanelX = (int)GlobalVariableGet(PositionKeyX);
   if(GlobalVariableCheck(PositionKeyY)) PanelY = (int)GlobalVariableGet(PositionKeyY);

   // Enable mouse-move events for custom panel dragging
   ChartSetInteger(ChartID(), CHART_EVENT_MOUSE_MOVE, true);

   // Compact panel and draggable header
   CreateRectLabel("MaxLoss_BG", PanelX, PanelY, PanelWidth, PanelHeight,
                   PanelBGColor, BORDER_FLAT, C'90,100,112', false);
   CreateRectLabel(DragArea, PanelX, PanelY, PanelWidth, 28,
                   clrNONE, BORDER_FLAT, clrNONE, false);
   // The header area must receive clicks; otherwise MT5 pans the chart.
   ObjectSetInteger(ChartID(), DragArea, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(ChartID(), DragArea, OBJPROP_ZORDER, 10);
   CreateLabel(LabelHeader, "RISK", 10, 5, clrWhite, FontSize+2);
   CreateLabel(LabelSubHeader, "|  DAILY & MARGIN", 66, 7, C'130,148,170', FontSize-1);
   // Lock status occupies the former drag-icon position.
   CreateLabel(LabelDragStatus, "LOCKED", PanelWidth-62, 8, C'130,148,170', FontSize-2);

   int y = 38;
   CreateLabel(LabelRiskTitle, "DAILY RISK", 10, y, C'130,148,170', FontSize-1); y += 22;
   if(ShowDaysSinceLast)
     {
      CreateLabel(LabelLastTrade, "Last trade", 10, y, TextColor, FontSize);
      CreateLabel(LabelLastVal, "---", 190, y, TextColor, FontSize); y += 20;
     }
   CreateLabel(LabelAllowed, "Max loss", 10, y, TextColor, FontSize);
   CreateLabel(LabelAllowedVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelPL, "P/L", 10, y, TextColor, FontSize);
   CreateLabel(LabelPLVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelRem, "Remaining", 10, y, TextColor, FontSize);
   CreateLabel(LabelRemVal, "---", 190, y, clrLimeGreen, FontSize);
   // Remaining uses a single value field; no secondary percentage label.
   y += 22;

   CreateRectLabel(RiskBarBG, PanelX+10, PanelY+y, PanelWidth-20, 5,
                   C'43,55,68', BORDER_FLAT, clrNONE, false);
   CreateRectLabel(RiskBarFill, PanelX+10, PanelY+y, PanelWidth-20, 5,
                   clrLimeGreen, BORDER_FLAT, clrNONE, false);
   y += 17;
   CreateRectLabel("MaxLoss_Separator", PanelX+10, PanelY+y, PanelWidth-20, 1,
                   C'38,48,60', BORDER_FLAT, clrNONE, false); y += 12;

   CreateLabel(LabelMarginTitle, "MARGIN", 10, y, C'130,148,170', FontSize-1); y += 22;
   CreateLabel(LabelUsage, "Usage", 10, y, TextColor, FontSize);
   CreateLabel(LabelUsageVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelLevel, "Level", 10, y, TextColor, FontSize);
   CreateLabel(LabelLevelVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelUsed, "Used", 10, y, TextColor, FontSize);
   CreateLabel(LabelUsedVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelFree, "Free", 10, y, TextColor, FontSize);
   CreateLabel(LabelFreeVal, "---", 190, y, clrWhite, FontSize); y += 20;
   CreateLabel(LabelLeverage, "Leverage", 10, y, TextColor, FontSize);
   CreateLabel(LabelLevVal, "---", 190, y, clrWhite, FontSize);

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
   ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_TYPE, border);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, brdclr);
   ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 1);
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
   ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, PanelX + relx);
   ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, PanelY + rely);
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
   string prefix[] = {
      "MaxLoss_BG", DragArea, LabelDragStatus,
      LabelHeader, LabelSubHeader, LabelRiskTitle,
      LabelLastTrade, LabelLastVal, LabelAllowed, LabelAllowedVal,
      LabelPL, LabelPLVal, LabelRem, LabelRemVal,
      RiskBarBG, RiskBarFill, "MaxLoss_Separator",
      LabelMarginTitle, LabelUsage, LabelUsageVal,
      LabelLevel, LabelLevelVal, LabelUsed, LabelUsedVal,
      LabelFree, LabelFreeVal, LabelLeverage, LabelLevVal
   };
   
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
      // While floating, one click on the header locks the panel in place.
      if(IsDragging)
        {
         IsDragging = false;
         ObjectSetString(ChartID(), LabelDragStatus, OBJPROP_TEXT, "LOCKED");
         ObjectSetInteger(ChartID(), LabelDragStatus, OBJPROP_COLOR, C'130,148,170');
         LastHeaderClickMs = 0;
         ChartRedraw();
         return;
        }

      // A double-click enables cursor-follow mode. A single click only arms
      // the double-click detector and does not move the panel.
      ulong now = GetTickCount64();
      if(LastHeaderClickMs > 0 && now - LastHeaderClickMs <= (ulong)DoubleClickWindowMs)
        {
         DragOffsetX = (int)lparam - (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_XDISTANCE);
         DragOffsetY = (int)dparam - (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_YDISTANCE);
         IsDragging = true;
         ObjectSetString(ChartID(), LabelDragStatus, OBJPROP_TEXT, "MOVING");
         ObjectSetInteger(ChartID(), LabelDragStatus, OBJPROP_COLOR, clrLimeGreen);
         LastHeaderClickMs = 0;
         ChartRedraw();
        }
      else
        {
         LastHeaderClickMs = now;
        }
     }
   else if(id == CHARTEVENT_MOUSE_MOVE && IsDragging)
     {
      // Follow the cursor without requiring the mouse button to remain held.
      int newX = (int)lparam - DragOffsetX;
      int newY = (int)dparam - DragOffsetY;
      int currX = (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_XDISTANCE);
      int currY = (int)ObjectGetInteger(ChartID(), DragArea, OBJPROP_YDISTANCE);
      if(newX != currX || newY != currY)
        {
         MoveAllObjects(newX - currX, newY - currY);
         PanelX = newX;
         PanelY = newY;
         if(PositionKeyX != "") GlobalVariableSet(PositionKeyX, PanelX);
         if(PositionKeyY != "") GlobalVariableSet(PositionKeyY, PanelY);
        }
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
     
   // Daily Loss Calculation
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
   // Show exactly one Remaining format. Do not create/update a secondary label,
   // which can otherwise display MT5's default "Label" text when empty.
   if(RemainingDisplay == REMAINING_USD)
      ObjectSetString(ChartID(), LabelRemVal, OBJPROP_TEXT, DoubleToString(remaining, 2));
   else
      ObjectSetString(ChartID(), LabelRemVal, OBJPROP_TEXT, StringFormat("%.1f%%", percentRem));
   ObjectSetInteger(ChartID(), LabelPLVal, OBJPROP_COLOR, plColor);
   ObjectSetInteger(ChartID(), LabelRem, OBJPROP_COLOR, remColor);
   ObjectSetInteger(ChartID(), LabelRemVal, OBJPROP_COLOR, remColor);
   int barWidth = (int)MathRound((PanelWidth-20) * MathMax(0.0, MathMin(100.0, percentRem)) / 100.0);
   ObjectSetInteger(ChartID(), RiskBarFill, OBJPROP_XSIZE, MathMax(1, barWidth));
   ObjectSetInteger(ChartID(), RiskBarFill, OBJPROP_BGCOLOR, remColor);
   ObjectSetInteger(ChartID(), RiskBarFill, OBJPROP_COLOR, remColor);
   
   if(ShowDaysSinceLast && ObjectFind(ChartID(), LabelLastVal) >= 0)
     {
      int days = DaysSinceLastTrade();
      string text = (days == 0) ? "Today" : StringFormat("%d days", days);
      ObjectSetString(ChartID(), LabelLastVal, OBJPROP_TEXT, text);
     }
     
   // === Margin Usage Calculation ===
   double equity       = AccountInfoDouble(ACCOUNT_EQUITY);
   double used_margin  = AccountInfoDouble(ACCOUNT_MARGIN);
   double free_margin  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   double margin_usage = (equity > 0 && used_margin > 0) ? (used_margin / equity) * 100.0 : 0.0;
   
   color usageColor = (margin_usage <= MaxMarginUsageSafe) ? clrLime :
                      (margin_usage <= MaxMarginUsageWarning) ? clrYellow : clrRed;
                      
   // Update dengan format yang lebih rapi
   ObjectSetString(ChartID(), LabelUsageVal,  OBJPROP_TEXT, StringFormat("%.1f%%", margin_usage));
   ObjectSetString(ChartID(), LabelLevelVal,  OBJPROP_TEXT, StringFormat("%.1f%%", margin_level));
   ObjectSetString(ChartID(), LabelUsedVal,   OBJPROP_TEXT, StringFormat("%.2f", used_margin));
   ObjectSetString(ChartID(), LabelFreeVal,   OBJPROP_TEXT, StringFormat("%.2f", free_margin));
   ObjectSetInteger(ChartID(), LabelUsageVal, OBJPROP_COLOR, usageColor);
   
   
   // ======================== LEVERAGE EFEKTIF ========================
   long accountLev = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   double initRate = 0.0, maintRate = 0.0;
   SymbolInfoMarginRate(_Symbol, ORDER_TYPE_BUY, initRate, maintRate);
   
   double usedRate = (CustomMarginRate > 0.0) ? CustomMarginRate : initRate;
   if(usedRate <= 0.0) usedRate = 1.0;
   
   double effLev = NormalizeDouble((double)accountLev / usedRate, 2);
   
   ObjectSetString(ChartID(), LabelLevVal, OBJPROP_TEXT, StringFormat("1:%.2f", effLev));
   // ==================================================================
   
   DummyBuffer[0] = 0.0;
   ChartRedraw(ChartID());
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Hitung jumlah hari sejak trade terakhir                          |
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
