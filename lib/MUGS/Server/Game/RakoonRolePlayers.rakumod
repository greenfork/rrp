# ABSTRACT: Server for Rakoon as a role player games

use MUGS::Core;
use MUGS::Server::Genre::IF;
use RPG::Base::Creature;
use Gettext;

constant DEBUG = False;

constant LANG = "en";

module CharacterClass {
    enum T «:Warrior(1) Priest Mage Healer Archer»;

    constant sorted = T.enums.sort(*.value).map(*.key).Array;

    constant %str-to-class = :{
        ::Warrior => <warrior воин>,
        ::Priest => <priest священник>,
        ::Mage => <mage маг>,
        ::Healer => <healer целитель>,
        ::Archer => <archer лучник>,
    }.invert.Map;
}

#| MUGS' character with additional data specific to this game.
class MUGS::Server::Game::RakoonRolePlayers::CharacterInstance is RPG::Base::Creature {
    has MUGS::Character:D $.character is required;
    has CharacterClass::T $.class is rw;
}
constant CharacterInstance = MUGS::Server::Game::RakoonRolePlayers::CharacterInstance;

#| Parsing context
class MUGS::Server::Game::RakoonRolePlayers::CommandParser::Context {
    has @.class-choices;
}

#| A single player command
grammar MUGS::Server::Game::RakoonRolePlayers::CommandParser {
    rule TOP {
        | <class-choice>
        | <command>
    }
    rule class-choice { @($*ctx.class-choices) }

    proto rule command {*}
    rule command:sym<quit> { $(gettext 'quit') }
    rule command:sym<lang> { $(gettext 'lang') $<lang> = ["ru"|"en"] }
}

class MUGS::Server::Game::RakoonRolePlayers::CommandParser::Actions {
    method TOP($/)                    { make $<class-choice>.made || $<command>.made }
    method class-choice($/)           { make ('class', %CharacterClass::str-to-class{~$/}) }
    method command:sym<quit>($/)      { make 'quit' }
    method command:sym<lang>($/)      { make ('lang', ~$<lang>) }
}

role MUGS::Server::Game::RakoonRolePlayers::PlayerActions {
    #| Process the parsed player command
    method process-player-command(CharacterInstance:D $instance, Str:D $command, @args) {
        given $command {
            when 'quit'      { self.set-gamestate(Finished); {} }
            when 'lang'      { self.change-lang(@args[0]); self.active-message($instance) }
            when 'class'     { self.set-class($instance, @args[0]) }
            default          { self.fail('Not implemented command') }
        }
    }

    #| Set player class
    method set-class(CharacterInstance:D $instance, CharacterClass::T:D $class) {
        $instance.class = $class;
        { message => gettext("Class chosen", gettext(~$instance.class)) }
    }
}

#| Server side of Rakoon as a role player game
class MUGS::Server::Game::RakoonRolePlayers is MUGS::Server::Genre::IF
        does MUGS::Server::Game::RakoonRolePlayers::PlayerActions {
    has $!lang = LANG;

    method game-type() { 'rrp' }
    method game-desc() { 'Rakoon as a role player!' }
    method name(::?CLASS:D:) { $.character.screen-name }

    method wrap-character(MUGS::Character:D $character) {
        my $instance = CharacterInstance.new(:$character);
        $instance
    }

    #| Parse a single command in a given context
    method parse-command(Str:D $input, $*ctx) {
        my $actions = MUGS::Server::Game::RakoonRolePlayers::CommandParser::Actions;
        MUGS::Server::Game::RakoonRolePlayers::CommandParser.parse($input.fc, :$actions);
    }

    method process-unparsed-input(::?CLASS:D: MUGS::Character:D :$character!,
                                  Str:D :$input!, :$context) {
        my $instance = self.instance-for-character($character);
        my $parsed = self.parse-command($input, $context)
            or self.fail(gettext("Available actions: %s", self.available-actions($instance).join(' ')));

        my ($command, @args) = |$parsed.made;
        dd $command, @args if DEBUG;
        my %result := self.process-player-command($instance, $command, @args);

        %result;
    }

    method post-process-action(::?CLASS:D: MUGS::Character:D :$character!,
                               :$action!, :$result!) {
        my %result := $result;
        my $instance = self.instance-for-character($character);
    }

    #| Currently relevant message to the player.
    method active-message(CharacterInstance:D $instance) {
        if not $instance.class.defined {
            { classes => self.classes-with-description().Array }
        }
        else {
            {}
        }
    }

    method change-lang($lang) {
        $!lang = $lang;
        gettext-init($lang);
    }

    #| Throw a generic failure exception, indicating why an action failed
    method fail(Str:D $message) {
        X::MUGS::Request::AdHoc.new(:$message).throw;
    }

    method parsing-context(::?CLASS:D: MUGS::Character:D :$character!) {
        my $instance = self.instance-for-character($character);
        my @class-choices = self.class-choices($instance);

        MUGS::Server::Game::RakoonRolePlayers::CommandParser::Context.new(
            :@class-choices);
    }

    method initial-state(::?CLASS:D: MUGS::Character:D :$character) {
        my $instance = self.instance-for-character($character);
        gettext-init($!lang);
        { :pre-title(gettext('Rakoon role players')),
          :pre-message(gettext('Ready for journey')),
          |self.active-message($instance),
          |callsame }
    }

    method common-actions() {
        <quit lang>.map(&gettext)
    }

    method available-actions($instance) {
        self.common-actions().Array.append: self.class-choices($instance);
    }

    method class-choices($instance) {
        $instance.class.defined ?? [] !!
            CharacterClass::sorted.map: { gettext(~$^class).fc };
    }

    method classes-with-description() {
        CharacterClass::sorted.map: -> $class-name {
            gettext($class-name) => gettext("$class-name description")
        }
    }
}

# Register this class as a valid server class
MUGS::Server::Game::RakoonRolePlayers.register;
