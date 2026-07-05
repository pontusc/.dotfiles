# Walker

## Elephant (provider daemon)

Walker needs **elephant**, which is AUR-only — the CachyOS walker package
doesn't declare it. The providers the walker config uses are listed in
`packages-aur.txt`. One-time setup after install:

```sh
# elephant installs its own *user* unit (no packaged unit file exists):
elephant service enable
systemctl --user start elephant.service
```

The unit is `WantedBy=graphical-session.target`, which never activates in
this session — elephant is started explicitly from `config/autostart.lua`.

## Menus

Custom menus live in `.config/elephant/menus/` — `power.toml` drives the
SUPER+Escape power menu (walker on the elephant `menus:power` provider).
Elephant only scans the menus dir at provider setup: after adding or
renaming a menu file, `systemctl --user restart elephant`
(`elephant listproviders` should then show `menus:<name>`).
