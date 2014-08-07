#!/usr/bin/perl
#
# by Tim Willis <tim@willishq.com>

use strict;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);
use vars qw($timer @signals);

my $last_active = time();
my $checking_for_idle = 0;
my $allow_auto_afk = 1;

$VERSION = "0.1";
%IRSSI = (
    authors     => "Tim Willis",
    contact     => "tim\@willishq.com",
    name        => "afk",
    description => "An auto nick changer script",
    license     => "MIT",
    changed     => "$VERSION",
);

sub debug {
    my ($str) = @_;
    my $test_mode = Irssi::settings_get_bool('afk_test_mode');

    if ($test_mode) {
        print CLIENTCRAP "%R[AFK]%n %Bdebug%n ".$str;
    }
}

sub change_nick {
    my ($server, $reason) = @_;

    my $nick = $server->{nick};

    my $orig_nick = $nick;
    my $delim = Irssi::settings_get_str("afk_delimiter");

    # remove reason
    $nick =~ s/\Q$delim\E.*$//g;
    if ($reason) {
        $nick = $nick.$delim.$reason;
    }
    if ($nick ne $orig_nick) {
        my $test_mode = Irssi::settings_get_bool('afk_test_mode');
        if (! $test_mode) {
            debug("Changing nick to ".$nick);
            $server->command('NICK '.$nick);
        } else {
            debug("Would have changed nick to ".$nick);
        }
    } else {
        debug("Nick is already ".$nick);
    }
}

sub cmd_afk { 
    my ($data, $server, $channel) = @_;

    $data =~ s/^\s+|\s+$//g;
    my @tokens = split(/\s+/, $data);

    if (@tokens > 1) {
        Irssi::print "afk usage: /afk [reason]";
        return 1;
    }

    my $reason = @tokens[0];

    $allow_auto_afk = $reason ? 0 : 1;

    change_nick($server, $reason);
}

# Check for a screensaver (osx only)
# Return 1 if we're active, 0 if we're idle.
sub is_active {
    my $returncode = system("ps -ef | ps ax | grep [S]creenSaverEngine > /dev/null;");
    return $returncode ? 1 : 0;
}

sub do_idle_check {
    debug("------");

    Irssi::timeout_remove($timer);

    my $timeout = Irssi::settings_get_int("afk_timeout");
    debug("Timeout: ".$timeout);
    debug("Auto AFK Allowed: ".$allow_auto_afk);

    if (is_active()){
        $last_active = time();
        # debug("Last Active Time: ".$last_active);
        my @servers = Irssi::servers();
        if ($allow_auto_afk) {
            change_nick($_, "") foreach(@servers);
        }
    }

    my $time_away = time() - $last_active;
    debug("Away for ".$time_away);

    if ($time_away >= $timeout) {
        my @servers = Irssi::servers();
        my $reason = Irssi::settings_get_str('afk_default_reason');
        if ($allow_auto_afk) {
            change_nick($_, $reason) foreach(@servers);
        }
    }

    if ($checking_for_idle) {
        $timer = Irssi::timeout_add(5000, "do_idle_check", undef);
        debug("Scheduling next idle check.");
    } else {
        debug("Idle check is off.");
    }
}

sub cmd_auto_afk {
    if (! $checking_for_idle) {
        $checking_for_idle = 1;
        print CLIENTCRAP '%R[AFK]%n Started idle check';
        do_idle_check();
    } else {
        $checking_for_idle = 0;
        print CLIENTCRAP '%R[AFK]%n Stopped idle check';
    }
}

Irssi::settings_add_str($IRSSI{name}, 'afk_delimiter', '_');
Irssi::settings_add_str($IRSSI{name}, 'afk_default_reason', 'afk');
Irssi::settings_add_int($IRSSI{name}, 'afk_timeout', 15*60);
Irssi::settings_add_bool($IRSSI{name}, 'afk_test_mode', 0);

Irssi::command_bind('afk', 'cmd_afk');
Irssi::command_bind('autoafk', 'cmd_auto_afk');

print CLIENTCRAP '%B>>%n '.$IRSSI{name}.' '.$VERSION.' loaded';
