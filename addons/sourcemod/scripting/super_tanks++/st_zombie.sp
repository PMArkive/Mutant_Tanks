// Super Tanks++: Zombie Ability
#pragma semicolon 1
#pragma newdecls required
#include <super_tanks++>

public Plugin myinfo =
{
	name = "[ST++] Zombie Ability",
	author = ST_AUTHOR,
	description = ST_DESCRIPTION,
	version = ST_VERSION,
	url = ST_URL
};

bool g_bTankConfig[ST_MAXTYPES + 1];
int g_iZombieAbility[ST_MAXTYPES + 1];
int g_iZombieAbility2[ST_MAXTYPES + 1];
int g_iZombieAmount[ST_MAXTYPES + 1];
int g_iZombieAmount2[ST_MAXTYPES + 1];
int g_iZombieInterval[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[ST++] Zombie Ability only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("super_tanks++"))
	{
		SetFailState("No Super Tanks++ library found.");
	}
}

public void OnMapStart()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			g_iZombieInterval[iPlayer] = 0;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_iZombieInterval[client] = 0;
}

public void OnClientDisconnect(int client)
{
	g_iZombieInterval[client] = 0;
}

public void OnMapEnd()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			g_iZombieInterval[iPlayer] = 0;
		}
	}
}

public void ST_Configs(char[] savepath, int limit, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);
	for (int iIndex = 1; iIndex <= limit; iIndex++)
	{
		char sName[MAX_NAME_LENGTH + 1];
		Format(sName, sizeof(sName), "Tank %d", iIndex);
		if (kvSuperTanks.JumpToKey(sName))
		{
			main ? (g_bTankConfig[iIndex] = false) : (g_bTankConfig[iIndex] = true);
			main ? (g_iZombieAbility[iIndex] = kvSuperTanks.GetNum("Zombie Ability/Ability Enabled", 0)) : (g_iZombieAbility2[iIndex] = kvSuperTanks.GetNum("Zombie Ability/Ability Enabled", g_iZombieAbility[iIndex]));
			main ? (g_iZombieAbility[iIndex] = iSetCellLimit(g_iZombieAbility[iIndex], 0, 1)) : (g_iZombieAbility2[iIndex] = iSetCellLimit(g_iZombieAbility2[iIndex], 0, 1));
			main ? (g_iZombieAmount[iIndex] = kvSuperTanks.GetNum("Zombie Ability/Zombie Amount", 10)) : (g_iZombieAmount2[iIndex] = kvSuperTanks.GetNum("Zombie Ability/Zombie Amount", g_iZombieAmount[iIndex]));
			main ? (g_iZombieAmount[iIndex] = iSetCellLimit(g_iZombieAmount[iIndex], 1, 100)) : (g_iZombieAmount2[iIndex] = iSetCellLimit(g_iZombieAmount2[iIndex], 1, 100));
			kvSuperTanks.Rewind();
		}
	}
	delete kvSuperTanks;
}

public void ST_Ability(int client)
{
	int iZombieAbility = !g_bTankConfig[ST_TankType(client)] ? g_iZombieAbility[ST_TankType(client)] : g_iZombieAbility2[ST_TankType(client)];
	if (iZombieAbility == 1 && bIsTank(client))
	{
		g_iZombieInterval[client]++;
		int iZombieAmount = !g_bTankConfig[ST_TankType(client)] ? g_iZombieAmount[ST_TankType(client)] : g_iZombieAmount2[ST_TankType(client)];
		if (g_iZombieInterval[client] >= iZombieAmount)
		{
			for (int iZombie = 1; iZombie <= iZombieAmount; iZombie++)
			{
				char sCommand[32];
				sCommand = bIsL4D2Game() ? "z_spawn_old" : "z_spawn";
				int iCmdFlags = GetCommandFlags(sCommand);
				SetCommandFlags(sCommand, iCmdFlags & ~FCVAR_CHEAT);
				FakeClientCommand(client, "%s zombie area", sCommand);
				SetCommandFlags(sCommand, iCmdFlags|FCVAR_CHEAT);
			}
			g_iZombieInterval[client] = 0;
		}
	}
}