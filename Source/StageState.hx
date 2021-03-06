import haxe.Json;
import haxe.ds.IntMap;
import openfl.events.Event;
import openfl.geom.Point;

import openfl.Assets;
import openfl.ui.Keyboard;
import openfl.display.BitmapData;

import core.Element;
import core.State;
import core.GameSoundEvent;
import core.SwitchStateEvent;

class StageState extends State
{
    private var LEFT:Int = 1 << 0;
    private var RIGHT:Int = 1 << 1;
    private var UP:Int = 1 << 2;
    private var DOWN:Int = 1 << 3;
    private var WATER:Int = 1 << 4;

    private var PLAYER_DETECTION_RADIUS:Float = 300;

    private var _currentLevel:Int;

    private var _player:Player;
    private var _levelEnd:LevelEnd;
    private var _hud:HUD;
    private var _guards = new List <Guard> ();

    private var _puddleLayer:Element;
    private var _lowerLayer1:Tilemap;
    private var _lowerLayer2:Tilemap;
    private var _shadeLayer:Tilemap;
    private var _collideLayer:Tilemap;
    private var _upperLayer:Tilemap;

    private var _lasers = new List <Laser> ();
    private var _puddles = new List <Puddle> ();
    private var _cameras = new List <Camera> ();
    private var _circuits = new List <Circuit> ();
    private var _terminals = new List <Terminal> ();
    private var _plants = new List <Plant> ();

    public function new(levelNumber:Int)
    {
        super();
        _currentLevel = levelNumber;
    }

    override public function onEnter():Void
    {
        dispatchEvent(new GameSoundEvent(GameSoundEvent.BG_MUSIC,
                    "assets/sound/fase_1_reason.ogg"));

        var json:String = Assets.getText("stages/level" + _currentLevel + ".json");

        if(json != null)
        {
            loadLevel(Json.parse(json));
        }
        else
        {
            dispatchEvent(new SwitchStateEvent(SwitchStateEvent.SWITCH_STATE,
                    new MainMenuState()));
        }
    }

    private function loadLevel(obj):Void
    {
        var tileset:BitmapData = Assets.getBitmapData("images/tileset.png");
        var layers:Array<Dynamic> = obj.layers;

        for (layer in layers)
        {
            if (layer.name == "lower1")
            {
                _lowerLayer1 = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
            if (layer.name == "lower2")
            {
                _lowerLayer2 = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
            if (layer.name == "shade")
            {
                _shadeLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
            if (layer.name == "collide")
            {
                _collideLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
            if (layer.name == "upper")
            {
                _upperLayer = new Tilemap(layer, tileset, obj.tilewidth, obj.tileheight);
            }
            if (layer.name == "guards")
            {
                var objects:Array<Dynamic> = layer.objects;
                var behavior:Int;
                var route:Array<Point>;

                for (object in objects)
                {
                    behavior = Std.parseInt(object.properties.bhv);
                    route = new Array<Point> ();
                    var polylines:Array<Dynamic> = object.polyline;

                    for (coordinate in polylines)
                    {
                        route.push(new Point(coordinate.x + object.x, coordinate.y + object.y));
                    }
                    _guards.add (new Guard (behavior, route));
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
                        _lasers.add (new Laser (object.x, object.y + 30, object.width , Std.parseInt(object.properties.direction),
                                    object.properties.color, Std.parseInt(object.properties.id)));
                    }
                    if (object.name == "camera")
                    {
                        _cameras.add (new Camera (object.x, object.y, object.properties.color, Std.parseInt(object.properties.id)));
                    }
                    if (object.name == "terminal")
                    {
                        var t:Terminal = new Terminal (object.x, object.y,
                                Std.parseInt(object.properties.id),
                                Std.parseInt(object.properties.direction),
								Std.parseInt(object.properties.time),
                                object.properties.color);
                        t.addEventListener(CircuitEvent.REACTIVATE,
                                reactivate);
                        _terminals.add(t);
                    }
                    if (object.name == "circuit")
                    {
                        var route = new Array<Point> ();
                        var polylines:Array<Dynamic> = object.polyline;

                        for (coordinate in polylines)
                        {
                            route.push(new Point(coordinate.x + object.x, coordinate.y + object.y));
                        }
                        var c:Circuit = new Circuit
                            (Std.parseInt(object.properties.id), route);
                        c.addEventListener(CircuitEvent.DEACTIVATE,
                                deactivate);
                        _circuits.add (c);
                    }
                    if (object.name == "levelEnd")
                    {
                        _levelEnd = new LevelEnd(object.x,object.y);
                    }
                    if (object.name == "plant")
                    {
                        var p:Plant = new Plant(object.x, object.y);
                        _plants.add(p);
                    }
                }
            }
        }

        addElement(_lowerLayer1);
		_puddleLayer = new Element();
        addElement(_puddleLayer);
        addElement(_collideLayer);
        addElement(_lowerLayer2);
        addElement(_shadeLayer);
        for (i in _lasers) addElement(i);
		for (i in _terminals) addElement(i);
		for (i in _plants) addElement(i);
        addElement(_player);
        for (i in _guards) addElement(i);
        addElement(_upperLayer);
        for (i in _circuits) addElement(i);
        for (i in _cameras) addElement(i);
        _hud = new HUD();
        addElement(_hud);
    }

    override public function getInputActions():IntMap<Int>
    {
        var inputMap:IntMap<Int> = new IntMap<Int>();
        inputMap.set(Keyboard.A, LEFT);
        inputMap.set(Keyboard.LEFT, LEFT);
        inputMap.set(Keyboard.S, DOWN);
        inputMap.set(Keyboard.DOWN, DOWN);
        inputMap.set(Keyboard.D, RIGHT);
        inputMap.set(Keyboard.RIGHT, RIGHT);
        inputMap.set(Keyboard.W, UP);
        inputMap.set(Keyboard.UP, UP);
        inputMap.set(Keyboard.SPACE, WATER);
        return inputMap;
    }

    override public function update (dt:Float)
    {
        var hor:Int = 0;
        var ver:Int = 0;
        if(pressed(UP) && !pressed(DOWN))
        {
            ver = -1;
        }
        else if(pressed(DOWN) && !pressed(UP))
        {
            ver = 1;
        }

        if(pressed(LEFT) && !pressed(RIGHT))
        {
            hor = -1;
        }
        else if(pressed(RIGHT) && !pressed(LEFT))
        {
            hor = 1;
        }
        _player.move(hor, ver);

        if(justPressed(WATER))
        {
            _player.water();

            var b:Body = new Body(1,1);
            b.position.y = _player.getBody().position.y + 10;

            if (_player.getFacing() == 0)
            {
                b.position.x = _player.getBody().position.x +
                    _player.getBody().width + 30; 
            }
            else
            {
                b.position.x = _player.getBody().position.x - 30  + 5;
            }

            for(t in _terminals)
            {
                if (t.getBody().overlapBody(b))
                {
                    t.deactivate();
                    for (c in _circuits)
                    {
                        if (t.id == c.id)
                        {
                            c.activate();
                            break;
                        }
                    }
                    break;
                }
            }

            for(p in _plants)
            {
                if (p.getBody().overlapBody(b))
                {
                    p.water();
                    break;
                }
            }

            if(!_collideLayer.collidePoint(b.position.x + b.width/2,
                        b.position.y + b.height/2))
            {
                var p:Puddle = new Puddle(b.position.x, b.position.y);
                _puddles.add(p);
                _puddleLayer.addElement(p);

                if (_puddleLayer.numChildren >= 4) 
                {
                    _puddles.pop().startDisappearing();
                }
            }
        }

        for (p in _puddles)
        {
            if(!p.visible)
            {
                _puddleLayer.removeElement(p);
                _puddles.remove(p);
            }
        }

        super.update(dt);

        _collideLayer.collideTilemap(_player.getBody());

        var playerPoint = new Point (_player.getBody().position.x +
                _player.getBody().width / 2, _player.getBody().position.y +
                _player.getBody().height / 2);

        x = - (playerPoint.x - stage.stageWidth/2 + _player.getBody().width/2);
        if (x > 0) x = 0;
        if (x < -_collideLayer.width + stage.stageWidth) 
            x = -_collideLayer.width + stage.stageWidth;

        y = - (playerPoint.y - stage.stageHeight/2 + _player.getBody().height/2);
        if (y > 0) y = 0;
        if (y < -_collideLayer.height + stage.stageHeight) 
            y = -_collideLayer.height + stage.stageHeight;

        _hud.x = -x + 20;
        _hud.y = -y + 20; 
        
        #if debug
        _upperLayer.graphics.clear();
        #end
        for (g in _guards)
        {
            for (p in _puddles)
            {
                if (p.getBody().overlapBody(g.getBody()))
                {
                    g.interrupt();
                }
            }

            if (!g.isInterrupted())
            {
                var playerDistance = Point.distance(g.eye, playerPoint);

                if (playerDistance < PLAYER_DETECTION_RADIUS) 
                {
                    var angle:Float = Math.atan2(playerPoint.y - g.eye.y, 
                            playerPoint.x - g.eye.x);
                    if (angle < 0) angle += 2 * Math.PI;

                    #if debug
                    _upperLayer.graphics.lineStyle(1, 0xFF0000);
                    _upperLayer.graphics.moveTo(g.eye.x, g.eye.y);
                    _upperLayer.graphics.lineTo(
                        g.eye.x + playerDistance * Math.cos(angle),
                        g.eye.y + playerDistance * Math.sin(angle));
                    #end

                    if (g.isFacing(angle))
                    {
                        if (_collideLayer.isPointVisible(g.eye, playerPoint)) 
                        {
                            g.alert();
                            _hud.increase(2);
                            if (playerDistance < 130)
                            {
                                _hud.increase(5);
                            }
                        }
                    }
                }
                if (playerDistance < 30)
                {
                    g.alert();
                    _hud.increase(4);
                }
            }
        }
		
		for (c in _cameras)
        {

			var playerDistance = Point.distance(c.eye, playerPoint);

			if (playerDistance < PLAYER_DETECTION_RADIUS && c.active) 
			{
				var angle:Float = Math.atan2(playerPoint.y - c.eye.y, 
						playerPoint.x - c.eye.x);
				if (angle < 0) angle += 2 * Math.PI;

                #if debug
                _upperLayer.graphics.lineStyle(1, 0xFF0000);
                _upperLayer.graphics.moveTo(c.eye.x, c.eye.y);
                _upperLayer.graphics.lineTo(
                    c.eye.x + playerDistance * Math.cos(angle),
                    c.eye.y + playerDistance * Math.sin(angle));
                #end

				if (angle >= c.angle * Math.PI / 2 - Math.PI / 4 &&
						angle <= c.angle * Math.PI / 2 + Math.PI / 4)
				{
					if (_collideLayer.isPointVisible(c.eye, playerPoint)) 
					{
						c.alert();
						_hud.increase(2);
						if (playerDistance < 140)
						{
							_hud.increase(5);
						}
					}
				}
			}
        }

        for (l in _lasers)
        {
            if (_player.getBody().overlapBody(l.getBody()) && l.visible) 
            {
                _hud.increase(20);
            }
        }

        if (_player.getBody().overlapBody(_levelEnd.getBody())) 
        {
            dispatchEvent(new SwitchStateEvent(SwitchStateEvent.SWITCH_STATE,
                        new WinState(takeScreenshot(), _currentLevel)));
        }

        if (_hud.isFull() ) {
            dispatchEvent(new SwitchStateEvent(SwitchStateEvent.SWITCH_STATE,
                        new GameOverState(takeScreenshot(), _currentLevel)));
        }
    }

    override public function draw():Void
    {
        super.draw();
    }

    private function deactivate(e:CircuitEvent)
    {
        for(c in _circuits)
        {
            if (c.id == e.id)
            {
                for (cam in _cameras)
                {
                    if (c.id == cam.id)
                    {
                        cam.deactivate();
                        break;
                    }
                }

                for (l in _lasers)
                {
                    if (c.id == l.id)
                    {
                        l.deactivate();
                        break;
                    }
                }
                break;
            }
        }
    }

    private function reactivate(e:CircuitEvent)
    {
        for(t in _terminals)
        {
            if (t.id == e.id)
            {
                for (c in _circuits)
                {
                    if (t.id == c.id)
                    {
                        c.reset();
                        break;
                    }
                }

                for (cam in _cameras)
                {
                    if (t.id == cam.id)
                    {
                        cam.activate();
                        break;
                    }
                }

                for (l in _lasers)
                {
                    if (t.id == l.id)
                    {
                        l.activate();
                        break;
                    }
                }
                break;
            }

        }
    }
}
