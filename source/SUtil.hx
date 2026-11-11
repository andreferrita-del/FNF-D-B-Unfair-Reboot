
package;

#if android
import android.os.Build.VERSION;
import android.os.Environment;
import openfl.utils.Assets as OpenFlAssets;
#end

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
	 * Android initialization without permission requests.
	 */
	public static function check():Void
	{
		#if android
		var sdkVersion:Int = android.os.BuildVersion.SDK_INT;

		// Keep Android OS integration available.
		if (sdkVersion >= 23)
		{
			var path:String = getPath();

			if (!FileSystem.exists(path))
			{
				try
				{
					FileSystem.createDirectory(path);
				}
				catch (e:Dynamic)
				{
					trace('Could not create game directory: ' + e);
				}
			}
		}
		#end
	}

	/**
	 * Returns the game's external storage directory.
	 */
	public static function getPath():String
	{
		#if android
		return Environment.getExternalStorageDirectory()
			+ '/.'
			+ Application.current.meta.get('file')
			+ '/';
		#else
		return '';
		#end
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

				#if android
				try
				{
					var crashPath:String = getPath() + 'crash/';

					if (!FileSystem.exists(crashPath))
						FileSystem.createDirectory(crashPath);

					File.saveContent(
						crashPath
						+ Application.current.meta.get('file')
						+ '_'
						+ FlxStringUtil.formatTime(Sys.time(), true)
						+ '.log',
						errMsg + '\n'
					);
				}
				catch (e:Dynamic)
				{
					SUtil.applicationAlert(
						'Error!',
						"Couldn't save crash dump: " + e
					);
				}
				#end

				System.exit(1);
			}
		);
	}

	static function applicationAlert(title:String, description:String):Void
	{
		Application.current.window.alert(description, title);
	}

	#if android

	/**
	 * Save text content.
	 */
	public static function saveContent(
		fileName:String = 'file',
		fileExtension:String = '.json',
		fileData:String = 'you forgot to add something in your code'
	):Void
	{
		try
		{
			var saveDirectory:String = getPath() + 'saves/';

			if (!FileSystem.exists(saveDirectory))
				FileSystem.createDirectory(saveDirectory);

			File.saveContent(
				saveDirectory + fileName + fileExtension,
				fileData
			);

			applicationAlert('Done!', 'File Saved Successfully!');
		}
		catch (e:Dynamic)
		{
			applicationAlert(
				'Error!',
				"Couldn't save the file: " + e
			);
		}
	}

	/**
	 * Copy an asset to external storage.
	 */
	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try
		{
			if (!FileSystem.exists(savePath))
			{
				File.saveBytes(
					savePath,
					OpenFlAssets.getBytes(copyPath)
				);
			}
		}
		catch (e:Dynamic)
		{
			applicationAlert(
				'Error!',
				"Couldn't copy the file: " + e
			);
		}
	}

	#end
}
