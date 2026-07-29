#!/bin/zsh
set -e

link_wowfolder() {
    if [[ -d "$1" ]]; then
        link_expansion "$1/_classic_"
        link_expansion "$1/_classic_era_"
        link_expansion "$1/_classic_beta_"
        link_expansion "$1/_classic_ptr_"
        link_expansion "$1/_classic_era_ptr_"
        link_expansion "$1/_retail_"
        link_expansion "$1/_beta_"
        link_expansion "$1/_ptr_"
        link_expansion "$1/_xptr_"
    fi
}

link_expansion() {
    if [[ -d "$1" ]]; then
        echo "Linking Expansion $1"
        if [[ -d "$1/Interface/AddOns/MissingRaidBuffs" ]]; then
            echo "Removing MissingRaidBuffs in $1"
            rm -rf "$1/Interface/AddOns/MissingRaidBuffs"
        fi
        if [[ ! -d "$1/Interface/AddOns/MissingRaidBuffs" ]]; then
            echo "Adding MissingRaidBuffs in $1"
            mkdir -p "$1/Interface/AddOns"
            rsync -a  --link-dest="$PWD/" --exclude='.*' "$PWD/" "$1/Interface/AddOns/MissingRaidBuffs"
        fi
    fi
}

report_taskcomplete() {
    echo "Task Complete!"
}

# run the script
link_wowfolder "/Applications/World of Warcraft"
report_taskcomplete