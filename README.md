# AFK and Auto AFK commands for IRSSI

## Requirements

* Mac OSX 10.9 or higher

## Installation

0. Place ``autoafk.pl`` in ``~/.irssi/scripts/``
0. Load script:
       
       /script load autoafk.pl

## Commands

    /afk <reason> - Change nick to nick_<reason>
    /afk          - Remove reason from nick
    /autoafk      - Toggle auto afk listener

## Configuration

    /SET afk_delimiter <char> // default: _
    /SET afk_default_reason <str> // default: afk
    /SET afk_timeout <num_seconds> // default: 900 seconds (15 min)
    /SET afk_test_mode [ON|OFF] //default: off
