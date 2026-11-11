package;

#if android
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
	public static function check():Void
	{
		#if android
		var path:String = getPath();

		if (!FileSystem.exists(path))
		{
			try
			{
				FileSystem.createDirectory(path);
			}
			catch (e:Dynamic)
			{
				trace('Storage directory error: ' + e);
			}
		}
		#end
	}

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
						crashPath + Application.current.meta.get('file')
						+ '_' + FlxStringUtil.formatTime(Sys.time(), true) + '.log',
						errMsg + '\n'
					);
				}
				catch (e:Dynamic)
				{
					SUtil.applicationAlert('Error!', 'Crash dump error: ' + e);
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
	public static function saveContent(
		fileName:String = 'file',
		fileExtension:String = '.json',
		fileData:String = 'you forgot to add something in your code'
	):Void
	{
		try
		{
			var directory:String = getPath() + 'saves/';

			if (!FileSystem.exists(directory))
				FileSystem.createDirectory(directory);

			File.saveContent(directory + fileName + fileExtension, fileData);

			applicationAlert('Done!', 'File Saved Successfully!');
		}
		catch (e:Dynamic)
		{
			applicationAlert('Error!', 'Save error: ' + e);
		}
	}

	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try
		{
			if (!FileSystem.exists(savePath))
				File.saveBytes(savePath, OpenFlAssets.getBytes(copyPath));
		}
		catch (e:Dynamic)
		{
			applicationAlert('Error!', 'Copy error: ' + e);
		}
	}
	#end
}
