import haxe.Json;
import haxe.ds.IntMap;
import openfl.geom.Point;

import openfl.Assets;
import openfl.ui.Keyboard;
import openfl.display.BitmapData;

import core.State;

class StageState extends State
{
    private var LEFT:Int = 1 << 0;
    private var RIGHT:Int = 1 << 1;
    private var UP:Int = 1 << 2;
    private var DOWN:Int = 1 << 3;

    private var PLAYER_DETECTION_RADUIS:Float;

    private var _player:Player;
    private var _hud:HUD;
	private var _guards = new List <Guard> ();

    private var _lowerLayer:Tilemap;
	private var _collideLayer:Tilemap;
	private var _upperLayer:Tilemap;
	private var _shadeLayer:Tilemap;
	
	private var _lasers = new List <Laser> ();
	//private var _cameras = new List <Camera> ();
	//private var _circuits = new List <Circuit> ();
	//private var _terminals = new List <Terminal> ();

    public function new()
    {
        super();

        PLAYER_DETECTION_RADUIS = Math.sqrt(800 * 800 + 600 * 600);

        var obj:Dynamic = Json.parse(Assets.getText("assets/level1.json"));
        var tileset:BitmapData = Assets.getBitmapData("assets/tileset.png");
        var layers:Array<Dynamic> = obj.layers;

        for (layer in layers)
        {
            if (layer.name == "lower")
            {
				_lowerLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
			if (layer.name == "collide")
            {
				_collideLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
			if (layer.name == "upper")
            {
				_upperLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
			if (layer.name == "shade")
            {
				_shadeLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
			if (layer.name == "guards")
            {
				var objects:Array<Dynamic> = layer.objects;
				var behavior:Int;
				var route:Array<Point>;
				
				for (object in objects)
				{
					if (object.name == "guard")
					{
						behavior = Std.parseInt(object.properties.behavior);
						route = new Array<Point> ();
						var polylines:Array<Dynamic> = object.polyline;
						
						for (coordinate in polylines)
						{
							route.push(new Point(coordinate.x + object.x, coordinate.y + object.y));
						}
						_guards.add (new Guard (behavior, route));	
					}
				}
            }
			if (layer.name == "objects")
            {
				var objects:Array<Dynamic> = layer.objects;
				
				for (object in objects)
				{
					if (object.name == "player")
					{
						_player = new Player(object.x,object.y);
					}
					if (object.name == "laser")
					{
						_lasers.add (new Laser (object.x, object.y, Math.floor((object.width / 30)), Std.parseInt(object.properties.direction),
							object.properties.color, Std.parseInt(object.properties.id)));
					}
					if (object.name == "camera")
					{
						//_cameras.add (new Camera (object.x, object.y, Std.parseInt(object.properties.direction), Std.parseInt(object.properties.id)));
					}
					if (object.name == "terminal")
					{
						//_terminals.add (new Terminal (object.x, object.y, Std.parseInt(object.properties.direction), Std.parseInt(object.properties.id)));
					}
					if (object.name == "circuit")
					{
						//_circuits.add (new Circuit (route, Std.parseInt(object.properties.id)));
					}
					if (object.name == "levelEnd")
					{
						//_levelEnd = new LevelEnd(object.x,object.y);
					}
				}
			}
        }

        addElement(_lowerLayer);
		addElement(_collideLayer);
		addElement(_player);
		for (i in _guards) addElement(i);
		for (i in _lasers) addElement(i);
		addElement(_upperLayer);
		addElement(_shadeLayer);
		
        _hud = new HUD();
        addElement(_hud);
    }

    override public function setInputActions(inputMap:IntMap<Int>)
    {
        inputMap.set(Keyboard.A, LEFT);
        inputMap.set(Keyboard.LEFT, LEFT);
        inputMap.set(Keyboard.S, DOWN);
        inputMap.set(Keyboard.DOWN, DOWN);
        inputMap.set(Keyboard.D, RIGHT);
        inputMap.set(Keyboard.RIGHT, RIGHT);
        inputMap.set(Keyboard.W, UP);
        inputMap.set(Keyboard.UP, UP);
    }

    override public function update (dt:Float)
    {
        var hor:Int = 0;
        var ver:Int = 0;
        if (pressed(UP) && !pressed(DOWN))
        {
            ver = -1;
        }
        else if (pressed(DOWN) && !pressed(UP))
        {
            ver = 1;
        }

        if (pressed(LEFT) && !pressed(RIGHT))
        {
            hor = -1;
        }
        else if(pressed(RIGHT) && !pressed(LEFT))
        {
            hor = 1;
        }

        _player.move(hor, ver);

        super.update(dt);

        _collideLayer.collideTilemap(_player.getBody());

		var playerPoint = new Point (_player.getBody().position.x +
                _player.getBody().width / 2, _player.getBody().position.y +
                _player.getBody().height / 2);
	    
        x = - (_player.x - stage.stageWidth/2 + _player.width/2);
        if (x > 0) x = 0;
        if (x < -_collideLayer.width + stage.stageWidth) x =
            -_collideLayer.width + stage.stageWidth;

        y = - (_player.y - stage.stageHeight/2 + _player.height/2);
        if (y > 0) y = 0;
        if (y < -_collideLayer.height + stage.stageHeight) y =
            -_collideLayer.height + stage.stageHeight;

		for (g in _guards)
		{
            var playerDistance = Point.distance(g.eye, playerPoint);

			if (playerDistance < PLAYER_DETECTION_RADUIS) 
            {
                var angle:Float = Math.atan2(playerPoint.y - g.eye.y, 
                        playerPoint.x - g.eye.x);
                if (angle < 0) angle += 2 * Math.PI;

                if (angle >= g.faceDirection * Math.PI / 2 - Math.PI / 4 &&
                        angle <= g.faceDirection * Math.PI / 2 + Math.PI / 4)
                {
                    if (_collideLayer.isPointVisible(g.eye, playerPoint)) 
                    {
                        g.alert();
                        _hud.increase(2);
                    }
                }
            }
        }
    }
}
