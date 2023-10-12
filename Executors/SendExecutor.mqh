//+------------------------------------------------------------------+
//|                                                 SendExecutor.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "ISendExecutor.mqh"

#include "../Handlers/SendOpenPositionsHandler.mqh"
#include "../Handlers/ManagePositionsHandler.mqh"
//+------------------------------------------------------------------+
//| Send Messages Executor                                           |
//+------------------------------------------------------------------+
class CSendExecutor : public ISendExecutor
  {
private:
   CSocketServerWrapper *m_server;
   IHandler          *m_handlers[];
protected:
   void              CreateHandlers(string user, string password, string csvfilename);
   void              DestroyHandlers();
public:
                     CSendExecutor(CSocketServerWrapper *&server,string user, string password, string csvfilename);
                    ~CSendExecutor();
   void              Execute();
   void              SlTpModified(ulong pos, double sl, double tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSendExecutor::CSendExecutor(CSocketServerWrapper *&server,string user, string password, string csvfilename)
  {
   m_server = server;
   CreateHandlers(user,password,csvfilename);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSendExecutor::~CSendExecutor()
  {
   DestroyHandlers();
  }
//+------------------------------------------------------------------+
//| Execute                                                          |
//+------------------------------------------------------------------+
void CSendExecutor::Execute()
  {
  
   for(int i = 0; i < ArraySize(m_handlers); i++)
     {
      m_handlers[i].Handle();
     }
  }
  
  
 void CSendExecutor::SlTpModified(ulong pos, double sl, double tp)
  {
   for(int i = 0; i < ArraySize(m_handlers); i++)
     {
      m_handlers[i].SlTpModified(pos,sl,tp);
      
    
     }
  }
  
//+------------------------------------------------------------------+
//| Create Handlers Method                                           |
//+------------------------------------------------------------------+
void CSendExecutor::CreateHandlers(string user, string password, string csvfilename)
  {
   ArrayResize(m_handlers, 1);
   m_handlers[0] = new CManagePositionsHandler(m_server, user, password, csvfilename);
   //m_handlers[1] = new CSendOpenPositionsHandler(m_server);
   
  }
//+------------------------------------------------------------------+
//| Destroy Handlers Method                                          |
//+------------------------------------------------------------------+
void CSendExecutor::DestroyHandlers()
  {
  
   for(int i = ArraySize(m_handlers) - 1; i >= 0; i--)
     {
      delete m_handlers[i];
     }
   ArrayFree(m_handlers);
  }
//+------------------------------------------------------------------+
