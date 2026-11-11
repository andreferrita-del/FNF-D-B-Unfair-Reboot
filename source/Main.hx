
package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import meta.*;
import meta.data.PlayerSettings;
import meta.data.dependency.Discord;
import meta.data.dependency.FNFTransition;
import meta.data.dependency.FNFUIState;
import openfl.Lib;
import openfl.display.Sprite;

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

        FlxTransitionableState.skipNextTransIn = true;

        var gameCreate:FlxGame = new FlxGame(
            gameWidth,
            gameHeight,
            mainClassState,
            framerate,
            framerate,
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
}
