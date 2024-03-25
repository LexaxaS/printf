#include "stdio.h"

extern int MyPrintf(char* format_string, ...);

int main()
    {
    int primerDeda = MyPrintf ("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 126, -1, "love", 3802, 100, 33, 126);
    return 0;
    }