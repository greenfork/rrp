# ABSTRACT: Server for Rakoon as a role player games

use MUGS::Core;
use MUGS::Server::Genre::IF;
use RPG::Base::Creature;

class MUGS::Server::Game::RakoonRolePlayers::CharacterInstance is RPG::Base::Creature {
    has MUGS::Character:D $.character is required;
}

#| Server side of Rakoon as a role player game
class MUGS::Server::Game::RakoonRolePlayers is MUGS::Server::Genre::IF {
    method game-type() { 'rrp' }
    method game-desc() { 'Rakoon as a role player!' }
    method name(::?CLASS:D:) { $.character.screen-name }

    method wrap-character(MUGS::Character:D $character) {
        my $instance = CharacterInstance.new(:$character);
        say "wrap-character: ", $instance;
        # $!start.add-thing($instance);
        $instance
    }

    method process-unparsed-input(::?CLASS:D: MUGS::Character:D :$character!,
                                  Str:D :$input!, :$context) {
        say "process-unparsed-input: $input with context $context";
        {};
    }

    method parsing-context(::?CLASS:D: MUGS::Character:D :$character!) {
        my $instance = self.instance-for-character($character);
        # my @exits    = $instance.container.exits.keys;
        # my @items    = $instance.known-things.map(*.name.fc);

        # MUGS::Server::Game::Adventure::CommandParser::Context.new(:@exits, :@items)
        say "parsing-context";
        1
    }
}


# Register this class as a valid server class
MUGS::Server::Game::RakoonRolePlayers.register;
