<?php

namespace luguohuakai\sys;

class Sys
{
    private string $sys;

    // win
    private $wmi;

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
            $mem_total = round($mem->TotalVisibleMemorySize / 1000000, 2);
            $mem_available = round($mem->FreePhysicalMemory / 1000000, 2);
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
            $mem_total = round($mem[1] / 1000000, 2);
            $mem_used = round($mem[2] / 1000000, 2);
            $mem_free = round($mem[3] / 1000000, 2);
            $mem_shared = round($mem[4] / 1000000, 2);
            $mem_cached = round($mem[5] / 1000000, 2);
            $mem_available = round($mem[6] / 1000000, 2);
        }
        $data = compact('mem_total', 'mem_available', 'mem_used');
        if (isset($mem_shared)) $data['mem_shared'] = $mem_shared;
        if (isset($mem_free)) $data['mem_free'] = $mem_free;
        if (isset($mem_cached)) $data['mem_cached'] = $mem_cached;

        return $data;
    }

    /**
     * @return array [k => v] <br>
     * cpu_load cpu负载 0.00-100.00 <br>
     * cpu_count cpu核心数
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
        }

        return compact('cpu_load', 'cpu_count');
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

        return compact('connections', 'total_connections');
    }

    /**
     * @return array [k => v] GB <br>
     * disk_free 剩余磁盘容量 <br>
     * disk_total 总磁盘容量
     */
    public function disk(): array
    {
        $disk_free = round(disk_free_space(".") / 1000000000);
        $disk_total = round(disk_total_space(".") / 1000000000);
        return compact('disk_free', 'disk_total');
    }

    /**
     * php使用内存 GB
     * @return float
     */
    public function phpUsage(): float
    {
        return round(memory_get_usage() / 1000000, 2);
    }

    /**
     * @return array [k => v] <br>
     * name 服务器域名 <br>
     * ip 服务器IP
     */
    public function server(): array
    {
        return [
            'name' => $_SERVER['SERVER_NAME'],
            'ip' => $_SERVER['SERVER_ADDR']
        ];
    }
}