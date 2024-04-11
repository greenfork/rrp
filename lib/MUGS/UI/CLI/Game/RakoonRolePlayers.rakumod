# ABSTRACT: CLI for Rakoon as a role player games

use MUGS::Core;
use MUGS::Client::Game::RakoonRolePlayers;
use MUGS::UI::CLI::Genre::IF;


#| CLI for a Rakoon as a role player game
class MUGS::UI::CLI::Game::RakoonRolePlayers is MUGS::UI::CLI::Genre::IF {
    method game-type() { 'rakoon-role-players' }

    method game-help() { 'You are a Rakoon' }
}


# Register this class as a valid game UI
MUGS::UI::CLI::Game::RakoonRolePlayers.register;
