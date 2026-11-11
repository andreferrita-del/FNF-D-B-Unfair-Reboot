
package;

import flash.system.System;
import flixel.FlxG;
import flixel.util.FlxStringUtil;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import sys.FileSystem;
import sys.io.File;

class SUtil
{
	/**
	 * Compatibility check.
	 * No external Android permissions required.
	 */
	public static function check():Void
	{
		// No permission request required.
	}

	/**
	 * External storage path.
	 * Empty by default to avoid legacy external storage access.
	 */
	public static function getPath():String
	{
		return '';
	}

	/**
	 * Uncaught error handler.
	 */
	public static function uncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR,
			function(u:UncaughtErrorEvent)
			{
				var callStack:Array<StackItem> = CallStack.exceptionStack(true);
				var errMsg:String = '';

				for (stackItem in callStack)
				{
					switch (stackItem)
					{
						case FilePos(s, file, line, column):
							errMsg += file + ' (line ' + line + ')\n';

						default:
							Sys.println(stackItem);
					}
				}

				errMsg += u.error;

				Sys.println(errMsg);
				SUtil.applicationAlert('Error!', errMsg);

				System.exit(1);
			}
		);
	}

	static function applicationAlert(title:String, description:String):Void
	{
		Application.current.window.alert(description, title);
	}
}
