
package meta.state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.dependency.Discord;
import meta.data.font.Alphabet;
import meta.state.menus.*;
import openfl.Assets;
import openfl.display.BitmapData;

using StringTools;

class TitleState extends MusicBeatState
{
    static var initialized:Bool = false;

    var blackScreen:FlxSprite;
    var credGroup:FlxGroup;
    var credTextShit:Alphabet;
    var textGroup:FlxGroup;
    var ngSpr:FlxSprite;

    var curWacky:Array<String> = [];

    var wackyImage:FlxSprite;

    var logoBl:FlxSprite;
    var gfDance:FlxSprite;
    var danceLeft:Bool = false;
    var titleText:FlxSprite;

    var transitioning:Bool = false;
    var skippedIntro:Bool = false;

    override public function create():Void
    {
        controls.setKeyboardScheme(None, false);

        curWacky = FlxG.random.getObject(getIntroTextShit());

        if (curWacky == null || curWacky.length < 2)
            curWacky = ["Forever Engine", "Android Edition"];

        super.create();

        startIntro();
    }

    /**
     * Carrega um atlas Sparrow diretamente dos assets OpenFL.
     * Evita File.getContent(), que não funciona com arquivos
     * XML empacotados dentro do APK.
     */
    function loadSparrowAtlas(name:String):FlxAtlasFrames
    {
        var imagePath:String = 'images/' + name + '.png';
        var xmlPath:String = 'images/' + name + '.xml';

        try
        {
            if (!Assets.exists(imagePath) || !Assets.exists(xmlPath))
            {
                trace('Atlas não encontrado: ' + name);
                return null;
            }

            var bitmap:BitmapData = Assets.getBitmapData(imagePath);
            var xml:String = Assets.getText(xmlPath);

            if (bitmap == null || xml == null || xml.length == 0)
            {
                trace('Atlas inválido: ' + name);
                return null;
            }

            return FlxAtlasFrames.fromSparrow(bitmap, xml);
        }
        catch (e:Dynamic)
        {
            trace('Erro carregando atlas ' + name + ': ' + e);
            return null;
        }
    }

    function startIntro():Void
    {
        if (!initialized)
        {
            #if (DISCORD_RPC && !android)
            Discord.changePresence('TITLE SCREEN', 'Main Menu');
            #end

            ForeverTools.resetMenuMusic(true);
        }

        persistentUpdate = true;

        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(bg);

        // LOGO
        logoBl = new FlxSprite(-150, -100);

        var logoFrames = loadSparrowAtlas('menus/base/title/logoBumpin');

        if (logoFrames != null)
        {
            logoBl.frames = logoFrames;
            logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
            logoBl.animation.play('bump');
        }

        logoBl.antialiasing = true;
        logoBl.updateHitbox();

        // GIRLFRIEND
        gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);

        var gfFrames = loadSparrowAtlas('menus/base/title/gfDanceTitle');

        if (gfFrames != null)
        {
            gfDance.frames = gfFrames;

            gfDance.animation.addByIndices(
                'danceLeft',
                'gfDance',
                [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
                '',
                24,
                false
            );

            gfDance.animation.addByIndices(
                'danceRight',
                'gfDance',
                [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
                '',
                24,
                false
            );

            gfDance.animation.play('danceLeft');
        }

        gfDance.antialiasing = true;
        add(gfDance);
        add(logoBl);

        // TITLE TEXT
        titleText = new FlxSprite(100, FlxG.height * 0.8);

        var titleFrames = loadSparrowAtlas('menus/base/title/titleEnter');

        if (titleFrames != null)
        {
            titleText.frames = titleFrames;

            titleText.animation.addByPrefix(
                'idle',
                'Press Enter to Begin',
                24
            );

            titleText.animation.addByPrefix(
                'press',
                'ENTER PRESSED',
                24
            );

            titleText.animation.play('idle');
        }

        titleText.antialiasing = true;
        titleText.updateHitbox();
        add(titleText);

        // CRÉDITOS
        credGroup = new FlxGroup();
        add(credGroup);

        textGroup = new FlxGroup();

        blackScreen = new FlxSprite();
        blackScreen.makeGraphic(
            FlxG.width,
            FlxG.height,
            FlxColor.BLACK
        );

        credGroup.add(blackScreen);

        credTextShit = new Alphabet(
            0,
            0,
            "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er",
            true
        );

        credTextShit.screenCenter();
        credTextShit.visible = false;

        // NEWGROUNDS
        ngSpr = new FlxSprite(
            0,
            FlxG.height * 0.52
        );

        if (Assets.exists('images/menus/base/title/newgrounds_logo.png'))
        {
            ngSpr.loadGraphic(
                Assets.getBitmapData('images/menus/base/title/newgrounds_logo.png')
            );
        }
        else
        {
            ngSpr.loadGraphic(Paths.image('menus/base/title/newgrounds_logo'));
        }

        add(ngSpr);

        ngSpr.visible = false;
        ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
        ngSpr.updateHitbox();
        ngSpr.screenCenter(X);
        ngSpr.antialiasing = true;

        FlxTween.tween(
            credTextShit,
            {y: credTextShit.y + 20},
            2.9,
            {
                ease: FlxEase.quadInOut,
                type: PINGPONG
            }
        );

        if (initialized)
        {
            skipIntro();
        }
        else
        {
            initialized = true;
        }
    }

    function getIntroTextShit():Array<Array<String>>
    {
        var result:Array<Array<String>> = [];

        var path:String = Paths.txt('introText');

        try
        {
            if (Assets.exists(path))
            {
                var fullText:String = Assets.getText(path);

                for (line in fullText.split('\n'))
                {
                    var cleanLine:String = line.trim();

                    if (cleanLine.length == 0)
                        continue;

                    var parts:Array<String> = cleanLine.split('--');

                    if (parts.length >= 2)
                    {
                        result.push([
                            parts[0].trim(),
                            parts[1].trim()
                        ]);
                    }
                }
            }
        }
        catch (e:Dynamic)
        {
            trace('Erro lendo introText: ' + e);
        }

        if (result.length == 0)
        {
            result.push(['Forever Engine', 'Android Edition']);
        }

        return result;
    }

    override function update(elapsed:Float):Void
    {
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

        #if android
        for (touch in FlxG.touches.list)
        {
            if (touch.justPressed)
            {
                pressedEnter = true;
                break;
            }
        }
        #end

        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        if (gamepad != null)
        {
            if (gamepad.justPressed.START)
                pressedEnter = true;

            #if switch
            if (gamepad.justPressed.B)
                pressedEnter = true;
            #end
        }

        if (pressedEnter && !transitioning && skippedIntro)
        {
            if (titleText.animation.getByName('press') != null)
                titleText.animation.play('press');

            FlxG.camera.flash(FlxColor.WHITE, 1);

            FlxG.sound.play(
                Paths.sound('confirmMenu'),
                0.7
            );

            transitioning = true;

            new FlxTimer().start(2, function(tmr:FlxTimer)
            {
                Main.switchState(this, new MainMenuState());
            });
        }

        if (pressedEnter && !skippedIntro && initialized)
        {
            skipIntro();
        }

        super.update(elapsed);
    }

    function createCoolText(textArray:Array<String>):Void
    {
        for (i in 0...textArray.length)
        {
            var money:Alphabet = new Alphabet(
                0,
                0,
                textArray[i],
                true,
                false
            );

            money.screenCenter(X);
            money.y += (i * 60) + 200;

            credGroup.add(money);
            textGroup.add(money);
        }
    }

    function addMoreText(text:String):Void
    {
        var coolText:Alphabet = new Alphabet(
            0,
            0,
            text,
            true,
            false
        );

        coolText.screenCenter(X);
        coolText.y += (textGroup.length * 60) + 200;

        credGroup.add(coolText);
        textGroup.add(coolText);
    }

    function deleteCoolText():Void
    {
        while (textGroup.members.length > 0)
        {
            var member = textGroup.members[0];

            credGroup.remove(member, true);
            textGroup.remove(member, true);
        }
    }

    override function beatHit():Void
    {
        super.beatHit();

        if (logoBl != null && logoBl.animation.getByName('bump') != null)
            logoBl.animation.play('bump');

        danceLeft = !danceLeft;

        if (gfDance != null)
        {
            if (danceLeft)
            {
                if (gfDance.animation.getByName('danceRight') != null)
                    gfDance.animation.play('danceRight');
            }
            else
            {
                if (gfDance.animation.getByName('danceLeft') != null)
                    gfDance.animation.play('danceLeft');
            }
        }

        FlxG.log.add(curBeat);

        switch (curBeat)
        {
            case 1:
                createCoolText([
                    'ninjamuffin',
                    'phantomArcade',
                    'kawaisprite',
                    'evilsker'
                ]);

            case 3:
                addMoreText('present');

            case 4:
                deleteCoolText();

            case 5:
                createCoolText([
                    'In association',
                    'with'
                ]);

            case 7:
                addMoreText('newgrounds');
                ngSpr.visible = true;

            case 8:
                deleteCoolText();
                ngSpr.visible = false;

            case 9:
                createCoolText([curWacky[0]]);

            case 11:
                addMoreText(curWacky[1]);

            case 12:
                deleteCoolText();

            case 13:
                addMoreText('Friday');

            case 14:
                addMoreText('Night');

            case 15:
                addMoreText('Funkin');

            case 16:
                skipIntro();
        }
    }

    function skipIntro():Void
    {
        if (!skippedIntro)
        {
            if (ngSpr != null)
                remove(ngSpr);

            FlxG.camera.flash(FlxColor.WHITE, 4);

            if (credGroup != null)
                remove(credGroup);

            skippedIntro = true;
        }
    }
}
