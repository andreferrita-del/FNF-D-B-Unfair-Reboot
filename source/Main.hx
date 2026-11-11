
package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import meta.*;
import meta.data.PlayerSettings;
import meta.data.dependency.Discord;
import meta.data.dependency.FNFTransition;
import meta.data.dependency.FNFUIState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

class Main extends Sprite
{
	public static var gameWidth:Int = 1280;
	public static var gameHeight:Int = 720;

	public static var mainClassState:Class<FlxState> = Init;
	public static var framerate:Int = 120;

	public static var gameVersion:String = '0.3.1';

	var zoom:Float = -1;
	var skipSplash:Bool = true;
	var infoCounter:Overlay;

	public static var gameWeeks:Array<Dynamic> = [
		[['Tutorial'], ['gf'], [FlxColor.fromRGB(129, 100, 223)], 'Funky Beginnings'],
		[
			['Bopeebo', 'Fresh', 'Dadbattle'],
			['dad', 'dad', 'dad'],
			[FlxColor.fromRGB(129, 100, 223)],
			'vs. DADDY DEAREST'
		],
		[
			['Spookeez', 'South', 'Monster'],
			['spooky', 'spooky', 'monster'],
			[FlxColor.fromRGB(30, 45, 60)],
			'Spooky Month'
		],
		[
			['Pico', 'Philly-Nice', 'Blammed'],
			['pico'],
			[FlxColor.fromRGB(111, 19, 60)],
			'vs. Pico'
		],
		[
			['Satin-Panties', 'High', 'Milf'],
			['mom'],
			[FlxColor.fromRGB(203, 113, 170)],
			'MOMMY MUST MURDER'
		],
		[
			['Cocoa', 'Eggnog', 'Winter-Horrorland'],
			['parents-christmas', 'parents-christmas', 'monster-christmas'],
			[FlxColor.fromRGB(141, 165, 206)],
			'RED SNOW'
		],
		[
			['Senpai', 'Roses', 'Thorns'],
			['senpai', 'senpai', 'spirit'],
			[FlxColor.fromRGB(206, 106, 169)],
			'hating simulator ft. moawling'
		],
	];

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR,
			onCrash
		);

		#if (html5 || neko)
		framerate = 60;
		#end

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;

			zoom = Math.min(ratioX, ratioY);

			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		SUtil.check();

		FlxTransitionableState.skipNextTransIn = true;

		var gameCreate:FlxGame;

		gameCreate = new FlxGame(
			gameWidth,
			gameHeight,
			mainClassState,
			Std.int(framerate),
			Std.int(framerate),
			skipSplash
		);

		addChild(gameCreate);

		#if DISCORD_RPC
		Discord.initializeRPC();
		Discord.changePresence('');
		#end

		PlayerSettings.init();

		infoCounter = new Overlay(0, 0);
		addChild(infoCounter);
	}

	public static function framerateAdjust(input:Float):Float
	{
		return input * (60 / FlxG.drawFramerate);
	}

	public static var lastState:FlxState;

	public static function switchState(curState:FlxState, target:FlxState):Void
	{
		mainClassState = Type.getClass(target);

		if (!FlxTransitionableState.skipNextTransIn)
		{
			curState.openSubState(new FNFTransition(0.35, false));

			FNFTransition.finishCallback = function()
			{
				FlxG.switchState(target);
			};

			trace('changed state');
			return;
		}

		FlxTransitionableState.skipNextTransIn = false;

		FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int):Void
	{
		if (newFramerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else
		{
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;

		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = Paths.getPath() + "crash/" + "FE_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";

				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error
			+ "\nPlease report this error to the GitHub page: https://github.com/Yoshubs/Forever-Engine";

		/*if (!FileSystem.exists(SUtil.getPath() + "crash/"))
		{
			FileSystem.createDirectory(SUtil.getPath() + "crash/");
		}*/

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var crashDialoguePath:String = SUtil.getPath() + "FE-CrashDialog";

		#if windows
		crashDialoguePath += ".exe";
		#end

		if (FileSystem.exists(crashDialoguePath))
		{
			Sys.println("Found crash dialog: " + crashDialoguePath);
			new Process(crashDialoguePath, [path]);
		}
		else
		{
			Sys.println("No crash dialog found! Making a simple alert instead...");
			Application.current.window.alert(errMsg, "Error!");
		}

		Sys.exit(1);
	}
}
