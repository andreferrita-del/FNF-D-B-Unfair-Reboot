
package meta.data;

import haxe.Json;
import haxe.format.JsonParser;
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

        var songName:String = folder.toLowerCase();
        var chartName:String = jsonInput.toLowerCase();

        var chartPath:String = Paths.songJson(
            songName,
            chartName
        );

        var rawJson:String = Paths.getText(chartPath);

        if (rawJson == null || rawJson.trim().length == 0)
        {
            throw 'Chart não encontrado ou vazio: ' + chartPath;
        }

        rawJson = rawJson.trim();

        // Remove caracteres extras depois do JSON.
        var lastBrace:Int = rawJson.lastIndexOf('}');

        if (lastBrace == -1)
            throw 'JSON inválido: ' + chartPath;

        rawJson = rawJson.substr(0, lastBrace + 1);

        return parseJSONshit(rawJson);
    }

    public static function parseJSONshit(rawJson:String):SwagSong
    {
        var parsed:Dynamic = Json.parse(rawJson);

        if (parsed == null || parsed.song == null)
            throw 'Formato de chart inválido: propriedade song ausente';

        var swagShit:SwagSong = cast parsed.song;

        swagShit.validScore = true;

        return swagShit;
    }
}
