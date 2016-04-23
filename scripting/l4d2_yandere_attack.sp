
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1;                // Force strict semicolon mode.
#pragma newdecls required;			// Force new style syntax.

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_VERSION		"1.0.4"
#define CVAR_FLAGS			FCVAR_NOTIFY
#define MSGTAG "\x04[Yandere!]\x01 "

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

public Plugin myinfo =
{
	name        = "Yandere Attack!",
	author      = "Robotex",
	description = "Gameplay extensions for Yandere Attack!",
	version     = PLUGIN_VERSION,
	url         = "http://www.projectsperanza.com"
}

public void OnPluginStart()
{
	CreateConVar("sm_yandereattack_version", PLUGIN_VERSION, "Yandere Attack! version", CVAR_FLAGS|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", OnPlayerDeath); //Hook the event when a player dies 
	HookEvent("player_first_spawn", event_PlayerSpawn);
	HookEvent("player_spawn", event_PlayerSpawn);
}

// ------------------------------------------------------------------------
// Event_RoundStart()
// ------------------------------------------------------------------------
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i))
		{
			PrintToChat(i, "\x03\x01You will be moved to  \x03Infected Team  \x01soon.");
			CreateTimer(15.0, Timer_AutoJoinInfected, GetClientUserId(i));
		}
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(10.0, WelcomePlayer, GetClientSerial(client)); // You could also use GetClientUserId(client)
}

public Action WelcomePlayer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	if (client == 0) // The serial is no longer valid, the player must have disconnected
	{
		return;
	}
	
	if (GetClientTeam(client) != TEAM_INFECTED)
	{
		PrintToChat(client, "\x03\x01Welcome to  \x04Yandere Attack!  \x01You will be moved to  \x05Infected Team \x01soon.");
		CreateTimer(15.0, Timer_AutoJoinInfected, GetClientUserId(client));  //  Autojoin infected
	}
	else
	{
		PrintToChat(client, "\x03\x01Welcome to  \x04Yandere Attack!  \x01Have fun!");
	}
}

// ------------------------------------------------------------------------
// Autojoin infected after round start
// ------------------------------------------------------------------------
public Action Timer_AutoJoinInfected(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	// If joined the infected team already or not valid, don't do anything
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == TEAM_INFECTED) return;

	if (!AreAllInGame() || GetClientTeam(client) == 0)
	{
		CreateTimer(1.0, Timer_AutoJoinInfected, GetClientUserId(client)); // if during transition, delay autojoin
	}
	else
	{
		FakeClientCommand(client, "sm_infected");  // Autojoin infected
	}
}

// ------------------------------------------------------------------------
// Returns true if all connected players are in the game
// ------------------------------------------------------------------------
bool AreAllInGame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!IsClientInGame(i)) return false;
		}
	}
	return true;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast) //The event as a function
{
    int client = GetClientOfUserId(GetEventInt(event, "userid")); //New client index got from the user id who died.
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); //New client index got from the userid who killed.
    if (client > 0 //Make sure the client is higher than zero, 0 means it isnt valid or is world (server)
    && IsValidEntity(client) //Make sure the client is a valid entity
    && IsClientInGame(client) //Make sure the player is ingame
	&& GetClientTeam(client)==TEAM_SURVIVOR //Make sure the client is a survivor
    )
    {
		if (attacker > 0 && IsClientInGame(attacker) && !IsFakeClient(attacker))
		{
			char attacker_name[MAX_TARGET_LENGTH];
			char client_name[MAX_TARGET_LENGTH];
			GetClientName(attacker, attacker_name, sizeof(attacker_name));
			GetClientName(client, client_name, sizeof(client_name));
			//ReplaceString(attacker_name, sizeof(attacker_name), "[", "");
			//ReplaceString(client_name, sizeof(client_name), "[", "");
			PrintToChatAll("%s \x03%s \x01pwned \x05%s \x01!", MSGTAG, attacker_name, client_name);
		}
		
		int survivor_alive_count = 0;
		for(int i = 1; i < GetMaxClients(); i++)
		{
			if (IsClientInGame( i ) && GetClientTeam(i)==TEAM_SURVIVOR && IsPlayerAlive(i))
			{
				survivor_alive_count++;
			}
		}
		PrintToChatAll("%s  \x05%i \x01survivors left.", MSGTAG, survivor_alive_count);
    }
}  

public Action event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client > 0 && GetClientTeam(client) == TEAM_SURVIVOR)
	{	
		//SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 300, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 250, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 50, 4, true);
	}
}
