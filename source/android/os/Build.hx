package android.os;

extern class Build
{
	@:native("VERSION")
	static var VERSION:Version;
}

extern class Version
{
	@:native("SDK_INT")
	static var SDK_INT:Int;
}
