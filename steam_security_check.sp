#include <steamworks>
#include <json>

ConVar g_cvSteamApiKey;
ConVar g_cvSteamCheck;

public Plugin myinfo = 
{
    name = "Steam Security Check",
    author = "Rowedahelicon",
    description = "Kicks players with incompleted Steam profiles, usually hackers",
    version = "1.0.0",
    url = "https://www.rowedahelicon.com"
};

public void OnPluginStart()
{
    g_cvSteamApiKey = CreateConVar("sec_steam_api", "", "API key for steam interface", FCVAR_PROTECTED);
    g_cvSteamCheck = CreateConVar("sec_steam_check", "1", "Enables / Disables the use of the Steam Profile Check", FCVAR_PROTECTED);
}

public OnClientPostAdminCheck(int client)
{
    if(g_cvSteamCheck.IntValue > 0)
    {
        check_profile(client);
    }
}

void check_profile(int client)
{
    Handle hRequest = INVALID_HANDLE;

    char sApiKey[64];
    g_cvSteamApiKey.GetString(sApiKey, sizeof(sApiKey));
    
    char sId64[64];
    GetClientAuthId(client, AuthId_SteamID64, sId64, sizeof(sId64));    
    
    char sId[64];
    GetClientAuthId(client, AuthId_Steam2, sId, sizeof(sId));

    DataPack pack = new DataPack();
    pack.WriteString(sId);

    hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/");
    SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "key", sApiKey);
    SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "steamids", sId64);
    SteamWorks_SetHTTPCallbacks(hRequest, getCallback);
    SteamWorks_SetHTTPRequestContextValue(hRequest, pack);
    SteamWorks_SendHTTPRequest(hRequest);
}

public getCallback(Handle hRequestCB, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data)
{
    if(!bRequestSuccessful)
    {
        LogError("[Steam Profile Security] There was an error in the request.");
        CloseHandle(hRequestCB);
        return;
    }

    if(eStatusCode == k_EHTTPStatusCode200OK) 
    {
        //Nothing, but don't error out
    }
    else if(eStatusCode == k_EHTTPStatusCode404NotFound) 
    {
        PrintToServer("[Steam Profile Security] 404 error found, is steam offline?");
        CloseHandle(hRequestCB);
        return;
    }
    else if(eStatusCode == k_EHTTPStatusCode500InternalServerError)
    {
        PrintToServer("[Steam Profile Security] 505 error found, is steam offline?");
        CloseHandle(hRequestCB);
        return;
    }
    else 
    {
        char errmessage[128];
        Format(errmessage, 128, "[Steam Profile Security] returned with an unexpected HTTP Code: %d. Check your API key.", eStatusCode);
        LogError(errmessage);
        CloseHandle(hRequestCB);
        return;
    }

    int bodysize;
    bool bodyexists = SteamWorks_GetHTTPResponseBodySize(hRequestCB, bodysize);

    if(bodyexists == false)
    {
        LogError("[Steam Profile Security] An unknown error occured with grabbing the body size.");
        CloseHandle(hRequestCB);
        return;
    }

    char bodybuffer[10000];
    bool gotdata = SteamWorks_GetHTTPResponseBodyData(hRequestCB, bodybuffer, bodysize);

    if(gotdata == false)
    {
        LogError("[Steam Profile Security] No information found in response body.");
        CloseHandle(hRequestCB);
        return;
    }

    JSON_Object obj = json_decode(bodybuffer);

    JSON_Object arrResponse = obj.GetObject("response");
    JSON_Array arrPlayers = view_as<JSON_Array>(arrResponse.GetObject("players"));
    JSON_Object objPlayer = arrPlayers.GetObject(0);
    bool profilestate = objPlayer.GetBool("profilestate");

    if(!profilestate)
    {
        char sId[64];

        DataPack pack = view_as<DataPack>(data);
        pack.Reset();
        pack.ReadString(sId, sizeof(sId));
        
        LogAction(0, -1, "SteamID: %s was kicked for having an incomplete Steam Profile", sId);
        ServerCommand("sm_kick #%s 'Incomplete Steam profile!'", sId);
    }

    CloseHandle(hRequestCB);
    json_cleanup_and_delete(obj);
}
