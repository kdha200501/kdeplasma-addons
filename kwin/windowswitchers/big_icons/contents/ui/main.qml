/*
 KWin - the KDE window manager
 This file is part of the KDE project.

 SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>

 SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    currentIndex: (instantiator.object as BigIconsDialog)?.currentIndex ?? currentIndex

    Instantiator {
        id: instantiator
        active: tabBox.visible
        delegate: BigIconsDialog { }
    }

    component BigIconsDialog: PlasmaCore.Dialog {
        property alias currentIndex: icons.currentIndex
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.Popup | Qt.X11BypassWindowManagerHint
        backgroundHints: PlasmaCore.Dialog.NoBackground
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - frame.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - frame.height * 0.5

        mainItem: Item {
          id: frame
          readonly property real padding: Kirigami.Units.smallSpacing * 2
          implicitWidth: dialogMainItem.implicitWidth + padding * 2
          // mirrors the caption row below the icons so the icons sit centred
          readonly property real extraTop: captionLabel.implicitHeight + Kirigami.Units.smallSpacing * 4
          implicitHeight: dialogMainItem.implicitHeight + padding * 2 + extraTop

          Rectangle {
            anchors.fill: parent
            // Matches the macOS app switcher proportions
            radius: Math.round(height * 0.17)
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.85)
          }

          ColumnLayout {
            id: dialogMainItem
            anchors.fill: parent
            anchors.margins: frame.padding
            anchors.topMargin: frame.padding + frame.extraTop
            spacing: Kirigami.Units.smallSpacing * 2

            ListView {
                id: icons

                readonly property int baseIconSize: Math.round(Kirigami.Units.iconSizes.enormous * 0.75)
                readonly property int baseIconPadding: Math.round(Kirigami.Units.largeSpacing * 1.25)
                readonly property int baseDelegateWidth: baseIconSize + baseIconPadding * 2
                // shrink icons so all of them fit on a single row (0.3 accounts for the side margins)
                readonly property real availableWidth: tabBox.screenGeometry.width * 0.9 - frame.padding * 2
                readonly property real scale: Math.min(1, availableWidth / (Math.max(1, count) + 0.3) / baseDelegateWidth)
                readonly property int iconSize: Math.max(1, Math.floor(baseIconSize * scale))
                readonly property int iconPadding: Math.floor(baseIconPadding * scale)
                readonly property int delegateWidth: iconSize + iconPadding * 2
                readonly property int delegateHeight: iconSize + iconPadding * 2

                implicitWidth: Math.max(1, count) * delegateWidth
                implicitHeight: delegateHeight
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: delegateWidth * 0.15
                Layout.rightMargin: delegateWidth * 0.15
                Layout.preferredWidth: implicitWidth
                Layout.maximumWidth: tabBox.screenGeometry.width * 0.9
                Layout.fillWidth: false // to make centering with few icons work
                Layout.fillHeight: true
                orientation: ListView.Horizontal

                currentIndex: tabBox.currentIndex
                focus: true
                keyNavigationWraps: true

                model: tabBox.model
                delegate: Item {
                    property string caption: model.caption
                    property string appName: {
                        var name = model.resourceClass;
                        if (!name) return model.caption;
                        name = name.split('.').pop();
                        name = name.charAt(0).toUpperCase() + name.slice(1);
                        if (name === "Dolphin") return "Finder";
                        return name;
                    }

                    width: icons.delegateWidth
                    height: icons.delegateHeight

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: icons.iconSize
                        height: icons.iconSize
                        source: model.icon
                        active: index == icons.currentIndex
                    }

                    Accessible.name: caption

                    TapHandler {
                        onSingleTapped: {
                            if (index === icons.currentIndex) {
                                icons.model.activate(index);
                                return;
                            }
                            icons.currentIndex = index;
                        }
                        onDoubleTapped: icons.model.activate(index)
                    }
                }

                highlight: Rectangle {
                    id: highlightItem
                    width: icons.delegateWidth
                    height: icons.delegateHeight
                    color: "#505050"
                    opacity: 0.7
                    radius: Kirigami.Units.cornerRadius
                }

                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
            }

            Item {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                implicitHeight: captionLabel.implicitHeight

                PlasmaComponents3.Label {
                    id: captionLabel
                    text: icons.currentItem?.appName ?? ""
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle
                    font.weight: Font.Bold
                    width: Math.min(implicitWidth + Kirigami.Units.largeSpacing * 2, parent.width)
                    x: {
                        if (!icons.currentItem) return icons.x + icons.width / 2 - width / 2;
                        var itemCenterX = icons.currentItem.x + icons.delegateWidth / 2 - icons.contentX + icons.x;
                        return Math.max(0, Math.min(itemCenterX - width / 2, parent.width - width));
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 1
                        verticalOffset: 1
                        radius: 4
                        samples: 9
                        color: "#80000000"
                    }
                }
            }

            Connections {
                target: tabBox
                function onCurrentIndexChanged() {
                    icons.currentIndex = tabBox.currentIndex;
                }
            }

            /*
             * Key navigation on outer item for two reasons:
             * @li we have to emit the change signal
             * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
             **/
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left) {
                    icons.decrementCurrentIndex()
                } else if (event.key === Qt.Key_Right) {
                    icons.incrementCurrentIndex()
                }
            }
          }
        }

        onSceneGraphError: () => {
            // This slot is intentionally left blank, otherwise QtQuick may post a qFatal() message on a graphics reset.
        }
    }
}
