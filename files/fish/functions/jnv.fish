function jnv
    if isatty stdin
        # 没有标准输入，检查是否有参数
        if test (count $argv) -eq 0
            # 没有参数也没有标准输入，使用 pbpaste
            pbpaste | jnv
        else
            # 有参数，直接传给 jnv
            command jnv $argv
        end
    else
        # 有标准输入，传给 jnv
        command jnv $argv
    end
end
