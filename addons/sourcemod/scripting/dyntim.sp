#include <sourcemod>

#include <gokz/core> // For getting server default mode
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