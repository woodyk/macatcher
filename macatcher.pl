#!/usr/bin/perl
#
#

use strict;

$SIG{INT}  = \&sig_handler;
$SIG{TERM} = \&sig_handler;

my @fields;
my $tshark   = "/usr/bin/tshark";
my $int      = "wlan0";
my $packets  = "1000";
my $tcommand = "$tshark -i $int -c $packets -s0 -Tjson";
my $iwconfig = "/sbin/iwconfig";
my $channels = "13";
my $icommand = "$iwconfig $int channel ";
our $pid;

@fields = qw(frame.interface_name frame.time frame.time_epoch
	wlan_radio.channel wlan_radio.signal_dbm
	wlan.addr wlan.sa wlan.sa_resolved wlan.da wlan.da_resolved 
	wlan.bssid wlan.bssid_resolved wlan.ssid
	wlan.ta wlan.ta_resolved wlan.ra wlan.ra_resolved
	radiotap.flags.wep radiotap.channel.flags.2ghz radiotap.channel.flags.5ghz);

if ($pid = fork) {
} else {
	channel_scan();
	exit;
}

my $tshark_fields;
foreach (@fields) {
	$tshark_fields .= " -e $_";
}

$tcommand .= $tshark_fields;

open (CMD, "$tcommand|") || die "Unable to open pipe to $tshark\n";
while (<CMD>) {
	print "$_";
}
close(CMD);

kill(9, $pid);
exit 0;

sub channel_scan {
	my $count = 1;

	while ($count <= $channels) {
		#print "################ SETTING CHANNEL TO $count\n";
		`$icommand $count`;

		if ($? != 0) {
			print "Failed to change channel to $count.\n";
			exit 1;
		}

		if ($count == $channels) {
			$count = 1;
		} else {
			$count++;
		}
		sleep 2;
	}
}

sub sig_handler {
	print "Caught signal $!\n";
	print "Reaping child $$\n";
	kill(9, $$);
	exit 0;
}
