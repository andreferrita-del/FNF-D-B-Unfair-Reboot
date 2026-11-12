
package meta.data;

import haxe.Json;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;
import meta.data.Section.SwagSection;

using StringTools;

typedef SwagSong =
{
    var song:String;
    var notes:Array<SwagSection>;
    var bpm:Float;
    var needsVoices:Bool;
    var speed:Float;

    var player1:String;
    var player2:String;
    var stage:String;
    var noteSkin:String;
    var validScore:Bool;
}

class Song
{
    public var song:String;
    public var notes:Array<SwagSection>;
    public var bpm:Float;

    public var needsVoices:Bool = true;
    public var speed:Float = 1;

    public var player1:String = 'bf';
    public var player2:String = 'dad';

    public function new(song, notes, bpm)
    {
        this.song = song;
        this.notes = notes;
        this.bpm = bpm;
    }

    public static function loadFromJson(
        jsonInput:String,
        ?folder:String
    ):SwagSong
    {
        if (folder == null || folder.length == 0)
            folder = jsonInput;

        var songName = folder.toLowerCase();
        var chartName = jsonInput.toLowerCase();

        var chartPath = Paths.songJson(songName, chartName);

        var rawJson:String = null;

        try
        {
            if (FileSystem.exists(chartPath))
            {
                rawJson = File.getContent(chartPath);
            }
            else
            {
                var assetPath = chartPath;

                if (assetPath.startsWith('assets/'))
                    assetPath = assetPath.substr(7);

                if (Assets.exists(assetPath))
                    rawJson = Assets.getText(assetPath);
                else if (Assets.exists(chartPath))
                    rawJson = Assets.getText(chartPath);
            }
        }
        catch (e:Dynamic)
        {
            throw 'Erro ao carregar chart "$chartPath": $e';
        }

        if (rawJson == null || rawJson.trim().length == 0)
            throw 'Chart não encontrado ou vazio: $chartPath';

        return parseJSONshit(rawJson);
    }

    public static function parseJSONshit(rawJson:String):SwagSong
    {
        var parsed:Dynamic;

        try
        {
            parsed = Json.parse(rawJson.trim());
        }
        catch (e:Dynamic)
        {
            throw 'Erro ao interpretar JSON da música: $e';
        }

        if (parsed == null || parsed.song == null)
            throw 'Formato de chart inválido: propriedade song ausente';

        var swagShit:SwagSong = cast parsed.song;

        if (swagShit.notes == null)
            throw 'Chart inválido: propriedade notes ausente';

        if (swagShit.speed <= 0)
            swagShit.speed = 1;

        swagShit.validScore = true;

        return swagShit;
    }
}
