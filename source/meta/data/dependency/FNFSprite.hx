
package meta.data.dependency;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;

class FNFSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
	}

	public function playAnim(
		AnimName:String,
		Force:Bool = false,
		Reversed:Bool = false,
		Frame:Int = 0
	):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
		{
			offset.set(0, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets[name] = [x, y];
	}

	override public function loadGraphic(
		Graphic:FlxGraphicAsset,
		Animated:Bool = false,
		Width:Int = 0,
		Height:Int = 0,
		Unique:Bool = false,
		?Key:String
	):FNFSprite
	{
		var graph:FlxGraphic = FlxG.bitmap.add(Graphic, Unique, Key);

		if (graph == null)
			return this;

		if (Width == 0)
		{
			Width = Animated ? graph.height : graph.width;
			Width = (Width > graph.width) ? graph.width : Width;
		}

		if (Height == 0)
		{
			Height = Animated ? Width : graph.height;
			Height = (Height > graph.height) ? graph.height : Height;
		}

		if (Animated)
		{
			frames = FlxTileFrames.fromGraphic(
				graph,
				FlxPoint.get(Width, Height)
			);
		}
		else
		{
			frames = graph.imageFrame;
		}

		return this;
	}

	override public function destroy():Void
	{
		// O gerenciamento do FlxGraphic fica sob responsabilidade
		// do sistema de cache do HaxeFlixel.
		super.destroy();

		animOffsets = null;
	}
}
