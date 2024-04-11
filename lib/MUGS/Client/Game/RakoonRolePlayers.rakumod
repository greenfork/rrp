# ABSTRACT: Client for Rakoon as a role player games

use MUGS::Core;
use MUGS::Client::Genre::IF;


#| Client side of Rakoon as a role player game
class MUGS::Client::Game::RakoonRolePlayers is MUGS::Client::Genre::IF {
    method game-type() { 'rrp' }
}


# Register this class as a valid client
MUGS::Client::Game::RakoonRolePlayers.register;
