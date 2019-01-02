/**
 * Super Tanks++: a L4D/L4D2 SourceMod Plugin
 * Copyright (C) 2018  Alfred "Crasher_3637/Psyk0tik" Llagas
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

#include <sourcemod>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Aimless Ability",
	author = ST_AUTHOR,
	description = "The Super Tank prevents survivors from aiming.",
	version = ST_VERSION,
	url = ST_URL
};

#define ST_MENU_AIMLESS "Aimless Ability"

bool g_bAimless[MAXPLAYERS + 1], g_bAimless2[MAXPLAYERS + 1], g_bAimless3[MAXPLAYERS + 1], g_bAimless4[MAXPLAYERS + 1], g_bAimless5[MAXPLAYERS + 1], g_bCloneInstalled, g_bLateLoad, g_bTankConfig[ST_MAXTYPES + 1];

char g_sAimlessEffect[ST_MAXTYPES + 1][4], g_sAimlessEffect2[ST_MAXTYPES + 1][4], g_sAimlessMessage[ST_MAXTYPES + 1][3], g_sAimlessMessage2[ST_MAXTYPES + 1][3];

float g_flAimlessAngle[MAXPLAYERS + 1][3], g_flAimlessChance[ST_MAXTYPES + 1], g_flAimlessChance2[ST_MAXTYPES + 1], g_flAimlessDuration[ST_MAXTYPES + 1], g_flAimlessDuration2[ST_MAXTYPES + 1], g_flAimlessRange[ST_MAXTYPES + 1], g_flAimlessRange2[ST_MAXTYPES + 1], g_flAimlessRangeChance[ST_MAXTYPES + 1], g_flAimlessRangeChance2[ST_MAXTYPES + 1], g_flHumanCooldown[ST_MAXTYPES + 1], g_flHumanCooldown2[ST_MAXTYPES + 1];

int g_iAimlessAbility[ST_MAXTYPES + 1], g_iAimlessAbility2[ST_MAXTYPES + 1], g_iAimlessCount[MAXPLAYERS + 1], g_iAimlessHit[ST_MAXTYPES + 1], g_iAimlessHit2[ST_MAXTYPES + 1], g_iAimlessHitMode[ST_MAXTYPES + 1], g_iAimlessHitMode2[ST_MAXTYPES + 1], g_iAimlessOwner[MAXPLAYERS + 1], g_iHumanAbility[ST_MAXTYPES + 1], g_iHumanAbility2[ST_MAXTYPES + 1], g_iHumanAmmo[ST_MAXTYPES + 1], g_iHumanAmmo2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "\"[ST++] Aimless Ability\" only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCloneInstalled = LibraryExists("st_clone");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = false;
	}
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("super_tanks++.phrases");

	RegConsoleCmd("sm_st_aimless", cmdAimlessInfo, "View information about the Aimless ability.");

	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer, "24"))
			{
				OnClientPutInServer(iPlayer);
			}
		}

		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	vReset();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	vReset2(client);
}

public void OnMapEnd()
{
	vReset();
}

public Action cmdAimlessInfo(int client, int args)
{
	if (!ST_PluginEnabled())
	{
		ReplyToCommand(client, "%s Super Tanks++\x01 is disabled.", ST_TAG4);

		return Plugin_Handled;
	}

	if (!bIsValidClient(client, "0245"))
	{
		ReplyToCommand(client, "%s This command is to be used only in-game.", ST_TAG);

		return Plugin_Handled;
	}

	switch (IsVoteInProgress())
	{
		case true: ReplyToCommand(client, "%s %t", ST_TAG2, "Vote in Progress");
		case false: vAimlessMenu(client, 0);
	}

	return Plugin_Handled;
}

static void vAimlessMenu(int client, int item)
{
	Menu mAbilityMenu = new Menu(iAimlessMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
	mAbilityMenu.SetTitle("Aimless Ability Information");
	mAbilityMenu.AddItem("Status", "Status");
	mAbilityMenu.AddItem("Ammunition", "Ammunition");
	mAbilityMenu.AddItem("Buttons", "Buttons");
	mAbilityMenu.AddItem("Cooldown", "Cooldown");
	mAbilityMenu.AddItem("Details", "Details");
	mAbilityMenu.AddItem("Duration", "Duration");
	mAbilityMenu.AddItem("Human Support", "Human Support");
	mAbilityMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int iAimlessMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0: ST_PrintToChat(param1, "%s %t", ST_TAG3, iAimlessAbility(param1) == 0 ? "AbilityStatus1" : "AbilityStatus2");
				case 1: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityAmmo", iHumanAmmo(param1) - g_iAimlessCount[param1], iHumanAmmo(param1));
				case 2: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityButtons2");
				case 3: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityCooldown", flHumanCooldown(param1));
				case 4: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AimlessDetails");
				case 5: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityDuration", flAimlessDuration(param1));
				case 6: ST_PrintToChat(param1, "%s %t", ST_TAG3, iHumanAbility(param1) == 0 ? "AbilityHumanSupport1" : "AbilityHumanSupport2");
			}

			if (bIsValidClient(param1, "24"))
			{
				vAimlessMenu(param1, menu.Selection);
			}
		}
		case MenuAction_Display:
		{
			char sMenuTitle[255];
			Panel panel = view_as<Panel>(param2);
			Format(sMenuTitle, sizeof(sMenuTitle), "%T", "AimlessMenu", param1);
			panel.SetTitle(sMenuTitle);
		}
		case MenuAction_DisplayItem:
		{
			char sMenuOption[255];
			switch (param2)
			{
				case 0:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Status", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 1:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Ammunition", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 2:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Buttons", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 3:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Cooldown", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 4:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Details", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 5:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Duration", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 6:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "HumanSupport", param1);
					return RedrawMenuItem(sMenuOption);
				}
			}
		}
	}

	return 0;
}

public void ST_OnDisplayMenu(Menu menu)
{
	menu.AddItem(ST_MENU_AIMLESS, ST_MENU_AIMLESS);
}

public void ST_OnMenuItemSelected(int client, const char[] info)
{
	if (StrEqual(info, ST_MENU_AIMLESS, false))
	{
		vAimlessMenu(client, 0);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!ST_PluginEnabled())
	{
		return Plugin_Continue;
	}

	if (g_bAimless[client])
	{
		TeleportEntity(client, NULL_VECTOR, g_flAimlessAngle[client], NULL_VECTOR);
	}

	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && bIsValidClient(victim, "0234") && damage > 0.0)
	{
		char sClassname[32];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if (ST_TankAllowed(attacker) && ST_CloneAllowed(attacker, g_bCloneInstalled) && (iAimlessHitMode(attacker) == 0 || iAimlessHitMode(attacker) == 1) && bIsSurvivor(victim))
		{
			if (StrEqual(sClassname, "weapon_tank_claw") || StrEqual(sClassname, "tank_rock"))
			{
				vAimlessHit(victim, attacker, flAimlessChance(attacker), iAimlessHit(attacker), "1", "1");
			}
		}
		else if (ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && (iAimlessHitMode(victim) == 0 || iAimlessHitMode(victim) == 2) && bIsSurvivor(attacker))
		{
			if (StrEqual(sClassname, "weapon_melee"))
			{
				vAimlessHit(attacker, victim, flAimlessChance(victim), iAimlessHit(victim), "1", "2");
			}
		}
	}
}

public void ST_OnConfigsLoaded(const char[] savepath, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);

	for (int iIndex = ST_MinType(); iIndex <= ST_MaxType(); iIndex++)
	{
		char sTankName[33];
		Format(sTankName, sizeof(sTankName), "Tank #%i", iIndex);
		if (kvSuperTanks.JumpToKey(sTankName))
		{
			switch (main)
			{
				case true:
				{
					g_bTankConfig[iIndex] = false;

					g_iHumanAbility[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Human Ability", 0);
					g_iHumanAbility[iIndex] = iClamp(g_iHumanAbility[iIndex], 0, 1);
					g_iHumanAmmo[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Human Ammo", 5);
					g_iHumanAmmo[iIndex] = iClamp(g_iHumanAmmo[iIndex], 0, 9999999999);
					g_flHumanCooldown[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Human Cooldown", 30.0);
					g_flHumanCooldown[iIndex] = flClamp(g_flHumanCooldown[iIndex], 0.0, 9999999999.0);
					g_iAimlessAbility[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Ability Enabled", 0);
					g_iAimlessAbility[iIndex] = iClamp(g_iAimlessAbility[iIndex], 0, 1);
					kvSuperTanks.GetString("Aimless Ability/Ability Effect", g_sAimlessEffect[iIndex], sizeof(g_sAimlessEffect[]), "0");
					kvSuperTanks.GetString("Aimless Ability/Ability Message", g_sAimlessMessage[iIndex], sizeof(g_sAimlessMessage[]), "0");
					g_flAimlessChance[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Chance", 33.3);
					g_flAimlessChance[iIndex] = flClamp(g_flAimlessChance[iIndex], 0.0, 100.0);
					g_flAimlessDuration[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Duration", 5.0);
					g_flAimlessDuration[iIndex] = flClamp(g_flAimlessDuration[iIndex], 0.1, 9999999999.0);
					g_iAimlessHit[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Aimless Hit", 0);
					g_iAimlessHit[iIndex] = iClamp(g_iAimlessHit[iIndex], 0, 1);
					g_iAimlessHitMode[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Aimless Hit Mode", 0);
					g_iAimlessHitMode[iIndex] = iClamp(g_iAimlessHitMode[iIndex], 0, 2);
					g_flAimlessRange[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Range", 150.0);
					g_flAimlessRange[iIndex] = flClamp(g_flAimlessRange[iIndex], 1.0, 9999999999.0);
					g_flAimlessRangeChance[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Range Chance", 15.0);
					g_flAimlessRangeChance[iIndex] = flClamp(g_flAimlessRangeChance[iIndex], 0.0, 100.0);
				}
				case false:
				{
					g_bTankConfig[iIndex] = true;

					g_iHumanAbility2[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Human Ability", g_iHumanAbility[iIndex]);
					g_iHumanAbility2[iIndex] = iClamp(g_iHumanAbility2[iIndex], 0, 1);
					g_iHumanAmmo2[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Human Ammo", g_iHumanAmmo[iIndex]);
					g_iHumanAmmo2[iIndex] = iClamp(g_iHumanAmmo2[iIndex], 0, 9999999999);
					g_flHumanCooldown2[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Human Cooldown", g_flHumanCooldown[iIndex]);
					g_flHumanCooldown2[iIndex] = flClamp(g_flHumanCooldown2[iIndex], 0.0, 9999999999.0);
					g_iAimlessAbility2[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Ability Enabled", g_iAimlessAbility[iIndex]);
					g_iAimlessAbility2[iIndex] = iClamp(g_iAimlessAbility2[iIndex], 0, 1);
					kvSuperTanks.GetString("Aimless Ability/Ability Effect", g_sAimlessEffect2[iIndex], sizeof(g_sAimlessEffect2[]), g_sAimlessEffect[iIndex]);
					kvSuperTanks.GetString("Aimless Ability/Ability Message", g_sAimlessMessage2[iIndex], sizeof(g_sAimlessMessage2[]), g_sAimlessMessage[iIndex]);
					g_flAimlessChance2[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Chance", g_flAimlessChance[iIndex]);
					g_flAimlessChance2[iIndex] = flClamp(g_flAimlessChance2[iIndex], 0.0, 100.0);
					g_flAimlessDuration2[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Duration", g_flAimlessDuration[iIndex]);
					g_flAimlessDuration2[iIndex] = flClamp(g_flAimlessDuration2[iIndex], 0.1, 9999999999.0);
					g_iAimlessHit2[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Aimless Hit", g_iAimlessHit[iIndex]);
					g_iAimlessHit2[iIndex] = iClamp(g_iAimlessHit2[iIndex], 0, 1);
					g_iAimlessHitMode2[iIndex] = kvSuperTanks.GetNum("Aimless Ability/Aimless Hit Mode", g_iAimlessHitMode[iIndex]);
					g_iAimlessHitMode2[iIndex] = iClamp(g_iAimlessHitMode2[iIndex], 0, 2);
					g_flAimlessRange2[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Range", g_flAimlessRange[iIndex]);
					g_flAimlessRange2[iIndex] = flClamp(g_flAimlessRange2[iIndex], 1.0, 9999999999.0);
					g_flAimlessRangeChance2[iIndex] = kvSuperTanks.GetFloat("Aimless Ability/Aimless Range Chance", g_flAimlessRangeChance[iIndex]);
					g_flAimlessRangeChance2[iIndex] = flClamp(g_flAimlessRangeChance2[iIndex], 0.0, 100.0);
				}
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_OnEventFired(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "player_death"))
	{
		int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
		if (ST_TankAllowed(iTank, "024"))
		{
			vRemoveAimless(iTank);
		}
	}
}

public void ST_OnAbilityActivated(int tank)
{
	if (ST_TankAllowed(tank) && (!ST_TankAllowed(tank, "5") || iHumanAbility(tank) == 0) && ST_CloneAllowed(tank, g_bCloneInstalled) && iAimlessAbility(tank) == 1)
	{
		vAimlessAbility(tank);
	}
}

public void ST_OnButtonPressed(int tank, int button)
{
	if (ST_TankAllowed(tank, "02345") && ST_CloneAllowed(tank, g_bCloneInstalled))
	{
		if (button & ST_SUB_KEY == ST_SUB_KEY)
		{
			if (iAimlessAbility(tank) == 1 && iHumanAbility(tank) == 1)
			{
				if (!g_bAimless2[tank] && !g_bAimless3[tank])
				{
					vAimlessAbility(tank);
				}
				else if (g_bAimless2[tank])
				{
					ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessHuman3");
				}
				else if (g_bAimless3[tank])
				{
					ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessHuman4");
				}
			}
		}
	}
}

public void ST_OnChangeType(int tank)
{
	vRemoveAimless(tank);
}

static void vAimlessAbility(int tank)
{
	if (g_iAimlessCount[tank] < iHumanAmmo(tank) && iHumanAmmo(tank) > 0)
	{
		g_bAimless4[tank] = false;
		g_bAimless5[tank] = false;

		float flAimlessRange = !g_bTankConfig[ST_TankType(tank)] ? g_flAimlessRange[ST_TankType(tank)] : g_flAimlessRange2[ST_TankType(tank)],
			flAimlessRangeChance = !g_bTankConfig[ST_TankType(tank)] ? g_flAimlessRangeChance[ST_TankType(tank)] : g_flAimlessRangeChance2[ST_TankType(tank)],
			flTankPos[3];

		GetClientAbsOrigin(tank, flTankPos);

		int iSurvivorCount;

		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor, "234"))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);

				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flAimlessRange)
				{
					vAimlessHit(iSurvivor, tank, flAimlessRangeChance, iAimlessAbility(tank), "2", "3");

					iSurvivorCount++;
				}
			}
		}

		if (iSurvivorCount == 0)
		{
			if (ST_TankAllowed(tank, "5") && iHumanAbility(tank) == 1)
			{
				ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessHuman5");
			}
		}
	}
	else if (ST_TankAllowed(tank, "5") && iHumanAbility(tank) == 1)
	{
		ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessAmmo");
	}
}

static void vAimlessHit(int survivor, int tank, float chance, int enabled, const char[] message, const char[] mode)
{
	if (enabled == 1 && bIsSurvivor(survivor))
	{
		if (g_iAimlessCount[tank] < iHumanAmmo(tank) && iHumanAmmo(tank) > 0)
		{
			if (GetRandomFloat(0.1, 100.0) <= chance && !g_bAimless[survivor])
			{
				g_bAimless[survivor] = true;
				g_iAimlessOwner[survivor] = tank;

				if (ST_TankAllowed(tank, "5") && iHumanAbility(tank) == 1 && StrEqual(mode, "3") && !g_bAimless2[tank])
				{
					g_bAimless2[tank] = true;
					g_iAimlessCount[tank]++;

					ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessHuman", g_iAimlessCount[tank], iHumanAmmo(tank));
				}

				GetClientEyeAngles(survivor, g_flAimlessAngle[survivor]);

				DataPack dpStopAimless;
				CreateDataTimer(flAimlessDuration(tank), tTimerStopAimless, dpStopAimless, TIMER_FLAG_NO_MAPCHANGE);
				dpStopAimless.WriteCell(GetClientUserId(survivor));
				dpStopAimless.WriteCell(GetClientUserId(tank));
				dpStopAimless.WriteString(message);

				char sAimlessEffect[4];
				sAimlessEffect = !g_bTankConfig[ST_TankType(tank)] ? g_sAimlessEffect[ST_TankType(tank)] : g_sAimlessEffect2[ST_TankType(tank)];
				vEffect(survivor, tank, sAimlessEffect, mode);

				char sAimlessMessage[3];
				sAimlessMessage = !g_bTankConfig[ST_TankType(tank)] ? g_sAimlessMessage[ST_TankType(tank)] : g_sAimlessMessage2[ST_TankType(tank)];
				if (StrContains(sAimlessMessage, message) != -1)
				{
					char sTankName[33];
					ST_TankName(tank, sTankName);
					ST_PrintToChatAll("%s %t", ST_TAG2, "Aimless", sTankName, survivor);
				}
			}
			else if (StrEqual(mode, "3") && !g_bAimless2[tank])
			{
				if (ST_TankAllowed(tank, "5") && iHumanAbility(tank) == 1 && !g_bAimless4[tank])
				{
					g_bAimless4[tank] = true;

					ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessHuman2");
				}
			}
		}
		else if (ST_TankAllowed(tank, "5") && iHumanAbility(tank) == 1 && !g_bAimless5[tank])
		{
			g_bAimless5[tank] = true;

			ST_PrintToChat(tank, "%s %t", ST_TAG3, "AimlessAmmo");
		}
	}
}

static void vRemoveAimless(int tank)
{
	for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
	{
		if (bIsSurvivor(iSurvivor, "24") && g_bAimless[iSurvivor] && g_iAimlessOwner[iSurvivor] == tank)
		{
			g_bAimless[iSurvivor] = false;
			g_iAimlessOwner[iSurvivor] = 0;
		}
	}

	vReset2(tank);
}

static void vReset()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer, "24"))
		{
			vReset2(iPlayer);

			g_iAimlessOwner[iPlayer] = 0;
		}
	}
}

static void vReset2(int tank)
{
	g_bAimless[tank] = false;
	g_bAimless2[tank] = false;
	g_bAimless3[tank] = false;
	g_bAimless4[tank] = false;
	g_bAimless5[tank] = false;
	g_iAimlessCount[tank] = 0;
}

static float flAimlessChance(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_flAimlessChance[ST_TankType(tank)] : g_flAimlessChance2[ST_TankType(tank)];
}

static float flAimlessDuration(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_flAimlessDuration[ST_TankType(tank)] : g_flAimlessDuration2[ST_TankType(tank)];
}

static float flHumanCooldown(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_flHumanCooldown[ST_TankType(tank)] : g_flHumanCooldown2[ST_TankType(tank)];
}

static int iAimlessAbility(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAimlessAbility[ST_TankType(tank)] : g_iAimlessAbility2[ST_TankType(tank)];
}

static int iAimlessHit(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAimlessHit[ST_TankType(tank)] : g_iAimlessHit2[ST_TankType(tank)];
}

static int iAimlessHitMode(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAimlessHitMode[ST_TankType(tank)] : g_iAimlessHitMode2[ST_TankType(tank)];
}

static int iHumanAbility(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iHumanAbility[ST_TankType(tank)] : g_iHumanAbility2[ST_TankType(tank)];
}

static int iHumanAmmo(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iHumanAmmo[ST_TankType(tank)] : g_iHumanAmmo2[ST_TankType(tank)];
}

public Action tTimerStopAimless(Handle timer, DataPack pack)
{
	pack.Reset();

	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!bIsSurvivor(iSurvivor) || !g_bAimless[iSurvivor])
	{
		g_bAimless[iSurvivor] = false;
		g_iAimlessOwner[iSurvivor] = 0;

		return Plugin_Stop;
	}

	int iTank = GetClientOfUserId(pack.ReadCell());
	if (!ST_TankAllowed(iTank) || !ST_CloneAllowed(iTank, g_bCloneInstalled))
	{
		g_bAimless[iSurvivor] = false;
		g_iAimlessOwner[iSurvivor] = 0;

		return Plugin_Stop;
	}

	g_bAimless[iSurvivor] = false;
	g_bAimless2[iTank] = false;
	g_iAimlessOwner[iSurvivor] = 0;

	char sMessage[3];
	pack.ReadString(sMessage, sizeof(sMessage));

	if (ST_TankAllowed(iTank, "5") && iHumanAbility(iTank) == 1 && StrContains(sMessage, "2") != -1 && !g_bAimless3[iTank])
	{
		g_bAimless3[iTank] = true;

		ST_PrintToChat(iTank, "%s %t", ST_TAG3, "AimlessHuman6");

		if (g_iAimlessCount[iTank] < iHumanAmmo(iTank) && iHumanAmmo(iTank) > 0)
		{
			CreateTimer(flHumanCooldown(iTank), tTimerResetCooldown, GetClientUserId(iTank), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_bAimless3[iTank] = false;
		}
	}

	char sAimlessMessage[3];
	sAimlessMessage = !g_bTankConfig[ST_TankType(iTank)] ? g_sAimlessMessage[ST_TankType(iTank)] : g_sAimlessMessage2[ST_TankType(iTank)];
	if (StrContains(sAimlessMessage, sMessage) != -1)
	{
		ST_PrintToChatAll("%s %t", ST_TAG2, "Aimless2", iSurvivor);
	}

	return Plugin_Continue;
}

public Action tTimerResetCooldown(Handle timer, int userid)
{
	int iTank = GetClientOfUserId(userid);
	if (!ST_TankAllowed(iTank, "02345") || !ST_CloneAllowed(iTank, g_bCloneInstalled) || !g_bAimless3[iTank])
	{
		g_bAimless3[iTank] = false;

		return Plugin_Stop;
	}

	g_bAimless3[iTank] = false;

	ST_PrintToChat(iTank, "%s %t", ST_TAG3, "AimlessHuman7");

	return Plugin_Continue;
}