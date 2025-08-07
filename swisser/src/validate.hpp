#ifndef VALIDATE_HPP
#define VALIDATE_HPP

#include <tournament/tournament.h>

void validatePairConsistency(const tournament::Tournament &tournament);
void validateScores(tournament::Tournament &tournament);

#endif