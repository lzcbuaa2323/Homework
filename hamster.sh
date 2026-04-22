#!/bin/bash

WATCH_DIR="$HOME/project"          # 改成你要监控的目录
TAUNT_FILE="$HOME/.hamster_taunts.txt"
LOG_FILE="$HOME/.cache/hamster.log"

# 毒舌词库
TAUNTS=(
    "已经凌晨了，你写的代码明天肯定要回滚。"
    "仓鼠还在跑轮，你还在写 bug。"
    "你的黑眼圈和这个红色背景很配。"
    "这个时间写的递归，自己明天都看不懂。"
)

# 获取当前 SSH 会话的终端设备（通过 who 命令找你的登录 tty）
get_my_tty() {
    who -m | awk '{print $2}'       # who -m 显示当前用户本次登录的信息
}

# 改变背景色为亮红，5秒后恢复
flash_red() {
    local tty=$(get_my_tty)
    if [[ -n "$tty" ]] && [[ -w "/dev/$tty" ]]; then
        # 设置背景为亮红色 (ANSI OSC 11)
        echo -e "\033]11;#FF0000\007" > "/dev/$tty"
        sleep 5
        # 恢复默认背景色（此处改为黑色，可根据自己主题修改）
        echo -e "\033]11;#000000\007" > "/dev/$tty"
    fi
}

# 打印嘲讽信息，同时输出到终端和日志
say_taunt() {
    local idx=$(( RANDOM % ${#TAUNTS[@]} ))
    local msg="${TAUNTS[$idx]}"
    local tty=$(get_my_tty)
    echo "[$(date +'%H:%M:%S')] 仓鼠观察员：$msg" | tee -a "$LOG_FILE" > "/dev/$tty" 2>/dev/null || true
}

# 检查是否深夜
is_late_night() {
    local hour=$(date +%H)
    [[ $hour -ge 23 ]] || [[ $hour -lt 6 ]]
}

# 主循环
while true; do
    if is_late_night; then
        inotifywait -q -r \
            --exclude '(\.git|node_modules|__pycache__|\.venv|\.idea)' \
            -e modify,create,delete \
            --format '%w%f' \
            "$WATCH_DIR" 2>/dev/null | while read -r file; do
            # 仅对代码文件作出反应
            if [[ "$file" =~ \.(py|js|ts|go|java|cpp|c|rs|sh)$ ]]; then
                say_taunt
                flash_red
            fi
        done
    else
        sleep 60
    fi
done