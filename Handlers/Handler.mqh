//+------------------------------------------------------------------+
//|                                                      Handler.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "IHandler.mqh"
#include "../SocketLibrary/SocketServerWrapper.mqh"
//+------------------------------------------------------------------+
//| Base Handler Class                                               |
//+------------------------------------------------------------------+
class CHandler : public IHandler
  {
protected:
   CSocketServerWrapper *m_server;
public:
                     CHandler(CSocketServerWrapper *&server);
   bool              Handle() { return false; };
   
    void SlTpModified(ulong pos, double sl, double tp) {};
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHandler::CHandler(CSocketServerWrapper *&server)
  {
   m_server = server;
  }
//+------------------------------------------------------------------+
