#include <chrono>
#include <iostream>
#include <list>
#include <memory>
#include <new>
#include <random>
#include <string>
#include <utility>

#include "fileformats/generatorconfiguration.h"
#include "fileformats/trf.h"
#include "fileformats/types.h"
#include "swisssystems/common.h"
#include "tournament/tournament.h"
#include "utility/uintstringconversion.h"

#include <sstream>

#define NO_VALID_PAIRING 1
#define UNEXPECTED_ERROR 2
#define INVALID_REQUEST 3
#define LIMIT_EXCEEDED 4
#define FILE_ERROR 5

std::istringstream readStdin();
std::istringstream readStdin()
{
	std::stringstream ss;
	ss << std::cin.rdbuf();
	return std::istringstream(ss.str());
}

swisssystems::SwissSystem getSwissSystemFlag(int, char **);
swisssystems::SwissSystem getSwissSystemFlag(int argc, char ** argv)
{
	if (argc >= 2 && !strcmp(argv[1], "--burstein"))
		return swisssystems::BURSTEIN;
	return swisssystems::DUTCH;
}

int main(int argc, char ** argv)
{
	std::cout << "content-type: text/plain\n\n";

	swisssystems::SwissSystem const swissSystem = getSwissSystemFlag(argc, argv);

	std::istringstream inputStream = readStdin();
	if (inputStream.str().empty()) return 0;

	// try
	{
		// Input a tournament file, and compute the pairings of the next round.
		// try
		{
			// Read the tournament.
			tournament::Tournament tournament;
			// try
			{
				tournament = fileformats::trf::readFile(inputStream, true);
			}
			if (0) // catch (const fileformats::FileFormatException &exception)
			{
				// std::cerr << exception.what() << std::endl;
				return INVALID_REQUEST;
			}
			if (0) // catch (const fileformats::FileReaderException &exception)
			{
				// std::cerr << exception.what() << std::endl;
				return FILE_ERROR;
			}
			if (tournament.initialColor == tournament::COLOR_NONE)
			{
				std::cerr << "Please configure the initial piece colors."
					<< std::endl;
				return INVALID_REQUEST;
			}
			tournament.updateRanks();
			tournament.computePlayerData();

			// Add default accelerations.
			const swisssystems::Info &info = swisssystems::getInfo(swissSystem);
			if (tournament.defaultAcceleration)
			{
				for (
					tournament::round_index round_index{ };
					round_index <= tournament.playedRounds;
					++round_index)
				{
					info.updateAccelerations(tournament, round_index);
				}
			}

			std::ostream *outputStream = &std::cout;

			// Compute the matching.
			std::list<swisssystems::Pairing> pairs;
			// try
			// {
				pairs =
					// info.computeMatching(std::move(tournament), checklistStream.get());
					info.computeMatching(std::move(tournament), nullptr);
			// }
			if (0) // catch (const swisssystems::NoValidPairingException &exception)
			{
				std::cerr << "No valid pairing exists: "
					// << exception.what()
					<< std::endl;
				return NO_VALID_PAIRING;
			}
			if (0) // catch (const swisssystems::UnapplicableFeatureException &exception)
			{
				std::cerr << "Error while pairing: "
					// << exception.what()
					<< std::endl;
				return INVALID_REQUEST;
			}

			swisssystems::sortResults(pairs, tournament);

			// Output the pairs.
			*outputStream << pairs.size() << std::endl;
			for (const swisssystems::Pairing &pair : pairs)
			{
				*outputStream << pair.white + 1u
					<< ' '
					<< (pair.white == pair.black
								? "0"
								: utility::uintstringconversion::toString(pair.black + 1u))
					<< std::endl;
			}
		}
		if (0) // catch (const tournament::BuildLimitExceededException &exception)
		{
			// std::cerr << exception.what() << std::endl;
			return LIMIT_EXCEEDED;
		}
		if (0) // catch (const std::length_error &)
		{
			std::cerr << "The build does not support tournaments this large."
				<< std::endl;
			return LIMIT_EXCEEDED;
		}
		if (0) // catch (const std::bad_alloc &)
		{
			std::cerr << "The program ran out of memory." << std::endl;
			return LIMIT_EXCEEDED;
		}
		return 0;
	}
	if (0) // catch (const std::exception &exception)
	{
		std::cerr << "Unexpected error (please report): "
			// << exception.what()
			<< std::endl;
		return UNEXPECTED_ERROR;
	}
}
