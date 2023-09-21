<?php

namespace luguohuakai\sys;

use luguohuakai\func\Func;

class Sys
{
    private string $sys;

    // win
    private COM $wmi;

    public function __construct()
    {
        $this->sys = PHP_OS_FAMILY;
    }

    /**
     * 注意: COM组件需要在php.ini中开启<br>
     * [COM_DOT_NET]<br>
     * extension=php_com_dotnet.dll
     * @return void
     */
    public function initWin()
    {
        if (!class_exists('COM')) {
            echo 'Class not exists: COM; config php.ini:extension=php_com_dotnet.dll, Please!' . PHP_EOL;
            exit(1);
        }
        $this->wmi = new COM('WinMgmts:\\\\.');
    }

    /**
     * @return array [k => v]<br>
     * Linux + Win: <br>
     * mem_total 总内存<br>
     * mem_used 已用内存<br>
     * mem_available 可用内存<br>
     * Linux:<br>
     * mem_shared 共享内存<br>
     * mem_cached 缓冲内存<br>
     * mem_free 剩余内存数
     */
    public function mem(): array
    {
        if ($this->sys === 'Windows') {
            // WIN MEM
            $this->initWin();
            $res = $this->wmi->ExecQuery('SELECT FreePhysicalMemory,FreeVirtualMemory,TotalSwapSpaceSize,TotalVirtualMemorySize,TotalVisibleMemorySize FROM Win32_OperatingSystem');
            $mem = $res->ItemIndex(0);
            $mem_total = $mem->TotalVisibleMemorySize;
            $mem_available = $mem->FreePhysicalMemory;
            $mem_used = $mem_total - $mem_available;
        } else {
            // Linux MEM
            $free = shell_exec('free');
            $free = trim($free);
            $free_arr = explode("\n", $free);
            $mem = explode(' ', $free_arr[1]);
            $mem = array_filter($mem, function ($value) {
                return ($value !== null && $value !== false && $value !== '');
            }); // removes nulls from array
            $mem = array_merge($mem); // puts arrays back to [0],[1],[2] after
            $mem_total = $mem[1];
            $mem_used = $mem[2];
            $mem_free = $mem[3];
            $mem_shared = $mem[4];
            $mem_cached = $mem[5];
            $mem_available = $mem[6];
        }
        $data = compact('mem_total', 'mem_available', 'mem_used');
        if (isset($mem_shared)) $data['mem_shared'] = $mem_shared;
        if (isset($mem_free)) $data['mem_free'] = $mem_free;
        if (isset($mem_cached)) $data['mem_cached'] = $mem_cached;

        return $data;
    }

    /**
     * 内存信息
     * @param bool $bFormat 格式化
     * @return array
     */
    public function getMem(bool $bFormat = false): array
    {
        if (false === ($str = file_get_contents('/proc/meminfo'))) return [];

        preg_match_all("/MemTotal\s*:+\s*([\d.]+).+?MemFree\s*:+\s*([\d.]+).+?MemAvailable\s*:+\s*([\d.]+).+?Cached\s*:+\s*([\d.]+).+?SwapTotal\s*:+\s*([\d.]+).+?SwapFree\s*:+\s*([\d.]+)/s", $str, $mems);
        preg_match_all("/Buffers\s*:+\s*([\d.]+)/s", $str, $buffers);

        $mtotal = $mems[1][0] * 1024;
        $mfree = $mems[2][0] * 1024;
        $mem_available = $mems[3][0] * 1024;

        $mbuffers = $buffers[1][0] * 1024;
        $mcached = $mems[4][0] * 1024;
        $stotal = $mems[5][0] * 1024;
        $sfree = $mems[6][0] * 1024;
        $mused = $mtotal - $mfree;
        $sused = $stotal - $sfree;
        $mrealused = $mtotal - $mfree - $mcached - $mbuffers; // 真实内存使用

        $rtn['mem_total'] = !$bFormat ? $mtotal : Func::dataSizeFormat($mtotal, 1);
        $rtn['mem_free'] = !$bFormat ? $mfree : Func::dataSizeFormat($mfree, 1);
        $rtn['mem_available'] = !$bFormat ? $mem_available : Func::dataSizeFormat($mem_available, 1);
        $rtn['mem_shared'] = !$bFormat ? $mbuffers : Func::dataSizeFormat($mbuffers, 1);
        $rtn['mem_cached'] = !$bFormat ? $mcached : Func::dataSizeFormat($mcached, 1);
        $rtn['mem_used'] = !$bFormat ? ($mtotal - $mfree) : Func::dataSizeFormat($mtotal - $mfree, 1);
        $rtn['mem_percent'] = (floatval($mtotal) != 0) ? round($mused / $mtotal * 100, 1) : 0;
        $rtn['mem_real_used'] = !$bFormat ? $mrealused : Func::dataSizeFormat($mrealused, 1);
        $rtn['mem_real_free'] = !$bFormat ? ($mtotal - $mrealused) : Func::dataSizeFormat($mtotal - $mrealused, 1);// 真实空闲
        $rtn['mem_real_percent'] = (floatval($mtotal) != 0) ? round($mrealused / $mtotal * 100, 1) : 0; // 真实内存使用率
        $rtn['mem_cached_percent'] = (floatval($mcached) != 0) ? round($mcached / $mtotal * 100, 1) : 0; // Cached内存使用率
        $rtn['swap_total'] = !$bFormat ? $stotal : Func::dataSizeFormat($stotal, 1);
        $rtn['swap_free'] = !$bFormat ? $sfree : Func::dataSizeFormat($sfree, 1);
        $rtn['swap_used'] = !$bFormat ? $sused : Func::dataSizeFormat($sused, 1);
        $rtn['swap_percent'] = (floatval($stotal) != 0) ? round($sused / $stotal * 100, 1) : 0;
        return $rtn;
    }

    /**
     * @return array [k => v] <br>
     * load 系统负载<br>
     */
    public function sysLoad(): array
    {
        return [
            'sys_load' => sys_getloadavg(),
        ];
    }

    /**
     * 获取系统负载
     * @return array|string[]
     */
    public function getLoad(): array
    {
        if (false === ($str = file_get_contents('/proc/loadavg'))) return [];

        return explode(' ', $str);
    }

    /**
     * 获取CPU使用率
     * @return array
     */
    public function cpu(): array
    {
        $cpu_usage = 0;
        $cpu_info1 = $this->cpuInfo();
        if ($cpu_info1) {
            sleep(1);
            $cpu_info2 = $this->cpuInfo();

            $time = $cpu_info2['time'] - $cpu_info1['time'];
            $total = $cpu_info2['total'] - $cpu_info1['total'];
            $cpu_usage = round($time / $total, 4) * 100;
        }
        return compact('cpu_usage');
    }

    private function cpuInfo()
    {
        if (false === ($str = file_get_contents('/proc/stat'))) return false;

        $cpu = [];
        $mode = "/(cpu)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)[\s]+([0-9]+)/";
        preg_match_all($mode, $str, $cpu);
        $total = $cpu[2][0] + $cpu[3][0] + $cpu[4][0] + $cpu[5][0] + $cpu[6][0] + $cpu[7][0] + $cpu[8][0] + $cpu[9][0];
        $time = $cpu[2][0] + $cpu[3][0] + $cpu[4][0] + $cpu[6][0] + $cpu[7][0] + $cpu[8][0] + $cpu[9][0];

        return [
            'total' => $total,
            'time' => $time,
        ];
    }

    /**
     * @return array [k => v] <br>
     * count cpu核心数<br>
     * real_count cpu物理个数<br>
     * per_count 每个cpu核心个数<br>
     * model_name CPU型号<br>
     * arch cpu架构<br>
     */
    public function cpuStatic(): array
    {
        $cpu_count = shell_exec('nproc');
        $cpu_real_count = `cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`;
        $per_cpu_count = `cat /proc/cpuinfo | grep "cores" |uniq| awk -F ': ' '{print $2}'`;
        $model_name = `cat /proc/cpuinfo | grep "model name" | awk -F ': ' '{print $2}' | sort | uniq`;
        $arch = `uname -m`;
        return [
            'count' => (int)trim($cpu_count),
            'real_count' => isset($cpu_real_count) ? (int)trim($cpu_real_count) : 0,
            'per_count' => isset($per_cpu_count) ? (int)trim($per_cpu_count) : 0,
            'model_name' => isset($model_name) ? trim($model_name) : '',
            'arch' => isset($arch) ? trim($arch) : '',
        ];
    }

    /**
     * 服务器运行时间
     * @return string[]
     */
    public function uptime(): array
    {
        if (false === ($str = file_get_contents('/proc/uptime'))) return ['sys_uptime' => ''];
        $upTime = '';
        $str = explode(' ', $str);
        $str = trim($str[0]);
        $min = $str / 60;
        $hours = $min / 60;
        $days = (int)($hours / 24);
        $hours = $hours % 24;
        $min = $min % 60;

        if ($days !== 0) $upTime = $days . '天';
        if ($hours !== 0) $upTime .= $hours . '小时';

        return ['sys_uptime' => $upTime . $min . '分钟'];
    }

    /**
     * 连接数统计<br>
     * @return array [k => v]<br>
     * connections 已建立连接数<br>
     * total_connections 总连接数
     */
    public function connections(): array
    {
        if ($this->sys === 'Windows') {
            // WIN CONNECTIONS
            $connections = shell_exec('netstat -nt | findstr :' . $_SERVER['SERVER_PORT'] . ' | findstr ESTABLISHED | find /C /V ""');
            $total_connections = shell_exec('netstat -nt | findstr :' . $_SERVER['SERVER_PORT'] . ' | find /C /V ""');
        } else {
            // Linux Connections
            $connections = `netstat -ntu | grep -E ':80 |443 ' | grep ESTABLISHED | grep -v LISTEN | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | grep -v 127.0.0.1 | wc -l`;
            $total_connections = `netstat -ntu | grep -E ':80 |443 ' | grep -v LISTEN | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | grep -v 127.0.0.1 | wc -l`;
        }
        $connections = (int)trim($connections);
        $total_connections = (int)trim($total_connections);

        return compact('connections', 'total_connections');
    }

    /**
     * 磁盘信息 <br>
     * @return array [k => v] <br>
     * disk_free 剩余磁盘容量 <br>
     * disk_total 总磁盘容量
     */
    public function disk(string $dir = '.'): array
    {
        $disk_free = round(disk_free_space($dir));
        $disk_total = round(disk_total_space($dir));
        return compact('disk_free', 'disk_total');
    }

    /**
     * 服务器静态信息<br>
     * @return array [k => v] <br>
     * ip 服务器IP <br>
     * product_name 产品名称 <br>
     * description 系统描述 <br>
     * date 系统时间 <br>
     * uname_r 内核 <br>
     * uname_o 系统 <br>
     * uname_n 主机名 <br>
     * selinux selinux状态 <br>
     * last_reboot 最后启动 <br>
     * uptime 运行时间
     */
    public function server(): array
    {
        $ip = `hostname -i`;
        $product_name = `dmidecode | grep "Product Name"`;
        $lsb_release = `lsb_release -a | grep "Description"`;
        $uname_r = `uname -r`;
        $uname_o = `uname -o`;
        $uname_n = `uname -n`;
        $selinux = `/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}'`;
        $last_reboot = `who -b | awk '{print $3,$4}'`;
        $uptime = `uptime | sed 's/.*up \([^,]*\), .*/\1/'`;
        return [
            'ip' => trim($ip),
            'product_name' => trim($product_name),
            'description' => trim(explode(':', $lsb_release)[1]),
            'date' => date('Y-m-d H:i:s'),
            'uname_r' => isset($uname_r) ? trim($uname_r) : '',
            'uname_o' => isset($uname_o) ? trim($uname_o) : '',
            'uname_n' => isset($uname_n) ? trim($uname_n) : '',
            'selinux' => isset($selinux) ? trim($selinux) : '',
            'last_reboot' => isset($last_reboot) ? trim($last_reboot) : '',
            'uptime' => isset($uptime) ? trim($uptime) : '',
        ];
    }

    public function getIp(): array
    {
        $ip = `hostname -i`;
        return ['ip' => trim($ip)];
    }

    /**
     * 获取网络数据
     * @param bool $bFormat
     * @return array
     */
    public function network(bool $bFormat = false): array
    {
        $rtn = [];
        $netstat = file_get_contents('/proc/net/dev');
        if (false === $netstat) return [];

        $buffer = preg_split("/\n/", $netstat, -1, PREG_SPLIT_NO_EMPTY);
        foreach ($buffer as $buf) {
            if (preg_match('/:/', $buf)) {
                list($dev_name, $stats_list) = preg_split('/:/', $buf, 2);
                $dev_name = trim($dev_name);

                $stats = preg_split('/\s+/', trim($stats_list));
                $rtn[$dev_name]['name'] = $dev_name;
                $rtn[$dev_name]['in_rate'] = !$bFormat ? $stats[0] : $this->netSizeFormat($stats[0]);
                $rtn[$dev_name]['in_packets'] = $stats[1];
                $rtn[$dev_name]['in_errors'] = $stats[2];
                $rtn[$dev_name]['in_drop'] = $stats[3];

                $rtn[$dev_name]['out_traffic'] = !$bFormat ? $stats[8] : $this->netSizeFormat($stats[8]);
                $rtn[$dev_name]['out_packets'] = $stats[9];
                $rtn[$dev_name]['out_errors'] = $stats[10];
                $rtn[$dev_name]['out_drop'] = $stats[11];
            }
        }

        return $rtn;
    }

    public function netSizeFormat($size): string
    {
        if ($size < 1024) {
            $unit = 'Bbps';
        } else if ($size < 10240) {
            $size = round($size / 1024, 2);
            $unit = 'Kbps';
        } else if ($size < 102400) {
            $size = round($size / 1024, 2);
            $unit = 'Kbps';
        } else if ($size < 1048576) {
            $size = round($size / 1024, 2);
            $unit = 'Kbps';
        } else if ($size < 10485760) {
            $size = round($size / 1048576, 2);
            $unit = 'Mbps';
        } else if ($size < 104857600) {
            $size = round($size / 1048576, 2);
            $unit = 'Mbps';
        } else if ($size < 1073741824) {
            $size = round($size / 1048576, 2);
            $unit = 'Mbps';
        } else {
            $size = round($size / 1073741824, 2);
            $unit = 'Gbps';
        }

        $size .= $unit;

        return $size;
    }
}