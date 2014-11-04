#include <stdio.h>

char hexchar[] = "0123456789ABCDEF";

int
main()
{
	char c;

	while(scanf("%c", &c) != -1)
	{
		printf("%c%c\n", hexchar[c>>4], hexchar[c&15]);
	}

	return 0;
}
