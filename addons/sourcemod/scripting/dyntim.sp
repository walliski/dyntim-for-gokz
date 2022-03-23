#include <sourcemod>
#include <sdktools>

#include <gokz/core> // For getting server default mode
#include <gokz/localdb> // For GetCurrentMapID
#include <gokz/localranks> // For DB structure

#include <autoexecconfig>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "DynTim for GOKZ",
    author = "Walliski",
    description = "Dynamic Timelimit based on average map completion time.",
    version = "1.1.0",
    url = "https://github.com/walliski/dyntim-for-gokz"
};

Database gH_DB = null;
ConVar gCV_dyntim_timelimit_min;
ConVar gCV_dyntim_timelimit_max;
ConVar gCV_dyntim_timelimit_default;
ConVar gCV_dyntim_multiplier;

bool gB_allow_roundtime_change = false;

public void OnPluginStart()
{
    CreateConVars();

    // Unlock roundtime's 60 minutes upper cap.
    SetConVarBounds(FindConVar("mp_roundtime"), ConVarBound_Upper, true, gCV_dyntim_timelimit_max.FloatValue);
}

public void OnMapTimeLeftChanged()
{
    int newTimeleft = FindConVar("mp_timelimit").IntValue;
    SetRoundTime(newTimeleft);
}

public void OnMapEnd()
{
    // Disallow changes until we load in a new map.
    gB_allow_roundtime_change = false;
}

void CreateConVars()
{
    AutoExecConfig_SetFile("plugins.dyntime", "sourcemod");
    AutoExecConfig_SetCreateFile(true);

    gCV_dyntim_timelimit_min = AutoExecConfig_CreateConVar("dyntim_timelimit_min", "15", "If calculated timelimit is smaller than this, use this value instead. (Minutes)", _, true, 0.0);
    gCV_dyntim_timelimit_max = AutoExecConfig_CreateConVar("dyntim_timelimit_max", "180", "If calculated timelimit is bigger than this, use this value instead. (Minutes)", _, true, 0.0);
    gCV_dyntim_timelimit_default = AutoExecConfig_CreateConVar("dyntim_timelimit_default", "25", "Default timelimit if there are too few runs on the server to calculate one. (Minutes)", _, true, 0.0);
    gCV_dyntim_multiplier = AutoExecConfig_CreateConVar("dyntim_multiplier", "1.0", "Multiply the resulting timelimit with this, before checking min and max values.");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

public void OnAllPluginsLoaded()
{
    gH_DB = GOKZ_DB_GetDatabase();
}

public void GOKZ_DB_OnDatabaseConnect(DatabaseType DBType)
{
    gH_DB = GOKZ_DB_GetDatabase();
}

// SQL for getting average PB time, taken from GOKZ LocalRanks plugin.
char sql_getaverage[] = "\
SELECT AVG(PBTime), COUNT(*) \
    FROM \
    (SELECT MIN(Times.RunTime) AS PBTime \
    FROM Times \
    INNER JOIN MapCourses ON Times.MapCourseID=MapCourses.MapCourseID \
    INNER JOIN Players ON Times.SteamID32=Players.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    AND MapCourses.Course=0 AND Times.Mode=%d \
    GROUP BY Times.SteamID32) AS PBTimes";

public void GOKZ_DB_OnMapSetup(int mapID)
{
    DB_SetDynamicTimelimit(mapID);
}

void DB_SetDynamicTimelimit(int mapID)
{
    char query[1024];
    int mode = GOKZ_GetDefaultMode();
    Transaction txn = SQL_CreateTransaction();

    FormatEx(query, sizeof(query), sql_getaverage, mapID, mode);
    txn.AddQuery(query);

    SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SetDynamicTimelimit, DB_TxnFailure_Generic, _, DBPrio_High);
}

void DB_TxnSuccess_SetDynamicTimelimit(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
    if (!SQL_FetchRow(results[0]))
    {
        return;
    }

    // Allowing the roundtime to change at this point. Without this, changes to timelimit would throw errors as not
    // gamerules etc. would have been initialized soon enough.
    gB_allow_roundtime_change = true;

    int mapCompletions = SQL_FetchInt(results[0], 1);
    if (mapCompletions < 5) // We dont want to base the avg time on too few times.
    {
        SetTimeLimit(gCV_dyntim_timelimit_default.IntValue);
        return;
    }

    // DB has the times in ms. We convert it to seconds.
    int averageTime = RoundToNearest(SQL_FetchInt(results[0], 0) / 1000.0);

    int newTime = 0;

    // Do some magic scaling for lower numbers:
    if (averageTime <= 60) newTime = averageTime * 16;
    else if (averageTime <= 90) newTime = averageTime * 12;
    else if (averageTime <= 120) newTime = averageTime * 10;
    else if (averageTime <= 150) newTime = averageTime * 9;
    else if (averageTime <= 180) newTime = averageTime * 7;
    else if (averageTime <= 300) newTime = averageTime * 6;
    else if (averageTime <= 360) newTime = averageTime * 5;
    else if (averageTime <= 420) newTime = averageTime * 4;
    else newTime = averageTime * 3;

    int newTimeMinutes = RoundToNearest((newTime * gCV_dyntim_multiplier.FloatValue)/60.0);

    // Make sure the values are not too high or low.
    int min = gCV_dyntim_timelimit_min.IntValue;
    int max = gCV_dyntim_timelimit_max.IntValue;
    newTimeMinutes = newTimeMinutes < min ? min : newTimeMinutes;
    newTimeMinutes = newTimeMinutes > max ? max : newTimeMinutes;

    SetTimeLimit(newTimeMinutes);
}

// TxnFailure helper taken from GOKZ.
public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    LogError("Database transaction error: %s", error);
}

public void SetRoundTime(int roundTimeMinutes)
{
    if (!gB_allow_roundtime_change) return;

    int newRoundTime = roundTimeMinutes * 60;
    GameRules_SetProp("m_iRoundTime", newRoundTime);

    FindConVar("mp_roundtime").SetInt(roundTimeMinutes);
}

public void SetTimeLimit(int timelimitMinutes)
{
    char timelimitBuffer[32];
    Format(timelimitBuffer, sizeof(timelimitBuffer), "mp_timelimit %i", timelimitMinutes);
    ServerCommand(timelimitBuffer);
}
