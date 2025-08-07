#include "validate.hpp"

void validatePairConsistency(const tournament::Tournament &tournament)
{
    for (const tournament::Player &player : tournament.players)
    {
        if (player.isValid)
        {
        tournament::round_index matchIndex{ };
        for (const tournament::Match &match : player.matches)
        {
            if (match.gameWasPlayed)
            {
            const tournament::Player &opponent =
                tournament.players[match.opponent];
            if (
                !opponent.isValid
                || !opponent.matches[matchIndex].gameWasPlayed
                || opponent.matches[matchIndex].color == match.color
                || opponent.matches[matchIndex].opponent != player.id)
            {
                throw std::runtime_error(
                "Match "
                    + utility::uintstringconversion::toString(matchIndex + 1u)
                    + " for player "
                    + utility::uintstringconversion::toString(player.id + 1u)
                    + " contradicts the entry for the opponent.");
            }
            }
            ++matchIndex;
        }
        }
    }
}

void validateScores(tournament::Tournament &tournament){
    for (tournament::Player &player : tournament.players)
    {
        if (player.isValid)
        {
        if (player.accelerations.size() > tournament.expectedRounds)
        {
            throw std::runtime_error(
            "Player "
                + utility::uintstringconversion::toString(player.id + 1u)
                + " has more acceleration entries than the total number of "
                "rounds in the tournament.");
        }
        tournament::points points{ };
        tournament::round_index matchIndex{ };
        for (const tournament::Match &match : player.matches)
        {
            if (matchIndex >= tournament.playedRounds)
            {
            break;
            }
            points += tournament.getPoints(player, match);
            if (points < tournament.getPoints(player, match))
            {
            throw tournament::BuildLimitExceededException(
                "This build only supports scores up to "
                + utility::uintstringconversion
                    ::toString(tournament::maxPoints, 1)
                + '.');
            }
            ++matchIndex;
        }

        if (player.scoreWithoutAcceleration != points)
        {
            if (
            player.scoreWithoutAcceleration
                >= player.acceleration(tournament))
            {
            player.scoreWithoutAcceleration
                -= player.acceleration(tournament);
            }
            if (player.scoreWithoutAcceleration != points)
            {
            player.scoreWithoutAcceleration
                += player.acceleration(tournament);
            }
        }
        if (player.scoreWithoutAcceleration != points)
        {
            if (player.matches.size() > tournament.playedRounds)
            {
            tournament::points nextRoundPoints =
                tournament
                .getPoints(player, player.matches[tournament.playedRounds]);
            if (player.scoreWithoutAcceleration >= nextRoundPoints)
            {
                player.scoreWithoutAcceleration -= nextRoundPoints;
            }
            }
        }
        if (player.scoreWithoutAcceleration != points)
        {
            if (
            player.scoreWithoutAcceleration
                >= player.acceleration(tournament))
            {
            player.scoreWithoutAcceleration
                -= player.acceleration(tournament);
            }
        }
        if (player.scoreWithoutAcceleration != points)
        {
            throw std::runtime_error(
            "The score for player "
                + utility::uintstringconversion::toString(player.id + 1u)
                + " does not match the game results.");
        }
        }
    }
}