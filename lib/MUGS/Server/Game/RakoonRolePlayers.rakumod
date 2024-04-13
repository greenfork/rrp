# ABSTRACT: Server for Rakoon as a role player games

use MUGS::Core;
use MUGS::Server::Genre::IF;
use RPG::Base::Creature;

class MUGS::Server::Game::RakoonRolePlayers::CharacterInstance is RPG::Base::Creature {
    has MUGS::Character:D $.character is required;
    has $.class is rw = Nil;
}

constant CLASSES = %{
    Warrior => q:to/DESC/,
One who actually fights the creatures out there, who braves new, possibly
lethal dangers every day. In short: a Raku application writer.
DESC
    Priest => q:to/DESC/,
The priest is important for the group, but doesn’t put himself in the way of
direct danger like the warrior. Instead, they perform vital tasks with their
hands at a safe distance. In the Raku world, priests submit bug tickets, write
tests and answer newbie questions on the #raku channel.
DESC
    Mage => q:to/DESC/,
In the flurry of activity during a quest, the mages are the ones who wield
forceful spells in the form of new features in our implementations. The mages
know some pretty hefty incantations, but they speak in codes (like "Haskell",
"Parrot" or "Lisp") so that us mere non-initiates can only stand by in
admiration when they get going.
DESC
    Healer => q:to/DESC/,
Some people are in the group to make sure the group is doing well, and that
no-one is critically low on hit-points. Discussions can sometimes get heated
or sharp, by which point we're very glad to have the people around who are
specially trained to see beyond the ego and help us focus on the important
parts of the picture. We simply need to be reminded at times, that we're
(as S01 expresses it) "a bunch of ants all cooperating (sort of) to haul food
toward the nest (on average)". We don't need to agree always on everything,
but keeping the group coherent is important, and healers do their magic in
the background to help us with that.
DESC
    Archer => q:to/DESC/,
As for long-distance influence, and reaching outside of our own circles,
the archer fills the important role of blogging, tweeting, iron-manning
and generally making a positive noise about Raku, which can reach people
far away.
DESC
}

#| Context for parsing (room exits, visible items, etc.)
class MUGS::Server::Game::RakoonRolePlayers::CommandParser::Context {
    has @.class-choices;
}

#| A single player command
grammar MUGS::Server::Game::RakoonRolePlayers::CommandParser {
    rule TOP { <class-choice> }
    rule class-choice { @($*ctx.class-choices) }
}

class MUGS::Server::Game::RakoonRolePlayers::CommandParser::Actions {
    method TOP($/)                    { make $<class-choice>.made }
    method class-choice($/)           { make ~$/ }
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

    #| Parse a single command in a given context
    method parse-command(Str:D $input, $*ctx) {
        my $actions = MUGS::Server::Game::RakoonRolePlayers::CommandParser::Actions;
        MUGS::Server::Game::RakoonRolePlayers::CommandParser.parse($input.fc, :$actions);
    }

    #| Process the parsed player command
    method process-player-command(CharacterInstance:D $instance, Str:D $command, @args) {
        given $command {
            when 'quit'      { self.set-gamestate(Finished); {} }
            when 'go'        { self.move-character($instance, @args[0]); {} }
            when 'inventory' { self.inventory($instance) }
            when 'look'      { {} }
            when 'lock'      { self.lock-thing(  $instance.known-thing-named(@args[0])) }
            when 'unlock'    { self.unlock-thing($instance.known-thing-named(@args[0])) }
            when any($*ctx.class-choices) { $instance.class = $_; {:message("Now it is {$instance.class}")} }
            default          { self.fail("I can't handle that command yet") }
        }
    }

    method process-unparsed-input(::?CLASS:D: MUGS::Character:D :$character!,
                                  Str:D :$input!, :$context) {
        # XXXX: Need a better exception class
        my $parsed = self.parse-command($input, $context)
            or self.fail('Could not parse your input');

        my $*ctx = $context;
        my ($command, @args) = |$parsed.made;
        my $instance  = self.instance-for-character($character);
        my %result   := self.process-player-command($instance, $command, @args);

        %result;
    }

    #| Throw a generic failure exception, indicating why an action failed
    method fail(Str:D $message) {
        X::MUGS::Request::AdHoc.new(:$message).throw;
    }

    method parsing-context(::?CLASS:D: MUGS::Character:D :$character!) {
        my $instance = self.instance-for-character($character);
        my @class-choices = CLASSES.keys.sort.reverse.map(*.fc);

        MUGS::Server::Game::RakoonRolePlayers::CommandParser::Context.new(:@class-choices);
    }

    method initial-state(::?CLASS:D: MUGS::Character:D :$character) {
        my $instance = self.instance-for-character($character);
        { :pre-title('Rakoon role players'),
          :pre-message('You are ready to embark on a new journey. Choose your class:'),
          :classes(CLASSES),
          |callsame }
    }
}


# Register this class as a valid server class
MUGS::Server::Game::RakoonRolePlayers.register;
