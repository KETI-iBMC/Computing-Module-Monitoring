#include<cstdio>
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>

int main()
{
	sleep(5);
	system("kill -9 8797");
	system("./Sensor_Monitoring");
}
