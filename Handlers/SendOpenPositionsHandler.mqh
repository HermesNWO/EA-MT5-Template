//+------------------------------------------------------------------+
//|                                     SendOpenPositionsHandler.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "Handler.mqh"
#include "../Utils/StringBuilder.mqh"
//+------------------------------------------------------------------+
//| Send Open Postions To The Socket Server                          |
//+------------------------------------------------------------------+
class CSendOpenPositionsHandler : public CHandler
  {
private:
   long              m_frequency; // in seconds
   datetime          m_last_handling_time;
protected:
   bool              SendWebRequestAlert();
public:
                     CSendOpenPositionsHandler(CSocketServerWrapper *&server) : CHandler(server)
     {
      m_frequency = 60;
     };
   virtual bool      Handle();
  };
//+------------------------------------------------------------------+
//| Handle                                                           |
//+------------------------------------------------------------------+
bool CSendOpenPositionsHandler::Handle(void)
  {
   if(TimeCurrent() - m_last_handling_time > m_frequency)
     {
      m_last_handling_time = TimeCurrent();

      if(PositionsTotal() == 0)
        {
         string emptyOpenPositionList;
         StringConcatenate(emptyOpenPositionList, "<!MASTER_OPENED_POSITIONS_EMPTY|",
                           IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)), "!>");
         m_server.SendSignalToAll(emptyOpenPositionList);
         return true;
        }

      string login = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
      string broker = AccountInfoString(ACCOUNT_SERVER);

      CStringBuilder *sb = new CStringBuilder(100000);
      sb.Append("<!");
      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(!PositionSelectByTicket(PositionGetTicket(i)))
           {
            continue;
           }

         sb.Append("MASTER_OPEN_POSITIONS|");
         sb.Append(PositionGetString(POSITION_SYMBOL));
         sb.Append("|");
         sb.Append(login);
         sb.Append("|");
         sb.Append(broker);
         sb.Append("|");
         sb.Append(IntegerToString(PositionGetInteger(POSITION_MAGIC)));
         sb.Append("|");
         sb.Append(IntegerToString(PositionGetInteger(POSITION_TICKET)));
         sb.Append("|");
         sb.Append(TimeToString(PositionGetInteger(POSITION_TIME)));
         sb.Append("|");
         sb.Append(IntegerToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_VOLUME), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_PRICE_CURRENT), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_SL), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_TP), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_SWAP), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)));
         sb.Append("|");
         sb.Append(DoubleToString(PositionGetDouble(POSITION_PROFIT), 2));
         sb.Append("|");
         sb.Append(PositionGetString(POSITION_COMMENT));
         sb.Append(i != PositionsTotal() - 1 ? "*" : "");
        }
      sb.Append("!>");
      m_server.SendSignalToAll(sb.ToString());
      
      delete sb;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
