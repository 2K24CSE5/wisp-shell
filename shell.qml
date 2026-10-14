import Quickshell
import qs.modules.wallpaper
import qs.modules.settings
import qs.modules.polkit
import qs.modules.lockscreen
import qs.modules.bar
import qs.modules.notifications

ShellRoot {
    Wallpaper {}
    Settings {}
    Polkit {}
    LockScreen {}
    Bar {}
}
