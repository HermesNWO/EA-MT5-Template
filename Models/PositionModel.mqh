//+------------------------------------------------------------------+
//|                                                PositionModel.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Position Model Contains Position Data                            |
//+------------------------------------------------------------------+
class CPositionModel
  {
public:
   long               MagicNumber;
   datetime           DateTime;
   ENUM_POSITION_TYPE PositionType;
   double             Volume;
   string             Asset;
   double             Price;
   double             Sl;
   double             Tp;
   double             Commission;
   double             Swap;
   double             Profit;
  };
//+------------------------------------------------------------------+