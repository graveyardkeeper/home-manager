function scrcpy
    functions -e scrcpy
    if [ -z "$ANDROID_SERIAL" ]
        set -gx ANDROID_SERIAL (command adb devices -l | grep -E '\sdevice\s' | fzf --bind one:accept --exit-0 | awk '{print $1}')
    end
    command scrcpy $argv
end
