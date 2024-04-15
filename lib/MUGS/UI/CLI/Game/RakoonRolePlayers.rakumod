# ABSTRACT: CLI for Rakoon as a role player games

use MUGS::Core;
use MUGS::Client::Game::RakoonRolePlayers;
use MUGS::UI::CLI::Genre::IF;


#| CLI for a Rakoon as a role player game
class MUGS::UI::CLI::Game::RakoonRolePlayers is MUGS::UI::CLI::Genre::IF {
    method game-type() { 'rrp' }

    method game-help() { 'You are a Rakoon' }

    method show-game-state($response) {
        callsame;

        my %data := $response ~~ Map ?? $response !! $response.data;

        with %data<classes> {
            my sub class-name($class) {
                $.app-ui.put-colored($class, 'bold');
                put '';
            }
            for $_<> -> $class {
                my ($class-name, $class-desc) = $class.pairs[0].kv;
                class-name($class-name);
                $.app-ui.put-sanitized($class-desc);
                put '';
            }
        }
    }
}


# Register this class as a valid game UI
MUGS::UI::CLI::Game::RakoonRolePlayers.register;
