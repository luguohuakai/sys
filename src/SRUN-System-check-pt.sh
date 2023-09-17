#!/bin/sh

#环境变量PATH没设好，在cron里执行时有很多命令会找不到
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile

[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
#uploadHostDailyCheckApi="http://1.1.1.1:8080/api"
#uploadHostDailyCheckReportApi="http://1.1.1.1:8080/api"
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION="S202004011202"

#日志相关
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
[ -f $PROGPATH ] && PROGPATH="."
LOGPATH="/srun3/log/System-check"
[ -e $LOGPATH ] || mkdir $LOGPATH
RESULTFILE="$LOGPATH/SRUN-System-check-`date +%Y%m%d%H%M`.txt"
function version(){
    echo ""
    echo ""
    echo ";系统巡检脚本：Version $VERSION"
}

function getCpuStatus(){
    echo ""
    echo ""
    echo ";############################ CPU检查 ##################################"
    echo ""	
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
    echo ";物理CPU个数
srun_Physical_CPUs=\"$Physical_CPUs\""
    echo ";逻辑CPU个数
srun_Virt_CPUs=\"$Virt_CPUs\""
    echo ";每CPU核心数
srun_CPU_Kernels=\"$CPU_Kernels\""
    echo ";CPU型号
srun_CPU_Type=\"$CPU_Type\""
    echo ";CPU架构
srun_CPU_Arch=\"$CPU_Arch\""
    #报表信息
    report_CPUs=$Virt_CPUs    #CPU数量
    report_CPUType=$CPU_Type  #CPU类型
    report_Arch=$CPU_Arch     #CPU架构
}

# function getsrunlogStatus(){
    # echo ""
    # echo ""
    # echo ";############################ srunlog清理检查 ##################################"
    # logcrontab=$(cat /etc/crontab |grep clear_log)
    # logetc=$(cat /srun3/etc/log_center.conf )
    # logtxtinterface=$(du -sh /srun3/log/interface/* |tail -10)
	# logSizeinterface=$(ls /srun3/log/rad_auth/ |wc -l)
	# logtxtdetail=$(du -sh /srun3/log/detail/* |tail -10)
	# logSizedetail=$(ls /srun3/log/detail/ |wc -l)
	# logphpmd5=$(md5sum /srun3/bin/scripts/clear_log.php)
	# echo ";脚本是否最新版本（md5对比 a98885f8bada9f8566911852b10568d2）非最新版本请到为知下载最新脚本"
	# echo ";脚本md5
# srun_log_phpmd5=\"$logphpmd5\""
    # echo ";清理脚本
# srun_log_crontab=\"$logcrontab\""
    # echo ";脚本配置
# srun_log_etc=\"$logetc\""
	# psinterface=$(ps -ef |grep -w /srun3/bin/interface |grep -v grep |awk '{print $8}')
	# if [[ $psinterface = /srun3/bin/interface ]];then
    # echo ";----------detail----------"
    # echo ";log文件数量
# srun_log_Sizedetail=\"$logSizedetail\""
    # echo ";近10天log
# srun_log_txt_detail=\"$logtxtdetail\""
	# fi
# }


function getdbbackStatus(){
    echo ""
    echo ""
    echo ";############################ 数据备份检查 ##################################"
	dbbackuppwd=$(cat /srun3/bin/db_backup |grep "filepath" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"' | awk -F '.' '{print $1}')
	redisbackuppwd=$(cat /srun3/bin/redis_backup |grep "filepath" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"' | awk -F '.' '{print $1}')
    mysqldbcrontab=$(cat /etc/crontab |grep /srun3/bin/db_backup)
    redisdbcrontab=$(cat /etc/crontab |grep /srun3/bin/redis_backup)
	mysqlbackClear=$(cat /etc/crontab |grep "rm -rf" |grep db_backup)
	redislbackClear=$(cat /etc/crontab |grep "rm -rf" |grep redis_backup)
    redisbackup=$(du -sh ${redisbackuppwd}* |tail -10)
	mysqlbackup=$(du -sh ${dbbackuppwd}* |tail -10)
	mysqlQuantity=$(ls ${dbbackuppwd}* |wc -l)
	redisQuantity=$(ls ${redisbackuppwd}* |wc -l)
    echo ";mysql备份脚本
srun_mysqldb_crontab=\"$mysqldbcrontab\""
    echo ";redis备份脚本
srun_redisdb_crontab=\"$redisdbcrontab\""
    echo ";mysql清理配置
srun_mysql_backClear=\"$mysqlbackClear\""
    echo ";redis清理配置
srun_redis_lbackClear=\"$redislbackClear\""
    echo ";----------redis备份文件----------"
    echo ";备份文件数量
srun_redis_Quantity=\"$redisQuantity\""
	echo ""
    # echo ";近10天文件大小
# srun_redis_backup=\"$redisbackup\""
    echo ""
	echo ""
	mysqlgrep=$(ps -ef |grep "mysql" |grep -v grep| tail -1 | awk '{print $8}')
	if [[ $mysqlgrep = /srun3/mysql/bin/mysqld ]];then
    echo ";----------mysql备份文件----------"
	echo ""
    echo ";备份文件数量
srun_mysql_Quantity=\"$mysqlQuantity\""
	echo ""
    # echo ";近10天文件大小
# srun_mysql_backup=\"$mysqlbackup\""
	fi
}

# function getMemStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 内存检查(MB) ##################################"
	# echo ""
    # if [[ $centosVersion < 7 ]];then
        # free -mo
    # else
        # free -h
    # fi
    # #报表信息
    # MemTotal=$(grep MemTotal /proc/meminfo| awk '{print $2}')  #KB
    # MemFree=$(grep MemFree /proc/meminfo| awk '{print $2}')    #KB
    # let MemUsed=MemTotal-MemFree
    # MemPercent=$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")
    # report_MemTotal="$((MemTotal/1024))""MB"        #内存总容量(MB)
    # report_MemFree="$((MemFree/1024))""MB"          #内存剩余(MB)
    # report_MemUsedPercent="$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%"   #内存使用率%
# }

function getDiskStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 磁盘检查 ##################################"
	# echo ""
    # df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
    # df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk
    # join /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$12}'| column -t
    # #报表信息
    # diskdata=$(df -TP | sed '1d' | awk '$2!="tmpfs"{print}') #KB
    # disktotal=$(echo "$diskdata" | awk '{total+=$3}END{print total}') #KB
    # diskused=$(echo "$diskdata" | awk '{total+=$4}END{print total}')  #KB
    # diskfree=$((disktotal-diskused)) #KB
    # diskusedpercent=$(echo $disktotal $diskused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
    # inodedata=$(df -iTP | sed '1d' | awk '$2!="tmpfs"{print}')
    # inodetotal=$(echo "$inodedata" | awk '{total+=$3}END{print total}')
    # inodeused=$(echo "$inodedata" | awk '{total+=$4}END{print total}')
    # inodefree=$((inodetotal-inodeused))
    # inodeusedpercent=$(echo $inodetotal $inodeused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
    # report_DiskTotal=$((disktotal/1024/1024))"GB"   #硬盘总容量(GB)
    # report_DiskFree=$((diskfree/1024/1024))"GB"     #硬盘剩余(GB)
    # report_DiskUsedPercent="$diskusedpercent""%"    #硬盘使用率%
    # report_InodeTotal=$((inodetotal/1000))"K"       #Inode总量
    # report_InodeFree=$((inodefree/1000))"K"         #Inode剩余
    # report_InodeUsedPercent="$inodeusedpercent""%"  #Inode使用率%
	smartctl=$(smartctl -H /dev/sda |grep "SMART Health Status")
	overallhealth=$(smartctl -H /dev/sda |grep "SMART overall-health")
	dellsmartctl=$(smartctl -a -d megaraid,0 /dev/sda |grep "SMART Health Status")
	redisdb=$(du -sh /srun3/redis/db/*)
	echo ""
	echo ";----------------------硬盘健康检查-------------------------------"
	echo "srun_smartctl=\"$smartctl\""
	echo "srun_overallhealth=\"$overallhealth\""
	echo ";----------------------DELL服务器硬盘检查-------------------------"
	echo "srun_dellsmartctl=\"$dellsmartctl\""
	echo ""
	# echo ";----------------------redis库大小-------------------------------"
	# echo "srun_redisdb=\"$redisdb\""

}
function getmysqlanalysis(){
	echo ""
    echo ""
	if [[ $mysqlgrep = /srun3/mysql/bin/mysqld ]];then
    echo ";############################ mysql数据概况查询 ##################################"
    HOSTNAME=$(cat /srun3/etc/srun.conf |grep "hostname" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"')
	USERNAME=$(cat /srun3/etc/srun.conf |grep "username" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"')
	PASSWORD=$(cat /srun3/etc/srun.conf |grep "password" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"')
	DBNAME=$(cat /srun3/etc/srun.conf |grep "dbname" |  head -n 1  | cut -d "=" -f2- | awk '{print $1}' | tr -d '"')
	sql="select count(*) from online_radius;"
	sql1="select max(count) from online_report_point where time_point>unix_timestamp(date_sub(curdate(),interval 1 day)) and time_point< unix_timestamp(curdate());
"
	sql2="select max(count) from online_report_user where time_point>unix_timestamp(date_sub(curdate(),interval 1 day)) and time_point< unix_timestamp(curdate());
"
	sql3="select count(*) from users;"
	sql4="select count(*) as '次数',err_msg as '错误信息' from srun_login_log group by err_msg having count(*)>1 ORDER BY count(*) DESC LIMIT 5;"
	sql7="select max(count) from online_report_user where time_point>unix_timestamp(date_sub(curdate(),interval 0 day));"
	sql8="select max(count) from online_report_point where time_point>unix_timestamp(date_sub(curdate(),interval 0 day));"
	sql9="SELECT SUM(spend_num) FROM checkout_list where create_at>unix_timestamp(date_sub(curdate(),interval 0 day))"
	sql10="SELECT SUM(spend_num) FROM checkout_list where create_at>unix_timestamp(DATE_FORMAT(now(), '%Y%m01' ));"
	sql11="SELECT SUM(pay_num) FROM pay_list where create_at>unix_timestamp(date_sub(curdate(),interval 0 day));"
	sql12="SELECT SUM(pay_num) FROM pay_list where create_at>unix_timestamp(DATE_FORMAT(now(), '%Y%m01' ));"
	sql13="SELECT SUM(rt_spend_num) FROM checkout_list where create_at>unix_timestamp(DATE_FORMAT(now(), '%Y%m01' ));"
	export MYSQL_PWD=${PASSWORD}
	users="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql3}" --default-character-set=UTF8 -N)"
	Currentonline="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql}" --default-character-set=UTF8 -N)"
	Yesterdayonlinedevice="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql1}" --default-character-set=UTF8 -N)"
	Yesterdayonline="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql2}" --default-character-set=UTF8 -N)"
	Currentmaximumonlinepopulation="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql7}" --default-character-set=UTF8 -N)"
	Currentmaximumnumberofonlinedevices="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql8}" --default-character-set=UTF8 -N)"
	Amountsettledtoday="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql9}" --default-character-set=UTF8 -N)"
	Settlementamountofthismonth="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql10}" --default-character-set=UTF8 -N)"
	Paymentamounttoday="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql11}" --default-character-set=UTF8 -N)"
	Paymentamountofthismonth="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql12}" --default-character-set=UTF8 -N)"
	Realtimesettlementamountofthismonth="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql13}" --default-character-set=UTF8 -N)"
	srunloginlog="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql4}" --default-character-set=UTF8)"
	echo ""
    echo ""
    #echo "=======================    当前系统用户数    ========================="
	echo ";当前用户数
srun_mysql_users=\"$users\""
    echo ";当前在线数
srun_mysql_Currentonline=\"$Currentonline\""
	echo ";今天最大在线人数
srun_mysql_Currentmaximumonlinepopulation=\"$Currentmaximumonlinepopulation\""
	echo ";今天最大在线设备数
srun_mysql_Currentmaximumnumberofonlinedevices=\"$Currentmaximumnumberofonlinedevices\""
	echo ";昨天最大在线人数
srun_mysql_Yesterdayonline=\"$Yesterdayonline\""
    echo ";昨天最大在线设备数
srun_mysql_Yesterdayonlinedevice=\"$Yesterdayonlinedevice\""
	# echo ""
	# echo ";今日结算金额
# srun_mysql_Amountsettledtoday=\"$Amountsettledtoday\""
	# echo ";本月结算金额
# srun_mysql_Settlementamountofthismonth=\"$Settlementamountofthismonth\""
	# echo ";本月实时结算金额
# srun_mysql_Realtimesettlementamountofthismonth=\"$Realtimesettlementamountofthismonth\""
	# echo ""
	# echo ";今日缴费金额
# srun_mysql_Paymentamounttoday=\"$Paymentamounttoday\""
	# echo ";本月缴费金额
# srun_mysql_Paymentamountofthismonth=\"$Paymentamountofthismonth\""
	echo ""
    echo ";本月认证失败原因TOP5
srun_mysql_srunloginlog=\"$srunloginlog\""
	echo ""
    echo ""
    # echo ";############################ mysql状态查询 #################################"
	# #查看正在运行的线程
	# sql5="show processlist;"
	# processlist="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql5}" --default-character-set=UTF8)"
	# #慢查询个数
	# sql6="Show status like 'slow_queries';"
	# slow_queries="$(mysql -h${HOSTNAME} -u${USERNAME} -D ${DBNAME} -e "${sql6}" --default-character-set=UTF8 -N)"
	# echo ";慢查询个数
# srun_slow_queries=\"$slow_queries\""
    # echo ""
	# echo ";正在运行的线程"
	# echo ";Id(线程)  User(用户)  Host(来源IP和端口)  db(库)  Command(执行的命令)  Time(持续时间秒)  State(状态)  Info(语句)"
	# echo "
# srun_processlist=\"$processlist\""

    fi
}

function getredisStatus(){
    echo ""
    echo ""
	#redis密码获取
	redispassword=$(cat /srun3/etc/system.conf |grep "password" | head -n 1 | cut -d "=" -f2- | awk '{print $1}' | tr -d '"')
	#Redis 分配的内存总量
    usedmemoryhuman0=$(/srun3/redis/bin/redis-cli -p 16380 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	usedmemoryhuman1=$(/srun3/redis/bin/redis-cli -p 16381 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	usedmemoryhuman2=$(/srun3/redis/bin/redis-cli -p 16382 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	usedmemoryhuman3=$(/srun3/redis/bin/redis-cli -p 16383 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	usedmemoryhuman4=$(/srun3/redis/bin/redis-cli -p 16384 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	usedmemoryhuman5=$(/srun3/redis/bin/redis-cli -p 16385 -a ${redispassword} info memory |grep used_memory_human |tr -d used_memory_human:)
	#Redis 已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
    usedmemoryrsshuman0=$(/srun3/redis/bin/redis-cli -p 16380 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	usedmemoryrsshuman1=$(/srun3/redis/bin/redis-cli -p 16381 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	usedmemoryrsshuman2=$(/srun3/redis/bin/redis-cli -p 16382 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	usedmemoryrsshuman3=$(/srun3/redis/bin/redis-cli -p 16383 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	usedmemoryrsshuman4=$(/srun3/redis/bin/redis-cli -p 16384 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	usedmemoryrsshuman5=$(/srun3/redis/bin/redis-cli -p 16385 -a ${redispassword} info memory |grep used_memory_rss_human |tr -d used_memory_rss_human:)
	#redis的内存消耗峰值
	usedmemorypeakhuman0=$(/srun3/redis/bin/redis-cli -p 16380 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	usedmemorypeakhuman1=$(/srun3/redis/bin/redis-cli -p 16381 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	usedmemorypeakhuman2=$(/srun3/redis/bin/redis-cli -p 16382 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	usedmemorypeakhuman3=$(/srun3/redis/bin/redis-cli -p 16383 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	usedmemorypeakhuman4=$(/srun3/redis/bin/redis-cli -p 16384 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	usedmemorypeakhuman5=$(/srun3/redis/bin/redis-cli -p 16385 -a ${redispassword} info memory |grep used_memory_peak_human |tr -d used_memory_peak_human:)
	#使用内存达到峰值内存的百分比，即(used_memory/ used_memory_peak) *100%
	usedmemorypeakperc0=$(/srun3/redis/bin/redis-cli -p 16380 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	usedmemorypeakperc1=$(/srun3/redis/bin/redis-cli -p 16381 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	usedmemorypeakperc2=$(/srun3/redis/bin/redis-cli -p 16382 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	usedmemorypeakperc3=$(/srun3/redis/bin/redis-cli -p 16383 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	usedmemorypeakperc4=$(/srun3/redis/bin/redis-cli -p 16384 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	usedmemorypeakperc5=$(/srun3/redis/bin/redis-cli -p 16385 -a ${redispassword} info memory |grep used_memory_peak_perc |tr -d used_memory_peak_perc:)
	#db0的key的数量,以及带有生存期的key的数,平均存活时间
	keyspace0=$(/srun3/redis/bin/redis-cli -p 16380 -a ${redispassword} info keyspace |tail -1)
	keyspace1=$(/srun3/redis/bin/redis-cli -p 16381 -a ${redispassword} info keyspace |tail -1)
	keyspace2=$(/srun3/redis/bin/redis-cli -p 16382 -a ${redispassword} info keyspace |tail -1)
	keyspace3=$(/srun3/redis/bin/redis-cli -p 16383 -a ${redispassword} info keyspace |tail -1)
	keyspace4=$(/srun3/redis/bin/redis-cli -p 16384 -a ${redispassword} info keyspace |tail -1)
	keyspace5=$(/srun3/redis/bin/redis-cli -p 16385 -a ${redispassword} info keyspace |tail -1)
    echo ";############################ redis检查 #########################################################"
	#16380
	echo ";------16380------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman0=\"$usedmemoryhuman0\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman0=\"$usedmemoryrsshuman0\""
	echo ";内存消耗峰
srun_redis_usedmemorypeakhuman0=\"$usedmemorypeakhuman0\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc0=\"$usedmemorypeakperc0\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace0=\"${keyspace0}\""
	echo ""
	#16381
	echo ";------16381------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman1=\"$usedmemoryhuman1\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman1=\"$usedmemoryrsshuman1\""
	echo ";内存消耗峰值
srun_redis_usedmemorypeakhuman1=\"$usedmemorypeakhuman1\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc1=\"$usedmemorypeakperc1\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace1=\"$keyspace1\""
	echo ""
	#16382
	echo ";------16382------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman2=\"$usedmemoryhuman2\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman2=\"$usedmemoryrsshuman2\""
	echo ";内存消耗峰值
srun_redis_usedmemorypeakhuman2=\"$usedmemorypeakhuman2\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc2=\"$usedmemorypeakperc2\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace2=\"$keyspace2\""
	echo ""
	#16383
	echo ";------16383------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman3=\"$usedmemoryhuman3\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman3=\"$usedmemoryrsshuman3\""
	echo ";内存消耗峰值
srun_redis_usedmemorypeakhuman3=\"$usedmemorypeakhuman3\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc3=\"$usedmemorypeakperc3\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace3=\"$keyspace3\""
	echo ""
	#16384
	echo ";------16384------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman4=\"$usedmemoryhuman4\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman4=\"$usedmemoryrsshuman4\""
	echo ";内存消耗峰值
srun_redis_usedmemorypeakhuman4=\"$usedmemorypeakhuman4\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc4=\"$usedmemorypeakperc4\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace4=\"$keyspace4\""
	echo ""
	#16385
	echo ";------16385------"
	echo ";分配的内存总量
srun_redis_usedmemoryhuman5=\"$usedmemoryhuman5\""
	echo ";已分配的内存总量（俗称常驻集大小）这个值和 top 、 ps等命令的输出一致
srun_redis_usedmemoryrsshuman5=\"$usedmemoryrsshuman5\""
	echo ";内存消耗峰值
srun_redis_usedmemorypeakhuman5=\"$usedmemorypeakhuman5\""
	echo ";使用内存达到峰值内存的百分比
srun_redis_usedmemorypeakperc5=\"$usedmemorypeakperc5\""
	echo ";db0的key的数量,以及带有生存期的key的数,平均存活时间
srun_redis_keyspace5=\"$keyspace5\""
	echo ""

}

function getSystemStatus(){
    echo ""
    echo ""
	touch /srun3/log/watch_rad.log
	touch /srun3/log/watch_interface.log
    echo ";############################ 系统检查 #####################################"
	echo ""
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
	srun=$(/srun3/bin/rad_auth -v |head -1)
	serverid=$(/srun3/bin/rad_auth -v |grep 'erver id')
	Onlineuser=$(/srun3/bin/rad_auth -v |grep 'Online')
	mysql=$(mysql -V)
	redis=$(/srun3/redis/bin/redis-server -v)
	rad_auth1=$(cat /srun3/log/watch_rad.log |grep rad_auth |tail -n -3 |sed -n 1p)
	rad_auth2=$(cat /srun3/log/watch_rad.log |grep rad_auth |tail -n -3 |sed -n 2p)
	rad_auth3=$(cat /srun3/log/watch_rad.log |grep rad_auth |tail -n -3 |sed -n 3p)
	rad_dm1=$(cat /srun3/log/watch_rad.log |grep rad_dm |tail -n -3 |sed -n 1p)
	rad_dm2=$(cat /srun3/log/watch_rad.log |grep rad_dm |tail -n -3 |sed -n 2p)
	rad_dm3=$(cat /srun3/log/watch_rad.log |grep rad_dm |tail -n -3 |sed -n 3p)
	radius1=$(cat /srun3/log/watch_rad.log |grep radiusd* |tail -n -3 |sed -n 1p)
	radius2=$(cat /srun3/log/watch_rad.log |grep radiusd* |tail -n -3 |sed -n 2p)
	radius3=$(cat /srun3/log/watch_rad.log |grep radiusd* |tail -n -3 |sed -n 3p)
	interface1=$(cat /srun3/log/watch_interface.log |grep interface |tail -n -3 |sed -n 1p)
	interface2=$(cat /srun3/log/watch_interface.log |grep interface |tail -n -3 |sed -n 2p)
	interface3=$(cat /srun3/log/watch_interface.log |grep interface |tail -n -3 |sed -n 3p)
	srun_portal_server1=$(cat /srun3/log/watch_rad.log |grep srun_portal_server |tail -3 |sed -n 1p)
	srun_portal_server2=$(cat /srun3/log/watch_rad.log |grep srun_portal_server |tail -3 |sed -n 2p)
	srun_portal_server3=$(cat /srun3/log/watch_rad.log |grep srun_portal_server |tail -3 |sed -n 3p)
	Manufacturer=$(dmidecode -t system |grep -E "Manufacturer" |awk '{print $2,$3,$4,$5}')
	Product_Name=$(dmidecode -t system |grep -E "Product Name" |awk '{print $2,$3,$4,$5}')
	do_checkout=$(cat /etc/crontab |grep do_checkout.4k)
	IP=$(cat /srun3/etc/system.conf |grep my_ip)
	echo ";服务器型号"
	echo "[system_check]"
	echo "srun_dmide_code[manufacturer]=\"$Manufacturer\""
	echo "srun_dmide_code[product_name]=\"$Product_Name\""
	echo ";服务器IP"
	echo "$IP"
    echo ";系统
srun_os=\"$OS\""
    echo ";发行版本
srun_release=\"$Release\""
    echo ";内核
srun_kernel=\"$Kernel\""
    echo ";主机名
srun_hostname=\"$Hostname\""
    echo ";语言/编码
srun_default_lang=\"$default_LANG\""
    echo ";当前时间
srun_date=\"$(date +'%F %T')\""
    echo ";最后启动
srun_last_reboot=\"$LastReboot\""
    echo ";运行时间
srun_uptime=\"$uptime\""
	echo ";SELinux
srun_se_linux=\"$SELinux\""
	echo ""
	echo ";############################ SRUN ##################################"
	echo "[srun]"
	echo ";srun内核版本
srun_srun=\"$srun\""
	echo "
srun_server_id=\"$serverid\""
	echo "
srun_online_user=\"$Onlineuser\""
	echo ";mysql版本
srun_mysql=\"$mysql\""
	echo ";redis版本
srun_redis=\"$redis\""
	echo ""
	# psrad_auth=$(ps -ef |grep -w /srun3/bin/rad_auth |grep -v grep |awk '{print $8}')
	# if [[ $psrad_auth = /srun3/bin/rad_auth ]];then
	# echo ";red_auth重启记录
# srun_rad_auth[]=\"$rad_auth1\"
# srun_rad_auth[]=\"$rad_auth2\"
# srun_rad_auth[]=\"$rad_auth3\""
	# echo ""
	# echo ";red_dm重启记录
# srun_rad_dm[]=\"$rad_dm1\"
# srun_rad_dm[]=\"$rad_dm2\"
# srun_rad_dm[]=\"$rad_dm3\""
	# echo ""
	# echo ";radius重启记录
# srun_radius[]=\"$radius1\"
# srun_radius[]=\"$radius2\"
# srun_radius[]=\"$radius3\""
	# echo ""
	# fi
	# echo ""
	# if [[ $psinterface = /srun3/bin/interface ]];then
	# echo ";interface重启记录
# srun_interface[]=\"$interface1\"
# srun_interface[]=\"$interface2\"
# srun_interface[]=\"$interface3\""
	# echo ""
	# fi
	# pssrun_portal_server=$(ps -ef |grep -w /srun3/bin/srun_portal_server |grep -v grep |awk '{print $8}')
	# if [[ $pssrun_portal_server = /srun3/bin/srun_portal_server ]];then
	# echo ";portal重启记录
# srun_srun_portal_server[]=\"$srun_portal_server1\"
# srun_srun_portal_server[]=\"$srun_portal_server2\"
# srun_srun_portal_server[]=\"$srun_portal_server3\""
	# fi
	echo ""
	echo ";----------------------- 结算脚本 -----------------------------"
	echo ""
	echo "
srun_do_checkout=\"$do_checkout\""


    #报表信息
    report_DateTime=$(date +"%F %T")  #日期
    report_Hostname="$Hostname"       #主机名
    report_OSRelease="$Release"       #发行版本
    report_Kernel="$Kernel"           #内核
    report_Language="$default_LANG"   #语言/编码
    report_LastReboot="$LastReboot"   #最近启动时间
    report_Uptime="$uptime"           #运行时间（天）
    report_Selinux="$SELinux"
    export LANG="$default_LANG"

}

function getServiceStatus(){
    echo ""
    echo ""
    echo ";############################ 服务检查 ##################################"
    echo ""
    if [[ $centosVersion > 7 ]];then
        conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
        process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)"       #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)"           #运行中服务数量
    else
        conf=$(/sbin/chkconfig | grep -E ":on|:启用")
        process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)"       #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)"           #运行中服务数量
    fi
    echo "服务配置"
    echo "--------"
    echo "$conf"  | column -t
    echo ""
    echo "正在运行的服务"
    echo "--------------"
    echo "$process"

}


# function getAutoStartStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 自启动检查 ##################################"
    # conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
    # echo "
# linux_conf=\"$conf\""
    # #报表信息
    # report_SelfInitiatedProgram="$(echo $conf | wc -l)"    #自启动程序数量
# }

# function getLoginStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 系统登录检查 ##################################"
    # Logincheck=$(last | head)
	# echo "
# linux_Logincheck=\"$Logincheck\""
# }

# function getNetworkStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 网络检查 ##################################"
    # if [[ $centosVersion < 7 ]];then
        # #/sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v inet6
		# ifconfig=$(/sbin/ifconfig -a)
	# echo "linux_ifconfig=\"$ifconfig\""
    # else
        # #ip a
        # for i in $(ip link | grep BROADCAST | awk -F: '{print $2}');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' ;echo "" ;done
    # fi
    # GATEWAY=$(ip route | grep default | awk '{print $3}')
    # DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    # echo ""
    # echo ";网关
# linux_GATEWAY=\"$GATEWAY\""
    # echo ";DNS
# linux_DNS=\"$DNS\""
    # #报表信息
    # IP=$(ip -f inet addr | grep -v 127.0.0.1 |  grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
    # MAC=$(ip link | grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
    # report_IP="$IP"            #IP地址
    # report_MAC=$MAC            #MAC地址
    # report_Gateway="$GATEWAY"  #默认网关
    # report_DNS="$DNS"          #DNS
	# sarnetwork=$(sar -n DEV 1 5)
	# echo ""
    # echo ""
    # echo ";############################ 流量情况 ##################################"
	# echo "
# linux_sarnetwork=\"$sarnetwork\""
# }

function getListenStatus(){
    echo ""
    echo ""
    echo "############################ 监听检查 ##################################"
    TCPListen=$(ss -ntul | column -t)
    echo "$TCPListen"
    #报表信息
    report_Listen="$(echo "$TCPListen"| sed '1d' | awk '/tcp/ {print $5}' | awk -F: '{print $NF}' | sort | uniq | wc -l)"
}

# function getCronStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 计划任务检查 ##################################"
    # Crontab=0
    # for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        # for user in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            # crontab -l -u $user >/dev/null 2>&1
            # status=$?
            # if [ $status -eq 0 ];then
                # echo "$user"
                # echo "--------"
                # crontab -l -u $user
                # let Crontab=Crontab+$(crontab -l -u $user | wc -l)
                # echo ""
            # fi
        # done
    # done
    # #计划任务
    # #find /etc/cron* -type f | xargs -i ls -l {} | column  -t
    # let Crontab=Crontab+$(find /etc/cron* -type f | wc -l)
	# Scheduletasks=$(cat /etc/crontab)
	# echo ";############################ crontab ##################################"
	# echo "
# linux_Scheduletasks=\"$Scheduletasks\""
    # #报表信息
    # report_Crontab="$Crontab"    #计划任务数

# }
function getHowLongAgo(){
    # 计算一个时间戳离现在有多久了
    datetime="$*"
    [ -z "$datetime" ] && echo "错误的参数：getHowLongAgo() $*"
    Timestamp=$(date +%s -d "$datetime")    #转化为时间戳
    Now_Timestamp=$(date +%s)
    Difference_Timestamp=$(($Now_Timestamp-$Timestamp))
    days=0;hours=0;minutes=0;
    sec_in_day=$((60*60*24));
    sec_in_hour=$((60*60));
    sec_in_minute=60
    while (( $(($Difference_Timestamp-$sec_in_day)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_day
        let days++
    done
    while (( $(($Difference_Timestamp-$sec_in_hour)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_hour
        let hours++
    done
    echo "$days 天 $hours 小时前"
}

function getUserLastLogin(){
    # 获取用户最近一次登录的时间，含年份
    # 很遗憾last命令不支持显示年份，只有"last -t YYYYMMDDHHMMSS"表示某个时间之间的登录，我
    # 们只能用最笨的方法了，对比今天之前和今年元旦之前（或者去年之前和前年之前……）某个用户
    # 登录次数，如果登录统计次数有变化，则说明最近一次登录是今年。
    username=$1
    : ${username:="`whoami`"}
    thisYear=$(date +%Y)
    oldesYear=$(last | tail -n1 | awk '{print $NF}')
    while(( $thisYear >= $oldesYear));do
        loginBeforeToday=$(last $username | grep $username | wc -l)
        loginBeforeNewYearsDayOfThisYear=$(last $username -t $thisYear"0101000000" | grep $username | wc -l)
        if [ $loginBeforeToday -eq 0 ];then
            echo "从未登录过"
            break
        elif [ $loginBeforeToday -gt $loginBeforeNewYearsDayOfThisYear ];then
            lastDateTime=$(last -i $username | head -n1 | awk '{for(i=4;i<(NF-2);i++)printf"%s ",$i}')" $thisYear" #格式如: Sat Nov 2 20:33 2015
            lastDateTime=$(date "+%Y-%m-%d %H:%M:%S" -d "$lastDateTime")
            echo "$lastDateTime"
            break
        else
            thisYear=$((thisYear-1))
        fi
    done

}

function getUserStatus(){
    echo ""
    echo ""
    echo ";############################ 系统用户检查 ##################################"
    #/etc/passwd 最后修改时间
    pwdfile="$(cat /etc/passwd)"
    Modify=$(stat /etc/passwd | grep Modify | tr '.' ' ' | awk '{print $2,$3}')

    echo "/etc/passwd 最后修改时间：$Modify ($(getHowLongAgo $Modify))"
    echo ""
    echo "特权用户"
    echo "--------"
    RootUser=""
    for user in $(echo "$pwdfile" | awk -F: '{print $1}');do
        if [ $(id -u $user) -eq 0 ];then
            echo "$user"
            RootUser="$RootUser,$user"
        fi
    done
    echo ""
    echo "用户列表"
    echo "--------"
    USERs=0
    echo "$(
    echo "用户名 UID GID HOME SHELL 最后一次登录"
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for username in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            userLastLogin="$(getUserLastLogin $username)"
            echo "$pwdfile" | grep -w "$username" |grep -w "$shell"| awk -F: -v lastlogin="$(echo "$userLastLogin" | tr ' ' '_')" '{print $1,$3,$4,$6,$7,lastlogin}'
        done
        let USERs=USERs+$(echo "$pwdfile" | grep "$shell"| wc -l)
    done
    )" | column -t
    echo ""
    echo "空密码用户"
    echo "----------"
    USEREmptyPassword=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
            for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            r=$(awk -F: '$2=="!!"{print $1}' /etc/shadow | grep -w $user)
            if [ ! -z $r ];then
                echo $r
                USEREmptyPassword="$USEREmptyPassword,"$r
            fi
        done
    done
    echo ""
    echo "相同ID的用户"
    echo "------------"
    USERTheSameUID=""
    UIDs=$(cut -d: -f3 /etc/passwd | sort | uniq -c | awk '$1>1{print $2}')
    for uid in $UIDs;do
        echo -n "$uid";
        USERTheSameUID="$uid"
        r=$(awk -F: 'ORS="";$3=='"$uid"'{print ":",$1}' /etc/passwd)
        echo "$r"
        echo ""
        USERTheSameUID="$USERTheSameUID $r,"
    done
    #报表信息
    report_USERs="$USERs"    #用户
    report_USEREmptyPassword=$(echo $USEREmptyPassword | sed 's/^,//')
    report_USERTheSameUID=$(echo $USERTheSameUID | sed 's/,$//')
    report_RootUser=$(echo $RootUser | sed 's/^,//')    #特权用户
}


function getPasswordStatus {
    echo ""
    echo ""
    echo "############################ 密码检查 ##################################"
    pwdfile="$(cat /etc/passwd)"
    echo ""
    echo "密码过期检查"
    echo "------------"
    result=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            get_expiry_date=$(/usr/bin/chage -l $user | grep 'Password expires' | cut -d: -f2)
            if [[ $get_expiry_date = ' never' || $get_expiry_date = 'never' ]];then
                printf "%-15s 永不过期\n" $user
                result="$result,$user:never"
            else
                password_expiry_date=$(date -d "$get_expiry_date" "+%s")
                current_date=$(date "+%s")
                diff=$(($password_expiry_date-$current_date))
                let DAYS=$(($diff/(60*60*24)))
                printf "%-15s %s天后过期\n" $user $DAYS
                result="$result,$user:$DAYS days"
            fi
        done
    done
    report_PasswordExpiry=$(echo $result | sed 's/^,//')

    echo ""
    echo "密码策略检查"
    echo "------------"
    grep -v "#" /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE"


}

function getSudoersStatus(){
    echo ""
    echo ""
    echo "############################ Sudoers检查 ##################################"
    conf=$(grep -v "^#" /etc/sudoers| grep -v "^Defaults" | sed '/^$/d')
    echo "$conf"
    echo ""
    #报表信息
    report_Sudoers="$(echo $conf | wc -l)"
}

function getInstalledStatus(){
    echo ""
    echo ""
    echo "############################ 软件检查 ##################################"
    rpm -qa --last | head | column -t
}

# function getProcessStatus(){
    # echo ""
    # echo ""
    # echo ";############################ 服务器负载/进程检查 ##################################"
	# load=$(uptime |awk '{print$8,$9,$10,$11,$12,$13,$14}')
	# limits=$(cat /etc/security/limits.conf |grep -v '#')
	# ulimit=$(ulimit -n)
	# echo ";服务器负载"
	# echo "
# linux_load=\"$load\""
	# echo ""
	# echo ";系统最大进程数"
	# echo ";limits配置
# linux_limits=\"$limits\""
    # echo ""
	# echo ";ulimit值
# linux_ulimit=\"$ulimit\""
    # if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
        # echo ""
        # echo ";僵尸进程";
        # ps -ef | head -n1
        # ps -ef | grep defunct | grep -v grep
    # fi
    # echo ""
    # echo ";内存占用TOP10"
    # Memory=$(echo -e "PID %MEM RSS COMMAND
    # $(ps aux | awk '{print $2, $4, $6, $11, $12}' | sort -k3rn | head -n 10 )"| column -t)
	# echo "linux_Memory=\"$Memory\""
    # echo ""
    # echo ";CPU占用TOP10"
	# CPUTOP10=$(top cb -n1 | head -17 | tail -11)
	# echo "
# linux_CPU_TOP10=\"$CPUTOP10\""
	# httpd=$(ps -ef |grep -E "httpd_intf" |grep -v grep |head -n 1 && ps -ef |grep -E "httpd_mgrt" |grep -v grep |head -n 1 && ps -ef |grep -E "httpd_services" |grep -v grep |head -n 1 && ps -ef |grep -E "httpd_dvcmgrt" |grep -v grep |head -n 1)
	# srun3bin=$(ps -ef |grep -v grep|grep -E '(/srun3/bin/|redis)')
	# srun3mysql=$(ps -ef |grep -v grep|grep -E /srun3/mysql/)
	# srun3redis=$(ps -ef |grep -E redis |grep -v grep)
    # #报表信息
    # report_DefunctProsess="$(ps -ef | grep defunct | grep -v grep|wc -l)"
	# echo ""
	# echo ";-----------srun4k进程-------------"
	# echo ""
	# echo ";------web进程------
# srun_httpd=\"$httpd\""
	# echo ""
	# echo ";------核心进程------
# srun_srun3bin=\"$srun3bin\""
	# echo ";------mysql------
# srun_srun3mysql=\"$srun3mysql\""
# }

# function getJDKStatus(){
    # echo ""
    # echo ""
    # echo "############################ JDK检查 ##################################"
    # java -version 2>/dev/null
    # if [ $? -eq 0 ];then
        # java -version 2>&1
    # fi
    # echo "JAVA_HOME=\"$JAVA_HOME\""
    # #报表信息
    # report_JDK="$(java -version 2>&1 | grep version | awk '{print $1,$3}' | tr -d '"')"
# }
function getSyslogStatus(){
    echo ""
    echo ""
    echo "############################ syslog检查 ##################################"
    echo "服务状态：$(getState rsyslog)"
    echo ""
    echo "/etc/rsyslog.conf"
    echo "-----------------"
    cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^\\$" | sed '/^$/d'  | column -t
    #报表信息
    report_Syslog="$(getState rsyslog)"
}
# function getFirewallStatus(){
    # echo ""
    # echo ""
    # echo "############################ 防火墙检查 ##################################"
    # #防火墙状态，策略等
    # if [[ $centosVersion < 7 ]];then
        # /etc/init.d/iptables status >/dev/null  2>&1
        # status=$?
        # if [ $status -eq 0 ];then
                # s="active"
        # elif [ $status -eq 3 ];then
                # s="inactive"
        # elif [ $status -eq 4 ];then
                # s="permission denied"
        # else
                # s="unknown"
        # fi
    # else
        # s="$(getState iptables)"
    # fi
    # echo "srun_iptablesstate=\"iptables: $s\""
    # echo ""
    # echo ";/etc/sysconfig/iptables"
    # echo "-----------------------"
    # iptables=$(cat /etc/sysconfig/iptables 2>/dev/null)
	# echo "srun_iptables=\"$iptables\""
    # #报表信息
    # report_Firewall="$s"
# }

# function getSNMPStatus(){
    # #SNMP服务状态，配置等
    # echo ""
    # echo ""
    # echo "############################ SNMP检查 ##################################"
    # status="$(getState snmpd)"
    # echo "\"服务状态：$status\""
    # echo ""
    # if [ -e /etc/snmp/snmpd.conf ];then
        # echo ";/etc/snmp/snmpd.conf"
        # echo ";--------------------"
        # \"cat /etc/snmp/snmpd.conf 2>/dev/null | grep -v "^#" | sed '/^$/d' \"
    # fi
    # #报表信息
    # report_SNMP="$(getState snmpd)"
# }



function getState(){
    if [[ $centosVersion < 7 ]];then
        if [ -e "/etc/init.d/$1" ];then
            if [ `/etc/init.d/$1 status 2>/dev/null | grep -E "is running|正在运行" | wc -l` -ge 1 ];then
                r="active"
            else
                r="inactive"
            fi
        else
            r="unknown"
        fi
    else
        #CentOS 7+
        r="$(systemctl is-active $1 2>&1)"
    fi
    echo "$r"
}

function getSSHStatus(){
    #SSHD服务状态，配置,受信任主机等
    echo ""
    echo ""
    echo "############################ SSH检查 ##################################"
    #检查受信任主机
    pwdfile="$(cat /etc/passwd)"
    echo "服务状态：$(getState sshd)"
    Protocol_Version=$(cat /etc/ssh/sshd_config | grep Protocol | awk '{print $2}')
    echo "SSH协议版本：$Protocol_Version"
    echo ""
    echo "信任主机"
    echo "--------"
    authorized=0
    for user in $(echo "$pwdfile" | grep /bin/bash | awk -F: '{print $1}');do
        authorize_file=$(echo "$pwdfile" | grep -w $user | awk -F: '{printf $6"/.ssh/authorized_keys"}')
        authorized_host=$(cat $authorize_file 2>/dev/null | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')
        if [ ! -z $authorized_host ];then
            echo "$user 授权 \"$authorized_host\" 无密码访问"
        fi
        let authorized=authorized+$(cat $authorize_file 2>/dev/null | awk '{print $3}'|wc -l)
    done

    echo ""
    echo "是否允许ROOT远程登录"
    echo "--------------------"
    config=$(cat /etc/ssh/sshd_config | grep PermitRootLogin)
    firstChar=${config:0:1}
    if [ $firstChar == "#" ];then
        PermitRootLogin="yes"  #默认是允许ROOT远程登录的
    else
        PermitRootLogin=$(echo $config | awk '{print $2}')
    fi
    echo "PermitRootLogin $PermitRootLogin"

    echo ""
    echo "/etc/ssh/sshd_config"
    echo "--------------------"
    cat /etc/ssh/sshd_config | grep -v "^#" | sed '/^$/d'

    #报表信息
    report_SSHAuthorized="$authorized"    #SSH信任主机
    report_SSHDProtocolVersion="$Protocol_Version"    #SSH协议版本
    report_SSHDPermitRootLogin="$PermitRootLogin"    #允许root远程登录
}
function getNTPStatus(){
    #NTP服务状态，当前时间，配置等
    echo ""
    echo ""
    echo "############################ NTP检查 ##################################"
    if [ -e /etc/ntp.conf ];then
        echo "服务状态：$(getState ntpd)"
        echo ""
        echo "/etc/ntp.conf"
        echo "-------------"
        cat /etc/ntp.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
    fi
    #报表信息
    report_NTP="$(getState ntpd)"
}

function getAPItatus(){
    #API接口请求情况。
	APIgrep=$(ps -ef |grep /etc/httpd/conf/httpd_intf.conf |grep -v grep |tail -1 |awk '{print $10}')
	APISamedayfail=$(cat /srun3/www/srun4-api/rest/runtime/logs/`date -d '0 day ago' +%Y-%m-%d`.log |grep error |wc -l)
	APIYesterdayfail=$(cat /srun3/www/srun4-api/rest/runtime/logs/`date -d '1 day ago' +%Y-%m-%d`.log |grep error |wc -l)
	a=$(cat /srun3/www/srun4-api/rest/runtime/logic_logs/`date -d '0 day ago' +%Y-%m-%d`.log* |wc -l)
	b=$(cat /srun3/www/srun4-api/rest/runtime/logic_logs/`date -d '1 day ago' +%Y-%m-%d`.log* |wc -l)
	APISamedaySuccess=$[$a/2]
	APIYesterdaySuccess=$[$b/2]
    if [[ $APIgrep = /etc/httpd/conf/httpd_intf.conf ]];then
	echo ""
    echo ";############################ API接口检查 ##################################"
    echo ";今天接口请求失败次数
srun_API_Samedayfail=\"$APISamedayfail\""
    echo ";昨天接口请求失败次数
srun_API_Yesterdayfail=\"$APIYesterdayfail\""
    echo ""
	echo ";“成功次数老版本API接口无法统计”"
    echo ";今天接口请求成功次数
srun_API_SamedaySuccess=\"$APISamedaySuccess\""
	echo ";昨天接口请求成功次数
srun_API_YesterdaySuccess=\"$APIYesterdaySuccess\""
    fi
}

function uploadHostDailyCheckReport(){
    json="{
        \"DateTime\":\"$report_DateTime\",
        \"Hostname\":\"$report_Hostname\",
        \"OSRelease\":\"$report_OSRelease\",
        \"Kernel\":\"$report_Kernel\",
        \"Language\":\"$report_Language\",
        \"LastReboot\":\"$report_LastReboot\",
        \"Uptime\":\"$report_Uptime\",
        \"CPUs\":\"$report_CPUs\",
        \"CPUType\":\"$report_CPUType\",
        \"Arch\":\"$report_Arch\",
        \"MemTotal\":\"$report_MemTotal\",
        \"MemFree\":\"$report_MemFree\",
        \"MemUsedPercent\":\"$report_MemUsedPercent\",
        \"DiskTotal\":\"$report_DiskTotal\",
        \"DiskFree\":\"$report_DiskFree\",
        \"DiskUsedPercent\":\"$report_DiskUsedPercent\",
        \"InodeTotal\":\"$report_InodeTotal\",
        \"InodeFree\":\"$report_InodeFree\",
        \"InodeUsedPercent\":\"$report_InodeUsedPercent\",
        \"IP\":\"$report_IP\",
        \"MAC\":\"$report_MAC\",
        \"Gateway\":\"$report_Gateway\",
        \"DNS\":\"$report_DNS\",
        \"Listen\":\"$report_Listen\",
        \"Selinux\":\"$report_Selinux\",
        \"Firewall\":\"$report_Firewall\",
        \"USERs\":\"$report_USERs\",
        \"USEREmptyPassword\":\"$report_USEREmptyPassword\",
        \"USERTheSameUID\":\"$report_USERTheSameUID\",
        \"PasswordExpiry\":\"$report_PasswordExpiry\",
        \"RootUser\":\"$report_RootUser\",
        \"Sudoers\":\"$report_Sudoers\",
        \"SSHAuthorized\":\"$report_SSHAuthorized\",
        \"SSHDProtocolVersion\":\"$report_SSHDProtocolVersion\",
        \"SSHDPermitRootLogin\":\"$report_SSHDPermitRootLogin\",
        \"DefunctProsess\":\"$report_DefunctProsess\",
        \"SelfInitiatedService\":\"$report_SelfInitiatedService\",
        \"SelfInitiatedProgram\":\"$report_SelfInitiatedProgram\",
        \"RuningService\":\"$report_RuningService\",
        \"Crontab\":\"$report_Crontab\",
        \"Syslog\":\"$report_Syslog\",
        \"SNMP\":\"$report_SNMP\",
        \"NTP\":\"$report_NTP\",
        \"JDK\":\"$report_JDK\"
    }"
    #echo "$json" 
    curl -l -H "Content-type: application/json" -X POST -d "$json" "$uploadHostDailyCheckReportApi" 2>/dev/null
}


function check(){
    version
    getSystemStatus
    getCpuStatus
    getDiskStatus
	#getMemStatus
	#getsrunlogStatus
	getdbbackStatus
	getmysqlanalysis
	getredisStatus
    #getListenStatus
    #getProcessStatus
	getAPItatus
    #getNetworkStatus
    #getServiceStatus
	#getAutoStartStatus
    #getLoginStatus
    #getCronStatus
    #getUserStatus
    #getPasswordStatus
    #getSudoersStatus
    #getJDKStatus
    #getFirewallStatus
    #getSSHStatus
    #getSyslogStatus
    #getSNMPStatus
    #getNTPStatus
    #getInstalledStatus
}


#执行检查并保存检查结果
check > $RESULTFILE

echo "检查结果：$RESULTFILE"

#上传检查结果的文件
#curl -F "filename=@$RESULTFILE" "$uploadHostDailyCheckApi" 2>/dev/null

#上传检查结果的报表
#uploadHostDailyCheckReport 1>/dev/null
