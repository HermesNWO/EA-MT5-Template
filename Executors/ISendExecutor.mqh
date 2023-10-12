//+------------------------------------------------------------------+
//|                                                ISendExecutor.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
interface ISendExecutor
  {
   void Execute();
   void SlTpModified(ulong pos, double sl, double tp);
  };
//+------------------------------------------------------------------+
