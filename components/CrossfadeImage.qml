import QtQuick

Item {
    id: root

    property string source: ""
    property int fillMode: Image.PreserveAspectCrop
    property int transitionDuration: 350
    property bool hasValidSource: source !== ""

    anchors.fill: parent

    // Base background layer (holds settled texture)
    Image {
        id: currentBg
        anchors.fill: parent
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        visible: root.hasValidSource && currentBg.status === Image.Ready
        source: root.source
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
        visible: root.hasValidSource

        source: root.source

        function handleReady() {
            if (status !== Image.Ready)
                return;

            if (currentBg.source !== "" && currentBg.source !== nextBg.source) {
                fadeAnim.restart();
            } else {
                currentBg.source = nextBg.source;
                nextBg.opacity = 0.0;
            }
        }

        onStatusChanged: handleReady()
        onSourceChanged: {
            if (fadeAnim.running) {
                fadeAnim.stop();
            }
            nextBg.opacity = 0.0;
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
            }
        }
    }

    onHasValidSourceChanged: {
        if (!hasValidSource) {
            fadeAnim.stop();
            currentBg.source = "";
            nextBg.source = "";
            nextBg.opacity = 0.0;
        }
    }
}
