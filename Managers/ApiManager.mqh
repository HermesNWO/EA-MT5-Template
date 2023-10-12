//+------------------------------------------------------------------+
//|                                                   ApiManager.mqh |
//|                                  Copyright 2023, Yurii Dumanskyi |
//|                          https://www.mql5.com/en/users/dumanskyy |
//+------------------------------------------------------------------+
#include "../Models/JsonModel.mqh"

#define JSON_HEADERS "Content-Type: application/json\r\ncharset=utf-8\r\nConnection: Keep-Alive"
//+------------------------------------------------------------------+
//| Manages Operations With API                                      |
//+------------------------------------------------------------------+
class CApiManager
  {
private:
   string            m_url;
   string            m_headers;

   string            m_server_headers_text;
   string            m_server_response_text;
protected:
   int               SendWebRequest(string method, string jsonText);
   bool              HandleResponse(int responseId);
public:
                     CApiManager(string url, string headers = "")
     {
      m_url = url;
      m_headers = headers;
     };
   int               PostWebRequest(string jsonText, bool repeat=true);
   string            GenerateJson(CJsonModel *&jsonValues[]);

   // --- Get Server Response Text Property
   string            GetServerResponseText()
     {
      return m_server_response_text;
     }
   // --- Get Server Heanders Text Property
   string            GetServerHeadersText()
     {
      return m_server_headers_text;
     }
  };

struct messagequeuetype
  {
   string            message;

   int               counter;
  };
messagequeuetype queue[];

bool timeron = false;
  
//+------------------------------------------------------------------+
//| Sends Web Request To Api Server                                  |
//+------------------------------------------------------------------+
int CApiManager::PostWebRequest(string jsonText, bool repeat=true)
  {
   int repeattimes = 20;
   int counter = repeattimes;
   int waitseconds = 3;
   int responseId = -1;


   responseId = SendWebRequest("POST", jsonText);
   //Print("Response: ", responseId);


   if(responseId==-1 && repeat)
     {
      if(!timeron)
        {
         //EventSetTimer(waitseconds);
         timeron = true;
        }
      int s = ArraySize(queue);
      ArrayResize(queue,s+1);

      queue[s].counter = repeattimes-1;
      queue[s].message = jsonText;

     }





   return responseId;
  }
//+------------------------------------------------------------------+
//| Generates JSON based on key value string array                   |
//+------------------------------------------------------------------+
string CApiManager::GenerateJson(CJsonModel *&jsonValues[])
  {
   string jsonText = "{";
   for(int i = 0; i < ArraySize(jsonValues); i++)
     {
      if(jsonValues[i].IsText)
         jsonText += "\""+ jsonValues[i].Key +"\": \"" + jsonValues[i].Value + "\"";
      else
         jsonText += "\""+ jsonValues[i].Key +"\": " + jsonValues[i].Value;

      if(i != ArraySize(jsonValues) - 1)
         jsonText += ",\r\n";
     }
   jsonText += "}";

   return jsonText;
  }
//+------------------------------------------------------------------+
//| Sends Web Request                                                |
//+------------------------------------------------------------------+
int CApiManager::SendWebRequest(string method, string jsonText)
  {
// --- Use predefined headers if headers weren't passed through the constructor
   string headers = m_headers;
   if(m_headers == NULL || m_headers == "" || StringLen(m_headers) == 0)
      headers = JSON_HEADERS;

// Text must be converted to a uchar array. Note that StringToCharArray() adds
// a nul character to the end of the array unless the size/length parameter
// is explicitly specified
   uchar jsonData[];
   StringToCharArray(jsonText, jsonData, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(jsonData, ArraySize(jsonData) - 1);

   char serverResult[];

 
   
      int responseId = WebRequest(method,               // HTTP method
                                  m_url,                // URL
                                  headers,              // headers
                                  3000,                // timeout
                                  jsonData,             // the array of the HTTP message body
                                  serverResult,         // an array containing server response data
                                  m_server_headers_text // headers of server response
                                 );
                                 




   m_server_response_text = CharArrayToString(serverResult);

   HandleResponse(responseId);

   return responseId;
  }
//+-------------------------------------------------------------------+
//| Handles Response From API and print message what the response mean|
//+-------------------------------------------------------------------+
bool CApiManager::HandleResponse(int responseId)
  {
// --- Handle errors
   if(responseId == -1)
     {
      Print("Error on sending web request to API " + m_server_response_text);

      return false;
     }

   Print(IntegerToString(responseId) + " Successfully sent web request to API" + m_server_response_text);

   return true;
  }
//+-------------------------------------------------------------------+

//+------------------------------------------------------------------+
