# SDDM login theme

sddm-astronaut-theme (in `packages-aur.txt`), `pixel_sakura` variant.
Installing the package does not activate it — two root-owned steps:

```sh
# pick the variant (the theme's own mechanism — a line in its metadata)
sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/pixel_sakura.conf|' \
    /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

# point SDDM at the theme
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/10-theme.conf
```

Caveat: `metadata.desktop` belongs to the package, so a theme update resets
the variant to `astronaut` — re-run the first command after upgrades.

Preview variants without root: copy the theme dir somewhere user-owned, edit
`ConfigFile=` in the copy's `metadata.desktop`, then
`sddm-greeter-qt6 --test-mode --theme <copy>`.
