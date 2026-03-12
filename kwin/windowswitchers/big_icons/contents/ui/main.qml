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
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: ColumnLayout {
            id: dialogMainItem
            spacing: Kirigami.Units.smallSpacing * 2

            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.3, icons.implicitWidth), tabBox.screenGeometry.width * 0.9)

            Rectangle {
                id: background
                anchors.fill: parent
                anchors.margins: -Kirigami.Units.largeSpacing
                color: "#33DDDDDD"
                radius: Kirigami.Units.cornerRadius
                z: -1
            }

            property int maxItemsPerRow:  Math.floor(tabBox.screenGeometry.width * 0.9 / icons.delegateWidth)
            property int actualItemsPerRow:  Math.max(1, Math.min(tabBox.model.rowCount(), maxItemsPerRow))

            property int gridViewWidth: Math.max(4, actualItemsPerRow) * icons.delegateWidth
            property int gridViewHeight: Math.max(Math.ceil(tabBox.model.rowCount() / maxItemsPerRow), 1) * icons.delegateHeight

            GridView {
                id: icons

                readonly property int iconSize: Math.round(Kirigami.Units.iconSizes.enormous * 0.75)
                readonly property int iconPadding: Math.round(Kirigami.Units.largeSpacing * 1.25)
                readonly property int delegateWidth: iconSize + iconPadding * 2
                readonly property int delegateHeight: iconSize + iconPadding * 2

                implicitWidth: dialogMainItem.actualItemsPerRow * delegateWidth
                implicitHeight: dialogMainItem.gridViewHeight
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: tabBox.screenGeometry.width * 0.9
                Layout.fillWidth: false // to make centering with few icons work
                Layout.fillHeight: true
                cellWidth: delegateWidth
                cellHeight: delegateHeight

                currentIndex: tabBox.currentIndex
                focus: true
                flow: GridView.LeftToRight
                keyNavigationWraps: true

                model: tabBox.model
                delegate: Item {
                    property string caption: model.caption
                    property string appName: {
                        var name = model.resourceClass;
                        if (!name) return model.caption;
                        name = name.split('.').pop();
                        return name.charAt(0).toUpperCase() + name.slice(1);
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
                    color: Kirigami.Theme.highlightColor
                    opacity: 0.2
                    radius: Kirigami.Units.cornerRadius
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: icons.iconSize
                    height: icons.iconSize
                    source: "org.kde.dolphin"
                    visible: icons.count === 0
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
                    text: icons.currentItem ? icons.currentItem.appName : "Finder"
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideMiddle
                    font.weight: Font.Bold
                    width: Math.min(implicitWidth + Kirigami.Units.largeSpacing * 2, parent.width)
                    x: {
                        if (!icons.currentItem) return (parent.width - width) / 2;
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
                if (event.key === Qt.Key_Up) {
                    icons.moveCurrentIndexUp()
                } else if (event.key === Qt.Key_Down) {
                    icons.moveCurrentIndexDown()
                } else if (event.key === Qt.Key_Left) {
                    icons.moveCurrentIndexLeft()
                } else if (event.key === Qt.Key_Right) {
                    icons.moveCurrentIndexRight()
                }
            }
        }

        onSceneGraphError: () => {
            // This slot is intentionally left blank, otherwise QtQuick may post a qFatal() message on a graphics reset.
        }
    }
}
