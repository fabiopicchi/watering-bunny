package core;

import haxe.ds.IntMap;

import openfl.display.BitmapData;

class State extends Element
{
    private var _keyboardState:Int;
    private var _keyboardChanged:Int;

    public function new()
    {
        super();

        _keyboardState = 0;
        _keyboardChanged = 0;
    }

    public function takeScreenshot():BitmapData
    {
        var bmp:BitmapData = new BitmapData(stage.stageWidth,
            stage.stageHeight, true);
        bmp.draw(stage);

        return bmp;
    }

    private function justPressed(buttonCode:Int) 
    {
        return (_keyboardChanged & buttonCode == buttonCode &&
                _keyboardState & buttonCode == buttonCode);
    }

    private function justReleased(buttonCode:Int) 
    {
        return (_keyboardChanged & buttonCode == buttonCode &&
                _keyboardState & buttonCode != buttonCode);
    }

    private function pressed(buttonCode:Int) 
    {
        return (_keyboardState & buttonCode == buttonCode);
    }

    public function getInputActions():IntMap<Int>
    {
        return new IntMap<Int>();
    }

    public function updateInput(keyboardState:Int)
    {
        _keyboardChanged = (keyboardState ^ _keyboardState);
        _keyboardState = keyboardState;
    }

    public function onEnter():Void
    {

    }

    public function onLeave():Void
    {

    }
}
