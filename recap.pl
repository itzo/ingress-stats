#!/usr/bin/env perl
use strict;
use warnings;

use Switch;     #for case statements
use POSIX;      #for the floor function

# usage
# ./recap input.csv

my ($timestamp, $player, $action);
my %player_table;
my @actions = ('AP', 'deployed', 'destroyed an', 'destroyed a', 'destroyed the', 'linked', 'created', 'captured');

# Read data from csv
open (LIST, "$ARGV[0]") or die "Can't open log file: $!";
while (<LIST>) {
    chomp $_;
    next unless $_ =~ /(\d{2}\:\d{2})\s+<(\w+)>\s+(\w+)/;
    next if $_ =~ /Your/;
    $timestamp = $1;    # read it in in case we ever need it
    $player = $2;
    $action = $3;
    # Grab the different kinds of destroyed actions
    if ( $action eq 'destroyed' )
    {
        $_ =~ /\d{2}\:\d{2}\s+<\w+>\s+(\w+\s\w+)/;
        $action = $1;
    }

    $player_table{"$player"}{"$action"} += 1;
}
close LIST;

# Calculate Player AP
for my $playername ( keys %player_table ) {
    for my $playeraction ( keys %{ $player_table{$playername} } ) {
         switch ($playeraction) {
            case "deployed"
            { 
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*125;
                # Plus 250 bonus for deploying the last resonator
                # For this I'm approximating 1 last hit per slightly less than 6 deploys (or 17%).
                # So with 400 deployed resonators, assume 68 last resonator hits and
                # add 68 * 250 to your deployed AP score.
                my $last_resonator_bonus = floor( $player_table{$playername}{$playeraction} * 17/100 * 250 );
                $player_table{$playername}{"AP"} += $last_resonator_bonus; 
            }
            # e.g. destroyed an L7 resonator
            case "destroyed an"
            { 
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*75;
            }
            # e.g. destroyed a Control Field
            case "destroyed a"
            {
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*750;
            }
            # e.g. destroyed the Link
            case "destroyed the"
            {  
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*187;
            }
            case "linked"       
            { 
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*313; 
            }
            case "created"      
            { 
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*1250; 
            }
            case "captured"     
            { 
                $player_table{$playername}{"AP"} += $player_table{$playername}{$playeraction}*500;
            }
            else { print "Unrecognized: $playeraction\n" }
         }
    }
}

# Set nonexistent actions to 0
for my $player ( sort keys %player_table )
{   
    for my $action ( sort @actions ) 
    {
        if ( !exists ($player_table{$player}{$action}) )
        {
            $player_table{$player}{$action} = 0;
        }
    }
}

# Print results table
print "-----------------------------------------------------------------------------------\n";
print "Player                AP \tCAP \tCRE \tDEP \tDSF \tDSR \tDSL \tLIN\n";
print "-----------------------------------------------------------------------------------\n";
foreach my $player (
    sort { $player_table{$b}->{"AP"} <=> $player_table{$a}->{"AP"} }
    keys %player_table
    )
{   
    my $friendly_playername = $player;
    while (length($friendly_playername) < 20) 
    {
        $friendly_playername .= ' ';
    }
    print "$friendly_playername  ";

    for my $action ( sort @actions ) 
    {
        print "$player_table{$player}{$action} \t";
    }
    print "\n";
}
