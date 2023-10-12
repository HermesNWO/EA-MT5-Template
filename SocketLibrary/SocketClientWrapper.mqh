//+------------------------------------------------------------------+
//|                                          SocketClientWrapper.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "socket-library-mt4-mt5.mqh"
#include "../Executors/IReceiveExecutor.mqh"
//+------------------------------------------------------------------+
//| Class Socket Wrapper                                             |
//+------------------------------------------------------------------+
class CSocketClientWrapper
  {
private:
   ClientSocket      *m_client;
   string            m_host;
   ushort            m_port;
   IReceiveExecutor  *m_executor;
public:
                     CSocketClientWrapper(string host, ushort port, IReceiveExecutor *&executor);
                    ~CSocketClientWrapper();
   void              KeepAlive();
   bool              IsSocketConnected();
   void              NetworkOnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   bool              SendMessage(string message);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSocketClientWrapper::CSocketClientWrapper(string host, ushort port, IReceiveExecutor *&executor)
  {
   m_host = host;
   m_port = port;
   m_executor = executor;

   m_client = new ClientSocket(m_host, m_port);

   if(m_client.IsSocketConnected())
      Print("Successfully Connected To The Server "
            + m_host + ":"
            + IntegerToString(m_port));
   else
      Print("Failed Connection Attempt To The Server "
            + m_host + ":"
            + IntegerToString(m_port)
            + " Error # : " + IntegerToString(m_client.GetLastSocketError()));
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSocketClientWrapper::~CSocketClientWrapper()
  {
   if(m_client)
     {
      m_client.Send("close");
      m_client.Send("exit");
      delete m_client;
      m_client = NULL;
     }
  }
//+------------------------------------------------------------------+
//| Keep The Connection Alive                                        |
//+------------------------------------------------------------------+
void CSocketClientWrapper::KeepAlive()
  {
   if(!m_client)
     {
      m_client = new ClientSocket(m_host, m_port);

      if(m_client.IsSocketConnected())
        {
         Print("Successfully Re-Connected To The Server "
               + m_host + ":"
               + IntegerToString(m_port));
        }
      else
        {
         Print("Failed Re-Connection Attempt To The Server "
               + m_host + ":"
               + IntegerToString(m_port)
               + " Error # : " + IntegerToString(m_client.GetLastSocketError()));
        }
     }

//--- Ping
   //if(m_client.IsSocketConnected())
   //   m_client.Send("PING");

// If the socket is closed, destroy it, and attempt a new connection
// on the next call to OnTick()
   if(!m_client.IsSocketConnected())
     {
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      Print("Connection to the Master EA TCP server was interrupted. Auto Reconnection is enabled.");
      delete m_client;
      m_client = NULL;
     }
  }
//+------------------------------------------------------------------+
//| Checking if socket is connected                                  |
//+------------------------------------------------------------------+
bool CSocketClientWrapper::IsSocketConnected()
  {
   if(!m_client || CheckPointer(m_client) == POINTER_INVALID)
      return false;

   return m_client.IsSocketConnected();
  }
//+--------------------------------------------------------------------+
//| Event-driven functionality, turned on by                           |
//| #defining SOCKET_LIBRARY_USE_EVENTS                                |
//| before including the socket library. This generates dummy key-down |
//| messages when socket activity occurs, with lparam being the        |
//| .GetSocketHandle()                                                 |
//+--------------------------------------------------------------------+
void CSocketClientWrapper::NetworkOnChartEvent(const int id,const long &lparam,
      const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_KEYDOWN)
     {
      // If the lparam matches a .GetSocketHandle(), then it's a dummy
      // key press indicating that there's socket activity. Otherwise,
      // it's a real key press
      if(m_client != NULL
         && CheckPointer(m_client) != POINTER_INVALID
         && lparam == m_client.GetSocketHandle())
        {
         // Activity on a client socket
         string message = m_client.Receive();
         m_executor.Execute(message);
        }
     }
  }
//+------------------------------------------------------------------+
//| Send Message To The Server                                       |
//+------------------------------------------------------------------+
bool CSocketClientWrapper::SendMessage(string message)
  {
   KeepAlive();
   if(!m_client || CheckPointer(m_client) == POINTER_INVALID)
      return false;

   return m_client.Send(message);
  }
//+------------------------------------------------------------------+
