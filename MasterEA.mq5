//+------------------------------------------------------------------+
//|                                                     MasterEA.mq5 |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+

#property version "1.01"



input string            UserLogin = "test"; // User Login
input string            UserPassword = "test"; // User Password
input string            CsvFilename = "tradehistory.csv";
input string            ApiSave = "https://apipython2.onrender.com/savetraderequest";
input long              IgnoreTransactionsWithMagicNumber = -1;

#include "Defines.mqh"
#include "Utils/StringBuilder.mqh"
#include "Executors/ReceiveExecutor.mqh"
#include "Executors/SendExecutor.mqh"
#include "Positions/MonitorProfit.mqh"

CSocketServerWrapper *SocketServerWrapper;
IReceiveExecutor *ReceiveExecutor;
ISendExecutor *SendExecutor;
MonitorProfit monitorProfit(false, 1);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   in_ApiSave = ApiSave;
   in_IgnoreTransactionsWithMagicNumber = IgnoreTransactionsWithMagicNumber;

   last_request_datetime = TimeCurrent();

   /*if(UserLogin != "test" || UserPassword != "test")
     {
      Alert("Login or Password is incorrect!");
      return (INIT_FAILED);
     }*/


   Initialization(UserLogin,UserPassword);

   EventSetTimer(3);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Deinitialization();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//SendExecutor.Execute();
  }
//+------------------------------------------------------------------+
//| On Trade function                                                |
//+------------------------------------------------------------------+
void OnTrade()
  {
   monitorProfit.RunProcess();
   SendExecutor.Execute();
  }

datetime last_request_datetime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MakeWebRequests()
  {

   CApiManager *apiManager = new CApiManager(in_ApiSave);

   monitorProfit.ExecuteMainWithTimer();

   for(int i = 0; i < ArraySize(mainRequestsQueque); i++)
     {
      if(mainRequestsQueque[i].executed == false)
        {
         Print(mainRequestsQueque[i].request);
         mainRequestsQueque[i].executed = true;
         apiManager.PostWebRequest(mainRequestsQueque[i].request);



        }
     }



  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  OnTradeTransaction(
   const MqlTradeTransaction&    trans,     // trade transaction structure
   const MqlTradeRequest&        request,   // request structure
   const MqlTradeResult&         result     // response structure
)

  {


   if(trans.type==TRADE_TRANSACTION_REQUEST)
     {
      if(result.retcode==TRADE_RETCODE_DONE)
        {
         if(request.action == TRADE_ACTION_SLTP)
           {
            Print("event sltp");
            SendExecutor.SlTpModified(request.position,request.sl,request.tp);
           }

        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   MakeWebRequests();
   monitorProfit.RunProcess();
  }


//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   SocketServerWrapper.NetworkOnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
//| Initialization Of The EA                                         |
//+------------------------------------------------------------------+
void Initialization(string user, string password)
  {
   ReceiveExecutor = new CReceiveExecutor();
   SocketServerWrapper = new CSocketServerWrapper(CLIENT_PORT);
   SendExecutor = new CSendExecutor(SocketServerWrapper,user,password,CsvFilename);
  }
//+------------------------------------------------------------------+
//| Deinitialization Of The EA                                       |
//+------------------------------------------------------------------+
void Deinitialization()
  {
   delete ReceiveExecutor;
   delete SocketServerWrapper;
   delete SendExecutor;
  }
//+------------------------------------------------------------------+
