package android.os;

class Build
{
	public static var VERSION(default, null):Version;

	static function __init__():Void
	{
		VERSION = new Version();
	}
}

@:native("android.os.Build$VERSION")
extern class Version
{
	public static var SDK_INT(default, null):Int;
}
