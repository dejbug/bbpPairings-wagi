#ifndef GLOBALS_H
#define GLOBALS_H

#include <iostream>

#define THROW(x, m) do {\
	std::cout << __FILE__ << ':' << __LINE__ <<\
		" [" << #x << "] " << (m) << '\n';\
	std::cout.flush();\
	std::exit(-1);\
} while(0);

#endif // GLOBALS_H
