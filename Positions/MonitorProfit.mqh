//+------------------------------------------------------------------+
//|                                                MonitorProfit.mqh |
//|                                     Copyright 2023, Pedro Varela |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Pedro Varela"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../enums.mqh"
#include "../GlobalVariables.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MonitorProfit
  {
private:
   bool              print_journal_messages;
   int timer_to_update ;
   datetime          last_update_datetime;

public:
   OrdersMaxLossAndProfit myOrders[];

   void              MonitorProfit(bool print_journal_messages_, int timer_to_update_in_seconds)
     {
      this.print_journal_messages = print_journal_messages_;
      this.timer_to_update = timer_to_update_in_seconds;
     }

   void              ExecuteMainWithTimer()
     {
      if(TimeCurrent() - last_update_datetime > timer_to_update)
        {
         RunProcess();
        }
     }

   void              RunProcess()
     {
      last_update_datetime = TimeCurrent();
     
      for(int i = 0; i <= PositionsTotal() - 1; i++)
        {
         ulong ticket = PositionGetTicket(i);
         bool ticket_found_on_my_array = false;

         for(int n = 0; n < ArraySize(myOrders); n++)
           {
            if(myOrders[n].order_ticket == ticket)
              {
               // here develop logic to update ticket data
               double price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
               double profit_current = PositionGetDouble(POSITION_PROFIT);

               if(myOrders[n].highest_price < price_current)
                 {
                  myOrders[n].highest_price = price_current;
                 }

               if(myOrders[n].lowest_price > price_current)
                 {
                  myOrders[n].lowest_price = price_current;
                 }

               if(myOrders[n].highest_profit < profit_current)
                 {
                  myOrders[n].highest_profit = profit_current;
                 }

               if(myOrders[n].lowest_profit > profit_current)
                 {
                  myOrders[n].lowest_profit = profit_current;
                 }

               ticket_found_on_my_array = true;

               if(print_journal_messages)
                 {
                  Print("Ticket Update: ", myOrders[n].order_ticket, " | Lowest Price: ", myOrders[n].lowest_price, " | Highest Price: ", myOrders[n].highest_price, " | Max Loss: ", myOrders[n].lowest_profit, " | Max Profit: ", myOrders[n].highest_profit);

                 }
              }
           }

         if(!ticket_found_on_my_array)
           {
            OrdersMaxLossAndProfit o;

            o.order_ticket = ticket;
            o.highest_price = PositionGetDouble(POSITION_PRICE_CURRENT);
            o.lowest_price = PositionGetDouble(POSITION_PRICE_CURRENT);
            o.lowest_profit = PositionGetDouble(POSITION_PROFIT);
            o.highest_profit = PositionGetDouble(POSITION_PROFIT);

            ArrayResize(myOrders, ArraySize(myOrders) + 1);
            myOrders[ArraySize(myOrders) - 1] = o;

            if(print_journal_messages)
              {
               Print("New Ticket created: ", o.order_ticket, " | Lowest Price: ", o.lowest_price, " | Highest Price: ", o.highest_price, " | Max Loss: ", o.lowest_profit, " | Max Profit: ", o.highest_profit);
              }
           }
        }
        
        ArrayCopy(ordersMaxLossAndProfit, myOrders);
     }


  };

//+------------------------------------------------------------------+
