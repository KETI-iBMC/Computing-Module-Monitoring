#include<cstdio>
#include<stdlib.h>
#include<vector>
#include<string>
#include<cstring>

using namespace std;

#define MID_Byte 256
#define MAX_Byte 512

vector<string> ipmi_sel_list;


FILE *ipmi_sel;
FILE *dmesg_err;
void dmesg_ERR()
{
    FILE *fp;
    FILE *fp_fir;
    char FORMAT[MID_Byte]="%Y-%m-%d %T";
    char CPU_TIME[MID_Byte];
    char NOW_TIME[MID_Byte];
    
    int eof_check;
    fp = popen("date +%s","r");
    fscanf(fp,"%s",NOW_TIME);
    pclose(fp);

    fp = popen("cat /proc/uptime | awk -F '.' '{print $1}'","r");
    fscanf(fp,"%s",CPU_TIME);
    pclose(fp);


    fp = popen("dmesg -l err | awk -F ']' '{print $2}'","r");
    fp_fir = popen("dmesg -l err | awk -F '.' '{print $1}' | tr '[' ' ' | sed 's/ //g'","r");

    while(1)
    {
        char ERR_LINE[MAX_Byte];
        char ERR_TIME_LINE[MID_Byte];
        char PRINT_ERR_LINE[MID_Byte];
        char command[MID_Byte];
        char command2[MID_Byte];
        FILE *dmesg_fp;
        char ERR_TIME[MID_Byte];
        long stamp;
        if(fgets(ERR_LINE,MAX_Byte,fp) == NULL)
            break;
        
        fgets(ERR_TIME_LINE,MID_Byte,fp_fir);

        stamp = atol(NOW_TIME) - atol(CPU_TIME) + atol(ERR_TIME_LINE); 
        strcpy(command,"(date +\"%Y-%m-%d %T\"");
        sprintf(command,"%s --date=@%ld)",command,stamp);
        dmesg_fp = popen(command,"r");
        fgets(ERR_TIME,MAX_Byte,dmesg_fp);
        ERR_TIME[strlen(ERR_TIME)-1] = '\0';
        pclose(dmesg_fp);
        
        sprintf(PRINT_ERR_LINE,"[%s] %s",ERR_TIME,ERR_LINE);
        printf("%s",PRINT_ERR_LINE);
        dmesg_err = fopen("./log_data/dmesg_warn","w+");
        fseek(dmesg_err,0,SEEK_END);
        fwrite(PRINT_ERR_LINE,1,strlen(PRINT_ERR_LINE),dmesg_err);
        fclose(dmesg_err);
        //dmesg 초기화
    }    
    pclose(fp);
    pclose(fp_fir);

}


int main()
{
    dmesg_ERR();
}