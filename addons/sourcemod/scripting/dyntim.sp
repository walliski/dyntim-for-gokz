#include <sourcemod>

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
    version = "1.0.0",
    url = "https://github.com/walliski/dyntim-for-gokz"
};

Database gH_DB = null;

public void OnPluginStart()
{
    CreateConVars();
}

ConVar gCV_dyntim_timelimit_min;
ConVar gCV_dyntim_timelimit_max;

void CreateConVars()
{
    AutoExecConfig_SetFile("plugins.dyntime", "sourcemod");
    AutoExecConfig_SetCreateFile(true);

    gCV_dyntim_timelimit_min = AutoExecConfig_CreateConVar("dyntim_timelimit_min", "15", "If calculated timelimit is smaller than this, use this value instead. (Minutes)", _, true, 0.0);
    gCV_dyntim_timelimit_max = AutoExecConfig_CreateConVar("dyntim_timelimit_max", "180", "If calculated timelimit is bigger than this, use this value instead. (Minutes)", _, true, 0.0);

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

    int mapCompletions = SQL_FetchInt(results[0], 1);
    if (mapCompletions < 5) // We dont want to base the avg time on too few times.
    {
        return;
    }

    // DB has the times in ms. We convert it to seconds.
    int averageTime = RoundToNearest(SQL_FetchInt(results[0], 0) / 1000.0);

    int newTime = 0;

    // Do some magic scaling for lower numbers:
    if (averageTime <= 60) newTime = averageTime * 20;
    else if (averageTime <= 120) newTime = averageTime * 12;
    else if (averageTime <= 180) newTime = averageTime * 10;
    else if (averageTime <= 300) newTime = averageTime * 7;
    else if (averageTime <= 600) newTime = averageTime * 4;
    else newTime = averageTime * 3;

    int newTimeMinutes = RoundToNearest(newTime/60.0);

    // Make sure the values are not too high or low.
    int min = gCV_dyntim_timelimit_min.IntValue;
    int max = gCV_dyntim_timelimit_max.IntValue;
    newTimeMinutes = newTimeMinutes < min ? min : newTimeMinutes;
    newTimeMinutes = newTimeMinutes > max ? max : newTimeMinutes;

    // Roundtime cannot be over 60 minutes.
    int roundTime = newTimeMinutes > 60 ? 60 : newTimeMinutes;

    char buffer[32];
    Format(buffer, sizeof(buffer), "mp_timelimit %i", newTimeMinutes);
    ServerCommand(buffer);

    Format(buffer, sizeof(buffer), "mp_roundtime %i", roundTime);
    ServerCommand(buffer);
    ServerCommand("mp_restartgame 1"); // Need to restart for Roundtime to take place.
}

// TxnFailure helper taken from GOKZ.
public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    LogError("Database transaction error: %s", error);
}
