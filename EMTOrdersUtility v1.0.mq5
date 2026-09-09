//+------------------------------------------------------------------+
//|                                           EMTOrdersUtility.mq5   |
//|                                  Copyright 2026, Urayayi Kwinika |
//+------------------------------------------------------------------+

#property copyright "Copyright 2026, Urayayi Kwinika"
#property version   "1.0"
#property description "Trading Orders Utility"
#property indicator_chart_window
#property indicator_plots 0  // Resolves: "no indicator plot defined for indicator"
#property strict

//+------------------------------------------------------------------+
//| Parameters                                                       |
//+------------------------------------------------------------------+
enum ENUM_SHOW_TYPE
{
   SHOW_FOLLOW_PRICE = 0,   
   // Follow the price: Display text dynamically aligned with current price
   SHOW_AS_COMMENT   = 1,   
   // As comment: Show information in chart comment section
   SHOW_IN_CORNER    = 2    
   // In selected corner of the screen: Fixed position in a chart corner
};

enum ENUM_SEPARATOR
{
   SEP_VERTICAL_BAR = 124,  // | (vertical bar)
   SEP_FORWARD_SLASH = 47,  // / (forward slash)
   SEP_DOT          = 46,   // . (dot)
   SEP_BACKSLASH    = 92,   // \ (backslash)
   SEP_HASH         = 35    // # (hash)
};

// External parameters for customization
input ENUM_SHOW_TYPE show_type    = SHOW_IN_CORNER;     
// Defines how information is displayed
input ENUM_BASE_CORNER corner  = CORNER_RIGHT_LOWER; 
// Specifies chart corner for fixed display (Corrected enum)
input bool    show_profit         = true;               
// Toggle to display profit in account currency
input bool    show_perc           = false;              
// Toggle to display profit as a percentage
input bool    show_spread         = false;              
// Toggle to display current spread
input bool    show_time           = false;              
// Toggle to display time remaining until current bar closes
input color   colortext           = clrDodgerBlue;      
// Default text color for neutral values
input color   ecProfit            = clrLimeGreen;       
// Color for positive profit values
input color   ecLoss              = clrOrangeRed;       
// Color for negative profit values
input ENUM_SEPARATOR separator    = SEP_VERTICAL_BAR;   
// Character separating data fields
input int     coord_y             = 25;                 
// Vertical (Y) coordinate for fixed display in pixels
input int     indent              = 5;                 
// Horizontal offset in bars for price-following mode
input int     text_size           = 9;                  
// Font size for displayed text
input string  text_font           = "Tahoma";           
// Font type for displayed text

// Global variables
string name_1 = "EMT_UKwi";          // Identifier for main text object
string name_2 = "EMT_OrdersUtility"; // Identifier for order count label
string text_1 = "";                  // String to hold main display text
double n      = 1.0;                 // Scaling factor for pip calculations

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(_Digits == 3 || _Digits == 5) n *= 10;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   ObjectDelete(0, name_1);
   ObjectDelete(0, name_2);
}

//+------------------------------------------------------------------+
//| Function to count active orders                                  |
//+------------------------------------------------------------------+
void GetOrderCounts(int &long_count, int &sell_count, int &pending_count)
{
   long_count = 0;
   sell_count = 0;
   pending_count = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            int type = (int)PositionGetInteger(POSITION_TYPE);
            if(type == POSITION_TYPE_BUY) long_count++;
            else if(type == POSITION_TYPE_SELL) sell_count++;
         }
      }
   }

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(OrderGetTicket(i)))
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol)
         {
            int type = (int)OrderGetInteger(ORDER_TYPE);
            if(type >= ORDER_TYPE_BUY_LIMIT && type <= ORDER_TYPE_SELL_STOP)
               pending_count++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   double tu = 0.0, tp = 0.0, tr = 0.0;
   double sp = 0.0; // Initialize spread
   long spread_value = 0;
   bool spreadSuccess = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD, spread_value); // Corrected to SymbolInfoInteger
   if(spreadSuccess) sp = (double)spread_value / 10.0; // Convert points to pips
   string _sp = "", _m = "", _s = "";
   string sep = " " + CharToString((char)separator) + " ";

   if(AccountInfoDouble(ACCOUNT_BALANCE) == 0.0) // Corrected AccountBalance to AccountInfoDouble
   {
      text_1 = "";
   }
   else
   {
      tu = GetProfitOpenPosInPoint();
      tp = GetProfitOpenPos();
      tr = tp * 100.0 / AccountInfoDouble(ACCOUNT_BALANCE); // Corrected here
      text_1 = StringFormat("%.1f pips", tu);

      if(show_profit) text_1 += sep + StringFormat("%.2f %s", tp, AccountInfoString(ACCOUNT_CURRENCY));
      if(show_perc)   text_1 += sep + StringFormat("%.1f%%", tr);
   }

   int m = (int)(time[0] + PeriodSeconds() - TimeCurrent());
   int s = m % 60;
   m = (m - s) / 60;
   if(m < 10) _m = "0";
   if(s < 10) _s = "0";
   if(sp < 10) _sp = "..";
   else if(sp < 100) _sp = ".";

   if(show_spread)
   {
      if(AccountInfoDouble(ACCOUNT_BALANCE) == 0.0) // Corrected here
         text_1 += StringFormat("%.0f%s", sp, _sp);
      else
         text_1 += sep + StringFormat("%.0f%s", sp, _sp);
   }

   if(show_time)
   {
      if(AccountInfoDouble(ACCOUNT_BALANCE) == 0.0 && !show_spread) // Corrected here
         text_1 += StringFormat("%s%d:%s%d", _m, m, _s, s);
      else
         text_1 += sep + StringFormat("%s%d:%s%d", _m, m, _s, s);
   }

   int long_count, sell_count, pending_count;
   GetOrderCounts(long_count, sell_count, pending_count);
   string order_text = StringFormat("Long: %d    Sell: %d    Pending: %d", long_count, sell_count, pending_count);

   if(show_type == SHOW_IN_CORNER)
   {
      SetLabel(name_2, order_text, colortext, 3, coord_y + 20, corner, text_size);
   }

   if(show_type == SHOW_FOLLOW_PRICE)
   {
      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      SetText(name_1, text_1, ColorOnSign(tp), TimeCurrent(), bidPrice, text_size);
   }
   else if(show_type == SHOW_AS_COMMENT)
      Comment(text_1);
   else if(show_type == SHOW_IN_CORNER)
      SetLabel(name_1, text_1, ColorOnSign(tp), 3, coord_y, corner, text_size);

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate profit of open positions in account currency           |
//+------------------------------------------------------------------+
double GetProfitOpenPos(int mn = -1)
{
   double pr = 0.0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            if(mn < 0 || PositionGetInteger(POSITION_MAGIC) == mn)
            {
               pr += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            }
         }
      }
   }
   return(pr);
}

//+------------------------------------------------------------------+
//| Calculate profit of open positions in pips                       |
//+------------------------------------------------------------------+
double GetProfitOpenPosInPoint(int op = -1, int mn = -1)
{
   double pr = 0.0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            if((op < 0 || PositionGetInteger(POSITION_TYPE) == op) && (mn < 0 || PositionGetInteger(POSITION_MAGIC) == mn))
            {
               double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
               double lots = PositionGetDouble(POSITION_VOLUME);
               pr += (PositionGetDouble(POSITION_PROFIT) / lots / tick_value) / n;
            }
         }
      }
   }
   return(pr);
}

//+------------------------------------------------------------------+
//| Set text object on chart                                         |
//+------------------------------------------------------------------+
bool SetText(string nm, string tx, color cl, datetime time, double price, int fs)
{
   time += indent * PeriodSeconds();
   if(!ObjectCreate(0, nm, OBJ_TEXT, 0, time, price))
   {
      ObjectMove(0, nm, 0, time, price);
   }

   ObjectSetString(0, nm, OBJPROP_TEXT, tx);
   ObjectSetString(0, nm, OBJPROP_FONT, text_font);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, cl);
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm, OBJPROP_BACK, false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);

   return(true);
}

//+------------------------------------------------------------------+
//| Set label object on chart                                        |
//+------------------------------------------------------------------+
void SetLabel(string nm, string tx, color cl, int xd, int yd, ENUM_BASE_CORNER cr, int fs) // Corrected parameter type
{
   if(!ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, xd);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, yd);
   }

   ObjectSetString(0, nm, OBJPROP_TEXT, tx);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, cl);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, xd);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, yd);
   ObjectSetInteger(0, nm, OBJPROP_CORNER, cr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);

   if(cr == CORNER_RIGHT_UPPER || cr == CORNER_RIGHT_LOWER)
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR, ANCHOR_RIGHT);
}

//+------------------------------------------------------------------+
//| Returns the color based on the sign of a number                  |
//+------------------------------------------------------------------+
color ColorOnSign(double nu)
{
   if(nu > 0) return ecProfit;
   if(nu < 0) return ecLoss;
   return colortext;
}
//+------------------------------------------------------------------+End of Program