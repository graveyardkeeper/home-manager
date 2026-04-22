function _tide_pwd
    # 将家目录显示为 ~，并把最后一级之外的目录缩写为首字母。
    if set -l split_pwd (string replace -r "^$HOME" '~' -- $PWD | string split /)
        test -w . && set -f split_output "$split_pwd[1]" $split_pwd[2..] ||
            set -f split_output "$split_pwd[1]" $split_pwd[2..]
        set split_output[-1] "[38;2;0;175;255;1m$split_output[-1][m[38;2;0;135;175m"
    else
        set -f split_output "[38;2;0;175;255;1m~"
    end

    string join / -- $split_output | string length -V | read -g _tide_pwd_len

    if test (count $split_pwd) -gt 2
        for i in (seq 2 (math (count $split_pwd) - 1))
            set -l dir_section $split_pwd[$i]
            string match -qr "(?<short>\..|.)" -- $dir_section
            set split_output[$i] "[38;2;135;135;175m$short[m[38;2;0;135;175m"
            string join / -- $split_output | string length -V | read -g _tide_pwd_len
        end
    end

    string join -- / "[m[38;2;0;135;175m$split_output[1]" $split_output[2..]
end
