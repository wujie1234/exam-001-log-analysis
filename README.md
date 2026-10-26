# exam-001-log-analysis

分析 Web 服务器访问日志（Common Log Format / Apache、Nginx 默认格式），输出**访问次数最多的客户端 IP** 与 **HTTP 状态码分布**。

## 输出示例

```
=== Top IP ===
192.168.1.100: 5 requests

=== Status Code Distribution ===
200: 6
401: 1
404: 2
500: 1
```

## 用法

```bash
# 默认读取 /data/access.log，写入 /output/report.txt
./solve.sh

# 或显式指定路径，便于本地调试
./solve.sh data/sample-access.log ./report.txt
```

报告同时会打印到标准输出，方便直接查看。目录不存在时会自动创建。

## 运行环境

- bash 4+、awk（gawk / mawk / busybox awk 均可）
- 无第三方依赖，不需要 python

## 测试

```bash
./tests/run_tests.sh
```

对 `data/sample-access.log` 跑一遍并逐行精确比对，全部通过时退出码为 0。

## 日志格式假设

```
192.168.1.100 - - [01/Jan/2024:10:00:00 +0000] "GET /api/users HTTP/1.1" 200 1234
└─ 客户端 IP ─┘   └────── 时间戳 ──────┘ └──── request line ───┘ └status┘ └bytes┘
```

## 设计说明

**为什么不用字段切分取状态码。** `$9` 这种取法只在 request 行不含空格时成立。一旦出现 `"GET /a b HTTP/1.1"` 或服务端记录成裸 `"-"`，后面所有列都会错位，状态码会静默变成错误的数字。脚本改为按双引号切分，取第 3 段的第一个 token，失败再回退到倒数第二列。

**脏行过滤。** 只接受包含 `[timestamp]` 的行，空行、堆栈信息、乱文本不会被计成一个虚构的「客户端 IP」。

**输出可复现。** awk 的数组遍历顺序是未定义的，直接取最大值会在平局时随机选一个。脚本在次数相同时按 IP 字典序打破平局，因此同样的输入必然得到逐字节相同的报告。状态码则用插入排序按数值升序输出，且不依赖 gawk 独有的 `asort()`/`PROCINFO`。

**单遍扫描。** IP 计数和状态码计数在同一次 awk 过程中完成，日志只读一遍。

## 目录结构

```
.
├── solve.sh                 # 主脚本
├── data/
│   └── sample-access.log    # 样例日志
├── tests/
│   └── run_tests.sh         # 本地校验脚本
└── .gitignore
```
