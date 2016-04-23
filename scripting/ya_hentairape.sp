#pragma semicolon 1
#include <sourcemod>

#include <ps_natives>

#define PLUGIN_VERSION "1.0"
#define MSGTAG "\x04[Yandere!]\x01 "
#define PS_MIN "1.66"
#define PS_ModuleName "Hentai Rape! compatibility layer"

#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

new bool:loaded = false;

public Plugin:myinfo = 
{
	name = "[Yandere Attack!] Not Hentai Rape!",
	author = "Robotex",
	description = "Compatibility layer from Hentai Rape! to Yandere Attack!",
	version = PLUGIN_VERSION,
	url = "http://www.projectsperanza.com"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	LoadTranslations("points_system.phrases");
	RegConsoleCmd("sm_fap", Cmd_Fap);
	RegConsoleCmd("sm_god", Cmd_God);
	RegConsoleCmd("sm_bot", Cmd_Bot);
}

public OnPluginEnd()
{
	if(LibraryExists("ps_natives") && loaded)
	{
		loaded = false;
		PS_UnregisterModule(PS_ModuleName);
	}
}
	
public OnPSLoaded()
{
	if(LibraryExists("ps_natives"))
	{
		if(PS_GetVersion() >= StringToFloat(PS_MIN))
		{
			if(PS_RegisterModule(PS_ModuleName)) LogMessage("%T", "Module: Warning 1", LANG_SERVER);
			loaded = true;
		}	
		else
		{
			SetFailState("%T", "Module: Error 1", LANG_SERVER);
		}	
	}
	else
	{
		SetFailState("%T", "Module: Error 2", LANG_SERVER);
	}	
}

public OnPSUnloaded()
{
	loaded = false;
}	

public Action:Cmd_Fap(client, args)
{
	if(!loaded) return Plugin_Handled;
	FakeClientCommand(client, "sm_buy");
	return Plugin_Handled;
}

public Action:Cmd_God(client, args)
{
	if(!loaded) return Plugin_Handled;
	if (client > 0)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			FakeClientCommand(client, "jointeam 2");
		}
		else
		{
			FakeClientCommand(client, "jointeam 3");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_Bot(client, args)
{
	if(!loaded) return Plugin_Handled;
	if(GetClientTeam(client) == TEAM_SURVIVOR && !IsPlayerAlive(client) && CountAvailableBots(TEAM_SURVIVOR))
	{
		ChangeClientTeam(client, TEAM_SPECTATOR);
		FakeClientCommand(client,"jointeam 2");
	}
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Check if how many alive bots without an idle are available in a team
// ------------------------------------------------------------------------
int CountAvailableBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
					num++;
	}
	return num;
}

// ------------------------------------------------------------------------
// Is the bot valid? (either survivor or infected)
// ------------------------------------------------------------------------
bool IsBotValid(int client)
{
	if(client > 0 && IsClientInGame(client) && IsFakeClient(client) && !GetIdlePlayer(client) && !IsClientInKickQueue(client))
		return true;
	return false;
}

// ------------------------------------------------------------------------
// Returns the idle player of the bot, returns 0 if none
// ------------------------------------------------------------------------
int GetIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot) && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return client;
			}
		}
	}
	return 0;
}