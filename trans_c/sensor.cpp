// 사전설정 테스트 해야됨

#include<cstdio>
#include<stdlib.h>
#include<cstring>
#include<vector>
#include<string>
#include<unistd.h>
#include<iostream>
#include<signal.h>
#include<sys/types.h>
#include<sys/stat.h>
using namespace std;

vector <string>sensor_name;
vector <string>sensor_id;
vector <string>v_power;
vector <string>ipmi_sel_list;

#define MID_Byte 256
#define MAX_Byte 512

/*엑셀 머리표 및 데이터값*/
char EXCEL_SUB[MAX_Byte]="date, Memory %, CPU %, DISK %";
char EXCEL_VALUE[MAX_Byte];

/*시간 데이터*/
char pre_date[MID_Byte];

/*센서 로그, 오류 로그 파일 포인터*/
FILE *sensor_log;
FILE *dmesg_err;
FILE *dmesg_warn;
FILE *ipmi_sel;


/**파이프 파일 포인터*/
FILE *date_fp;


void pre_install();
void PRINT_SENSOR();
void INIT_SENSOR();
void Init();
void Sensor_Reading();
void dmesg_ERR();
void dmesg_WARN(); 
void IPMI_ERR();
void ZIP_LOG();



void pre_install()
{
    FILE *fp;
    int eof_check;
    int ipmitool_check=0;
    int lm_sensors_check=0;
    fp = popen("dpkg -l | grep -e ipmitool -e lm-sensors | awk '{print $2}' | sed 's/ //g'","r");
    while (1)
    {
        char Package_check[MID_Byte];
        eof_check = fscanf(fp,"%s",Package_check);
        if(eof_check == EOF)
            break;
        if(strstr(Package_check,"ipmitool") != NULL){
            ipmitool_check = 1;
        }
        else if(strstr(Package_check,"lm-sensors") != NULL){
            lm_sensors_check = 1;

        }

    }
    pclose(fp);

    fp = popen("yum list installed | grep -e ipmitool -e lm_sensors | sed 's/ //g'","r");
    while (1)
    {
        char Package_check[MID_Byte];
        eof_check = fscanf(fp,"%s",Package_check);
        if(eof_check == EOF)
            break;
        if(strstr(Package_check,"ipmitool") != NULL){
            ipmitool_check = 1;

        }
        else if(strstr(Package_check,"lm_sensors") != NULL){
            lm_sensors_check = 1;
        }
    }
    pclose(fp);


    if(ipmitool_check == 0){
        system("yum install ipmitool -y");
        system("apt-get install ipmitool -y");
    }
    if(lm_sensors_check == 0){
        system("yum install lm_sensors -y");
        system("apt-get install lm-sensors -y");
    }
}

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

    dmesg_err = fopen("./log_data/dmesgERROR.csv","r+");
    fseek(dmesg_err,0,SEEK_END);
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
        
        sprintf(PRINT_ERR_LINE,"[%s], %s",ERR_TIME,ERR_LINE);
        
        fwrite(PRINT_ERR_LINE,1,strlen(PRINT_ERR_LINE),dmesg_err);
        //dmesg 초기화
    }    
    fclose(dmesg_err);
    pclose(fp);
    pclose(fp_fir);
}

void dmesg_WARN()
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


    fp = popen("dmesg -l warn | awk -F ']' '{print $2}'","r");
    fp_fir = popen("dmesg -l warn | awk -F '.' '{print $1}' | tr '[' ' ' | sed 's/ //g'","r");

    dmesg_warn = fopen("./log_data/dmesgWARN.csv","r+");
    fseek(dmesg_warn,0,SEEK_END);
    while(1)
    {
        char WARN_LINE[MAX_Byte];
        char WARN_TIME_LINE[MID_Byte];
        char PRINT_WARN_LINE[MID_Byte];
        char command[MID_Byte];
        char command2[MID_Byte];
        FILE *dmesg_fp;
        char WARN_TIME[MID_Byte];
        long stamp;
        if(fgets(WARN_LINE,MAX_Byte,fp) == NULL)
            break;
        
        fgets(WARN_TIME_LINE,MID_Byte,fp_fir);

        stamp = atol(NOW_TIME) - atol(CPU_TIME) + atol(WARN_TIME_LINE); 
        strcpy(command,"(date +\"%Y-%m-%d %T\"");
        sprintf(command,"%s --date=@%ld)",command,stamp);
        dmesg_fp = popen(command,"r");
        fgets(WARN_TIME,MAX_Byte,dmesg_fp);
        WARN_TIME[strlen(WARN_TIME)-1] = '\0';
        pclose(dmesg_fp);
        
        sprintf(PRINT_WARN_LINE,"[%s], %s",WARN_TIME,WARN_LINE);
        
        fwrite(PRINT_WARN_LINE,1,strlen(PRINT_WARN_LINE),dmesg_warn);
        //dmesg 초기화
    }    
    fclose(dmesg_warn);
    pclose(fp);
    pclose(fp_fir);
}


void IPMI_ERR()
{
    FILE *sel_date_fp;
    FILE *sel_time_fp;
    FILE *sel_data_fp;


    int eof_check;

    sel_date_fp = popen("ipmitool sel list | awk -F '|' '{print $2}' | awk -F '/' '{print $3\"-\"$1\"-\"$2}' | sed 's/ //g'","r");
    sel_time_fp = popen("ipmitool sel list | awk -F '|' '{print $3}' | sed 's/ //g'","r");
    sel_data_fp = popen("ipmitool sel list | awk -F '|' '{print $4\",\"$5\",\"$6}'","r");
    while (1)
    {
        char IPMI_SEL_DATE[MID_Byte];
        char IPMI_SEL_TIME[MID_Byte];
        char IPMI_SEL_DATA[MID_Byte];
        char IPMI_SEL_ALL[MAX_Byte];

        eof_check = fscanf(sel_date_fp,"%s",IPMI_SEL_DATE);
        
        if(eof_check == EOF)
            break;

        fscanf(sel_time_fp,"%s",IPMI_SEL_TIME);
        fgets(IPMI_SEL_DATA,MAX_Byte,sel_data_fp);

        IPMI_SEL_DATA[strlen(IPMI_SEL_DATA)-1] = '\0';

        sprintf(IPMI_SEL_ALL,"[%s %s],%s\n",IPMI_SEL_DATE,IPMI_SEL_TIME,IPMI_SEL_DATA);
        string IPMI_TMP(IPMI_SEL_ALL);
        ipmi_sel_list.push_back(IPMI_TMP);

    } 

    pclose(sel_date_fp);
    pclose(sel_time_fp);
    pclose(sel_data_fp);

    ipmi_sel = fopen ("./log_data/sel_log.csv","r+");
    fseek(ipmi_sel,0,SEEK_END);

    for(int i=0; i<ipmi_sel_list.size();i++){
        fwrite(ipmi_sel_list[i].c_str(),1,ipmi_sel_list[i].length(),ipmi_sel);
    }

    system("ipmitool sel clear");
    ipmi_sel_list.clear();//벡터 초기화

    fclose(ipmi_sel);
}


void PRINT_SENSOR()
{
    FILE *fp;
    for(int i=0;i<sensor_id.size(); i++){
        int sensor_value;
        char tmp[MID_Byte];
        char raw_command[MID_Byte];
        char device_check[MID_Byte];
        char device_command[MID_Byte];

        sprintf(raw_command,"ipmitool raw 0x04 0x2d %s | awk '{print $1}'",sensor_id[i].c_str());
        fp = popen(raw_command,"r");
        fgets(tmp,MID_Byte,fp);
        sensor_value=(int)strtol(tmp, NULL, 16);
        
        pclose(fp);
        sprintf(device_command,"cat sensor.txt | grep '%s'| awk -F '|' '{print $3}' | sed 's/ //g' ",sensor_name[i].c_str());
        fp = popen(device_command,"r");
        
        fscanf(fp,"%s",device_check);
        
        pclose(fp);

        if(!strcmp(device_check,"RPM")){
            sensor_value*=100;
        }

        sprintf(EXCEL_VALUE,"%s, %d",EXCEL_VALUE, sensor_value);
        

    }
}

void INIT_SENSOR()
{
    FILE *fp;
    sensor_name.clear();
    char SN[MID_Byte],sensor_value[MID_Byte];
    int len;
    int tmp_var=1;
    system("ipmitool sensor | awk -F '|' '{print $1 \"|\" $2 \"|\" $3}' > sensor.txt");

    while(1)
    {
        char command1[MID_Byte];
        char command2[MID_Byte];
        char command3[MID_Byte];
        char buf[MID_Byte];
        
        sprintf(command3,"cat sensor.txt | sed -n \"%d\"P | awk -F '|' '{print $3}' | sed 's/ //g' ", tmp_var);
        fp=popen(command3,"r");
        if( fgets(buf,MID_Byte,fp) == NULL){
            break;
        }
        buf[strlen(buf)-1] = '\0';
        if(!strcmp(buf,"Volts") || !strcmp(buf,"discrete")){
            memset(buf,'\0',sizeof(buf));
            tmp_var++;
            continue;
        }
        memset(buf,'\0',sizeof(buf));



        pclose(fp);
        sprintf(command1,"cat sensor.txt | sed -n \"%d\"P | awk -F '|' '{print $1}' " ,tmp_var);

        fp=popen(command1,"r");
        
        if( fgets(SN,MID_Byte,fp) == NULL){
            break;
        }
        
        pclose(fp);

        sprintf(command2,"cat sensor.txt | sed -n \"%d\"P | awk -F '|' '{print $2}' | sed 's/ //g' ", tmp_var++);
        fp=popen(command2,"r");
        fgets(sensor_value,MID_Byte,fp);

        pclose(fp);

        sensor_value[strlen(sensor_value)-1]='\0';
        if(!strcmp(sensor_value,"na"))
            continue;
 
        int final_len=0;
        
        for(int i=0; i<strlen(SN)-1; i++){
            char tmp[3];
            sprintf(tmp,"%c%c",SN[i],SN[i+1]);

            if(!strcmp(tmp,"  ") || !strcmp(tmp," |")){
                SN[i] = '\0';
                sensor_name.push_back(SN);
                break;
            }
        }     
    }

    system("ipmitool sdr -v | grep 'Sensor ID' > SENSOR_ID.txt");
    
    for(int i=0;i<sensor_name.size();i++){
        sprintf(EXCEL_SUB,"%s, %s",EXCEL_SUB,sensor_name[i].c_str());/*엑셀 SUB*/

        char buf[MID_Byte];
        sprintf(buf,"cat SENSOR_ID.txt | grep '%s' | awk -F '(' '{print $2}' | sed 's/)//g' ",sensor_name[i].c_str());
        fp=popen(buf,"r");
        char sensor_id_tmp[MID_Byte];
        if( fgets(sensor_id_tmp,MID_Byte,fp) == NULL){
            break;
        }
        sensor_id_tmp[strlen(sensor_id_tmp)-1] = '\0';
        pclose(fp);

        string s(sensor_id_tmp);
        sensor_id.push_back(s);
    } 

    //Power
    int eof_check;
    fp = popen("sensors | grep power | awk '{print $2}'","r");

    while (1)
    {
        char power[MID_Byte];
        eof_check = fscanf(fp,"%s",power);
        if(eof_check == EOF)
            break;
        if(power[0] == '\n'){
            continue;
        }
        string s_power(power);
        v_power.push_back(power);
    }
    

    for(int i=1;i<=v_power.size();i++){
        sprintf(EXCEL_SUB,"%s, power%d",EXCEL_SUB,i);
    }
    v_power.clear();        
    pclose(fp);

}

void Init()
{

    char date[MID_Byte];
    char FILE_PATH[MID_Byte];
    date_fp = popen("date +%Y%m%d","r");

    fscanf(date_fp,"%s",date);
    pclose(date_fp);
    sprintf(FILE_PATH,"./log_data/%s_sensor_log.csv",date);
    if((sensor_log=fopen(FILE_PATH,"r+")) == NULL){
        if((sensor_log=fopen(FILE_PATH,"w+")) == NULL){
            printf("sensor_log 파일 생성 오류");
        }
        else{
            int tmp_len = strlen(EXCEL_SUB);

            EXCEL_SUB[tmp_len] = '\n';
            EXCEL_SUB[tmp_len+1] = '\0';
            fwrite(EXCEL_SUB,1,sizeof(EXCEL_SUB),sensor_log);

        }
    }
    
    if((ipmi_sel=fopen("./log_data/sel_log.csv","r+")) == NULL){
        if((ipmi_sel=fopen("./log_data/sel_log.csv","w+")) == NULL){
            if((ipmi_sel=fopen(FILE_PATH,"w+")) == NULL){
                printf("sel_log 파일 생성 오류");
            }
        }
    }

    if((dmesg_err=fopen("./log_data/dmesgERROR.csv","r+")) == NULL){
        if((dmesg_err=fopen("./log_data/dmesgERROR.csv","w+")) == NULL){
            if((dmesg_err=fopen(FILE_PATH,"w+")) == NULL){
                printf("dmesgERROR 파일 생성 오류");
            }
        }
    }

    if((dmesg_warn=fopen("./log_data/dmesgWARN.csv","r+")) == NULL){
        if((dmesg_warn=fopen("./log_data/dmesgWARN.csv","w+")) == NULL){
            if((dmesg_warn=fopen(FILE_PATH,"w+")) == NULL){
                printf("dmesgWARN 파일 생성 오류");
            }
        }
    }

    fclose(ipmi_sel);
    fclose(sensor_log);
    fclose(dmesg_err);
    fclose(dmesg_warn);
}

void Sensor_Reading()
{
    FILE *fp;

    char CUR_TIME[MID_Byte];

    long MEMORY_TOTAL;
    long MEMORY_USED;
    long MEMORY_PERCENT;
    
    char CPU_PERCENT[MID_Byte];
    
    long DISK_TOTAL;
    long DISK_USED;
    long DISK_PERCENT;
    
    char command[MAX_Byte];
    char tmp[MAX_Byte];
    //CUR_TIME
    fp = popen("date +%Y-%m-%d\\ %H:%M:%S","r");
    fgets(CUR_TIME,MID_Byte,fp);
    
    CUR_TIME[strlen(CUR_TIME)-1] = '\0';

    pclose(fp);

    //MEMORY_TOTAL
    fp = popen("free | grep ^Mem | awk '{print $2}'","r");
    fgets(tmp,MID_Byte,fp);
    MEMORY_TOTAL=atol(tmp);
    memset(tmp,'\0',sizeof(tmp));
    pclose(fp);
    
    //MEMORY_USED
    fp = popen("free | grep ^Mem | awk '{print $3}'","r");
    fgets(tmp,MID_Byte,fp);
    MEMORY_USED=atol(tmp);
    memset(tmp,'\0',sizeof(tmp));
    pclose(fp);
    
    //MEMORY_PERCENT
    MEMORY_PERCENT=(double)(MEMORY_USED/MEMORY_TOTAL)*100;
    
    //CPU_PERCENT
    fp = popen("top -b -n 1 | grep -i cpu\\(s\\)| awk -F, '{print $4}' | tr -d \"%id,\" | awk '{print 100-$1}'","r");
    fgets(CPU_PERCENT,MID_Byte,fp);
    CPU_PERCENT[strlen(CPU_PERCENT)-1] = '\0';
    pclose(fp);

    //DISK_TOTAL
    fp = popen("df -P | grep -v ^Filesystem | awk '{sum += $2} END { print sum; }'","r");
    fgets(tmp,MID_Byte,fp);
    DISK_TOTAL=atol(tmp);
    memset(tmp,'\0',sizeof(tmp));
    pclose(fp);

    //DISK_USED
    fp = popen("df -P | grep -v ^Filesystem | awk '{sum += $3} END { print sum; }'","r");
    fgets(tmp,MID_Byte,fp);
    DISK_USED=atol(tmp);
    memset(tmp,'\0',sizeof(tmp));
    pclose(fp);

    //DISK_PERCENT
    DISK_PERCENT=(double)(DISK_USED/DISK_TOTAL)*100;
    
    sprintf(EXCEL_VALUE,"[%s], %ld, %s, %ld",CUR_TIME,MEMORY_PERCENT,CPU_PERCENT,DISK_PERCENT);
    
    PRINT_SENSOR();
    
    int eof_check;
    fp = popen("sensors | grep power | awk '{print $2}'","r");

    while (1)
    {
        char power[MID_Byte];
        eof_check = fscanf(fp,"%s",power);
        if(eof_check == EOF)
            break;
        if(power[0] == '\n' || strlen(power) == 0){
            continue;
        }
        string s_power(power);
        v_power.push_back(power);

    }

    for(int i=0;i<v_power.size();i++){
        sprintf(EXCEL_VALUE,"%s, %s",EXCEL_VALUE,v_power[i].c_str());
    }
    
    v_power.clear();        
    pclose(fp);


    /*개행 추가*/
    int tmp_len = strlen(EXCEL_VALUE);
    EXCEL_VALUE[tmp_len]='\n';
    EXCEL_VALUE[tmp_len+1]='\0';
    
    char FILE_NAME[MID_Byte];

    sprintf(FILE_NAME,"./log_data/%s_sensor_log.csv",pre_date);

    sensor_log=fopen(FILE_NAME,"r+");
    fseek(sensor_log,0,SEEK_END);
    
    fwrite(EXCEL_VALUE,1,sizeof(EXCEL_VALUE),sensor_log);

    memset(EXCEL_VALUE,'\0',sizeof(EXCEL_VALUE));

    fclose(sensor_log);



}

void ZIP_LOG()
{
    char command[MID_Byte];

    sprintf(command, "gzip ./log_data/%s_sensor_log.csv",pre_date);

    system(command);
}

void restart()
{
    FILE *fp = fopen("./Restart.sh","w+");
    int my_pid;
    fprintf(fp,"#!/bin/bash\n");
    fprintf(fp,"kill -9 %d\n",getpid());
    fprintf(fp,"./Sensor_Monitoring\n");
    fprintf(fp,"sleep 10\n");
    fclose(fp);
    system("chmod 777 ./Restart.sh");
    system("./Restart.sh");    
}


int main(int argc, char **argv)
{
    printf("Sensor_Monitoring {Time (s)}\n");
    printf("Default interval (1 Second)\n");
   

     
    //daemon
    pid_t pid;
    if((pid=fork())<0){
        printf("not fork");
        return -1;
    }
    else if(pid !=0 )
        exit(0); //부모 종료

    setsid();
    signal(SIGHUP,SIG_IGN);

    if((pid = fork())!=0)
    {
        exit(0);
    }
    chdir(".");
    
    
    for(int i=0;i<3;i++)
        close(i);
    umask(0);
    

    //사전 설치 패키지
    pre_install();


    INIT_SENSOR();
    //system("rm SENSOR_ID.txt");
    if(access( "./log_data" , 0)){//디렉토리 존재 확인
        system("mkdir -p log_data");
    }

    Init();

    date_fp = popen("date +%Y%m%d","r");
    fscanf(date_fp,"%s",pre_date);
    pclose(date_fp);

    while(1)
    {
        char cur_date[MID_Byte];
        date_fp = popen("date +%Y%m%d","r");
        fscanf(date_fp,"%s",cur_date);
        pclose(date_fp);

        if(strcmp(cur_date,pre_date)){
            sensor_name.clear();
            sensor_id.clear();

            memset(EXCEL_SUB,'\0',sizeof(EXCEL_SUB));
            memset(EXCEL_VALUE,'\0',sizeof(EXCEL_VALUE));

            INIT_SENSOR();
            Init();
            ZIP_LOG();
            restart();
            sleep(10);
            memset(pre_date,'\0',sizeof(pre_date));
            strcpy(pre_date,cur_date);
        }
        if(argc != 1)
            sleep(atoi(argv[1]));
        if(argc == 1)
            sleep(0);


        dmesg_ERR();
        dmesg_WARN();
        IPMI_ERR();
        system("dmesg -C");
        
        Sensor_Reading();
    }

}
