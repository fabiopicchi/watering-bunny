import haxe.ds.IntMap;

import openfl.Lib;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

class Game extends Sprite 
{
    private var _lastFrame:Int;
    private var _state:StageState;
	private var _bgm:Bgm;
	private var _currentLevel:Int = 1;

    private var _usedKeys:IntMap<Int>;

    private var _keyboardRaw:Int;

    public function new() 
    {
        super();
        
        _usedKeys = new IntMap<Int>();
        _state = new StageState(_currentLevel);
        _state.setInputActions(_usedKeys);

        addChild(_state);
		
		//_bgm = new Bgm ("Assets/amigo_coelho.mp3");

        _keyboardRaw = 0;
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		addEventListener ("nextLevelEvent", onReachingLevelEnd);

        _lastFrame = Lib.getTimer();
        stage.addEventListener(Event.ENTER_FRAME, run);
    }

    private function onKeyDown(e:KeyboardEvent):Void
    {
        if (_usedKeys.exists(e.keyCode))
        {
            _keyboardRaw |= _usedKeys.get(e.keyCode);
        }
    }

    private function onKeyUp(e:KeyboardEvent):Void
    {
        if (_usedKeys.exists(e.keyCode))
        {
            _keyboardRaw &= (~_usedKeys.get(e.keyCode));
        }
    }

    public function run(e:Event):Void
    {
        var dt:Float = (Lib.getTimer() - _lastFrame) / 1000;

        _state.updateInput(_keyboardRaw);
        _state.update(dt);
        _state.draw();

        _lastFrame = Lib.getTimer();
    }

	public function onReachingLevelEnd (event:Event):Void {
		
		if (_currentLevel < 3)
		{
			removeChild(_state);
			_state = new StageState(++_currentLevel);
			addChild(_state);
		}
		else {
			//credits minigame goes here			
		}
		
	}
}
