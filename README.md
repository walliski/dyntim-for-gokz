# DynTim for GOKZ

Dynamic Timelimit for GOKZ. A small and simple plugin that will read the average map completion time for a map from the
local DB, and then try to calculate a more sensible timelimit based on that. This solves the problem of being stuck on
kz_mz for 30 minutes and having to spam rtv, vs. only having 30 minutes to complete kz_gy_agitation, and having to spam
extends. The times used is the times for the servers default mode.

The timelimit is calculated based on the average time of TP runs, if the total amount of times is higher than 5. The
average time is then multiplied with some hardcoded values. This makes short maps have a high timelimit in relation to
their average completion time (allows for completing them many times), while longer maps will not have that long
timelimit in relation to their average completion time (allows for completing them fewer times). The resulting value is
then checked to be inside the configurable limits, explained below.

## Installation

Copy the plugin into `csgo/addons/sourcemod/plugins`. After changing map or restarting the server, there will be a
config file generated in `csgo/cfg/sourcemod/plugins.dyntim.cfg`. In this file you can set the min and max values for
the calculated timelimit. You can also set a default timelimit in case it cannot be calculated. Note that this default
timelimit will override other configurations you might have!

```conf
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

// Default timelimit if there are too few runs on the server to calculate one. (Minutes)
// -
// Default: "25"
// Minimum: "0.000000"
dyntim_timelimit_default "25"

// Multiply the resulting timelimit with this, before checking min and max values.
// -
// Default: "1.0"
dyntim_multiplier "1.0"
```

## Compiling

To compile this plugin, you need the following includes:

1. [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz/src/master/)
2. [AutoExecConfig](https://github.com/Impact123/AutoExecConfig)

## Changelog

- **2.0.0** 23.3.2022  
  - **Breaking change:** Add default timelimit option.
  - Allow roundtime to be bigger than 60 minutes.
  - Change roundtime any time timelimit is changed.

- **1.1.0** 8.2.2021  
  - Added multiplier cvar so you can scale the resulting timelimit, in case you feel its consistently too high or low.
  - Lowered the resulting timelimits, and made the scaling a bit smoother, for shorter maps.

- **1.0.0** 8.11.2020  
  Initial release.

## Credits

- The code for getting the average time is copied from the
  [GOKZ repository](https://bitbucket.org/kztimerglobalteam/gokz/src/master/).
- [zer0k-z's fork](https://github.com/zer0k-z/lob-dyntim/) for default timelimit, and how to set roundtime bigger than
  60.
