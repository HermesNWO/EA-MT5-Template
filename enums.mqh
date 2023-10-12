//+------------------------------------------------------------------+
//|                                                        enums.mqh |
//|                                     Copyright 2023, Pedro Varela |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Pedro Varela"
#property link      "https://www.mql5.com"

enum ENUM_EXIT_REASONS{
   exr_take_profit, // TL
   exr_stop_loss,   // SL
   exr_manual_exit  // Manual Exit
};

struct OrdersMaxLossAndProfit
  {
   long             order_ticket;
   double            lowest_price;
   double            highest_price;
   double            lowest_profit;
   double            highest_profit;
};

struct Requests
  {
   string            request;
   bool              executed;
  };