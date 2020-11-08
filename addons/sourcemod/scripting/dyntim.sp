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
    version = "0.0.1",
    url = "https://github.com/walliski/dyntim-for-gokz"
};

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
