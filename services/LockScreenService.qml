pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.configs

Singleton {
    id: service

    property string currentTime: ""
    property string currentDate: ""
    property string statusMessage: ""
    property bool isAuthenticating: false
    property string pendingPassword: ""
    property bool isLocked: false
    property bool isDimmed: false

    readonly property int idleTimeoutSeconds: Math.max(0, Config.idleLockTimeout) * 60
    readonly property int fadeTime: (typeof Config.fadeDuration === "number" && Config.fadeDuration >= 300) ? Config.fadeDuration : 1000

    Timer {
        id: postFadeLockTimer
        interval: service.fadeTime + 50
        repeat: false
        onTriggered: {
            service.isLocked = true;
            pendingPassword = "";
            statusMessage = "";

            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
            service.isDimmed = false;
        }
    }

    function triggerFadeAndLock(): void {
        if (service.isDimmed || service.isLocked)
            return;

        service.isDimmed = true;

        Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -s -q set 0% -t " + service.fadeTime + "; fi"]);

        postFadeLockTimer.restart();
    }

    function wakeScreen(): void {
        postFadeLockTimer.stop();

        if (service.isDimmed) {
            service.isDimmed = false;

            Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -r -q -t 150 || brightnessctl -q set 80% -t 150; fi"]);
        }
    }

    IdleMonitor {
        id: idleMonitor
        enabled: service.idleTimeoutSeconds > 0
        timeout: service.idleTimeoutSeconds
        onIsIdleChanged: {
            if (isIdle) {
                if (!service.isLocked) {
                    service.triggerFadeAndLock();
                }
            } else {
                if (!service.isLocked) {
                    service.wakeScreen();
                } else {
                    Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -r -q -t 150 || brightnessctl -q set 80% -t 150; fi"]);
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const date = new Date();
            service.currentTime = Qt.formatTime(date, "hh:mm");
            service.currentDate = Qt.formatDateTime(date, "dddd, MMMM d");
        }
    }

    PamContext {
        id: pam
        config: "login"
        user: Config.targetUser
        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(service.pendingPassword);
                service.pendingPassword = "";
            }
        }
        onCompleted: result => {
            service.isAuthenticating = false;
            service.pendingPassword = "";
            if (result === PamResult.Success) {
                service.statusMessage = "Unlocked";
                service.isLocked = false;
                service.wakeScreen();
            } else {
                service.statusMessage = "Incorrect password";
            }
        }
        onError: error => {
            service.isAuthenticating = false;
            service.pendingPassword = "";
            service.statusMessage = PamError.toString(error);
        }
    }

    function unlock(password: string): void {
        if (!password || isAuthenticating || !Config.targetUser)
            return;
        pendingPassword = password;
        isAuthenticating = true;
        statusMessage = "Unlocking...";
        if (!pam.start()) {
            isAuthenticating = false;
            pendingPassword = "";
            statusMessage = "Could not start authentication";
        }
    }

    function lock(): void {
        pendingPassword = "";
        statusMessage = "";
        service.triggerFadeAndLock();
    }

    property IpcHandler lockIpc: IpcHandler {
        target: "lockscreen"
        function lock(): void {
            service.triggerFadeAndLock();
        }
    }
}
