import QtQuick 2.1
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponent

Item {
	id: widget

	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.h
	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.h
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/plasma/scripting/dataenginescript.cpp
	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			if (cmd) {
				connectSource(cmd)
			}
		}
		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}

	function performClick() {
		executable.exec(plasmoid.configuration.clickCommand)
	}

	function performMouseWheelUp() {
		executable.exec(plasmoid.configuration.mousewheelUpCommand)
	}

	function performMouseWheelDown() {
		executable.exec(plasmoid.configuration.mousewheelDownCommand)
	}

	Item {
		id: config
		readonly property bool active: !!command
		readonly property bool waitForCompletion: plasmoid.configuration.waitForCompletion
		readonly property int interval: Math.max(0, plasmoid.configuration.interval)
		readonly property string command: plasmoid.configuration.command || 'sleep 2 && echo "Test: $(date +%s)"'
		readonly property bool clickEnabled: !!plasmoid.configuration.clickCommand
		readonly property bool mousewheelEnabled: (plasmoid.configuration.mousewheelUpCommand || plasmoid.configuration.mousewheelDownCommand)
		readonly property color textColor: plasmoid.configuration.textColor || theme.textColor
		readonly property color outlineColor: plasmoid.configuration.outlineColor || theme.backgroundColor
		readonly property bool showOutline: plasmoid.configuration.showOutline

		onCommandChanged: widget.runCommand()
		onIntervalChanged: {
			// interval=0 stops the timer even with Timer.repeat=true, so we may
			// need to restart the timer. Might as well restart the interval too.
			timer.restart()
		}
		onWaitForCompletionChanged: {
			if (!waitForCompletion) {
				// The timer needs to be restarted in case the timer was already
				// triggered and the command is running. If we don't restart the
				// timer, it'll stop forever.
				timer.restart()
			}
		}
	}

	property string outputText: ''
	Connections {
		target: executable
		onExited: {
			if (cmd == config.command) {
				var formattedText = stdout
				if (plasmoid.configuration.replaceAllNewlines) {
					formattedText = formattedText.replace('\n', ' ').trim()
				} else if (formattedText.length >= 1 && formattedText[formattedText.length-1] == '\n') {
					formattedText = formattedText.substr(0, formattedText.length-1)
				}
				// console.log('[commandoutput]', 'stdout', JSON.stringify(stdout))
				// console.log('[commandoutput]', 'format', JSON.stringify(formattedText))
				widget.outputText = ansi2Html(formattedText)

				if (config.waitForCompletion) {
					timer.restart()
				}
			}
		}
	}

	function ansi2Html(str) {
		const ansi256 = {
			0: '#000000',
			1: '#800000',
			2: '#008000',
			3: '#808000',
			4: '#000080',
			5: '#800080',
			6: '#008080',
			7: '#c0c0c0',
			8: '#808080',
			9: '#ff0000',
			10: '#00ff00',
			11: '#ffff00',
			12: '#0000ff',
			13: '#ff00ff',
			14: '#00ffff',
			15: '#ffffff',
			16: '#000000',
			17: '#00005f',
			18: '#000087',
			19: '#0000af',
			20: '#0000d7',
			21: '#0000ff',
			22: '#005f00',
			23: '#005f5f',
			24: '#005f87',
			25: '#005faf',
			26: '#005fd7',
			27: '#005fff',
			28: '#008700',
			29: '#00875f',
			30: '#008787',
			31: '#0087af',
			32: '#0087d7',
			33: '#0087ff',
			34: '#00af00',
			35: '#00af5f',
			36: '#00af87',
			37: '#00afaf',
			38: '#00afd7',
			39: '#00afff',
			40: '#00d700',
			41: '#00d75f',
			42: '#00d787',
			43: '#00d7af',
			44: '#00d7d7',
			45: '#00d7ff',
			46: '#00ff00',
			47: '#00ff5f',
			48: '#00ff87',
			49: '#00ffaf',
			50: '#00ffd7',
			51: '#00ffff',
			52: '#5f0000',
			53: '#5f005f',
			54: '#5f0087',
			55: '#5f00af',
			56: '#5f00d7',
			57: '#5f00ff',
			58: '#5f5f00',
			59: '#5f5f5f',
			60: '#5f5f87',
			61: '#5f5faf',
			62: '#5f5fd7',
			63: '#5f5fff',
			64: '#5f8700',
			65: '#5f875f',
			66: '#5f8787',
			67: '#5f87af',
			68: '#5f87d7',
			69: '#5f87ff',
			70: '#5faf00',
			71: '#5faf5f',
			72: '#5faf87',
			73: '#5fafaf',
			74: '#5fafd7',
			75: '#5fafff',
			76: '#5fd700',
			77: '#5fd75f',
			78: '#5fd787',
			79: '#5fd7af',
			80: '#5fd7d7',
			81: '#5fd7ff',
			82: '#5fff00',
			83: '#5fff5f',
			84: '#5fff87',
			85: '#5fffaf',
			86: '#5fffd7',
			87: '#5fffff',
			88: '#870000',
			89: '#87005f',
			90: '#870087',
			91: '#8700af',
			92: '#8700d7',
			93: '#8700ff',
			94: '#875f00',
			95: '#875f5f',
			96: '#875f87',
			97: '#875faf',
			98: '#875fd7',
			99: '#875fff',
			100: '#878700',
			101: '#87875f',
			102: '#878787',
			103: '#8787af',
			104: '#8787d7',
			105: '#8787ff',
			106: '#87af00',
			107: '#87af5f',
			108: '#87af87',
			109: '#87afaf',
			110: '#87afd7',
			111: '#87afff',
			112: '#87d700',
			113: '#87d75f',
			114: '#87d787',
			115: '#87d7af',
			116: '#87d7d7',
			117: '#87d7ff',
			118: '#87ff00',
			119: '#87ff5f',
			120: '#87ff87',
			121: '#87ffaf',
			122: '#87ffd7',
			123: '#87ffff',
			124: '#af0000',
			125: '#af005f',
			126: '#af0087',
			127: '#af00af',
			128: '#af00d7',
			129: '#af00ff',
			130: '#af5f00',
			131: '#af5f5f',
			132: '#af5f87',
			133: '#af5faf',
			134: '#af5fd7',
			135: '#af5fff',
			136: '#af8700',
			137: '#af875f',
			138: '#af8787',
			139: '#af87af',
			140: '#af87d7',
			141: '#af87ff',
			142: '#afaf00',
			143: '#afaf5f',
			144: '#afaf87',
			145: '#afafaf',
			146: '#afafd7',
			147: '#afafff',
			148: '#afd700',
			149: '#afd75f',
			150: '#afd787',
			151: '#afd7af',
			152: '#afd7d7',
			153: '#afd7ff',
			154: '#afff00',
			155: '#afff5f',
			156: '#afff87',
			157: '#afffaf',
			158: '#afffd7',
			159: '#afffff',
			160: '#d70000',
			161: '#d7005f',
			162: '#d70087',
			163: '#d700af',
			164: '#d700d7',
			165: '#d700ff',
			166: '#d75f00',
			167: '#d75f5f',
			168: '#d75f87',
			169: '#d75faf',
			170: '#d75fd7',
			171: '#d75fff',
			172: '#d78700',
			173: '#d7875f',
			174: '#d78787',
			175: '#d787af',
			176: '#d787d7',
			177: '#d787ff',
			178: '#d7af00',
			179: '#d7af5f',
			180: '#d7af87',
			181: '#d7afaf',
			182: '#d7afd7',
			183: '#d7afff',
			184: '#d7d700',
			185: '#d7d75f',
			186: '#d7d787',
			187: '#d7d7af',
			188: '#d7d7d7',
			189: '#d7d7ff',
			190: '#d7ff00',
			191: '#d7ff5f',
			192: '#d7ff87',
			193: '#d7ffaf',
			194: '#d7ffd7',
			195: '#d7ffff',
			196: '#ff0000',
			197: '#ff005f',
			198: '#ff0087',
			199: '#ff00af',
			200: '#ff00d7',
			201: '#ff00ff',
			202: '#ff5f00',
			203: '#ff5f5f',
			204: '#ff5f87',
			205: '#ff5faf',
			206: '#ff5fd7',
			207: '#ff5fff',
			208: '#ff8700',
			209: '#ff875f',
			210: '#ff8787',
			211: '#ff87af',
			212: '#ff87d7',
			213: '#ff87ff',
			214: '#ffaf00',
			215: '#ffaf5f',
			216: '#ffaf87',
			217: '#ffafaf',
			218: '#ffafd7',
			219: '#ffafff',
			220: '#ffd700',
			221: '#ffd75f',
			222: '#ffd787',
			223: '#ffd7af',
			224: '#ffd7d7',
			225: '#ffd7ff',
			226: '#ffff00',
			227: '#ffff5f',
			228: '#ffff87',
			229: '#ffffaf',
			230: '#ffffd7',
			231: '#ffffff',
			232: '#080808',
			233: '#121212',
			234: '#1c1c1c',
			235: '#262626',
			236: '#303030',
			237: '#3a3a3a',
			238: '#444444',
			239: '#4e4e4e',
			240: '#585858',
			241: '#626262',
			242: '#6c6c6c',
			243: '#767676',
			244: '#808080',
			245: '#8a8a8a',
			246: '#949494',
			247: '#9e9e9e',
			248: '#a8a8a8',
			249: '#b2b2b2',
			250: '#bcbcbc',
			251: '#c6c6c6',
			252: '#d0d0d0',
			253: '#dadada',
			254: '#e4e4e4',
			255: '#eeeeee'
		};
		let open = 0;
		function replacer(match, p1) {
			if (p1 == '0') {
				let res = '</font>'.repeat(open);
				open = 0;
				return res;
			} else if (p1.substr(0, 5) == '38;5;') {
				open += 1;
				let values = p1.split(';'),
						color = ansi256[parseInt(values[2])];
				return '<font color=\"' + (color ? color : 'red') + '\">';
			}
			return '';
		}
		str = str.replace(/\n/g, "<br>").replace(/\s/g, "&nbsp;");
		str = str.replace(/\u001b\[(.*?)m/g, replacer);
		return str;
	}

	function runCommand() {
		executable.exec(config.command)
	}

	Timer {
		id: timer
		interval: config.interval
		running: true
		repeat: !config.waitForCompletion
		onTriggered: widget.runCommand()
		// onIntervalChanged: console.log('interval', interval)
		// onRunningChanged: console.log('running', running)
		// onRepeatChanged: console.log('repeat', repeat)

		Component.onCompleted: {
			// Run right away in case the interval is very long.
			triggered()
		}
	}

	Plasmoid.onActivated: widget.performClick()

	Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground

	Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
	Plasmoid.fullRepresentation: Item {
		id: panelItem

		readonly property bool isHorizontal: plasmoid.formFactor == PlasmaCore.Types.Horizontal
		readonly property bool isVertical: plasmoid.formFactor == PlasmaCore.Types.Vertical
		readonly property bool isInPanel: isHorizontal || isVertical
		readonly property bool isOnDesktop: !isInPanel

		readonly property int itemWidth: {
			if (isOnDesktop) {
				return Math.ceil(output.contentWidth)
			} else if (isHorizontal && plasmoid.configuration.useFixedWidth) {
				return plasmoid.configuration.fixedWidth * units.devicePixelRatio
			} else { // isHorizontal || isVertical
				return Math.ceil(output.implicitWidth)
			}
		}
		Layout.minimumWidth: isHorizontal ? itemWidth : -1
		Layout.fillWidth: isVertical
		Layout.preferredWidth: itemWidth // Panel widget default
		// width: itemWidth // Desktop widget default
		// onItemWidthChanged: console.log('itemWidth', itemWidth, 'implicitWidth', output.implicitWidth, 'contentWidth', output.contentWidth)

		readonly property int itemHeight: {
			if (isOnDesktop) {
				return Math.ceil(output.contentHeight)
			} else if (isVertical && plasmoid.configuration.useFixedHeight) {
				return plasmoid.configuration.fixedHeight * units.devicePixelRatio
			} else { // isHorizontal || isVertical
				return Math.ceil(output.implicitHeight)
			}
		}
		Layout.minimumHeight: isVertical ? itemHeight : -1
		Layout.fillHeight: isHorizontal
		Layout.preferredHeight: itemHeight // Panel widget default
		// height: itemHeight // Desktop widget default
		// onItemHeightChanged: console.log('itemHeight', itemHeight, 'implicitHeight', output.implicitHeight, 'contentHeight', output.contentHeight)


		// Note MouseArea is below the Text so
		// that we don't eat the link clicks.
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			hoverEnabled: config.clickEnabled

			cursorShape: output.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor

			onClicked: {
				widget.performClick()
			}

			property int wheelDelta: 0
			onWheel: {
				var delta = wheel.angleDelta.y || wheel.angleDelta.x
				wheelDelta += delta
				// Magic number 120 for common "one click"
				// See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
				while (wheelDelta >= 120) {
					wheelDelta -= 120
					widget.performMouseWheelUp()
				}
				while (wheelDelta <= -120) {
					wheelDelta += 120
					widget.performMouseWheelDown()
				}
				wheel.accepted = true
			}
		}

		PlasmaCore.ToolTipArea {
			anchors.fill: parent
			subText: output.text
			enabled: output.truncated
		}

		Text {
			id: output
			width: parent.width
			height: parent.height

			text: widget.outputText
			textFormat: Text.StyledText

			color: config.textColor
			style: config.showOutline ? Text.Outline : Text.Normal
			styleColor: config.outlineColor

			linkColor: theme.linkColor
			onLinkActivated: Qt.openUrlExternally(link)

			font.pointSize: -1
			font.pixelSize: plasmoid.configuration.fontSize * units.devicePixelRatio
			font.family: plasmoid.configuration.fontFamily || theme.defaultFont.family
			font.weight: plasmoid.configuration.bold ? Font.Bold : Font.Normal
			font.italic: plasmoid.configuration.italic
			font.underline: plasmoid.configuration.underline
			fontSizeMode: Text.FixedSize
			horizontalAlignment: plasmoid.configuration.textAlign
			verticalAlignment: Text.AlignTop

			property bool isFixedWidth: {
				if (plasmoid.formFactor == PlasmaCore.Types.Planar) { // Desktop Widget
					return true
				} else if (plasmoid.formFactor == PlasmaCore.Types.Horizontal) {
					return plasmoid.configuration.useFixedWidth
				} else if (plasmoid.formFactor == PlasmaCore.Types.Vertical) {
					return true
				} else {
					return false
				}
			}
			elide: Text.ElideRight
			wrapMode: isFixedWidth ? Text.Wrap : Text.NoWrap
		}

	}

}
