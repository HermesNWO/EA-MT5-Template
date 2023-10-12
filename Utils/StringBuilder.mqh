//+------------------------------------------------------------------+
//|                                                CStringBuilder.mqh |
//|                                  Copyright 2020, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Fast String Concating                                            |
//+------------------------------------------------------------------+
class CStringBuilder
  {
private:
   string            m_large;
   string            m_small;
   int               m_concat_threshold;
protected:
   void              Collapse();
public:
                     CStringBuilder(int concatThreshold = 150000);
   void              Append(string X);
   string            ToString();
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStringBuilder::CStringBuilder(int concatThreshold = 150000)
  {
   m_large = "";
   m_small = "";
   m_concat_threshold = concatThreshold;
  }
//+------------------------------------------------------------------+
//| Append string                                                    |
//+------------------------------------------------------------------+
void CStringBuilder::Append(string X)
  {
   if(StringLen(X) > m_concat_threshold)
     {
      Collapse();
      StringAdd(m_large, X);
     }
   else
     {
      StringAdd(m_small, X);
      if(StringLen(m_small) > m_concat_threshold)
        {
         Collapse();
        }
     }
  }
//+------------------------------------------------------------------+
//| Concat The Final String                                          |
//+------------------------------------------------------------------+
string CStringBuilder::ToString()
  {
   Collapse();
   return m_large;
  }
//+------------------------------------------------------------------+
//| Colapse String                                                   |
//+------------------------------------------------------------------+
void CStringBuilder::Collapse()
  {
   StringAdd(m_large, m_small);
   m_small = "";
  }
//+------------------------------------------------------------------+
