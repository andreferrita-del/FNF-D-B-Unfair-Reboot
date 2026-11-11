
package meta.state.menus;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import gameObjects.userInterface.HealthIcon;
import lime.utils.Assets;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Song.SwagSong;
import meta.data.dependency.Discord;
import meta.data.font.Alphabet;
import openfl.media.Sound;
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curSongPlaying:Int = -1;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var songThread:Thread;
	var threadActive:Bool = true;
	var mutex:Mutex;
	var songToPlay:Sound = null;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	private var mainColor = FlxColor.WHITE;
	private var bg:FlxSprite;
	private var scoreBG:FlxSprite;

	private var existingSongs:Array<String> = [];
	private var existingDifficulties:Array<Array<String>> = [];

	override function create()
	{
		super.create();

		mutex = new Mutex();

		// Load songs
		var folderSongs:Array<String> = CoolUtil.returnAssetsLibrary('songs');

		for (i in 0...Main.gameWeeks.length)
		{
			var weekSongs:Array<String> = cast Main.gameWeeks[i][0];

			addWeek(
				weekSongs,
				i,
				Main.gameWeeks[i][1],
				Main.gameWeeks[i][2]
			);

			for (j in weekSongs)
				existingSongs.push(j.toLowerCase());
		}

		#if !android
		for (i in folderSongs)
		{
			if (!existingSongs.contains(i.toLowerCase()))
			{
				var icon:String = 'gf';
				var chartExists:Bool = FileSystem.exists(Paths.songJson(i, i));

				if (chartExists)
				{
					var castSong:SwagSong = Song.loadFromJson(i, i);

					icon = (castSong != null) ? castSong.player2 : 'gf';

					if (castSong != null)
						addSong(
							CoolUtil.spaceToDash(castSong.song),
							1,
							icon,
							FlxColor.WHITE
						);
				}
			}
		}
		#end

		// Discord
		#if (DISCORD_RPC && !android)
		Discord.changePresence('FREEPLAY MENU', 'Main Menu');
		#end

		// Background
		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(
				0,
				(70 * i) + 30,
				songs[i].songName,
				true,
				false
			);

			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(
			scoreText.x - scoreText.width,
			0
		).makeGraphic(
			Std.int(FlxG.width * 0.35),
			66,
			0xFF000000
		);

		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(
			scoreText.x,
			scoreText.y + 36,
			0,
			"",
			24
		);

		diffText.alignment = CENTER;
		diffText.font = scoreText.font;
		diffText.x = scoreBG.getGraphicMidpoint().x;
		add(diffText);

		add(scoreText);

		if (songs.length > 0)
		{
			changeSelection();
			changeDiff();
		}

		selector = new FlxText();
		selector.size = 40;
		selector.text = ">";

		#if android
		addVirtualPad(LEFT_FULL, A_B);
		#end
	}

	public function addSong(
		songName:String,
		weekNum:Int,
		songCharacter:String,
		songColor:FlxColor
	)
	{
		var coolDifficultyArray:Array<String> = [];

		for (i in CoolUtil.difficultyArray)
		{
			if (
				FileSystem.exists(Paths.songJson(songName, songName + '-' + i))
				|| (
					FileSystem.exists(Paths.songJson(songName, songName))
					&& i == "NORMAL"
				)
			)
			{
				coolDifficultyArray.push(i);
			}
		}

		if (coolDifficultyArray.length > 0)
		{
			songs.push(
				new SongMetadata(
					songName,
					weekNum,
					songCharacter,
					songColor
				)
			);

			existingDifficulties.push(coolDifficultyArray);
		}
	}

	public function addWeek(
		songs:Array<String>,
		weekNum:Int,
		?songCharacters:Array<String>,
		?songColor:Array<FlxColor>
	)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		if (songColor == null)
			songColor = [FlxColor.WHITE];

		var num:Array<Int> = [0, 0];

		for (song in songs)
		{
			var character:String = songCharacters[
				(songCharacters.length == 1) ? 0 : num[0]
			];

			var color:FlxColor = songColor[
				(songColor.length == 1) ? 0 : num[1]
			];

			addSong(song, weekNum, character, color);

			if (songCharacters.length != 1)
				num[0]++;

			if (songColor.length != 1)
				num[1]++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (bg != null)
			FlxTween.color(bg, 0.35, bg.color, mainColor);

		var lerpVal = Main.framerateAdjust(0.1);

		lerpScore = Math.floor(
			FlxMath.lerp(lerpScore, intendedScore, lerpVal)
		);

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (songs.length == 0)
			return;

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
			changeSelection(-1);
		else if (downP)
			changeSelection(1);

		if (controls.UI_LEFT_P)
			changeDiff(-1);

		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			threadActive = false;
			Main.switchState(this, new MainMenuState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(
				songs[curSelected].songName.toLowerCase(),
				CoolUtil.difficultyArray.indexOf(
					existingDifficulties[curSelected][curDifficulty]
				)
			);

			PlayState.SONG = Song.loadFromJson(
				poop,
				songs[curSelected].songName.toLowerCase()
			);

			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;

			trace('CUR WEEK' + PlayState.storyWeek);

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			threadActive = false;

			Main.switchState(this, new PlayState());
		}

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreText.x = FlxG.width - scoreText.width - 5;

		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;

		diffText.x = scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2);

		mutex.acquire();

		if (songToPlay != null)
		{
			FlxG.sound.playMusic(songToPlay);

			if (FlxG.sound.music.fadeTween != null)
				FlxG.sound.music.fadeTween.cancel();

			FlxG.sound.music.volume = 0.0;
			FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);

			songToPlay = null;
		}

		mutex.release();
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0)
	{
		if (songs.length == 0)
			return;

		if (existingDifficulties[curSelected] == null
			|| existingDifficulties[curSelected].length == 0)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = existingDifficulties[curSelected].length - 1;

		if (curDifficulty >= existingDifficulties[curSelected].length)
			curDifficulty = 0;

		if (lastDifficulty != null && change != 0)
		{
			var attempts:Int = 0;

			while (
				existingDifficulties[curSelected][curDifficulty] == lastDifficulty
				&& attempts < existingDifficulties[curSelected].length
			)
			{
				curDifficulty += change;

				if (curDifficulty < 0)
					curDifficulty = existingDifficulties[curSelected].length - 1;

				if (curDifficulty >= existingDifficulties[curSelected].length)
					curDifficulty = 0;

				attempts++;
			}
		}

		intendedScore = Highscore.getScore(
			songs[curSelected].songName,
			curDifficulty
		);

		diffText.text = '< ' +
			existingDifficulties[curSelected][curDifficulty] +
			' >';

		lastDifficulty = existingDifficulties[curSelected][curDifficulty];
	}

	function changeSelection(change:Int = 0)
	{
		if (songs.length == 0)
			return;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;

		if (curSelected >= songs.length)
			curSelected = 0;

		intendedScore = Highscore.getScore(
			songs[curSelected].songName,
			curDifficulty
		);

		mainColor = songs[curSelected].songColor;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		if (curSelected < iconArray.length)
			iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		trace("curSelected: " + curSelected);

		changeDiff();
		changeSongPlaying();
	}

	function changeSongPlaying()
	{
		#if !android
		if (songThread == null)
		{
			songThread = Thread.create(function()
			{
				while (true)
				{
					if (!threadActive)
					{
						trace("Killing thread");
						return;
					}

					var index:Null<Int> = Thread.readMessage(false);

					if (index != null)
					{
						if (index == curSelected && index != curSongPlaying)
						{
							trace("Loading index " + index);

							var inst:Sound = Paths.inst(songs[index].songName);

							if (index == curSelected && threadActive)
							{
								mutex.acquire();
								songToPlay = inst;
								mutex.release();

								curSongPlaying = index;
							}
							else
								trace("Nevermind, skipping " + index);
						}
						else
							trace("Skipping " + index);
					}
				}
			});
		}

		if (songThread != null)
			songThread.sendMessage(curSelected);
		#end
	}
	
	var playingSongs:Array<FlxSound> = [];
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var songColor:FlxColor = FlxColor.WHITE;

	public function new(
		song:String,
		week:Int,
		songCharacter:String,
		songColor:FlxColor
	)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.songColor = songColor;
	}
}
