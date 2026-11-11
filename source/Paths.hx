
package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import meta.CoolUtil;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Paths
{
    inline public static var SOUND_EXT = "ogg";

    static var currentLevel:String;

    public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
    public static var currentTrackedTextures:Map<String, Texture> = [];
    public static var currentTrackedSounds:Map<String, Sound> = [];

    public static var dumpExclusions:Array<String> = [
        'assets/music/freakyMenu.$SOUND_EXT',
        'assets/music/foreverMenu.$SOUND_EXT',
        'assets/music/breakfast.$SOUND_EXT'
    ];

    public static var localTrackedAssets:Array<String> = [];

    // CAMINHOS DE ASSETS

    static function normalize(path:String):String
    {
        return path.replace('\\', '/');
    }

    static function assetExists(path:String, type:AssetType):Bool
    {
        path = normalize(path);

        if (OpenFlAssets.exists(path, type))
            return true;

        if (path.startsWith('assets/'))
        {
            var relativePath = path.substr(7);

            if (OpenFlAssets.exists(relativePath, type))
                return true;
        }

        return false;
    }

    static function getAssetPath(path:String, type:AssetType):String
    {
        path = normalize(path);

        if (OpenFlAssets.exists(path, type))
            return path;

        if (path.startsWith('assets/'))
        {
            var relativePath = path.substr(7);

            if (OpenFlAssets.exists(relativePath, type))
                return relativePath;
        }

        return path;
    }

    public static function setCurrentLevel(name:String):Void
    {
        currentLevel = name.toLowerCase();
    }

    public static function excludeAsset(key:String):Void
    {
        if (!dumpExclusions.contains(key))
            dumpExclusions.push(key);
    }

    // MEMÓRIA

    public static function clearUnusedMemory():Void
    {
        var counter:Int = 0;
        var keys:Array<String> = [];

        for (key in currentTrackedAssets.keys())
            keys.push(key);

        for (key in keys)
        {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
            {
                var obj = currentTrackedAssets.get(key);

                if (obj != null)
                {
                    if (currentTrackedTextures.exists(key))
                    {
                        var texture = currentTrackedTextures.get(key);

                        if (texture != null)
                            texture.dispose();

                        currentTrackedTextures.remove(key);
                    }

                    @:privateAccess
                    if (OpenFlAssets.cache.hasBitmapData(key))
                    {
                        OpenFlAssets.cache.removeBitmapData(key);
                        FlxG.bitmap._cache.remove(key);
                    }

                    obj.destroy();
                    currentTrackedAssets.remove(key);
                    counter++;
                }
            }
        }

        trace('removed $counter assets');
        System.gc();
    }

    public static function clearStoredMemory(?cleanUnused:Bool = false):Void
    {
        var bitmapKeys:Array<String> = [];

        @:privateAccess
        for (key in FlxG.bitmap._cache.keys())
            bitmapKeys.push(key);

        @:privateAccess
        for (key in bitmapKeys)
        {
            var obj = FlxG.bitmap._cache.get(key);

            if (obj != null && !currentTrackedAssets.exists(key))
            {
                OpenFlAssets.cache.removeBitmapData(key);
                FlxG.bitmap._cache.remove(key);
                obj.destroy();
            }
        }

        var soundKeys:Array<String> = [];

        for (key in currentTrackedSounds.keys())
            soundKeys.push(key);

        for (key in soundKeys)
        {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
                currentTrackedSounds.remove(key);
        }

        localTrackedAssets = [];
    }

    // GRÁFICOS

    public static function returnGraphic(
        key:String,
        ?library:String,
        ?textureCompression:Bool = false
    ):FlxGraphic
    {
        var path:String = getPath('images/$key.png', IMAGE, library);
        var cacheKey:String = normalize(path);

        if (currentTrackedAssets.exists(cacheKey))
        {
            localTrackedAssets.push(cacheKey);
            return currentTrackedAssets.get(cacheKey);
        }

        var bitmap:BitmapData = null;

        try
        {
            if (FileSystem.exists(path))
            {
                bitmap = BitmapData.fromFile(path);
            }
            else if (assetExists(path, IMAGE))
            {
                bitmap = OpenFlAssets.getBitmapData(
                    getAssetPath(path, IMAGE)
                );
            }
        }
        catch (e:Dynamic)
        {
            trace('Erro carregando imagem $path: $e');
            return null;
        }

        if (bitmap == null)
        {
            trace('Imagem não encontrada: $path');
            return null;
        }

        var newGraphic:FlxGraphic = null;

        try
        {
            if (
                textureCompression &&
                FlxG.stage != null &&
                FlxG.stage.context3D != null
            )
            {
                var texture = FlxG.stage.context3D.createTexture(
                    bitmap.width,
                    bitmap.height,
                    BGRA,
                    true,
                    0
                );

                texture.uploadFromBitmapData(bitmap);

                currentTrackedTextures.set(cacheKey, texture);

                var textureBitmap = BitmapData.fromTexture(texture);

                newGraphic = FlxGraphic.fromBitmapData(
                    textureBitmap,
                    false,
                    cacheKey,
                    false
                );
            }
            else
            {
                newGraphic = FlxGraphic.fromBitmapData(
                    bitmap,
                    false,
                    cacheKey,
                    false
                );
            }

            currentTrackedAssets.set(cacheKey, newGraphic);
            localTrackedAssets.push(cacheKey);

            return newGraphic;
        }
        catch (e:Dynamic)
        {
            trace('Erro criando gráfico $path: $e');

            if (bitmap != null)
                bitmap.dispose();

            return null;
        }
    }

    // SONS

    public static function returnSound(
        path:String,
        key:String,
        ?library:String
    ):Sound
    {
        var gottenPath:String = getPath(
            '$path/$key.$SOUND_EXT',
            SOUND,
            library
        );

        var cacheKey:String = normalize(gottenPath);

        if (currentTrackedSounds.exists(cacheKey))
        {
            localTrackedAssets.push(cacheKey);
            return currentTrackedSounds.get(cacheKey);
        }

        var sound:Sound = null;

        try
        {
            if (FileSystem.exists(gottenPath))
            {
                sound = Sound.fromFile(gottenPath);
            }
            else if (assetExists(gottenPath, SOUND))
            {
                sound = OpenFlAssets.getSound(
                    getAssetPath(gottenPath, SOUND)
                );
            }
        }
        catch (e:Dynamic)
        {
            trace('Erro carregando som $gottenPath: $e');
            return null;
        }

        if (sound == null)
        {
            trace('Som não encontrado: $gottenPath');
            return null;
        }

        currentTrackedSounds.set(cacheKey, sound);
        localTrackedAssets.push(cacheKey);

        return sound;
    }

    // CAMINHOS

    public static function getPath(
        file:String,
        type:AssetType,
        ?library:Null<String>
    ):String
    {
        if (library != null)
            return getLibraryPath(file, library);

        var levelPath:String = getLibraryPathForce(file, 'mods');

        if (assetExists(levelPath, type))
            return levelPath;

        if (FileSystem.exists(levelPath))
            return levelPath;

        return getPreloadPath(file);
    }

    public static function getLibraryPath(
        file:String,
        library:String = 'preload'
    ):String
    {
        if (library == 'preload' || library == 'default')
            return getPreloadPath(file);

        return getLibraryPathForce(file, library);
    }

    static function getLibraryPathForce(
        file:String,
        library:String
    ):String
    {
        return '$library/$file';
    }

    static function getPreloadPath(file:String):String
    {
        var returnPath:String = 'assets/$file';

        if (!FileSystem.exists(returnPath))
            returnPath = CoolUtil.swapSpaceDash(returnPath);

        return returnPath;
    }

    // ARQUIVOS

    public static function file(
        file:String,
        type:AssetType = TEXT,
        ?library:String
    ):String
    {
        return getPath(file, type, library);
    }

    public static function txt(key:String, ?library:String):String
    {
        return getPath('$key.txt', TEXT, library);
    }

    public static function xml(key:String, ?library:String):String
    {
        return getPath('data/$key.xml', TEXT, library);
    }

    public static function offsetTxt(key:String, ?library:String):String
    {
        return getPath('images/characters/$key.txt', TEXT, library);
    }

    public static function json(key:String, ?library:String):String
    {
        return getPath('songs/$key.json', TEXT, library);
    }

    public static function songJson(
        song:String,
        secondSong:String,
        ?library:String
    ):String
    {
        return getPath(
            'songs/${song.toLowerCase()}/${secondSong.toLowerCase()}.json',
            TEXT,
            library
        );
    }

    // TEXTO

    public static function getText(
        path:String,
        ?library:String
    ):String
    {
        var resolvedPath:String = path;

        if (library != null)
            resolvedPath = getLibraryPath(path, library);

        try
        {
            if (FileSystem.exists(resolvedPath))
                return File.getContent(resolvedPath);

            if (assetExists(resolvedPath, TEXT))
            {
                return OpenFlAssets.getText(
                    getAssetPath(resolvedPath, TEXT)
                );
            }
        }
        catch (e:Dynamic)
        {
            trace('Erro lendo texto $resolvedPath: $e');
        }

        trace('Texto não encontrado: $resolvedPath');
        return '';
    }

    // SONS E MÚSICAS

    public static function sound(key:String, ?library:String):Dynamic
    {
        return returnSound('sounds', key, library);
    }

    public static function soundRandom(
        key:String,
        min:Int,
        max:Int,
        ?library:String
    ):Dynamic
    {
        return sound(key + FlxG.random.int(min, max), library);
    }

    public static function music(key:String, ?library:String):Dynamic
    {
        return returnSound('music', key, library);
    }

    public static function voices(song:String):Any
    {
        var songKey:String =
            '${CoolUtil.swapSpaceDash(song.toLowerCase())}/Voices';

        return returnSound('songs', songKey);
    }

    public static function inst(song:String):Any
    {
        var songKey:String =
            '${CoolUtil.swapSpaceDash(song.toLowerCase())}/Inst';

        return returnSound('songs', songKey);
    }

    // IMAGENS

    public static function image(
        key:String,
        ?library:String,
        ?textureCompression:Bool = false
    ):FlxGraphic
    {
        return returnGraphic(key, library, textureCompression);
    }

    public static function font(key:String):String
    {
        return 'assets/fonts/$key';
    }

    // SPARROW ATLAS

    public static function getSparrowAtlas(
        key:String,
        ?library:String
    ):FlxAtlasFrames
    {
        var graphic:FlxGraphic = returnGraphic(key, library);

        if (graphic == null)
        {
            trace('Atlas sem imagem: $key');
            return null;
        }

        var xmlPath:String = getPath(
            'images/$key.xml',
            TEXT,
            library
        );

        var xmlData:String = getText(xmlPath);

        if (xmlData == null || xmlData.length == 0)
        {
            trace('Atlas sem XML: $xmlPath');
            return null;
        }

        try
        {
            return FlxAtlasFrames.fromSparrow(graphic, xmlData);
        }
        catch (e:Dynamic)
        {
            trace('Erro processando Sparrow $key: $e');
            return null;
        }
    }

    // PACKER ATLAS

    public static function getPackerAtlas(
        key:String,
        ?library:String
    ):FlxAtlasFrames
    {
        var graphic:FlxGraphic = returnGraphic(key, library);

        if (graphic == null)
        {
            trace('Packer sem imagem: $key');
            return null;
        }

        var txtPath:String = getPath(
            'images/$key.txt',
            TEXT,
            library
        );

        var txtData:String = getText(txtPath);

        if (txtData == null || txtData.length == 0)
        {
            trace('Packer sem TXT: $txtPath');
            return null;
        }

        try
        {
            return FlxAtlasFrames.fromSpriteSheetPacker(
                graphic,
                txtData
            );
        }
        catch (e:Dynamic)
        {
            trace('Erro processando Packer $key: $e');
            return null;
        }
    }
}
