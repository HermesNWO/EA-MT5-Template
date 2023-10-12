//+------------------------------------------------------------------+
//|                                              ReceiveExecutor.mqh |
//|                                  Copyright 2020, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "IReceiveExecutor.mqh"
//+------------------------------------------------------------------+
//| Receive Messages Executor                                        |
//+------------------------------------------------------------------+
class CReceiveExecutor : public IReceiveExecutor
  {
public:
   void              Execute(string message);
  };
//+------------------------------------------------------------------+
//| Execute Message                                                  |
//+------------------------------------------------------------------+
void CReceiveExecutor::Execute(string message)
  {
  
  }
//+------------------------------------------------------------------+
