/****************************************************************************
**
** Copyright (C) 2014 Dinu SV.
** (contact: mail@dinusv.com)
** This file is part of Live CV application.
**
** GNU General Public License Usage
** 
** This file may be used under the terms of the GNU General Public License 
** version 3.0 as published by the Free Software Foundation and appearing 
** in the file LICENSE.GPL included in the packaging of this file.  Please 
** review the following information to ensure the GNU General Public License 
** version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.
**
****************************************************************************/

import QtQuick 2.2
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.1
import Cv 1.0
import "view"

Rectangle {
    id : root
    width: 1240
    height: 700
    color : "#293039"

    signal beforeCompile()
    signal afterCompile()

    LogWindow{
        id : logWindow
        visible : false
        Component.onCompleted: width = root.width
        text : lcvlog.data
        onTextChanged: {
            if ( !visible && text !== "" )
                header.isLogWindowDirty = true
        }
    }

    Top{
        id : header
        anchors.top : parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        property var callback : function(){}

        isTextDirty: editor.isDirty

        property string action : ""

        onMessageYes: {
            fileSaveDialog.open()
        }
        onMessageNo: {
            callback()
            callback = function(){}
        }
        onNewFile  : {
            if ( editor.isDirty ){
                callback = function(){
                    editor.text    = "Rectangle{\n}"
                    editor.isDirty = false;
                }
                questionSave()
            } else {
                editor.text    = "Rectangle{\n}"
                editor.isDirty = false
            }
        }
        onOpenFile : {
            if ( editor.isDirty ){
                callback = function(){
                    fileOpenDialog.open()
                }
                questionSave()
            } else {
                fileOpenDialog.open()
            }
        }
        onSaveFile : {
            fileSaveDialog.open()
        }

        onToggleLogWindow : {
            if ( !logWindow.visible ){
                logWindow.show()
                isLogWindowDirty = false
            }
        }

        onFontPlus: if ( editor.font.pixelSize < 24 ) editor.font.pixelSize += 2
        onFontMinus: if ( editor.font.pixelSize > 10 ) editor.font.pixelSize -= 2
    }

    FileDialog {
        id: fileOpenDialog
        title: "Please choose a file"
        nameFilters: [ "Qml files (*.qml)", "All files (*)" ]
        selectExisting : true
        visible : false
        onAccepted: {
            editor.text = codeDocument.openFile(fileOpenDialog.fileUrl)
            editor.isDirty = false
        }
    }

    FileDialog{
        id : fileSaveDialog
        title: "Please choose a file"
        nameFilters: [ "Qml files (*.qml)", "All files (*)" ]
        selectExisting : false
        visible : false
        onAccepted: {
            codeDocument.saveFile(fileSaveDialog.fileUrl, editor.text)
            editor.isDirty = false
            header.callback()
            header.callback = function(){}
        }
        onRejected:{
            header.callback()
            header.callback = function(){}
        }
    }

    Rectangle{
        id : contentWrap
        anchors.top : header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height : parent.height - header.height

        Rectangle{
            id : editorWrap
            color : "#041725"
            height : parent.height
            anchors.left: parent.left
            clip : true

            Flickable {
                id: flick

                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.topMargin: 8
                anchors.bottomMargin: 30
                contentWidth: editor.paintedWidth
                contentHeight: editor.paintedHeight

                function ensureVisible(r){
                    if (contentX >= r.x)
                        contentX = r.x;
                    else if (contentX + width <= r.x + r.width)
                        contentX = r.x + r.width - width;
                    if (contentY >= r.y)
                        contentY = r.y;
                    else if (contentY + height <= r.y + r.height)
                        contentY = r.y + r.height - height;
                }

                Editor{
                    id : editor
                    property bool isDirty : false

                    onCursorRectangleChanged: {
                        flick.ensureVisible(cursorRectangle)
                    }
                    onSave: {
                        if ( codeDocument.file !==  "" ){
                            codeDocument.saveFile(editor.text)
                            editor.isDirty = false
                        }else
                            fileSaveDialog.open()
                    }
                    onOpen: {
                        header.openFile()
                    }
                    onToggleSize: {
                        if ( splitter.x < contentWrap.width / 2)
                            splitter.x = contentWrap.width - contentWrap.width / 4
                        else if ( splitter.x === contentWrap.width / 2 )
                            splitter.x = contentWrap.width / 4
                        else
                            splitter.x = contentWrap.width / 2
                    }
                    onPageDown : {
                        var lines = flick.height / cursorRectangle.height
                        var nextLineStartPos = editor.text.indexOf('\n', cursorPosition)
                        while ( lines-- > 0 && nextLineStartPos !== -1 ){
                            cursorPosition   = nextLineStartPos + 1
                            nextLineStartPos = editor.text.indexOf('\n', cursorPosition)
                        }
                    }
                    onPageUp : {
                        var lines = flick.height / cursorRectangle.height
                        var prevLineStartPos = editor.text.lastIndexOf('\n', cursorPosition - 1)
                        while ( --lines > 0 ){
                            cursorPosition   = prevLineStartPos + 1
                            prevLineStartPos = editor.text.lastIndexOf('\n', cursorPosition - 2)
                            if ( prevLineStartPos === -1 ){
                                cursorPosition = 0;
                                break;
                            }
                        }
                    }

                    text : "Rectangle{\n}"
                    color : "#eeeeee"
                    font.family: "Lucida Console, Courier New"

                    focus: true

                    height : Math.max( flick.height, paintedHeight )
                    width : Math.max( flick.width, paintedWidth )

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 40 }
                    }
                    Component.onCompleted: isDirty = false
                }

            }

            Rectangle{
                id : errorWrap
                anchors.bottom: parent.bottom
                height : error.text !== '' ? 30 : 0
                width : parent.width
                color : "#141a1a"
                Behavior on height {
                    SpringAnimation { spring: 3; damping: 0.1 }
                }

                Rectangle{
                    width : 14
                    height : parent.height
                    color : "#601818"
                    visible: error.text === "" ? false : true
                }
                Text {
                    id: error
                    anchors.left : parent.left
                    anchors.leftMargin: 25
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    font.pointSize: 25 * editor.fontScale
                    text: ""
                    onTextChanged : console.log(text)
                    color: "#c5d0d7"
                }
            }

        }

        Rectangle{
            id : splitter
             anchors.top: parent.top
             height : parent.height
             z : 100
             width : 2
             color : "#1c2228"
             Component.onCompleted: x = parent.width / 3.4
             onXChanged: {
                 viewer.width  = contentWrap.width - x - 2
                 editorWrap.width = x + 2
             }
             MouseArea{
                anchors.fill: parent
                drag.target: splitter
                drag.axis: Drag.XAxis
                drag.minimumX: 2
                drag.maximumX: contentWrap.width - 150
             }
             CursorArea{
                 anchors.fill: parent
                 cursorShape: Qt.SplitHCursor
             }
         }

        Rectangle{
            id : viewer
            anchors.left : splitter.right
            anchors.right: parent.right
            height : parent.height
            color : "#051521"

            Item {
                id: tester
                anchors.fill: parent
                property string program: editor.text
                property variant item
                onProgramChanged: {
                    editor.isDirty = true
                    createTimer.restart()
                }
                Timer {
                    id: createTimer
                    interval: 1000
                    running: true
                    repeat : false
                    onTriggered: {
                        var newItem;
                        try {
                            root.beforeCompile()
                            newItem = Qt.createQmlObject("import QtQuick 2.1\n" + tester.program, tester, "canvas");
                        } catch (err) {
                            error.text = "Line " + err.qmlErrors[0].lineNumber + ": " + err.qmlErrors[0].message;
                        }
                        if ( tester.program === "Rectangle{\n}" || tester.program === "" )
                            editor.isDirty = false

                        if (newItem){
                            error.text = "";
                            if (tester.item) {
                                tester.item.destroy();
                            }
                            tester.item = newItem;
                            root.afterCompile()
                        }
                    }
                }
            }
        }

    }

}
