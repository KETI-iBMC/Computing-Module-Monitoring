#include<cstdio>
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>
#include<cstring>

using namespace std;

#define MID_Byte 256

int main()
{
    FILE *fp = fopen("Restart.sh","w+");
    int my_pid;
    fprintf(fp,"#!/bin/bash\n");
    fprintf(fp,"sleep 5\n");
    fprintf(fp,"kill -9 %d\");\n",getpid());
    fprintf(fp,"./Sensor_Monitoring\n");
    system("chmod 777 ./Restart.sh");
    //system("./Restart.sh");    
}