#ifndef ROUNDROBIN_H
#define ROUNDROBIN_H

#include <list>

#include <matching/computer.h>
#include "common.h"

namespace tournament
{
  struct Tournament;
}

namespace swisssystems
{
  namespace roundrobin
  {

    std::list<Pairing> computeMatching(
      tournament::Tournament &&,
      std::ostream *const = nullptr);

    struct RoundRobinInfo final : public Info
    {
      std::list<Pairing> computeMatching(
        tournament::Tournament &&tournament,
        std::ostream *const ostream
      ) const override
      {
        return roundrobin::computeMatching(std::move(tournament), ostream);
      }
    };
  }
}

#endif
