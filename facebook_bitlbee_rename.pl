# See this script's repository at
# http://github.com/harleypig/irssi-bitlbee-facebook-rename
# for further information.

# This was forked from http://github.com/avar/irssi-bitlbee-facebook-rename)

# And my original stuff was culled from these places:

# renames bitlbee facebook-via-xmpp buddies to something sane
# Originally by Tim Angus, http://a.ngus.net/bitlbee_rename.pl
# Modified slightly to only rename people on chat.facebook.com, and also strip invalid chars from names, by Lakitu7
# copied in a mod by ajf on #bitlbee to only match u###### names
# truncates names over 25 chars to comply with bitlbee's limit; thanks Jesper on #bitlbee
# Fixed FB's change from 'u####' to '-####' - http://pastebin.com/nBS734WH

# Any errors are my own damn fault - harleypig

# script is for irssi. Save it as .irssi/scripts/bitlbee_rename.pl then /script load bitlbee_rename.pl
# known issues: If the name it's renaming to is already taken, the rename fails.

use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use Text::Unidecode;
use Encode qw( decode );

our $VERSION = '0.03-hp';

our %IRSSI = (

    authors => 'Alan Young',
    contact => 'harleypig@gmail.com',
    name    => 'bitlbee-facebook-rename',
    description => 'Rename XMPP chat.facebook.com contacts in bitlbee to human-readable names',
    license => 'GPL',

);

# These need to be made adjustable
my $bitlbeeChannel = '&bitlbee';
my $facebookhostname = 'chat.facebook.com';

my %nicksToRename = ();

sub message_join {

  # "message join", SERVER_REC, char *channel, char *nick, char *address
  my ( $server, $channel, $nick, $address ) = @_;

  my ( $username, $host ) = split /@/, $address, 2;

  if ( $channel eq $bitlbeeChannel
    && $host    =~ /$facebookhostname/
    && $nick    =~ /$username/
    && $nick    =~ /^-\d+/ ) {

    $nicksToRename{ $nick } = $channel;
    $server->command( "whois -- $nick" );

  }
}

sub whois_data {

  my ( $server, $data ) = @_;

  my ( $me, $nick, $user, $host ) = split /\s+/, $data;

  if ( exists $nicksToRename{ $nick } ) {

    my $channel = delete $nicksToRename{ $nick };

    # If I need to use utf8 then uncomment this line and remove the
    # following lines.
    # my $ircname = munge_nickname( $data );

    ( my $ircname = $data ) =~ s/^.*?://;
    $ircname =~ s/[^A-Za-z0-9_]//g;
    $ircname = substr $ircname, 0, 25;

    if ( $ircname ne $nick ) {

    $server->command("msg $channel rename $nick $ircname");
    $server->command("msg $channel save");

  }

  }
}

sub munge_nickname {

  ( my $nick = +shift ) =~ s/^.*?://;

  $nick = decode( 'utf8', $nick );
  $nick =~ s/[- ]/_/g;
  $nick = unidecode( $nick );
  $nick =~ s/[^A-Za-z0-9-]//g;
  $nick = substr $nick, 0, 24;

  return $nick;

}

Irssi::signal_add_first 'message join' => 'message_join';
Irssi::signal_add_first 'event 311'    => 'whois_data';
