# minecraftcli

A small Ruby CLI for looking up Minecraft player info — UUIDs, name history, and capes — straight from your terminal.

<img src="minecraftcli-sr.gif" width="100%" alt="minecraftcli demo" />

## Features

- Look up a player's UUID and current profile
- View name change history
- List capes the player has owned
- Interactive REPL or one-shot lookups via flags

## Install

Requires Ruby `>= 2.7` and Chrome (used headlessly for NameMC fallback).

```bash
git clone https://github.com/johncastro/minecraftcli.git
cd minecraftcli
bundle install
```

## Usage

Start the interactive session:

```bash
./bin/minecraftcli
```

Then use commands like:

```
lookup <username>
help
clear
exit
```

Or do a one-shot lookup:

```bash
./bin/minecraftcli --user <username>
```

## Data sources

- [Mojang API](https://api.mojang.com) — UUID and profile
- [Ashcon API](https://api.ashcon.app) — name history
- [capes.dev](https://api.capes.dev) — cape history
- [NameMC](https://namemc.com) — supplemental aliases/capes (via headless Chrome)

## License

MIT
# minecraftcli
