# DynTim for GOKZ

Dynamic Timelimit for GOKZ. A small and simple plugin that will read the average map completion time for a map from the
local DB, and then try to calculate a more sensible timelimit based on that. This solves the problem of being stuck on
kz_mz for 30 minutes and having to spam rtv, vs. only having 30 minutes to complete kz_gy_agitation, and having to spam
extends.

The timelimit is calculated based on the average time of TP runs, if the total amount of times is higher than 5. The
average time is then multiplied with some hardcoded values. This makes short maps have a high timelimit in relation to
their average completion time (allows for completing them many times), while longer maps will not have that long
timelimit in relation to their average completion time (allows for completing them fewer times). The resulting value is
then checked to be inside the configurable limits, explained below.

## Installation

Copy the plugin into `csgo/addons/sourcemod/plugins`. After changing map or restarting the server, there will be a
config file generated in `csgo/cfg/sourcemod/plugins.dyntim.cfg`. In this file you can set the min and max values for
the calculated timelimit:

```
// If calculated timelimit is smaller than this, use this value instead. (Minutes)
// -
// Default: "15"
// Minimum: "0.000000"
dyntim_timelimit_min "15"

// If calculated timelimit is bigger than this, use this value instead. (Minutes)
// -
// Default: "180"
// Minimum: "0.000000"
dyntim_timelimit_max "180"
```

## Compiling

To compile this plugin, you need the following includes:

1. [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz/src/master/)
2. [AutoExecConfig](https://github.com/Impact123/AutoExecConfig)

## Changelog

- **1.0.0** 8.11.2020  
  Initial release.

## Credits

The code for getting the average time is copied from the
[GOKZ repository](https://bitbucket.org/kztimerglobalteam/gokz/src/master/).
