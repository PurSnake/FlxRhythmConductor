package rhythm.conductor;

import hxsignal.Signal;

using rhythm.conductor.Util;

#if (!flixel && !heaps)
#error 'There is no supported backend'
#end

private typedef RhythmConductorTargetInner = #if flixel flixel.sound.FlxSound #elseif heaps hxd.snd.Channel #end;
@:forward abstract RhythmConductorTarget(RhythmConductorTargetInner) from RhythmConductorTargetInner to RhythmConductorTargetInner
{
	public var time(get, set):Float;
	@:noCompletion private inline function get_time():Float {
		#if flixel
		return this.time;
		#elseif heaps
		return this.position * 1000;
		#end
	}
	@:noCompletion private inline function set_time(v) {
		#if flixel
		this.time = v;
		#elseif heaps
		this.position = v * 0.001;
		#end
		return v;
	}

	public var length(get, never):Float;
	@:noCompletion private inline function get_length() {
		#if flixel
		return this.length;
		#elseif heaps
		return this.duration * 1000;
		#end
	}

	public var playing(get, never):Bool;
	@:noCompletion private inline function get_playing() {
		#if flixel
		return this.playing;
		#elseif heaps
		return !this.pause && !this.isReleased();
		#end
	}
}

typedef TimeSignal = Signal<(time:Int, backward:Bool)->Void>;
typedef BpmChangeSignal = Signal<(bpm:Float)->Void>;

class RhythmConductor {
	public static var instance(get, never):RhythmConductor;

	public var target(get, set):Null<RhythmConductorTarget>;

	public var timeChanges:Array<MusicTimeChangeEvent> = [];
	public var currentTimeChange(default, null):Null<MusicTimeChangeEvent>;
	public var prevTimeChange(default, null):Null<MusicTimeChangeEvent>;

	public var musicPosition(get, null):Float = 0;
	public var frameMusicPosition(get, null):Float = 0;

	public var musicPositionOffset:Float = Constants.MUSIC_POSITION_OFFSET;

	public var allowInterpolateSignals:Bool = true;

	public var percent(get, set):Float;

	public var musicLength(get, never):Float;

	public var currentBpm(get, never):Float;
	public var startBpm(get, never):Float;

	public var currentMeasure(default, null):Int = 0;
	public var currentMeasureTime(default, null):Float = 0;

	public var currentBeat(default, null):Int = 0;
	public var currentBeatTime(default, null):Float = 0;

	public var currentStep(default, null):Int = 0;
	public var currentStepTime(default, null):Float = 0;

	public static var measureHit(default, null):TimeSignal = new TimeSignal();

	public var onMeasureHit(default, null):TimeSignal = new TimeSignal();

	public static var beatHit(default, null):TimeSignal = new TimeSignal();

	public var onBeatHit(default, null):TimeSignal = new TimeSignal();

	public static var stepHit(default, null):TimeSignal = new TimeSignal();

	public var onStepHit(default, null):TimeSignal = new TimeSignal();

	public static var bpmChange(default, null):BpmChangeSignal = new BpmChangeSignal();

	public var onBpmChange(default, null):BpmChangeSignal = new BpmChangeSignal();

	private static function emitMeasureHit(measure:Int, backward:Bool) {
		measureHit.emit(measure, backward);
	}

	private static function emitBeatHit(beat:Int, backward:Bool) {
		beatHit.emit(beat, backward);
	}

	private static function emitStepHit(step:Int, backward:Bool) {
		stepHit.emit(step, backward);
	}

	private static function emitBpmChange(bpm:Float) {
		bpmChange.emit(bpm);
	}

	static function setupSingleton(input:RhythmConductor) {
		input.onMeasureHit.connect(emitMeasureHit);
		input.onBeatHit.connect(emitBeatHit);
		input.onStepHit.connect(emitStepHit);
		input.onBpmChange.connect(emitBpmChange);
	}

	static function clearSingleton(input:RhythmConductor) {
		input.onMeasureHit.disconnect(emitMeasureHit);
		input.onBeatHit.disconnect(emitBeatHit);
		input.onStepHit.disconnect(emitStepHit);
		input.onBpmChange.disconnect(emitBpmChange);
	}

	var overrideBpm:Null<Float> = null;

	@:noCompletion var prevTime:Float = 0;
	@:noCompletion var _updateTarget:Null<RhythmConductorTarget>;

	static var _instance:Null<RhythmConductor> = null;

	var _target:Null<RhythmConductorTarget> = null;

	public function new() {
		#if (flixel && debug)
		connectWatch();
		#end
	}

	public function connectWatch() {
		#if (flixel && debug)
		flixel.FlxG.watch.add(this, 'musicPosition', 'musicPosition');
		flixel.FlxG.watch.add(this, 'frameMusicPosition', 'frameMusicPosition');
		flixel.FlxG.watch.add(this, 'currentBpm', 'currentBpm');

		flixel.FlxG.watch.add(this, 'currentStepTime', 'currentStepTime');
		flixel.FlxG.watch.add(this, 'currentBeatTime', 'currentBeatTime');
		flixel.FlxG.watch.add(this, 'currentMeasureTime', 'currentMeasureTime');

		flixel.FlxG.watch.add(this, 'currentStep', 'currentStep');
		flixel.FlxG.watch.add(this, 'currentBeat', 'currentBeat');
		flixel.FlxG.watch.add(this, 'currentMeasure', 'currentMeasure');

		flixel.FlxG.watch.add(this, 'timeSignatureNumerator', 'timeSignatureNumerator');
		flixel.FlxG.watch.add(this, 'timeSignatureDenominator', 'timeSignatureDenominator');

		flixel.FlxG.signals.postUpdate.add(quickWatchStuff);
		#end
	}

	public function removeWatch() {
		#if (flixel && debug)
		flixel.FlxG.watch.remove(this, 'musicPosition');
		flixel.FlxG.watch.remove(this, 'frameMusicPosition');
		flixel.FlxG.watch.remove(this, 'currentBpm');

		flixel.FlxG.watch.remove(this, 'currentStepTime');
		flixel.FlxG.watch.remove(this, 'currentBeatTime');
		flixel.FlxG.watch.remove(this, 'currentMeasureTime');

		flixel.FlxG.watch.remove(this, 'currentStep');
		flixel.FlxG.watch.remove(this, 'currentBeat');
		flixel.FlxG.watch.remove(this, 'currentMeasure');

		flixel.FlxG.watch.remove(this, 'timeSignatureNumerator');
		flixel.FlxG.watch.remove(this, 'timeSignatureDenominator');

		flixel.FlxG.signals.postUpdate.remove(quickWatchStuff);
		#end
	}

	public function destroy() {
		timeChanges = null;

		#if (flixel && debug)
		removeWatch();
		#end
	}

	public static function reset() {
		if (RhythmConductor._instance != null)
			RhythmConductor._instance.destroy();

		set_instance(new RhythmConductor());
	}

	public var measureLengthMs(get, never):Float;

	public var beatLengthMs(get, never):Float;

	public var stepLengthMs(get, never):Float;

	public var beatsPerMeasure(get, never):Float;

	public var stepsPerMeasure(get, never):Int;

	public var timeSignatureNumerator(get, never):TimeSignature;

	public var timeSignatureDenominator(get, never):TimeSignature;

	var _elapsed:Float = 0.0;

	public function update(?musicPos:Float) { // TODO: Avoid constantly using iterations
		_updateTarget = target;

		var oldMeasure:Int = this.currentMeasure;
		var oldBeat:Int = this.currentBeat;
		var oldStep:Int = this.currentStep;
		var oldBpm:Float = this.currentBpm;

		var frameMusicPos:Float = frameMusicPosition + Util.getTimeDelta() * Constants.MS_PER_SECS;
		if (_updateTarget == null && musicPos == null) {
			_elapsed = Util.getTimeDelta() * Constants.MS_PER_SECS;
			musicPosition += _elapsed;
			frameMusicPosition += _elapsed;
		} else {
			var prevMusicPosition = musicPosition;
			var musicPosValue:Float = musicPos ?? _updateTarget?.time ?? 0;

			if (_updateTarget != null && !_updateTarget.playing)
				frameMusicPos = frameMusicPosition;

			if (_updateTarget != null && _updateTarget.playing) {
				musicPosition = musicPosValue.clamp(0, musicLength);
				frameMusicPosition = frameMusicPos.clamp(0, musicLength);
			} else {
				musicPosition = musicPosValue;
				frameMusicPosition = frameMusicPos;
			}
			_elapsed = musicPosition - prevMusicPosition;
		}

		currentTimeChange = timeChanges[0];
		prevTimeChange = null;
		if (musicPosition > 0.0) {
			for (i in 0...timeChanges.length) {
				if (this.musicPosition >= timeChanges[i].time) {
					prevTimeChange = currentTimeChange;
					currentTimeChange = timeChanges[i];
				}

				if (this.musicPosition < timeChanges[i].time)
					break;
			}
		}

		if (_updateTarget != null && overrideBpm == null && currentTimeChange == null)
			trace("[WARNING] Unable to obtain timeChange, cancelling musicPos update.");
		else
			/* if (musicPosition > 0.0) */ updateValues();

		if (currentBpm != oldBpm)
			this.onBpmChange.emit(currentBpm);

		emitChange(oldStep, currentStep, this.onStepHit);
		emitChange(oldBeat, currentBeat, this.onBeatHit);
		emitChange(oldMeasure, currentMeasure, this.onMeasureHit);

		// only update the timestamp if musicPosition actually changed
		// which it doesn't do every frame!
		if (musicPosition != prevTime) {
			// Update the timestamp for use in-between frames.
			frameMusicPosition = prevTime = musicPosition;
			// prevTimestamp = lime.system.System.getTimer();
		}
	}

	private function emitChange(oldVal:Int, currentVal:Int, signal:TimeSignal) {
		if (currentVal != oldVal) {
			if (allowInterpolateSignals && Math.abs(currentVal - oldVal) > 1.) {
				if (oldVal < currentVal) {
					var i:Int = oldVal;
					while (i < currentVal) signal.emit(++i, false);
				} else {
					var i:Int = oldVal;
					while (i > currentVal) signal.emit(i--, true);
				}
			} else signal.emit(currentVal, currentVal < oldVal);
		}
	}

	public function getCurrentTimeChangeBPMAccurate(musicPos:Float):Float {
		if (currentTimeChange == null) return Constants.BPM;
		if (prevTimeChange != null && currentTimeChange.duration > 0 && musicPos <= currentTimeChange.endTime) {
			var neededBpm = Util.lerp(prevTimeChange.bpm, currentTimeChange.bpm, currentTimeChange.caltEase(musicPos));
			// trace(currentTimeChange.caltEase(musicPos));
			// if (musicPos + _elapsed >= currentTimeChange.endTime)
			// 	neededBpm = currentTimeChange.bpm;

			return neededBpm;
		}
		return currentTimeChange.bpm;
	}

	public function setupTimeChanges(songTimeChanges:Array<MusicTimeChangeEvent>) {
		if (songTimeChanges.length > 0) {
			timeChanges = songTimeChanges.copy();
			MusicTimeChangeEvent.sortTimeChanges(timeChanges);
		}
		else timeChanges = [];

		update(musicPosition);
	}

	#if (flixel && debug)
	private static function quickWatchStuff() {
		flixel.FlxG.watch.addQuick("ct:time", RhythmConductor.instance.currentTimeChange?.time);
		flixel.FlxG.watch.addQuick("ct:dur", RhythmConductor.instance.currentTimeChange?.duration);
		flixel.FlxG.watch.addQuick("ct:etime", RhythmConductor.instance.currentTimeChange?.endTime);
		// FlxG.watch.addQuick("ct:ease", FlxRhythmConductor.instance.currentTimeChange?.ease);
	}
	#end

	function updateValues() {
		currentStepTime = getCumulativeSteps(musicPosition);
		currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
		currentMeasureTime = getCumulativeMeasures(musicPosition);

		currentStep = Math.floor(currentStepTime);
		currentBeat = Math.floor(currentBeatTime);
		currentMeasure = Math.floor(currentMeasureTime);
	}

	public function getCumulativeSteps(time:Float):Float {
		if (timeChanges.length == 0)
			return (time / stepLengthMs); // FlxMath.roundDecimal((time / stepLengthMs), 4);

		var totalSteps:Float = 0;
		var lastEventEndTime:Float = 0;
		var lastBpm:Float = startBpm;
		var timePassed:Float = 0;

		for (i in 0...timeChanges.length) {
			var event:MusicTimeChangeEvent = timeChanges[i];
			var nextEvent:Null<MusicTimeChangeEvent> = timeChanges[i + 1];
			var eventEndTime = event.time;

			if (lastEventEndTime < event.time && time > lastEventEndTime) {
				var segmentStart = lastEventEndTime;
				var segmentEnd = Math.min(event.time, time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0) {
					totalSteps += segmentDuration * lastBpm.getStepsPerMs();
					timePassed += segmentDuration;
				}
			}

			if (time <= event.time) break;

			if (event.duration > 0) {
				eventEndTime += event.duration;
				var interpStart = Math.max(event.time, lastEventEndTime);
				var interpEnd = Math.min(eventEndTime, time);
				var interpDuration = interpEnd - interpStart;

				if (interpDuration > 0) {
					var prevBpm = (i == 0) ? startBpm : timeChanges[i - 1].bpm;
					var progress = (interpStart - event.time) / event.duration;
					var progressEnd = (interpEnd - event.time) / event.duration;

					var steps:Float = 0.0;
					// var stepsPerPart:Int = 100;
					var stepsPerPart:Int = Math.floor(interpDuration / 10);
					var partDuration:Float = interpDuration / stepsPerPart;

					for (j in 0...stepsPerPart) {
						var partStart = interpStart + j * partDuration;
						// var partProgress = (partStart - event.time) / event.duration;
						var currentBpm = Util.lerp(prevBpm, event.bpm, event.caltEase(partStart));
						steps += partDuration * currentBpm.getStepsPerMs();
					}

					totalSteps += steps;
					timePassed += interpDuration;
				}
				lastBpm = event.bpm;
				lastEventEndTime = eventEndTime;
			} else {
				lastBpm = event.bpm;
				lastEventEndTime = event.time;
			}

			if (time > eventEndTime && (nextEvent == null || time < nextEvent.time)) {
				var segmentStart = eventEndTime;
				var segmentEnd = (nextEvent != null ? Math.min(nextEvent.time, time) : time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0) {
					totalSteps += segmentDuration * lastBpm.getStepsPerMs();
					timePassed += segmentDuration;
				}
				lastEventEndTime = segmentEnd;
			}

			if (time <= lastEventEndTime) break;
		}

		if (time > lastEventEndTime) {
			var segmentDuration = time - lastEventEndTime;
			totalSteps += segmentDuration * lastBpm.getStepsPerMs();
		}

		return totalSteps;
	}

	public function getCumulativeMeasures(time:Float):Float {
		if (timeChanges.length == 0)
			return currentBeatTime / Constants.BEATS_PER_MEASURE * Util.getTimeSignatureFactor(Constants.TIME_SIGNATURE_NUM, Constants.TIME_SIGNATURE_DEN);

		var totalMeasures:Float = 0;
		var lastEventEndTime:Float = 0;
		var lastBpm:Float = startBpm;
		var lastTimeSignatureNum:TimeSignature = Constants.TIME_SIGNATURE_NUM;
		var lastTimeSignatureDen:TimeSignature = Constants.TIME_SIGNATURE_DEN;
		var timePassed:Float = 0;

		for (i in 0...timeChanges.length) {
			var event:MusicTimeChangeEvent = timeChanges[i];
			var nextEvent:Null<MusicTimeChangeEvent> = timeChanges[i + 1];
			var eventEndTime = event.time;

			if (lastEventEndTime < event.time && time > lastEventEndTime) {
				var segmentStart = lastEventEndTime;
				var segmentEnd = Math.min(event.time, time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0) {
					var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
					totalMeasures += segmentDuration / measureLengthMs;
					timePassed += segmentDuration;
				}
			}

			if (time <= event.time) break;

			lastTimeSignatureNum = event.timeSignatureNum;
			lastTimeSignatureDen = event.timeSignatureDen;

			if (event.duration > 0) {
				eventEndTime += event.duration;
				var interpStart = Math.max(event.time, lastEventEndTime);
				var interpEnd = Math.min(eventEndTime, time);
				var interpDuration = interpEnd - interpStart;

				if (interpDuration > 0) {
					var prevBpm = (i == 0) ? startBpm : timeChanges[i - 1].bpm;
					// var stepsPerPart = 100;
					var stepsPerPart:Int = Math.floor(interpDuration / 10);
					var partDuration = interpDuration / stepsPerPart;

					for (j in 0...stepsPerPart) {
						var partStart = interpStart + j * partDuration;
						// var partProgress = (partStart - event.time) / event.duration;
						var currentBpm = Util.lerp(prevBpm, event.bpm, event.caltEase(partStart));

						var measureLengthMs = currentBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
						totalMeasures += partDuration / measureLengthMs;
					}
					timePassed += interpDuration;
				}
				lastBpm = event.bpm;
				lastEventEndTime = eventEndTime;
			} else {
				lastBpm = event.bpm;
				lastEventEndTime = event.time;
			}

			if (time > lastEventEndTime && (nextEvent == null || time < nextEvent.time)) {
				var segmentStart = lastEventEndTime;
				var segmentEnd = (nextEvent != null ? Math.min(nextEvent.time, time) : time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0) {
					var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
					totalMeasures += segmentDuration / measureLengthMs;
					timePassed += segmentDuration;
				}
				lastEventEndTime = segmentEnd;
			}

			if (time <= lastEventEndTime) break;
		}

		if (time > lastEventEndTime) {
			var segmentDuration = time - lastEventEndTime;
			var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
			totalMeasures += segmentDuration / measureLengthMs;
		}

		return totalMeasures;
	}

	function setTargetTime(time:Float) {
		var _target:Null<RhythmConductorTarget> = target;
		if (_target != null) _target.time = time;
	}

	private inline function get_musicPosition() {
		return (musicPosition + musicPositionOffset).clamp(0, musicLength);
	}

	private inline function get_frameMusicPosition() {
		return (frameMusicPosition + musicPositionOffset).clamp(0, musicLength);
	}

	private inline function set_percent(v) {
		final newMusicPos = musicLength * v;
		setTargetTime(newMusicPos);
		this.update(newMusicPos);
		return v;
	}

	private inline function get_percent() {
		return musicPosition / (Math.max(1, musicLength));
	}

	private inline function get_musicLength() {
		return target?.length ?? Constants.MS_PER_SECS; // 1000 ms
	}

	private static function get_instance() {
		if (RhythmConductor._instance == null)
			set_instance(new RhythmConductor());

		if (RhythmConductor._instance == null)
			throw "Could not initialize RhythmConductor instance!";

		return RhythmConductor._instance;
	}

	private static function set_instance(newInstance:RhythmConductor):RhythmConductor {
		if (RhythmConductor._instance != null)
			clearSingleton(RhythmConductor._instance);

		RhythmConductor._instance = newInstance;

		if (RhythmConductor._instance != null)
			setupSingleton(RhythmConductor._instance);

		return RhythmConductor._instance;
	}

	private function get_target() {
		return _target #if flixel ?? flixel.FlxG.sound?.music #end;
	}

	private inline function set_target(v) {
		return _target = v;
	}

	private function get_measureLengthMs() {
		return currentBpm.getMeasureLengthMs(timeSignatureNumerator, timeSignatureDenominator);
	}

	private function get_beatLengthMs() {
		return currentBpm.getBeatLengthMs();
	}

	private inline function get_stepLengthMs() {
		return currentBpm.getStepLengthMs();
	}

	private function get_beatsPerMeasure() {
		return Util.getBeatsPerMeasure(timeSignatureNumerator, timeSignatureDenominator);
	}

	private function get_stepsPerMeasure() {
		return Util.getStepsPerMeasure(timeSignatureNumerator, timeSignatureDenominator);
	}

	private inline function get_timeSignatureNumerator() {
		return currentTimeChange?.timeSignatureNum ?? Constants.TIME_SIGNATURE_NUM;
	}

	private inline function get_timeSignatureDenominator() {
		return currentTimeChange?.timeSignatureDen ?? Constants.TIME_SIGNATURE_DEN;
	}

	private function get_currentBpm() {
		if (overrideBpm != null)
			return overrideBpm;

		return getCurrentTimeChangeBPMAccurate(musicPosition);
	}

	private function get_startBpm() {
		if (overrideBpm != null)
			return overrideBpm;

		return timeChanges[0]?.bpm ?? Constants.BPM;
	}
}
