#include <stdio.h>

extern "C" int _print(const char* format, ...);

int main() 
{
    int a = _print("wow\n%b %o %x %s %s %c %d\n", -5, 58, 58, "hello", "c", "hello", 7);
    printf("%o\n", -5);

    printf("wow\n%o %x %s %s %c %d\n", 58, 58, "hello", "c", "hello", 7);

    printf("ret val %d\n", a);
    
    return 0;
}