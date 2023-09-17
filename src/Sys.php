<?php

namespace luguohuakai\sys;

class Sys
{
    private string $sys;

    // 容量进位/进制
    private int $binary = 1000;
    private int $kb;
    private int $mb;
    private int $gb;

    // win
    private $wmi;

    public function __construct()
    {
        $this->kb = $this->binary;
        $this->mb = $this->binary * $this->binary;
        $this->gb = $this->binary * $this->binary * $this->binary;
        $this->sys = PHP_OS_FAMILY;
    }

    /**
     * 设置容量进位 默认:1000
     * @param int $n
     * @return void
     */
    public function setBinary(int $n = 1000)
    {
        $this->binary = $n;
        $this->kb = $this->binary;
        $this->mb = $this->binary * $this->binary;
        $this->gb = $this->binary * $this->binary * $this->binary;
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

    public static function phpVersion(): string
    {
        return PHP_VERSION;
    }

    /**
     * @return array [k => v] GB<br>
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
            $mem_total = round($mem->TotalVisibleMemorySize / $this->mb, 2);
            $mem_available = round($mem->FreePhysicalMemory / $this->mb, 2);
            $mem_used = round($mem_total - $mem_available, 2);
        } else {
            // Linux MEM
            $free = shell_exec('free');
            $free = trim($free);
            $free_arr = explode("\n", $free);
            $mem = explode(" ", $free_arr[1]);
            $mem = array_filter($mem, function ($value) {
                return ($value !== null && $value !== false && $value !== '');
            }); // removes nulls from array
            $mem = array_merge($mem); // puts arrays back to [0],[1],[2] after
            $mem_total = round($mem[1] / $this->mb, 2);
            $mem_used = round($mem[2] / $this->mb, 2);
            $mem_free = round($mem[3] / $this->mb, 2);
            $mem_shared = round($mem[4] / $this->mb, 2);
            $mem_cached = round($mem[5] / $this->mb, 2);
            $mem_available = round($mem[6] / $this->mb, 2);
        }
        $data = compact('mem_total', 'mem_available', 'mem_used');
        if (isset($mem_shared)) $data['mem_shared'] = $mem_shared;
        if (isset($mem_free)) $data['mem_free'] = $mem_free;
        if (isset($mem_cached)) $data['mem_cached'] = $mem_cached;

        return $data;
    }

    /**
     * @return array [k => v] <br>
     * load cpu负载 0.00-100.00 <br>
     * count cpu核心数<br>
     * real_count cpu物理个数
     * per_count 每个cpu核心个数
     * model_name CPU型号
     * arch cpu架构
     */
    public function cpu(): array
    {
        if ($this->sys === 'Windows') {
            // Win CPU
            $this->initWin();
            $cpus = $this->wmi->InstancesOf('Win32_Processor');
            $cpu_load = 0;
            $cpu_count = 0;
            foreach ($cpus as $cpu) {
                $cpu_load += $cpu->LoadPercentage;
                $cpu_count++;
            }
        } else {
            // Linux CPU
            $load = sys_getloadavg();
            $cpu_load = $load[0];
            $cpu_count = shell_exec('nproc');
            $cpu_real_count = `cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`;
            $per_cpu_count = `cat /proc/cpuinfo | grep "cores" |uniq| awk -F ': ' '{print $2}'`;
            $model_name = `cat /proc/cpuinfo | grep "model name" | awk -F ': ' '{print $2}' | sort | uniq`;
            $arch = `uname -m`;
        }

        return [
            'load' => round($cpu_load, 2),
            'count' => (int)trim($cpu_count),
            'real_count' => isset($cpu_real_count) ? (int)trim($cpu_real_count) : 0,
            'per_count' => isset($per_cpu_count) ? (int)trim($per_cpu_count) : 0,
            'model_name' => isset($model_name) ? trim($model_name) : '',
            'arch' => isset($arch) ? trim($arch) : '',
        ];
    }

    /**
     * 连接数统计
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
     * @return array [k => v] GB <br>
     * disk_free 剩余磁盘容量 <br>
     * disk_total 总磁盘容量
     */
    public function disk(): array
    {
        $disk_free = round(disk_free_space(".") / $this->gb);
        $disk_total = round(disk_total_space(".") / $this->gb);
        return compact('disk_free', 'disk_total');
    }

    /**
     * php使用内存 GB
     * @return float
     */
    public function phpUsage(): float
    {
        return round(memory_get_usage() / $this->mb, 2);
    }

    /**
     * @return array [k => v] <br>
     * ip 服务器IP
     * product_name 产品名称
     * description 系统描述
     * date 系统时间
     * uname_r 内核
     * uname_o 系统
     * uname_n 主机名
     * selinux selinux状态
     * last_reboot 最后启动
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
}