//+------------------------------------------------------------------+
//|                                                    JsonModel.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Json Model To Generate and manage JSON                           |
//+------------------------------------------------------------------+
class CJsonModel
  {
public:
                     CJsonModel(string key, string value, bool isText = false)
     {
      Key = key;
      Value = value;
      IsText = isText;
     }
   string            Key;
   string            Value;
   bool              IsText;

   static void       DestroyJsonModels(CJsonModel *&jsonModels[]);
  };
//+------------------------------------------------------------------+
//| Destroys Array Of Json Models                                    |
//+------------------------------------------------------------------+
void CJsonModel::DestroyJsonModels(CJsonModel *&jsonModels[])
  {
   for(int i = ArraySize(jsonModels) - 1; i >= 0; i--)
     {
      delete jsonModels[i];
     }
   ArrayFree(jsonModels);
   ArrayResize(jsonModels, 0);
  }
//+------------------------------------------------------------------+
