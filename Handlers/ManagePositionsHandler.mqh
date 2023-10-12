//+------------------------------------------------------------------+
//|                                       ManagePositionsHandler.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "Handler.mqh"
#include "../Utils/StringBuilder.mqh"
#include "../Managers/ApiManager.mqh"
#include "../GlobalVariables.mqh"
#include "../enums.mqh"

string prefix = "MasterEA";
void SetPositionBaseline()
  {
   int TotalNumberOfOrders;   //  <-- this variable will hold the number of orders currently in the Trade pool

   int PositionIndex;



   TotalNumberOfOrders = PositionsTotal();    // <-- we store the number of Orders in the variable

   for(PositionIndex = TotalNumberOfOrders - 1; PositionIndex >= 0 ; PositionIndex --)  //  <-- for loop to loop through all Orders . .   COUNT DOWN TO ZERO !
     {
      ulong ticket1 = PositionGetTicket(PositionIndex);
      if(! ticket1)
         continue;

        {
         GlobalVariableSet(prefix+"_position"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)),PositionGetDouble(POSITION_VOLUME));
         HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
         int deals=HistoryDealsTotal();
         GlobalVariableSet(prefix+"_positiondealno"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)),deals);

        }
     } // end of For loop

  }


//+------------------------------------------------------------------+
//| Manage Positions And Send The Positions To Clients               |
//+------------------------------------------------------------------+
class CManagePositionsHandler : public CHandler
  {
private:
   int               m_last_positions_count;
   string            user;
   string            password;
   string            csvfilename;
   int               filehandle;
protected:
   bool              SendThroughApiManager(long ticketNumber,  long identifier,long magicNumber, long openTime, string orderType, double volume, string symbol,
                                           double openPrice, double sl, double tp, double closePrice, long closeTime, double swap, double profit,
                                           double commission, string closurePosition, double balance, string broker,string orderType, double point, double tick);
   void              CheckPositionChange();
   void              WriteCsv(string line);
   void              SaveInfo(double volumein,bool closeoperation,string overrideOrderType);


public:
                     CManagePositionsHandler(CSocketServerWrapper *&server,string user_, string password_, string csvfilename_) : CHandler(server)
     {
      Print("Creating Handler");
      m_last_positions_count = PositionsTotal();
      this.user = user_;
      this.password = password_;
      this.csvfilename = csvfilename_;
      filehandle=FileOpen(csvfilename,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_SHARE_READ);

      if(filehandle!=INVALID_HANDLE)
         FileSeek(filehandle,0,SEEK_END);

      string header = "operation|magicNumber|dateAndTimeOpening|typeOfTransaction|volume|symbole|priceOpening|stopLoss|takeProfit|priceClosure|commision|swap|profit|balance|identifier|ticket|broker|orderType|modification";



      if(filehandle==INVALID_HANDLE)
        {
         Print("Failed to filen for writing:",filehandle);

        }
      else
         if(FileTell(filehandle)==0)
            FileWriteString(filehandle,header+"\n");




      SetPositionBaseline();
     };

                    ~CManagePositionsHandler()
     {
      if(filehandle!=INVALID_HANDLE)
         FileClose(filehandle);
     }
   virtual bool      Handle();

   void              SlTpModified(ulong pos, double sl, double tp);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  CManagePositionsHandler::WriteCsv(string line)
  {
   if(filehandle!=INVALID_HANDLE)
     {
      FileWriteString(filehandle,line+"\n");

     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CManagePositionsHandler::SaveInfo(double volumein,bool closeoperation,string overrideOrderType)
  {
   string symbol = PositionGetString(POSITION_SYMBOL);
   long ticket = PositionGetInteger(POSITION_TICKET);
   long magic = PositionGetInteger(POSITION_MAGIC);
   long openTime = PositionGetInteger(POSITION_TIME);
   ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double volume = volumein-PositionGetDouble(POSITION_VOLUME);
   if(closeoperation)
      GlobalVariableSet(prefix+"_position"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)),PositionGetDouble(POSITION_VOLUME));
   else
      volume = PositionGetDouble(POSITION_VOLUME);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl = PositionGetDouble(POSITION_SL);
   double tp = PositionGetDouble(POSITION_TP);
   double closePrice = 0;
   long closeTime = 0;
//double commission = 0;
//double swap = PositionGetDouble(POSITION_SWAP);
//double profit = PositionGetDouble(POSITION_PROFIT);
   long positionId = PositionGetInteger(POSITION_IDENTIFIER);

   if(in_IgnoreTransactionsWithMagicNumber>0 && magic == in_IgnoreTransactionsWithMagicNumber)
      return;


   ENUM_ORDER_TYPE orderType;

   orderType = 1 - (ENUM_ORDER_TYPE) PositionGetInteger(POSITION_TYPE);


   long id = PositionGetInteger(POSITION_IDENTIFIER);
   HistorySelectByPosition(id);


   int deals=HistoryDealsTotal();

   int startfrom = (int) NormalizeDouble(GlobalVariableGet(prefix+"_positiondealno"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER))), 0);

   double swap = 0;
   double profit = 0;
   double commission = 0;
   double dealvolume = 0;


   for(int i=startfrom; i<deals; i++)
     {
      ulong dealTicket=               HistoryDealGetTicket(i);




      commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
      swap += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
      profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

      closePrice += HistoryDealGetDouble(dealTicket, DEAL_PRICE) * HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      dealvolume+= HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      sl = HistoryDealGetDouble(dealTicket, DEAL_SL);
      tp = HistoryDealGetDouble(dealTicket, DEAL_TP);
      closeTime = HistoryDealGetInteger(dealTicket,DEAL_TIME);



     }

   if(closePrice != 0 && dealvolume != 0)
     {
      closePrice /= dealvolume;
     }

   if(overrideOrderType!="")
      closePrice = 0;

   string originalordertype;
   if(HistoryOrderSelect(positionId))
     {
      originalordertype = StringSubstr(EnumToString((ENUM_ORDER_TYPE)HistoryOrderGetInteger(positionId,ORDER_TYPE)),StringLen("ORDER_TYPE_"));
     }


   CStringBuilder *sb = new CStringBuilder(1000);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   sb.Append(overrideOrderType!=""? "MODIFY_POSITION|":"CLOSE_POSITION|");
   sb.Append(IntegerToString(magic));
   sb.Append("|");
   sb.Append(TimeToString(closeTime));
   sb.Append("|");
   sb.Append(IntegerToString(orderType));
   sb.Append("|");
   sb.Append(DoubleToString(volume, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
   sb.Append("|");
   sb.Append(symbol);
   sb.Append("|");
   sb.Append(DoubleToString(openPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
   sb.Append("|");
   sb.Append(DoubleToString(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
   sb.Append("|");
   sb.Append(DoubleToString(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
   sb.Append("|");
   sb.Append(DoubleToString(closePrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
   sb.Append("|");

   sb.Append(DoubleToString(commission, 3));
   sb.Append("|");
   sb.Append(DoubleToString(swap, 3));
   sb.Append("|");
   sb.Append(DoubleToString(profit, 3));
   sb.Append("|");
   sb.Append(DoubleToString(balance, 3));
   sb.Append("|");
   sb.Append(IntegerToString(positionId));
   sb.Append("|");
   sb.Append(IntegerToString(ticket));


   string broker =  AccountInfoString(ACCOUNT_COMPANY);
   sb.Append("|");
   sb.Append(broker);
   sb.Append("|");
   sb.Append(originalordertype);
   sb.Append("|");
   sb.Append(overrideOrderType);

   WriteCsv(sb.ToString());

   m_server.SendSignalToAll(sb.ToString());

   string orderTypeShortText = orderType == ORDER_TYPE_BUY ? "Buy" : "Sell";
   if(overrideOrderType!="")
      orderTypeShortText = overrideOrderType;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tick =  SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);


   SendThroughApiManager(ticket, positionId, magic, openTime, orderTypeShortText, volume, symbol, openPrice, sl, tp,
                         closePrice, closeTime, swap, profit, commission,overrideOrderType!=""?"": "Close",balance,broker,originalordertype, point, tick);

   delete sb;


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CManagePositionsHandler::CheckPositionChange()
  {
   int TotalNumberOfOrders;   //  <-- this variable will hold the number of orders currently in the Trade pool

   int PositionIndex;



   TotalNumberOfOrders = PositionsTotal();    // <-- we store the number of Orders in the variable

   for(PositionIndex = TotalNumberOfOrders - 1; PositionIndex >= 0 ; PositionIndex --)  //  <-- for loop to loop through all Orders . .   COUNT DOWN TO ZERO !
     {
      ulong ticket1 = PositionGetTicket(PositionIndex);
      if(! ticket1)
         continue;
      if(GlobalVariableCheck(prefix+"_position"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER))))
        {
         double volume = GlobalVariableGet(prefix+"_position"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)));

         if(PositionGetDouble(POSITION_VOLUME)!=volume)
           {

            SaveInfo(volume,true,"");

           }
        }
      else
         GlobalVariableSet(prefix+"_position"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)),PositionGetDouble(POSITION_VOLUME));

      HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
      int deals=HistoryDealsTotal();
      GlobalVariableSet(prefix+"_positiondealno"+DoubleToString(PositionGetInteger(POSITION_IDENTIFIER)),deals);

     } // end of For loop

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CManagePositionsHandler::SlTpModified(ulong pos, double sl, double tp)
  {

   double prevsl = GlobalVariableGet("MasterEa_sl_positionid"+ DoubleToString(pos));
   double prevtp = GlobalVariableGet("MasterEa_tp_positionid"+ DoubleToString(pos));

   string modified = "";
   if(prevsl!=sl)
     {
      modified  = "Sl";
     }


   if(prevtp!=tp)
     {
      modified += "Tp";
     }

   if(modified=="")
      return;

   GlobalVariableSet("MasterEa_sl_positionid"+DoubleToString(pos), sl);
   GlobalVariableSet("MasterEa_tp_positionid"+DoubleToString(pos), tp);

   if(!PositionSelectByTicket(pos))
     {
      return;
     }

   SaveInfo(0,false,"Modify"+modified);


  }

//+------------------------------------------------------------------+
//| Handle                                                           |
//+------------------------------------------------------------------+
bool CManagePositionsHandler::Handle(void)
  {
// --- New position has been opened

   if(PositionsTotal() > m_last_positions_count)
     {
      m_last_positions_count = PositionsTotal();

      CheckPositionChange();

      // --- Select last opened position
      if(!PositionSelectByTicket(PositionGetTicket(PositionsTotal() - 1)))
         return false;

      string symbol = PositionGetString(POSITION_SYMBOL);
      long ticket = PositionGetInteger(POSITION_TICKET);
      long magic = PositionGetInteger(POSITION_MAGIC);
      long openTime = PositionGetInteger(POSITION_TIME);
      ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double closePrice = 0;
      long closeTime = 0;
      double commission = 0;
      double swap = PositionGetDouble(POSITION_SWAP);
      double profit = PositionGetDouble(POSITION_PROFIT);
      long positionId = PositionGetInteger(POSITION_IDENTIFIER);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);

      if(in_IgnoreTransactionsWithMagicNumber>0 && magic == in_IgnoreTransactionsWithMagicNumber)
         return false;

      GlobalVariableSet("MasterEa_sl_positionid"+DoubleToString(positionId),sl);
      GlobalVariableSet("MasterEa_tp_positionid"+DoubleToString(positionId),tp);


      string originalordertype;

      HistorySelect(0, INT_MAX);
      if(HistorySelectByPosition(positionId))
        {

         int deals=HistoryDealsTotal();


         if(HistoryDealsTotal()>0)
           {
            ulong dealTicket= HistoryDealGetTicket(0);
            ulong order = HistoryDealGetInteger(dealTicket,DEAL_ORDER);

            if(HistoryOrderSelect(order))
              {

              }
            else
              {
               int lastError = GetLastError();
               Print("Failed to select the order. Error code: ", lastError);

               Sleep(50);
               if(HistoryOrderSelect(order))
                 {

                 }



               if(OrderSelect(order))
                 {

                  originalordertype = StringSubstr(EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)),StringLen("ORDER_TYPE_"));
                 }
              }

           }

         if(HistoryOrdersTotal()>0)
           {
            ulong orderticket = HistoryOrderGetTicket(0);

            originalordertype = StringSubstr(EnumToString((ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderticket,ORDER_TYPE)),StringLen("ORDER_TYPE_"));
           }
        }
      else
         if(OrderSelect(positionId))
           {


           }


      CStringBuilder *sb = new CStringBuilder(1000);
      sb.Append("OPEN_POSITION|");
      sb.Append(IntegerToString(magic));
      sb.Append("|");
      sb.Append(TimeToString(openTime));
      sb.Append("|");
      sb.Append(IntegerToString(positionType));
      sb.Append("|");
      sb.Append(DoubleToString(volume));
      sb.Append("|");
      sb.Append(symbol);
      sb.Append("|");
      sb.Append(DoubleToString(openPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      sb.Append("|");
      sb.Append(DoubleToString(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      sb.Append("|");
      sb.Append(DoubleToString(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      sb.Append("|");
      sb.Append(DoubleToString(closePrice));
      sb.Append("|");
      sb.Append(DoubleToString(commission));
      sb.Append("|");
      sb.Append(DoubleToString(swap, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      sb.Append("|");
      sb.Append(DoubleToString(profit, 2));
      sb.Append("|");
      sb.Append(DoubleToString(balance, 3));
      sb.Append("|");
      sb.Append(IntegerToString(positionId));
      sb.Append("|");
      sb.Append(IntegerToString(ticket));

      string broker =  AccountInfoString(ACCOUNT_COMPANY);
      sb.Append("|");
      sb.Append(broker);

      sb.Append("|");
      sb.Append(originalordertype);
      sb.Append("|");


      WriteCsv(sb.ToString());

      m_server.SendSignalToAll(sb.ToString());

      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tick =  SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

      string orderTypeShortText = positionType == POSITION_TYPE_BUY ? "Buy" : "Sell";
      SendThroughApiManager(ticket, positionId,magic, openTime, orderTypeShortText, volume, symbol, openPrice,
                            sl, tp, closePrice, closeTime, swap, profit, commission, "Open", balance,broker,originalordertype, point, tick);

      delete sb;
     }

// --- Position has been closed
   else
      if(PositionsTotal() < m_last_positions_count)
        {
         m_last_positions_count = PositionsTotal();
         CheckPositionChange();
         //--- Request trade history
         HistorySelect(0, INT_MAX);

         ulong orderTicket = HistoryOrderGetTicket(HistoryOrdersTotal() - 1);
         // --- Select last closed position
         if(!HistoryOrderSelect(orderTicket))
            return false;

         string symbol = HistoryOrderGetString(orderTicket, ORDER_SYMBOL);
         long ticket = HistoryOrderGetInteger(orderTicket, ORDER_TICKET);
         long magic = HistoryOrderGetInteger(orderTicket, ORDER_MAGIC);
         long openTime = HistoryOrderGetInteger(orderTicket, ORDER_TIME_SETUP);
         ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
         double volume = HistoryOrderGetDouble(orderTicket, ORDER_VOLUME_INITIAL);
         double openPrice = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
         double sl = HistoryOrderGetDouble(orderTicket, ORDER_SL);
         double tp = HistoryOrderGetDouble(orderTicket, ORDER_TP);
         double closePrice = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_CURRENT);
         long closeTime = HistoryOrderGetInteger(orderTicket, ORDER_TIME_DONE);
         long positionId = HistoryOrderGetInteger(orderTicket, ORDER_POSITION_ID);

         if(in_IgnoreTransactionsWithMagicNumber>0 && magic == in_IgnoreTransactionsWithMagicNumber)
            return false;


         string originalordertype;

         if(HistorySelectByPosition(positionId))
           {
            int deals=HistoryDealsTotal();

            //openPrice = 0;
            //closePrice = 0;
            double dealvolume = 0;
            for(int i=0; i<deals; i++)
              {
               ulong dealTicket=               HistoryDealGetTicket(i);
               if(HistoryDealGetInteger(dealTicket,DEAL_ENTRY)==DEAL_ENTRY_IN)
                 {
                  openPrice += HistoryDealGetDouble(dealTicket, DEAL_PRICE) * HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                  dealvolume+= HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                  openTime = HistoryDealGetInteger(dealTicket,DEAL_TIME);
                 }

              }
            // Print("xxxopen price:",openPrice);
            //if(dealvolume != 0)
            // {
            openPrice /= dealvolume;
            // }



            if(HistoryOrdersTotal()>0)
              {
               ulong orderticket = HistoryOrderGetTicket(0);
               originalordertype = StringSubstr(EnumToString((ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderticket,ORDER_TYPE)),StringLen("ORDER_TYPE_"));
              }

           }

         ulong dealTicket = HistoryDealGetTicket(HistoryDealsTotal() - 1);

         double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

         closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         closeTime = HistoryDealGetInteger(dealTicket, DEAL_TIME);




         CStringBuilder *sb = new CStringBuilder(1000);
         sb.Append("CLOSE_POSITION|");
         sb.Append(IntegerToString(magic));
         sb.Append("|");
         sb.Append(TimeToString(closeTime));
         sb.Append("|");
         sb.Append(IntegerToString(orderType));
         sb.Append("|");
         sb.Append(DoubleToString(volume, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(symbol);
         sb.Append("|");
         sb.Append(DoubleToString(openPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         sb.Append("|");



         sl = HistoryDealGetDouble(dealTicket, DEAL_SL);
         tp = HistoryDealGetDouble(dealTicket, DEAL_TP);
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);

         sb.Append(DoubleToString(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(closePrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         sb.Append("|");



         sb.Append(DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_COMMISSION), 3));
         sb.Append("|");
         sb.Append(DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_SWAP), 3));
         sb.Append("|");
         sb.Append(DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_PROFIT), 3));
         sb.Append("|");
         sb.Append(DoubleToString(balance, 3));
         sb.Append("|");
         sb.Append(IntegerToString(positionId));
         sb.Append("|");
         sb.Append(IntegerToString(ticket));
         string broker =  AccountInfoString(ACCOUNT_COMPANY);
         sb.Append("|");
         sb.Append(broker);
         sb.Append("|");
         sb.Append(originalordertype);
         sb.Append("|");


         WriteCsv(sb.ToString());

         m_server.SendSignalToAll(sb.ToString());

         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         double tick =  SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

         string orderTypeShortText = orderType == ORDER_TYPE_BUY ? "Buy" : "Sell";
         SendThroughApiManager(ticket, positionId, magic, openTime, orderTypeShortText, volume, symbol, openPrice, sl, tp,
                               closePrice, closeTime, swap, profit, commission, "Close",balance,broker,originalordertype, point, tick);

         delete sb;
        }
      else
        {
         CheckPositionChange();



        }

   return true;
  }



// format 1970-01-01T00:00:00.000+00:00

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ConvertIntoProperDatetimeFormat(long time)
  {
   string f =  TimeToString(time,TIME_DATE|TIME_SECONDS); // "1970.01.01 00:00:00",
   string out = StringSubstr(f,0,4)+ "-" +  StringSubstr(f,5,2) +"-" +  StringSubstr(f,8,2)
                +  "T"+StringSubstr(f,11,8)+".000+00:00";
// result format:"2023-07-16T13:31:57.000+00:00"

   return out;
  }
//+------------------------------------------------------------------+
//| Send Through Api Manager                                         |
//+------------------------------------------------------------------+
bool CManagePositionsHandler::SendThroughApiManager(long ticketNumber, long identifier,long magicNumber, long openTime, string orderType, double volume, string symbol,
      double openPrice, double sl, double tp, double closePrice, long closeTime, double swap, double profit, double commission, string closurePosition,
      double balance, string broker,string originalOrderType, double point, double tick)
  {
// was https://trad-back.onrender.com/api/tradReq/save

   double highestPrice = 0;
   double lowestPrice = 0;
   double maxProfit = 0;
   double maxLoss = 0;

   for(int i = 0; i < ArraySize(ordersMaxLossAndProfit); i++)
     {
      if(ordersMaxLossAndProfit[i].order_ticket == identifier)
        {
         OrdersMaxLossAndProfit o = ordersMaxLossAndProfit[i];

         highestPrice = o.highest_price;
         lowestPrice = o.lowest_price;
         maxProfit = o.highest_profit;
         maxLoss = o.lowest_profit;
        }
     }



   CApiManager *apiManager = new CApiManager(in_ApiSave);

   CJsonModel *jsonModels[28];


   jsonModels[0] = new CJsonModel("ticketNumber", IntegerToString(ticketNumber));
   jsonModels[1] = new CJsonModel("magicNumber", IntegerToString(magicNumber));
   jsonModels[2] = new CJsonModel("dateAndTimeOpening", ConvertIntoProperDatetimeFormat(openTime),true);
   jsonModels[3] = new CJsonModel("typeOfTransaction", orderType, true);
   jsonModels[4] = new CJsonModel("volume", DoubleToString(volume));
   jsonModels[5] = new CJsonModel("symbole", symbol, true);
   jsonModels[6] = new CJsonModel("priceOpening", DoubleToString(openPrice));
   jsonModels[7] = new CJsonModel("stopLoss", DoubleToString(sl));
   jsonModels[8] = new CJsonModel("takeProfit", DoubleToString(tp));
   jsonModels[9] = new CJsonModel("dateAndTimeClosure", ConvertIntoProperDatetimeFormat(closeTime),true);
   jsonModels[10] = new CJsonModel("priceClosure", DoubleToString(closePrice));
   jsonModels[11] = new CJsonModel("swap", DoubleToString(swap));
   jsonModels[12] = new CJsonModel("profit", DoubleToString(profit));
   jsonModels[13] = new CJsonModel("commision", DoubleToString(commission));
   jsonModels[14] = new CJsonModel("closurePosition", closurePosition, true);
   jsonModels[15] = new CJsonModel("username", user, true);
   jsonModels[16] = new CJsonModel("password", password, true);

   jsonModels[17] = new CJsonModel("identifier", IntegerToString(identifier));
   jsonModels[18] = new CJsonModel("balance", DoubleToString(balance));
   jsonModels[19] = new CJsonModel("broker", broker, true);
   jsonModels[20] = new CJsonModel("orderType", originalOrderType, true);

   jsonModels[21] = new CJsonModel("point", DoubleToString(point), true);
   jsonModels[22] = new CJsonModel("tick", DoubleToString(tick), true);

   jsonModels[23] = new CJsonModel("exitReason", GetExitReason(orderType, sl, tp, closePrice), true);

   jsonModels[24] = new CJsonModel("maxProfit", DoubleToString(maxProfit), true);
   jsonModels[25] = new CJsonModel("maxLoss", DoubleToString(maxLoss), true);
   jsonModels[26] = new CJsonModel("highestPrice", DoubleToString(highestPrice), true);
   jsonModels[27] = new CJsonModel("lowestPrice", DoubleToString(lowestPrice), true);



   string jsonText = apiManager.GenerateJson(jsonModels);

   CJsonModel::DestroyJsonModels(jsonModels);

   ArrayResize(mainRequestsQueque, ArraySize(mainRequestsQueque) + 1);
   Requests r;
   r.executed = false;
   r.request = jsonText;
   mainRequestsQueque[ArraySize(mainRequestsQueque) - 1] = r;


   delete apiManager;
   return true;
  }
//+------------------------------------------------------------------+
string GetExitReason(string orderType, double sl, double tp, double closure_price)
  {
   string result = "";


   if(closure_price != 0)
     {
      if(MathAbs(closure_price - sl) < (Point() * 3))
        {
         result = "SL";
        }
      else
         if(MathAbs(closure_price - tp) < (Point() * 3))
           {
            result = "TP";
           }
         else
           {
            result = "Closed manually";
           }
     }
   else
     {
      result = "Not closed yet";
     }



   return result;
  }
//+------------------------------------------------------------------+
