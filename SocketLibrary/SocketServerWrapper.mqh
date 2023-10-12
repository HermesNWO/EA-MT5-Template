//+------------------------------------------------------------------+
//|                                          SocketServerWrapper.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
/* ###################################################################

Socket server.
Code can be used as both MQ4 and MQ5 (on both 32-bit and 64-bit MT5)

Receives messages from the example client and simply writes them
to the Experts log.

In addition, you can telnet into the server's port. Any CRLF-terminated
message you type is similarly printed to the Experts log. You
can also type in the commands "quote", to which the server reponds
with the current price of its chart, or "close", which causes the
server to shut down the connection.

As well as demonstrating server functionality, the use of Receive()
and the event-driven handling are also applicable to a client
which needs to receive data from the server as well as just sending it.

################################################################### */

#property strict
// --------------------------------------------------------------------
// Include socket library, asking for event handling
// --------------------------------------------------------------------
#define SOCKET_LIBRARY_USE_EVENTS
#include "socket-library-mt4-mt5.mqh"
#include "../Executors/IReceiveExecutor.mqh"
// --------------------------------------------------------------------
// EA user inputs
// --------------------------------------------------------------------
class CSocketServerWrapper
  {
private:
   // Server socket
   ServerSocket      *glbServerSocket;

   // Array of current clients
   ClientSocket      *glbClients[];

   string            lastMessage;
protected:
   void              AcceptNewConnections();
   void              HandleSocketIncomingData(int idxClient);
public:
                     CSocketServerWrapper(ushort port);
                    ~CSocketServerWrapper();
   void              SendSignalToAll(string message);
   void              NetworkOnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
  };
// --------------------------------------------------------------------
// Initialisation - set up server socket
// --------------------------------------------------------------------
CSocketServerWrapper::CSocketServerWrapper(ushort port)
  {
// Create the server socket
   glbServerSocket=new ServerSocket(port, true);
   if(glbServerSocket.Created())
     {
      Print("Server socket created, port : ", IntegerToString(port));
     }

   lastMessage="";
  }
// --------------------------------------------------------------------
// Termination - free server socket and any clients
// --------------------------------------------------------------------
CSocketServerWrapper::~CSocketServerWrapper(void)
  {
// Delete all clients currently connected
   for(int i=0; i<ArraySize(glbClients); i++)
     {
      glbClients[i].Send("DISCONNECT");
      delete glbClients[i];
     }

// Free the server socket. *VERY* important, or else
// the port number remains in use and un-reusable until
// MT4/5 is shut down
   delete glbServerSocket;
   Print("Server socket terminated");
  }
// --------------------------------------------------------------------
// Send message to all clients
// --------------------------------------------------------------------
void CSocketServerWrapper::SendSignalToAll(string message)
  {
   Print("Sending : ", message);
   for(int i=0; i<ArraySize(glbClients); i++)
     {
      glbClients[i].Send(message);
     }
   lastMessage=message;
  }
// --------------------------------------------------------------------
// Accepts new connections on the server socket, creating new
// entries in the glbClients[] array
// --------------------------------------------------------------------
void CSocketServerWrapper::AcceptNewConnections()
  {
// Keep accepting any pending connections until Accept() returns NULL
   ClientSocket*pNewClient=NULL;
   do
     {
      pNewClient=glbServerSocket.Accept();
      if(pNewClient!=NULL)
        {
         int sz=ArraySize(glbClients);
         ArrayResize(glbClients,sz+1);
         glbClients[sz]=pNewClient;
         Print("New client connection");

         //if(lastMessage!="")
         //   glbClients[sz].Send(lastMessage);
        }
     }
   while(pNewClient!=NULL);
  }
// --------------------------------------------------------------------
// Handles any new incoming data on a client socket, identified
// by its index within the glbClients[] array. This function
// deletes the ClientSocket object, and restructures the array,
// if the socket has been closed by the client
// --------------------------------------------------------------------
void CSocketServerWrapper::HandleSocketIncomingData(int idxClient)
  {
   ClientSocket*pClient=glbClients[idxClient];

// Keep reading CRLF-terminated lines of input from the client
// until we run out of new data
   bool bForceClose=false; // Client has sent a "close" message
   string strCommand;
   do
     {
      strCommand=pClient.Receive("\r\n");
      if(strCommand=="quote")
        {
         pClient.Send(Symbol()+","+DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_BID),6)+","+DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK),6)+"\r\n");

        }
      else
         if(strCommand=="close")
           {
            bForceClose=true;

           }
         else
            if(strCommand!="")
              {
               // Potentially handle other commands etc here.
               // For example purposes, we'll simply print messages to the Experts log

               //Print("<- ",strCommand);
              }
     }
   while(strCommand!="");

// If the socket has been closed, or the client has sent a close message,
// release the socket and shuffle the glbClients[] array
   if(!pClient.IsSocketConnected() || bForceClose)
     {
      Print("Client has disconnected");

      // Client is dead. Destroy the object
      delete pClient;

      // And remove from the array
      int ctClients=ArraySize(glbClients);
      for(int i=idxClient+1; i<ctClients; i++)
        {
         glbClients[i-1]=glbClients[i];
        }
      ctClients--;
      ArrayResize(glbClients,ctClients);
     }
  }
// --------------------------------------------------------------------
// Event-driven functionality, turned on by #defining SOCKET_LIBRARY_USE_EVENTS
// before including the socket library. This generates dummy key-down
// messages when socket activity occurs, with lparam being the
// .GetSocketHandle()
// --------------------------------------------------------------------
void CSocketServerWrapper::NetworkOnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_KEYDOWN)
     {
      // If the lparam matches a .GetSocketHandle(), then it's a dummy
      // key press indicating that there's socket activity. Otherwise,
      // it's a real key press
      if(lparam==glbServerSocket.GetSocketHandle())
        {
         // Activity on server socket. Accept new connections
         Print("New server socket event - incoming connection");
         AcceptNewConnections();

        }
      else
        {
         // Compare lparam to each client socket handle
         for(int i=0; i<ArraySize(glbClients); i++)
           {
            if(lparam==glbClients[i].GetSocketHandle())
              {
               HandleSocketIncomingData(i);
               return; // Early exit
              }
           }

         // If we get here, then the key press does not seem
         // to match any socket, and appears to be a real
         // key press event...
        }
     }
  }
//+------------------------------------------------------------------+