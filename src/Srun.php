<?php

namespace luguohuakai\sys;

/**
 * 深澜相关服务检测
 */
class Srun
{
    private string $srun_conf = '/srun3/etc/srun.conf';
    private string $system_conf = '/srun3/etc/system.conf';

    // 静态信息
    // 用户总数
    // 授权到期时间
    public function srun()
    {
        $version = `/srun3/bin/rad_auth -v |head -1`;
        $server_id = `/srun3/bin/rad_auth -v|grep "Server id"`;
        $online_user_num = `/srun3/bin/rad_auth -v|grep "Online user number"`;
    }

    // 动态信息
    // 在线数
    // mysql状态
    public function mysql()
    {
        $version = `mysql -V`;
    }

    // redis状态
    public function redis()
    {
        $backup_count = `ls /srun3/redis_backup/* | wc -l`;
        $version = `/srun3/redis/bin/redis-server -v`;
    }
    // radius/AAA服务状态
    // portal状态
    // clickhouse状态
    // 结算脚本

}