
package gameObjects.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		updateIcon(char, isPlayer);
	}

	public function updateIcon(char:String = 'bf', isPlayer:Bool = false):Void
	{
		var trimmedCharacter:String = char;

		if (trimmedCharacter.contains('-'))
			trimmedCharacter = trimmedCharacter.substring(0, trimmedCharacter.indexOf('-'));

		// Ordem de tentativa dos ícones.
		var candidates:Array<String> = [];

		candidates.push(char);

		if (trimmedCharacter != char)
			candidates.push(trimmedCharacter);

		candidates.push('bf');
		candidates.push('face');

		var iconGraphic:FlxGraphic = null;
		var selectedIcon:String = '';

		for (candidate in candidates)
		{
			var graphic:FlxGraphic = null;

			try
			{
				graphic = Paths.image('icons/icon-' + candidate);
			}
			catch (e:Dynamic)
			{
				graphic = null;
			}

			if (graphic != null && graphic.width > 0 && graphic.height > 0)
			{
				iconGraphic = graphic;
				selectedIcon = candidate;
				break;
			}
		}

		// Se nenhum arquivo existir, cria um ícone simples de emergência.
		if (iconGraphic == null)
		{
			trace('HealthIcon: nenhum ícone encontrado para ' + char);

			makeGraphic(150, 150, 0xFF777777);
			initialWidth = width;
			initialHeight = height;

			scrollFactor.set();
			return;
		}

		trace('HealthIcon: carregado icon-' + selectedIcon);

		antialiasing = true;

		loadGraphic(
			iconGraphic,
			true,
			Std.int(iconGraphic.width / 2),
			iconGraphic.height
		);

		initialWidth = width;
		initialHeight = height;

		animation.add('icon', [0, 1], 0, false, isPlayer);
		animation.play('icon');

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(
				sprTracker.x + sprTracker.width + 10,
				sprTracker.y - 30
			);
	}
}
