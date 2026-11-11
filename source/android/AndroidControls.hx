
package android;

import android.flixel.FlxHitbox;
import android.flixel.FlxVirtualPad;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;

using StringTools;

class AndroidControls extends FlxSpriteGroup
{
    public var virtualPad:FlxVirtualPad;
    public var hitbox:FlxHitbox;

    public function new()
    {
        super();

        var mode:Int = getMode();

        // Protege contra valores inválidos salvos nas configurações.
        if (mode < 0 || mode > 5)
            mode = 0;

        initControler(mode);
    }

    private function initControler(mode:Int = 0):Void
    {
        switch (mode)
        {
            case 0: // RIGHT_FULL
                virtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
                add(virtualPad);

            case 1: // LEFT_FULL
                virtualPad = new FlxVirtualPad(LEFT_FULL, NONE);
                add(virtualPad);

            case 2: // CUSTOM
                virtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
                virtualPad = getCustom(virtualPad);
                add(virtualPad);

            case 3: // BOTH_FULL
                virtualPad = new FlxVirtualPad(BOTH_FULL, NONE);
                add(virtualPad);

            case 4: // HITBOX
                hitbox = new FlxHitbox();
                add(hitbox);

            case 5: // KEYBOARD
                // Nenhum controle virtual é criado.
        }
    }

    override public function destroy():Void
    {
        // O grupo é responsável por destruir seus membros.
        super.destroy();

        virtualPad = null;
        hitbox = null;
    }

    public static function setMode(mode:Int = 0):Void
    {
        if (mode < 0 || mode > 5)
            mode = 0;

        if (FlxG.save == null || FlxG.save.data == null)
            return;

        FlxG.save.data.buttonsmode = mode;
        FlxG.save.flush();
    }

    public static function getMode():Int
    {
        if (FlxG.save == null || FlxG.save.data == null)
            return 0;

        var mode:Dynamic = FlxG.save.data.buttonsmode;

        if (mode == null)
            return 0;

        var result:Int = Std.int(mode);

        if (result < 0 || result > 5)
            return 0;

        return result;
    }

    public static function setCustom(virtualPad:FlxVirtualPad):Void
    {
        if (virtualPad == null)
            return;

        if (FlxG.save == null || FlxG.save.data == null)
            return;

        if (FlxG.save.data.buttons == null)
            FlxG.save.data.buttons = [];

        var saved:Array<Dynamic> = [];

        for (button in virtualPad)
        {
            if (button != null)
            {
                saved.push({
                    x: button.x,
                    y: button.y
                });
            }
        }

        FlxG.save.data.buttons = saved;
        FlxG.save.flush();
    }

    public static function getCustom(virtualPad:FlxVirtualPad):FlxVirtualPad
    {
        if (virtualPad == null)
            return null;

        if (FlxG.save == null || FlxG.save.data == null)
            return virtualPad;

        var saved:Array<Dynamic> = FlxG.save.data.buttons;

        if (saved == null)
            return virtualPad;

        var index:Int = 0;

        for (button in virtualPad)
        {
            if (button == null)
            {
                index++;
                continue;
            }

            if (index >= saved.length)
                break;

            var position:Dynamic = saved[index];

            if (position != null)
            {
                if (Reflect.hasField(position, "x"))
                    button.x = position.x;

                if (Reflect.hasField(position, "y"))
                    button.y = position.y;
            }

            index++;
        }

        return virtualPad;
    }
}
