import QtQuick

Item {
    id: root

    property string source: ""
    property int fillMode: Image.PreserveAspectCrop
    property int transitionDuration: 350
    readonly property bool hasValidSource: source !== ""

    anchors.fill: parent

    // Base background layer (holds settled texture)
    Image {
        id: currentBg
        anchors.fill: parent
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        visible: currentBg.source !== ""
    }

    // Top transition layer (fades in incoming texture)
    Image {
        id: nextBg
        anchors.fill: parent
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        opacity: 0.0
        visible: opacity > 0.0

        onStatusChanged: {
            if (status === Image.Ready && nextBg.source !== "") {
                if (currentBg.source !== "" && currentBg.source !== nextBg.source) {
                    fadeAnim.restart();
                } else {
                    currentBg.source = nextBg.source;
                    nextBg.opacity = 0.0;
                    nextBg.source = "";
                }
            }
        }

        NumberAnimation {
            id: fadeAnim
            target: nextBg
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: root.transitionDuration
            easing.type: Easing.InOutQuad
            onFinished: {
                currentBg.source = nextBg.source;
                nextBg.opacity = 0.0;
                nextBg.source = "";
            }
        }
    }

    onSourceChanged: {
        if (!source) {
            if (fadeAnim.running)
                fadeAnim.stop();
            currentBg.source = "";
            nextBg.source = "";
            nextBg.opacity = 0.0;
            return;
        }

        if (currentBg.source === "") {
            currentBg.source = source;
            return;
        }

        if (currentBg.source === source) {
            return;
        }

        if (fadeAnim.running) {
            fadeAnim.stop();
            currentBg.source = nextBg.source;
        }
        nextBg.opacity = 0.0;
        nextBg.source = source;
    }

    Component.onCompleted: {
        if (root.source) {
            currentBg.source = root.source;
        }
    }
}
